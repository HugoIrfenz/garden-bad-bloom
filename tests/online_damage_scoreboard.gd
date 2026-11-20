extends SceneTree

class FakePeer extends Node:
	var player_id := "a"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var peer := FakePeer.new()
	game.add_child(peer)
	game.online_peer = peer
	game.online_names = {"a": "Angela", "b": "Vivianne"}
	game.online_members = {"a": {"damage_dealt": 120}, "b": {"damage_dealt": 540},
		"c": {"damage_dealt": 120, "username": "Zaria"}}
	game.online_leaving = true
	game.online_finished_award_saved = true
	game._show_online_departure_summary()
	assert(game.screen == "summary" and game.online_peer == null)
	var frozen: Dictionary = game.online_final_leaderboard
	var rows: Array[Dictionary] = game.View.damage_leaderboard_rows(frozen.players, frozen.names)
	assert(rows.size() == 3 and rows[0].name == "Vivianne" and rows[0].damage == 540)
	assert(rows[1].name == "Angela" and rows[2].name == "Zaria")
	assert(str(frozen.self) == "a")
	game.handle_tap(game.View.SECOND_OPTION.get_center())
	assert(game.screen == "garden" and game.online_final_leaderboard.is_empty())
	game.free()
	print("PASS: sorted online damage scores survive voluntary leave and close cleanly")
	quit()
