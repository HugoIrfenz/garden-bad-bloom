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
const FIRST_PEER_TIMEOUT := 12.0
const OnlineSession = preload("res://scripts/online/online_session.gd")
const RunReplica = preload("res://scripts/online/run_replica.gd")
const RoomSocketPeer = preload("res://scripts/online/room_socket_peer.gd")
const DEFAULT_ICE := [{"urls": ["stun:stun.cloudflare.com:3478"]}]

var endpoint := ""
var code := ""
var token := ""
var username := ""
var player_id := ""
var room: Dictionary = {}
var ice_servers: Array = []
var ice_requested := false
var relay_unavailable_reason := ""
var mesh: WebRTCMultiplayerPeer
var game_socket_peer: MultiplayerPeerExtension
var fallback_requested := false
var fallback_deadline := 0.0
var transport_announced := false
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
var remote_description_ready: Dictionary = {}
var peer_recovery: Dictionary = {}
var first_peer_deadlines: Dictionary = {}
var first_peer_retry_used := false
var game_connection_failure := ""

func _ready() -> void:
	replica = RunReplica.new()
	replica.name = "RunReplica"
	add_child(replica)
	session = OnlineSession.new()
	session.name = "OnlineSession"
	add_child(session)
	session.configure(self)
	create_request = HTTPRequest.new()
	create_request.timeout = CONNECT_TIMEOUT_SECONDS
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
	if result != HTTPRequest.RESULT_SUCCESS:
		connection_problem.emit("Could not reach the room service. Check your connection and try again.")
		return
	var payload: Variant = JSON.parse_string(body.get_string_from_utf8()) if not body.is_empty() else null
	if response_code != 201 or not payload is Dictionary:
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
	socket.inbound_buffer_size = 2 * RoomSocketPeer.MAX_PACKET_BYTES
	socket.outbound_buffer_size = 2 * RoomSocketPeer.MAX_PACKET_BYTES
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
		_check_first_peer_deadlines(tick_now)
		_recover_dropped_peer(tick_now)
		if fallback_deadline > 0.0 and tick_now >= fallback_deadline:
			fallback_deadline = 0.0
			game_connection_failure = "Game relay unavailable. Leave and rejoin."
			connection_problem.emit(game_connection_failure)
	while state == WebSocketPeer.STATE_OPEN and socket.get_available_packet_count() > 0:
		var bytes := socket.get_packet()
		if socket.was_string_packet():
			var payload: Variant = JSON.parse_string(bytes.get_string_from_utf8())
			if payload is Dictionary:
				receive(payload)
		elif game_socket_peer != null:
			game_socket_peer.receive_packet(bytes)
	if state == WebSocketPeer.STATE_CLOSED and socket_state != state and not deliberate_close:
		# The room removes this connection from the other phones while it is
		# offline. Rebuild our side too, otherwise a rejoined app can retain stale
		# peer entries and never negotiate a fresh connection with the party.
		transport_announced = false
		if game_socket_peer != null:
			game_socket_peer.sync_peers({})
		if mesh != null:
			for id: String in peers.keys():
				var remote := int(peers[id])
				if mesh.has_peer(remote):
					mesh.remove_peer(remote)
			peers.clear()
		pending_signals.clear()
		remote_description_ready.clear()
		peer_recovery.clear()
		first_peer_deadlines.clear()
		ice_requested = false
		ice_servers.clear()
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
		"room":
			var old_host := str(room.get("host", ""))
			var old_epoch := int(room.get("epoch", -1))
			room = message
			replica.update_roster(room, player_id)
			if old_host != str(room.get("host", "")) or old_epoch != int(room.get("epoch", -1)):
				host_changed.emit(str(room.get("host", "")), int(room.get("epoch", 0)))
			room_changed.emit(room)
			if room.get("phase") == "playing" and not transport_announced:
				transport_announced = true
				send({"type": "game_transport_ready"})
			if room.get("transport") == "room-socket":
				refresh_game_socket()
				return
			if room.get("phase") == "playing" and not ice_requested:
				ice_requested = true
				send({"type": "ice"})
			refresh_peers()
		"ice":
			ice_servers = supported_ice_servers(message.get("iceServers", DEFAULT_ICE))
			relay_unavailable_reason = str(message.get("relayReason", ""))
			print("Co-op relay credentials offered: ", bool(message.get("relayAvailable", false)), " ", relay_unavailable_reason)
			refresh_peers()
		"signal":
			if room.get("transport") == "room-socket":
				return
			pending_signals.append(message)
			drain_signals()
		"left":
			session_left.emit()
		"error":
			connection_problem.emit(str(message.get("message", "Online connection failed.")))

static func supported_ice_servers(servers: Array) -> Array:
	var filtered: Array = []
	for server: Dictionary in servers:
		var raw: Variant = server.get("urls", [])
		var urls: Array = [raw] if raw is String else raw
		var usable: Array[String] = []
		for entry: String in urls:
			if entry.begins_with("stun:") or (entry.begins_with("turn:") and not entry.contains("transport=tcp")):
				usable.append(entry)
		if usable.is_empty():
			continue
		if usable.any(func(url: String): return url == "turn:turn.cloudflare.com:3478?transport=udp"):
			var alternate := "turn:turn.cloudflare.com:443?transport=udp"
			usable.erase(alternate)
			usable.push_front(alternate)
		var item := server.duplicate(true)
		item.urls = usable
		filtered.append(item)
	return DEFAULT_ICE.duplicate(true) if filtered.is_empty() else filtered

func refresh_game_socket() -> void:
	var local_id := 0
	var desired := {}
	for row: Dictionary in room.get("players", []):
		if row.id == player_id:
			local_id = int(row.peerId)
		elif bool(row.connected):
			desired[int(row.peerId)] = true
	if local_id < 2:
		return
	if game_socket_peer == null:
		first_peer_deadlines.clear()
		peer_recovery.clear()
		peers.clear()
		if mesh != null:
			mesh.close()
			mesh = null
		game_socket_peer = RoomSocketPeer.new()
		game_socket_peer.configure(socket, local_id)
		multiplayer.multiplayer_peer = game_socket_peer
		if not multiplayer.peer_connected.is_connected(_peer_connected):
			multiplayer.peer_connected.connect(_peer_connected)
		if not multiplayer.peer_disconnected.is_connected(_peer_disconnected):
			multiplayer.peer_disconnected.connect(_peer_disconnected)
	else:
		game_socket_peer.configure(socket, local_id)
	fallback_deadline = 0.0
	game_connection_failure = ""
	game_socket_peer.sync_peers(desired)

func refresh_peers() -> void:
	# The room socket is sufficient for lobby controls. Open the game mesh only after Start.
	if str(room.get("phase", "")) != "playing" or room.get("transport") == "room-socket" or player_id.is_empty() or ice_servers.is_empty():
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
			remote_description_ready.erase(id)
			first_peer_deadlines.erase(old_peer)
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
		# The offerer retries. The answerer still needs a bounded waiting message.
		var wait := FIRST_PEER_TIMEOUT if remote < local_id else FIRST_PEER_TIMEOUT * 2.0 + 6.0
		first_peer_deadlines[remote] = Time.get_ticks_msec() / 1000.0 + wait
		if remote < local_id:
			var offer_error := connection.create_offer()
			if offer_error != OK:
				push_warning("WebRTC offer failed: " + error_string(offer_error))
	drain_signals()

func _description_created(kind: String, sdp: String, id: String) -> void:
	if mesh == null or not peers.has(id) or not mesh.has_peer(int(peers[id])):
		return
	var connection: WebRTCPeerConnection = mesh.get_peer(int(peers[id])).connection
	connection.set_local_description(kind, sdp)
	send({"type": "signal", "to": id, "kind": kind, "payload": {"sdp": sdp}})

func _candidate_created(mid: String, index: int, candidate: String, id: String) -> void:
	if candidate.contains(" typ relay"):
		print("Co-op gathered a relay candidate.")
	send({"type": "signal", "to": id, "kind": "candidate", "payload": {"mid": mid, "index": index, "candidate": candidate}})

func drain_signals() -> void:
	if mesh == null:
		return
	var remaining: Array[Dictionary] = []
	# Apply offers and answers before candidates, even when signaling delivers
	# the candidate first or both messages arrive in the same poll.
	for candidates_only: bool in [false, true]:
		for message: Dictionary in pending_signals:
			var kind := str(message.get("kind", ""))
			if (kind == "candidate") != candidates_only:
				continue
			var id := str(message.get("from", ""))
			if not peers.has(id) or not mesh.has_peer(int(peers[id])):
				remaining.append(message)
				continue
			var connection: WebRTCPeerConnection = mesh.get_peer(int(peers[id])).connection
			var payload: Dictionary = message.get("payload", {})
			if kind == "offer" or kind == "answer":
				var error := connection.set_remote_description(kind, str(payload.get("sdp", "")))
				if error == OK:
					remote_description_ready[id] = true
				else:
					push_warning("WebRTC description failed: " + error_string(error))
			elif kind == "candidate":
				if not remote_description_ready.has(id):
					remaining.append(message)
					continue
				var error := connection.add_ice_candidate(str(payload.get("mid", "")), int(payload.get("index", 0)), str(payload.get("candidate", "")))
				if error != OK:
					push_warning("WebRTC candidate failed: " + error_string(error))
	pending_signals = remaining

func connection_progress() -> String:
	if not game_connection_failure.is_empty():
		return game_connection_failure
	if game_socket_peer != null:
		return "Using the room relay. Waiting for Room 1"
	if fallback_deadline > 0.0:
		return "Switching to the room relay"
	if mesh == null or peers.is_empty():
		return "Setting up the game connection"
	var host := str(room.get("host", ""))
	var remote := int(peers.get(host, 0))
	if remote > 1 and remote in multiplayer.get_peers():
		return "Connected. Waiting for Room 1"
	if not remote_description_ready.has(host) and host != player_id:
		return "Waiting for the host to respond"
	return "Connecting to your party"

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
	if game_socket_peer != null:
		game_socket_peer.close()
		if multiplayer.multiplayer_peer == game_socket_peer:
			multiplayer.multiplayer_peer = null
		game_socket_peer = null
	fallback_deadline = 0.0
	fallback_requested = false
	transport_announced = false
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		socket.close()
	if mesh != null:
		mesh.close()
		if multiplayer.multiplayer_peer == mesh:
			multiplayer.multiplayer_peer = null
	mesh = null
	peers.clear()
	pending_signals.clear()
	remote_description_ready.clear()
	peer_recovery.clear()
	first_peer_deadlines.clear()
	first_peer_retry_used = false
	game_connection_failure = ""
	room.clear()
	if replica != null:
		replica.clear()
	if session != null:
		session.reset()
	ice_servers.clear()
	ice_requested = false
	relay_unavailable_reason = ""
	deadline = 0.0
	heartbeat = 0.0
	socket_connect_started = -1.0
	pending_join = false
	code = ""
	token = ""
	player_id = ""
	deliberate_close = false

func _peer_connected(id: int) -> void:
	game_connection_failure = ""
	first_peer_deadlines.erase(id)
	peer_recovery.erase(id)
	peer_joined.emit(id)

func _peer_disconnected(id: int) -> void:
	# The higher peer ID initiates recovery, so both phones do not repeatedly
	# disconnect each other. A grace period lets ordinary room departures arrive.
	if mesh != null and id < multiplayer.get_unique_id() and peers.values().has(id):
		peer_recovery[id] = Time.get_ticks_msec() / 1000.0 + PEER_RECOVERY_SECONDS
	peer_left.emit(id)

func _check_first_peer_deadlines(now: float) -> void:
	for id: int in first_peer_deadlines.keys():
		if now < float(first_peer_deadlines[id]):
			continue
		first_peer_deadlines.erase(id)
		if id in multiplayer.get_peers() or not peers.values().has(id):
			continue
		if not fallback_requested and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			fallback_requested = true
			fallback_deadline = now + 6.0
			send({"type": "game_transport_fallback"})
			return
		if first_peer_retry_used or id > multiplayer.get_unique_id():
			game_connection_failure = "Connection timed out. Leave and rejoin."
			if relay_unavailable_reason == "budget-exhausted":
				game_connection_failure = "Connection timed out. Relay limit reached."
			connection_problem.emit(game_connection_failure)
			continue
		first_peer_retry_used = true
		push_warning("Game connection timed out. Reauthenticating to retry once.")
		socket.close(1000, "Retrying game connection")
		return

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
