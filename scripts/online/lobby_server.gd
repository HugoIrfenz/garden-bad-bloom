extends Node

signal server_message(payload: Dictionary)
signal lobby_changed(code: String)
signal room_started(code: String)
signal reconnect_expired(code: String, player_id: String)

const CampaignState = preload("res://scripts/online/campaign_state.gd")
const MAX_PLAYERS := 5
const MIN_PLAYERS := 2
const REJOIN_SECONDS := 60.0
const CODE_CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var rooms: Dictionary = {}
var peer_rooms: Dictionary = {}
var peer_players: Dictionary = {}
var elapsed := 0.0
var next_timer_update := 0.0
var last_timer_update := 0.0
var snapshot_clock := 0.0

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_disconnect)

func _process(delta: float) -> void:
	elapsed += delta
	snapshot_clock += delta
	var snapshot_due := snapshot_clock >= 0.10
	if snapshot_due:
		snapshot_clock = 0.0
	for code: String in rooms:
		var room: Dictionary = rooms[code]
		if not room.has("campaign") or room.party.paused(elapsed):
			continue
		room.campaign.motion.advance(room.campaign, minf(delta, 0.05), elapsed)
		var entered: bool = room.campaign.accept_unanimous_exit(elapsed)
		if entered:
			publish(code)
		elif snapshot_due:
			# Repeat the latest position even when movement stops, so a lost final
			# datagram cannot leave another player permanently out of date.
			publish(code, true)
	if elapsed < next_timer_update:
		return
	next_timer_update = elapsed + 0.25
	var timer_delta := elapsed - last_timer_update
	last_timer_update = elapsed
	for code: String in rooms.keys():
		var room: Dictionary = rooms.get(code, {})
		if room.is_empty():
			continue
		var expired := false
		var counting_down := false
		if room.has("party"):
			counting_down = room.party.resume_left > 0.0
			room.party.tick(timer_delta, elapsed)
		for player_id: String in room.players.keys():
			var player: Dictionary = room.players[player_id]
			if not player.connected and player.get("deadline", 0.0) > 0.0 and elapsed >= float(player.deadline):
				expired = true
				player.deadline = 0.0
				player.departed = true
				reconnect_expired.emit(code, player_id)
				if room.phase == "lobby":
					room.players.erase(player_id)
					if room.host == player_id:
						reassign_host(room)
		if room.players.is_empty() or room.players.values().all(func(player): return bool(player.departed)):
			rooms.erase(code)
		elif expired or counting_down or room.players.values().any(func(player): return not player.connected and float(player.deadline) > 0.0):
			publish(code)

@rpc("any_peer", "call_remote", "reliable")
func create_lobby(username: String) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if peer_rooms.has(peer) or not valid_name(username):
		reply(peer, {"type": "error", "message": "Enter a username before hosting."})
		return
	var code := new_code()
	var player := new_player(peer, username)
	rooms[code] = {"host": player.id, "phase": "lobby", "players": {player.id: player}}
	attach(peer, code, player)
	reply(peer, {"type": "created", "code": code, "token": player.token})
	publish(code)

@rpc("any_peer", "call_remote", "reliable")
func join_lobby(code: String, username: String) -> void:
	var peer := multiplayer.get_remote_sender_id()
	code = code.strip_edges().to_upper()
	if peer_rooms.has(peer) or not valid_name(username):
		reply(peer, {"type": "error", "message": "Enter a username before joining."})
		return
	if not rooms.has(code):
		reply(peer, {"type": "error", "message": "Room code was not found."})
		return
	var room: Dictionary = rooms[code]
	if room.phase != "lobby" or room.players.size() >= MAX_PLAYERS:
		reply(peer, {"type": "error", "message": "This room has started or is full."})
		return
	var player := new_player(peer, username)
	room.players[player.id] = player
	attach(peer, code, player)
	reply(peer, {"type": "joined", "code": code, "token": player.token})
	publish(code)

@rpc("any_peer", "call_remote", "reliable")
func select_hero(hero: int, ready: bool) -> void:
	var peer := multiplayer.get_remote_sender_id()
	var room := room_for(peer)
	if room.is_empty() or room.phase != "lobby" or hero < 0 or hero >= 8:
		return
	var player: Dictionary = room.players[peer_players[peer]]
	for other: Dictionary in room.players.values():
		if other.id != player.id and int(other.hero) == hero:
			reply(peer, {"type": "error", "message": "That heroine is already selected."})
			return
	player.hero = hero
	player.ready = ready
	publish(peer_rooms[peer])

@rpc("any_peer", "call_remote", "reliable")
func start_run() -> void:
	var peer := multiplayer.get_remote_sender_id()
	var room := room_for(peer)
	if room.is_empty() or room.phase != "lobby" or room.host != peer_players.get(peer, ""):
		return
	if room.players.size() < MIN_PLAYERS or room.players.size() > MAX_PLAYERS:
		return
	for player: Dictionary in room.players.values():
		if not player.connected or not player.ready or int(player.hero) < 0:
			return
	room.campaign = CampaignState.new()
	room.run_id = Crypto.new().generate_random_bytes(16).hex_encode()
	var seed_bytes := Crypto.new().generate_random_bytes(4)
	room.campaign.begin(int(seed_bytes.decode_u32(0)), room.players)
	room.party = room.campaign.party
	room.phase = "starting"
	publish(peer_rooms[peer])
	room_started.emit(peer_rooms[peer])

@rpc("any_peer", "call_remote", "reliable")
func rejoin(code: String, token: String) -> void:
	var peer := multiplayer.get_remote_sender_id()
	code = code.strip_edges().to_upper()
	if peer_rooms.has(peer) or not rooms.has(code):
		reply(peer, {"type": "error", "message": "Run unavailable."})
		return
	var room: Dictionary = rooms[code]
	for player: Dictionary in room.players.values():
		var spectator: bool = room.has("party") and room.party.players.has(player.id) and not room.party.players[player.id].alive
		if player.token == token and not player.connected and not player.departed and (spectator or float(player.deadline) > elapsed):
			if room.has("party") and not room.party.reconnect_player(player.id, elapsed):
				continue
			player.connected = true
			player.peer = peer
			player.deadline = 0.0
			attach(peer, code, player)
			reply(peer, {"type": "rejoined", "code": code})
			send_pending_awards(player)
			publish(code)
			return
	reply(peer, {"type": "error", "message": "Rejoin time expired."})

@rpc("any_peer", "call_remote", "unreliable_ordered")
func move_input(direction: Vector2, sequence: int) -> void:
	var peer := multiplayer.get_remote_sender_id()
	var room := room_for(peer)
	if room.is_empty() or not room.has("campaign") or room.party.paused(elapsed):
		return
	var id: String = peer_players[peer]
	if not room.party.players.has(id):
		return
	var player: Dictionary = room.party.players[id]
	if not player.alive or not player.connected or player.departed:
		return
	room.campaign.motion.submit(id, direction, sequence, elapsed)

@rpc("any_peer", "call_remote", "reliable")
func leave_run() -> void:
	var peer := multiplayer.get_remote_sender_id()
	var room := room_for(peer)
	if room.is_empty():
		return
	var code: String = peer_rooms[peer]
	var player_id: String = peer_players[peer]
	var player: Dictionary = room.players[player_id]
	# Let the departing client know its intentional leave was processed before
	# it closes the transport; otherwise it looks like an unexpected disconnect.
	reply(peer, {"type": "left"})
	if room.has("party"):
		room.campaign.motion.forget(player_id)
		room.party.leave_player(player_id)
	player.connected = false
	player.departed = true
	player.deadline = 0.0
	peer_rooms.erase(peer)
	peer_players.erase(peer)
	if room.phase == "lobby":
		room.players.erase(player_id)
		if room.host == player_id:
			reassign_host(room)
	else:
		reconnect_expired.emit(code, player_id)
	if room.players.is_empty() or room.players.values().all(func(player): return bool(player.departed)):
		rooms.erase(code)
	else:
		publish(code)

func _on_disconnect(peer: int) -> void:
	var room := room_for(peer)
	if room.is_empty():
		return
	var code: String = peer_rooms[peer]
	var player: Dictionary = room.players[peer_players[peer]]
	if room.has("party"):
		room.campaign.motion.forget(player.id)
		room.party.disconnect_player(player.id, elapsed)
	player.connected = false
	player.peer = 0
	var is_spectator: bool = room.has("party") and not room.party.players[player.id].alive
	player.deadline = 0.0 if is_spectator else elapsed + REJOIN_SECONDS
	peer_rooms.erase(peer)
	peer_players.erase(peer)
	publish(code)

func new_player(peer: int, username: String) -> Dictionary:
	var token := Crypto.new().generate_random_bytes(32).hex_encode()
	return {"id": token.sha256_text(), "token": token, "peer": peer, "username": username.strip_edges(),
		"hero": -1, "ready": false, "connected": true, "departed": false, "deadline": 0.0,
		"pending_awards": {}, "acknowledged_awards": {}}

func queue_award(code: String, player_id: String, event_id: String, seeds: int,
		foes: Array = [], weapons: Array = [], relics: Array = []) -> bool:
	var room: Dictionary = rooms.get(code, {})
	if room.is_empty() or not room.has("run_id") or not room.players.has(player_id) \
			or event_id.is_empty() or event_id.length() > 64 or seeds < 0:
		return false
	var player: Dictionary = room.players[player_id]
	var award_id := str(room.run_id) + ":" + event_id
	if player.pending_awards.has(award_id) or player.acknowledged_awards.has(award_id):
		return false
	player.pending_awards[award_id] = {"id": award_id, "seeds": seeds,
		"foes": foes.duplicate(true), "weapons": weapons.duplicate(), "relics": relics.duplicate()}
	if player.connected:
		send_pending_awards(player)
	return true

func send_pending_awards(player: Dictionary) -> void:
	for award: Dictionary in player.pending_awards.values():
		reply(int(player.peer), {"type": "award", "award": award})

@rpc("any_peer", "call_remote", "reliable")
func acknowledge_award(award_id: String) -> void:
	var peer := multiplayer.get_remote_sender_id()
	var room := room_for(peer)
	if room.is_empty():
		return
	var player: Dictionary = room.players[peer_players[peer]]
	if player.pending_awards.has(award_id):
		player.pending_awards.erase(award_id)
		player.acknowledged_awards[award_id] = true

func attach(peer: int, code: String, player: Dictionary) -> void:
	peer_rooms[peer] = code
	peer_players[peer] = player.id

func room_for(peer: int) -> Dictionary:
	return rooms.get(peer_rooms.get(peer, ""), {})

func reassign_host(room: Dictionary) -> void:
	room.host = ""
	for player: Dictionary in room.players.values():
		if player.connected:
			room.host = player.id
			return

func valid_name(username: String) -> bool:
	var value := username.strip_edges()
	return value.length() >= 1 and value.length() <= 24 and not value.contains("\n") and not value.contains("\r")

func new_code() -> String:
	while true:
		var bytes := Crypto.new().generate_random_bytes(6)
		var result := ""
		for byte in bytes:
			result += CODE_CHARS[int(byte) % CODE_CHARS.length()]
		if not rooms.has(result):
			return result
	return ""

func publish(code: String, transient := false) -> void:
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	room.sequence = int(room.get("sequence", 0)) + 1
	var players: Array = []
	for player: Dictionary in room.players.values():
		players.append({"id": player.id, "username": player.username, "hero": player.hero,
			"ready": player.ready, "connected": player.connected, "departed": player.departed,
			"rejoin_left": maxf(0.0, float(player.deadline) - elapsed)})
	var state := {"type": "lobby", "code": code, "host": room.host, "phase": room.phase,
		"players": players, "sequence": room.sequence}
	if room.has("party"):
		state.room_health_multiplier = room.party.room_health_multiplier
		state.paused = room.party.paused(elapsed)
		state.resume_left = room.party.resume_left
		state.living = room.party.living_count()
		state.room_cleared = room.party.room_cleared
		state.campaign = room.campaign.room_snapshot()
		var party_rows: Array = []
		for id: String in room.party.players:
			var member: Dictionary = room.party.players[id]
			party_rows.append({"id": id, "hero": member.hero, "position": member.position,
				"facing": member.get("facing", Vector2.DOWN), "hp": member.hp,
				"alive": member.alive, "connected": member.connected,
				"departed": member.departed, "door": member.door})
		state.party = party_rows
		var votes: Dictionary = {}
		for door: String in room.party.doors:
			votes[door] = room.party.door_count(door)
		state.door_votes = votes
	for player: Dictionary in room.players.values():
		if player.connected:
			reply(int(player.peer), state, transient)
	lobby_changed.emit(code)

func reply(peer: int, payload: Dictionary, transient := false) -> void:
	if peer <= 0 or peer not in multiplayer.get_peers():
		return
	var transport := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if transport == null:
		return
	var remote := transport.get_peer(peer)
	if remote == null or remote.get_state() != ENetPacketPeer.STATE_CONNECTED:
		return
	if transient:
		receive_snapshot.rpc_id(peer, payload)
	else:
		receive_message.rpc_id(peer, payload)

@rpc("authority", "call_remote", "unreliable_ordered")
func receive_snapshot(payload: Dictionary) -> void:
	server_message.emit(payload)

@rpc("authority", "call_remote", "reliable")
func receive_message(payload: Dictionary) -> void:
	server_message.emit(payload)
