extends SceneTree
class LeaveSession:
	var requests := 0
	func prepare_leave() -> void:
		requests += 1
class LeavePeer extends Node:
	var player_id := "guest"
	var session := LeaveSession.new()
	var socket := WebSocketPeer.new()
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var peer := LeavePeer.new()
	root.add_child(peer)
	game.online_peer = peer
	game.screen = "fight"
	game.run_paused = true
	game.confirm_end_run = true
	game.end_paused_run()
	game.end_paused_run()
	if game.confirm_end_run or not game.online_leaving or peer.session.requests != 1:
		quit(1)
		return
	game._physics_process(0.0)
	if game.screen != "fight":
		quit(2)
		return
	game.online_leave_started -= game.ONLINE_LEAVE_TIMEOUT + 0.1
	game._physics_process(0.0)
	if game.screen != "summary" or game.online_peer != null or game.online_leaving or game.run_paused or game.last_result.seeds_earned != 0:
		quit(3)
		return
	print("PASS: End Run requests rewards once and exits when the host does not respond.")
	game.free()
	quit()
