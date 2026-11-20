extends SceneTree

const Lobby = preload("res://scripts/online/lobby_server.gd")
const DEFAULT_PORT := 24771

func _initialize() -> void:
	var port := DEFAULT_PORT
	var configured_port := OS.get_environment("GARDEN_PORT")
	if not configured_port.is_empty():
		if not configured_port.is_valid_int():
			push_error("Invalid GARDEN_PORT")
			quit(1)
			return
		port = int(configured_port)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--port="):
			port = int(arg.trim_prefix("--port="))
	if port < 1 or port > 65535:
		push_error("Invalid server port")
		quit(1)
		return
	var transport := ENetMultiplayerPeer.new()
	var result := transport.create_server(port, 128)
	if result != OK:
		push_error("Could not listen on port %d: %s" % [port, error_string(result)])
		quit(1)
		return
	get_multiplayer().multiplayer_peer = transport
	var lobby := Lobby.new()
	lobby.name = "Lobby"
	root.add_child.call_deferred(lobby)
	print("Garden server listening on UDP port %d" % port)
