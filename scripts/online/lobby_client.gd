extends Node

signal connected
signal connection_failed(reason: String)
signal disconnected
signal message_received(payload: Dictionary)

const LobbyServer = preload("res://scripts/online/lobby_server.gd")
const SERVER_PEER := 1
const DEFAULT_PORT := 24771

var lobby: Node
var last_sequence := -1
var sequence_code := ""

func _ready() -> void:
	if is_instance_valid(lobby) and lobby.is_inside_tree():
		return
	lobby = LobbyServer.new()
	lobby.name = "Lobby"
	lobby.server_message.connect(_on_message)
	add_child(lobby)
	# The RPC path must match /root/Lobby on the dedicated server.
	remove_child(lobby)
	get_tree().root.add_child.call_deferred(lobby)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_disconnected)

func connect_server(address: String, port := DEFAULT_PORT) -> Error:
	disconnect_server()
	var transport := ENetMultiplayerPeer.new()
	var error := transport.create_client(address.strip_edges(), port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = transport
	return OK

func disconnect_server() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

func host(username: String) -> void:
	lobby.create_lobby.rpc_id(SERVER_PEER, username)

func join(code: String, username: String) -> void:
	lobby.join_lobby.rpc_id(SERVER_PEER, code, username)

func choose(hero: int, ready: bool) -> void:
	lobby.select_hero.rpc_id(SERVER_PEER, hero, ready)

func start_run() -> void:
	lobby.start_run.rpc_id(SERVER_PEER)

func rejoin(code: String, token: String) -> void:
	lobby.rejoin.rpc_id(SERVER_PEER, code, token)

func move(direction: Vector2, sequence: int) -> void:
	lobby.move_input.rpc_id(SERVER_PEER, direction, sequence)

func acknowledge_award(award_id: String) -> void:
	lobby.acknowledge_award.rpc_id(SERVER_PEER, award_id)

func leave_run() -> void:
	lobby.leave_run.rpc_id(SERVER_PEER)

func _on_connected() -> void:
	connected.emit()

func _on_failed() -> void:
	connection_failed.emit("Unable to connect to the Garden server.")

func _on_disconnected() -> void:
	disconnected.emit()

func _on_message(payload: Dictionary) -> void:
	var kind := str(payload.get("type", ""))
	if kind in ["created", "joined", "rejoined"]:
		last_sequence = -1
		sequence_code = str(payload.get("code", ""))
	elif kind == "lobby":
		var code := str(payload.get("code", ""))
		if code != sequence_code:
			return
		var sequence := int(payload.get("sequence", -1))
		if sequence <= last_sequence:
			return
		last_sequence = sequence
	message_received.emit(payload)

func _exit_tree() -> void:
	if is_instance_valid(lobby):
		lobby.queue_free()
