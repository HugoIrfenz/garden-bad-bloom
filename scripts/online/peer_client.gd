extends Node

# Room discovery and WebRTC mesh; no public game server runs the fight.
signal session_joined(code: String, token: String, player_id: String)
signal room_changed(state: Dictionary)
signal host_changed(host_id: String, epoch: int)
signal connection_problem(message: String)
signal reconnecting(seconds_left: float)
signal peer_joined(id: int)
signal peer_left(id: int)
signal session_left

const REJOIN_SECONDS := 60.0
const RETRY_SECONDS := 2.0
const HEARTBEAT_SECONDS := 20.0
const CONNECT_TIMEOUT_SECONDS := 10.0
const PEER_RECOVERY_SECONDS := 4.0
const OnlineSession = preload("res://scripts/online/online_session.gd")
const RunReplica = preload("res://scripts/online/run_replica.gd")
const DEFAULT_ICE := [{"urls": ["stun:stun.cloudflare.com:3478"]}]

var endpoint := ""
var code := ""
var token := ""
var username := ""
var player_id := ""
var room: Dictionary = {}
var ice_servers: Array = []
var mesh: WebRTCMultiplayerPeer
var socket := WebSocketPeer.new()
var socket_state := WebSocketPeer.STATE_CLOSED
var create_request: HTTPRequest
var replica: Node
var session: Node
var pending_join := false
var deliberate_close := false
var deadline := 0.0
var next_retry := 0.0
var heartbeat := 0.0
var socket_connect_started := -1.0
var peers: Dictionary = {}
var pending_signals: Array[Dictionary] = []
var peer_recovery: Dictionary = {}

func _ready() -> void:
	replica = RunReplica.new()
	replica.name = "RunReplica"
	add_child(replica)
	session = OnlineSession.new()
	session.name = "OnlineSession"
	add_child(session)
	session.configure(self)
	create_request = HTTPRequest.new()
	add_child(create_request)
	create_request.request_completed.connect(_created)

func host(server_url: String, name: String) -> Error:
	reset_session()
	endpoint = server_url.trim_suffix("/")
	username = name.strip_edges()
	if endpoint.is_empty() or username.is_empty():
		return ERR_INVALID_PARAMETER
	return create_request.request(endpoint + "/rooms", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"username": username}))

func join(server_url: String, room_code: String, name: String) -> Error:
	reset_session()
	endpoint = server_url.trim_suffix("/")
	code = room_code.strip_edges().to_upper()
	username = name.strip_edges()
	if endpoint.is_empty() or code.length() != 6 or username.is_empty():
		return ERR_INVALID_PARAMETER
	pending_join = true
	return open_socket()

func rejoin(server_url: String, room_code: String, saved_token: String) -> Error:
	reset_session()
	endpoint = server_url.trim_suffix("/")
	code = room_code.strip_edges().to_upper()
	token = saved_token
	if endpoint.is_empty() or code.length() != 6 or token.length() != 64:
		return ERR_INVALID_PARAMETER
	return open_socket()

func _created(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var payload: Variant = JSON.parse_string(body.get_string_from_utf8())
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 201 or not payload is Dictionary:
		connection_problem.emit("Could not create the online room.")
		return
	code = str(payload.get("code", ""))
	token = str(payload.get("token", ""))
	player_id = str(payload.get("id", ""))
	# Persist the token before opening a connection, so closing the app can rejoin.
	session_joined.emit(code, token, player_id)
	var error := open_socket()
	if error != OK:
		connection_problem.emit("Could not connect to the room: " + error_string(error))

func open_socket() -> Error:
	socket = WebSocketPeer.new()
	socket_state = WebSocketPeer.STATE_CONNECTING
	socket_connect_started = Time.get_ticks_msec() / 1000.0
	var address := endpoint
	if address.begins_with("https://"):
		address = "wss://" + address.trim_prefix("https://")
	elif address.begins_with("http://"):
		address = "ws://" + address.trim_prefix("http://")
	else:
		return ERR_INVALID_PARAMETER
	var error := socket.connect_to_url(address + "/rooms/" + code + "/ws")
	if error != OK:
		socket_state = WebSocketPeer.STATE_CLOSED
	return error

func _process(delta: float) -> void:
	var tick_now := Time.get_ticks_msec() / 1000.0
	# Mobile handovers can leave a TCP handshake stuck in CONNECTING forever.
	# Bound each attempt as well as the overall reconnect window.
	if socket_connect_started >= 0.0 and tick_now - socket_connect_started >= CONNECT_TIMEOUT_SECONDS:
		socket.close()
		socket_state = WebSocketPeer.STATE_CLOSED
		socket_connect_started = -1.0
		if not deliberate_close and not token.is_empty() and deadline <= 0.0:
			deadline = tick_now + REJOIN_SECONDS
			next_retry = tick_now + RETRY_SECONDS
		elif token.is_empty():
			connection_problem.emit("Unable to connect to the room.")
	if deadline > 0.0 and tick_now >= deadline and not deliberate_close:
		socket.close()
		socket_state = WebSocketPeer.STATE_CLOSED
		socket_connect_started = -1.0
		deadline = 0.0
		connection_problem.emit("Rejoin time expired.")
		return
	if deadline > 0.0 and socket_state == WebSocketPeer.STATE_CLOSED and not deliberate_close:
		var now := tick_now
		if now >= next_retry:
			next_retry = now + RETRY_SECONDS
			var error := open_socket()
			if error != OK:
				socket_state = WebSocketPeer.STATE_CLOSED
			reconnecting.emit(maxf(0.0, deadline - now))
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and socket_state != state:
		if pending_join:
			send({"type": "join", "username": username})
		else:
			send({"type": "auth", "token": token})
	if state == WebSocketPeer.STATE_OPEN:
		heartbeat += delta
		if heartbeat >= HEARTBEAT_SECONDS:
			heartbeat = 0.0
			send({"type": "ping"})
		_recover_dropped_peer(tick_now)
	while state == WebSocketPeer.STATE_OPEN and socket.get_available_packet_count() > 0:
		var payload: Variant = JSON.parse_string(socket.get_packet().get_string_from_utf8())
		if payload is Dictionary:
			receive(payload)
	if state == WebSocketPeer.STATE_CLOSED and socket_state != state and not deliberate_close:
		# The room removes this connection from the other phones while it is
		# offline. Rebuild our side too, otherwise a rejoined app can retain stale
		# peer entries and never negotiate a fresh connection with the party.
		if mesh != null:
			for id: String in peers.keys():
				var remote := int(peers[id])
				if mesh.has_peer(remote):
					mesh.remove_peer(remote)
			peers.clear()
		pending_signals.clear()
		peer_recovery.clear()
		if not token.is_empty() and deadline <= 0.0:
			deadline = Time.get_ticks_msec() / 1000.0 + REJOIN_SECONDS
			next_retry = 0.0
		elif token.is_empty():
			connection_problem.emit("Unable to join the room: " + socket.get_close_reason())
	socket_state = state

func receive(message: Dictionary) -> void:
	match str(message.get("type", "")):
		"joined", "authenticated":
			socket_connect_started = -1.0
			pending_join = false
			player_id = str(message.get("id", player_id))
			token = str(message.get("token", token))
			deadline = 0.0
			session_joined.emit(code, token, player_id)
			send({"type": "ice"})
		"room":
			var old_host := str(room.get("host", ""))
			var old_epoch := int(room.get("epoch", -1))
			room = message
			replica.update_roster(room, player_id)
			if old_host != str(room.get("host", "")) or old_epoch != int(room.get("epoch", -1)):
				host_changed.emit(str(room.get("host", "")), int(room.get("epoch", 0)))
			room_changed.emit(room)
			refresh_peers()
		"ice":
			ice_servers = message.get("iceServers", DEFAULT_ICE)
			refresh_peers()
		"signal":
			pending_signals.append(message)
			drain_signals()
		"left":
			session_left.emit()
		"error":
			connection_problem.emit(str(message.get("message", "Online connection failed.")))

func refresh_peers() -> void:
	if room.is_empty() or player_id.is_empty() or ice_servers.is_empty():
		return
	var local_id := 0
	var desired := {}
	for row: Dictionary in room.get("players", []):
		if row.id == player_id:
			local_id = int(row.peerId)
		elif bool(row.connected):
			desired[str(row.id)] = int(row.peerId)
	if local_id < 2:
		return
	if mesh == null:
		mesh = WebRTCMultiplayerPeer.new()
		var error := mesh.create_mesh(local_id)
		if error != OK:
			connection_problem.emit("Could not create peer network: " + error_string(error))
			return
		multiplayer.multiplayer_peer = mesh
		if not multiplayer.peer_connected.is_connected(_peer_connected):
			multiplayer.peer_connected.connect(_peer_connected)
		if not multiplayer.peer_disconnected.is_connected(_peer_disconnected):
			multiplayer.peer_disconnected.connect(_peer_disconnected)
	for id: String in peers.keys():
		if not desired.has(id):
			var old_peer := int(peers[id])
			if mesh.has_peer(old_peer):
				mesh.remove_peer(old_peer)
			peers.erase(id)
	for id: String in desired:
		if peers.has(id):
			continue
		var remote: int = desired[id]
		var connection := WebRTCPeerConnection.new()
		var error := connection.initialize({"iceServers": ice_servers})
		if error != OK:
			connection_problem.emit("Could not initialize peer connection: " + error_string(error))
			continue
		connection.session_description_created.connect(_description_created.bind(id))
		connection.ice_candidate_created.connect(_candidate_created.bind(id))
		error = mesh.add_peer(connection, remote)
		if error != OK:
			connection_problem.emit("Could not add peer: " + error_string(error))
			continue
		peers[id] = remote
		if remote < local_id:
			connection.create_offer()
	drain_signals()

func _description_created(kind: String, sdp: String, id: String) -> void:
	if mesh == null or not peers.has(id) or not mesh.has_peer(int(peers[id])):
		return
	var connection: WebRTCPeerConnection = mesh.get_peer(int(peers[id])).connection
	connection.set_local_description(kind, sdp)
	send({"type": "signal", "to": id, "kind": kind, "payload": {"sdp": sdp}})

func _candidate_created(mid: String, index: int, candidate: String, id: String) -> void:
	send({"type": "signal", "to": id, "kind": "candidate", "payload": {"mid": mid, "index": index, "candidate": candidate}})

func drain_signals() -> void:
	if mesh == null:
		return
	var remaining: Array[Dictionary] = []
	for message: Dictionary in pending_signals:
		var id := str(message.get("from", ""))
		if not peers.has(id) or not mesh.has_peer(int(peers[id])):
			remaining.append(message)
			continue
		var connection: WebRTCPeerConnection = mesh.get_peer(int(peers[id])).connection
		var payload: Dictionary = message.get("payload", {})
		match str(message.get("kind", "")):
			"offer", "answer": connection.set_remote_description(str(message.kind), str(payload.get("sdp", "")))
			"candidate": connection.add_ice_candidate(str(payload.get("mid", "")), int(payload.get("index", 0)), str(payload.get("candidate", "")))
	pending_signals = remaining

func select_hero(hero: int, ready: bool) -> void:
	send({"type": "select", "hero": hero, "ready": ready})

func start_run() -> void:
	send({"type": "start"})

func send(payload: Dictionary) -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(payload))

func leave() -> void:
	deliberate_close = true
	if replica != null and str(room.get("phase", "")) == "playing":
		replica.discard_recovery()
	send({"type": "leave"})

func reset_session() -> void:
	deliberate_close = true
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		socket.close()
	if mesh != null:
		mesh.close()
		if multiplayer.multiplayer_peer == mesh:
			multiplayer.multiplayer_peer = null
	mesh = null
	peers.clear()
	pending_signals.clear()
	peer_recovery.clear()
	room.clear()
	if replica != null:
		replica.clear()
	if session != null:
		session.reset()
	ice_servers.clear()
	deadline = 0.0
	heartbeat = 0.0
	socket_connect_started = -1.0
	pending_join = false
	code = ""
	token = ""
	player_id = ""
	deliberate_close = false

func _peer_connected(id: int) -> void:
	peer_recovery.erase(id)
	peer_joined.emit(id)

func _peer_disconnected(id: int) -> void:
	# The higher peer ID initiates recovery, so both phones do not repeatedly
	# disconnect each other. A grace period lets ordinary room departures arrive.
	if mesh != null and id < multiplayer.get_unique_id() and peers.values().has(id):
		peer_recovery[id] = Time.get_ticks_msec() / 1000.0 + PEER_RECOVERY_SECONDS
	peer_left.emit(id)

func _recover_dropped_peer(now: float) -> void:
	for id: int in peer_recovery.keys():
		if id in multiplayer.get_peers() or not peers.values().has(id):
			peer_recovery.erase(id)
			continue
		if now < float(peer_recovery[id]):
			continue
		# A live signaling socket does not imply the WebRTC data channel is
		# alive. Reauthenticate to make both sides discard stale connections and
		# renegotiate using the normal rejoin path.
		peer_recovery.clear()
		socket.close(1000, "Recovering game connection")
		return
