extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_run()
	game.floor_index = 6
	game.load_floor()
	game.room_id = game.floor_manifest.boss_id
	game.enter_room()
	var boss: Dictionary = game.foes[0]
	var boss_hp: int = boss.hp
	game._physics_process(0.016)
	if not require(game.foes.size() == 1 and game.room_arrival > 0.0, "The boss acted during its arrival"):
		return
	game._physics_process(game.ROOM_ARRIVAL)
	if not require(game.foes.size() == 6, "Main entry failed to spawn the capstone flower shield"):
		return
	game.strike(boss)
	if not require(boss.hp == boss_hp, "Main strike ignored the flower shield"):
		return
	game.checkpoint()
	game.resume_run()
	if not require(game.foes.size() == 6, "Active save lost capstone nodes"):
		return
	boss = game.foes[0]
	for foe in game.foes:
		if foe.get("flower_node", false):
			for _i in range(3):
				game.strike(foe)
	game._physics_process(0.016)
	if not require(game.foes.size() == 1, "Main attack could not destroy all shield nodes"):
		return
	for _i in range(1000):
		if int(boss.hp) <= 0:
			break
		game.strike(boss)
	game._physics_process(0.016)
	if not require(game.boss_victory.left > 0.0, "Capstone defeat did not start the victory sequence"):
		return
	game.checkpoint()
	game.resume_run()
	if not require(game.boss_victory.left > 0.0, "Capstone victory sequence did not resume"):
		return
	game._physics_process(game.boss_victory.left)
	game._physics_process(0.016)
	if not require(game.screen == "clear", "The capstone defeat did not clear a normal-floor campaign"):
		return
	game.tap(game.View.FIRST_OPTION.get_center())
	if not require(game.floor_index == 7 and game.screen == "fight", "Clear continuation did not create an Endless floor"):
		return
	print("PASS: integrated full capstone encounter, resumable shield, and Endless continuation.")
	quit(0)
