extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for index in range(5):
		game.hero = index
		game.start_run(true)
		game.attack_time = 0.0
		game.player = game.target(game.foes[0]) + Vector2(20, 0)
		var before: int = game.foes[0].hp
		game.act("attack")
		for step in range(8):
			game.update_bolts(1.0 / 60.0)
		if not require(game.foes[0].hp < before, "Hero attack missed: %d" % index):
			return
	game.depth = 0
	game.enter_room()
	var barrel: Vector2 = game.barrels[0]
	var blocked: Vector2 = game.slide_with_cover(barrel + Vector2(-30, 0), Vector2(10, 0))
	if not require(blocked.distance_to(barrel) >= game.BARREL_CLEARANCE, "Player entered a barrel"):
		return
	game.foes.clear()
	game._physics_process(0.016)
	var reward_petals: int = game.petals
	game.resume_run()
	game._physics_process(0.016)
	if not require(game.pending_chest and game.petals == reward_petals, "Resume lost the room chest or awarded Petals twice"):
		return
	game.player = game.chest_position + Vector2(32, 0)
	game.open_chest()
	game.resume_run()
	game._physics_process(0.5)
	if not require(game.screen == "reward", "Chest animation did not persist into the item choice"):
		return
	game.bonus = 0
	game.depth = 27
	game.enter_room()
	game.foes[0].hp = 0
	game._physics_process(0.016)
	if not require(game.boss_victory.left > 0.0, "Boss defeat animation did not start"):
		return
	game._physics_process(game.BossVictory.DURATION + 0.01)
	game._physics_process(0.016)
	if not require(game.screen == "clear", "Boss defeat did not award a clear after the animation"):
		return
	game.resume_run()
	if not require(game.screen == "clear" and game.depth == 27, "Clear did not survive resume"):
		return
	game.tap(game.View.FIRST_OPTION.get_center())
	if not require(game.screen == "fight" and game.depth == 28, "Endless transition failed"):
		return
	var spawn: Vector2 = game.target(game.foes[0])
	game.enter_room()
	if not require(spawn == game.target(game.foes[0]), "Same seed and room produced different spawn"):
		return
	game.foes.clear()
	game._physics_process(0.016)
	game.tap(game.View.Reward.THORN_EDGE_RECT.get_center())
	if not require(game.bonus == 2 and game.depth == 29, "Reward choice did not advance"):
		return
	game.resume_run()
	if not require(game.bonus == 2 and game.depth == 29, "Reward was lost after resume"):
		return
	game.hp = 0
	game._physics_process(0.016)
	if not require(game.screen == "summary" and not FileAccess.file_exists(game.SAVE), "Death did not close run"):
		return
	print("PASS: five hero attacks, cover, chest and reward resume, capstone transition, Endless, deterministic spawn, permadeath.")
	quit()
