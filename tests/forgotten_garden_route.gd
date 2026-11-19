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
	game.set_physics_process(false)
	game.start_run()
	for seed in range(300):
		game.run_seed = seed
		game.load_floor()
		for id in game.floor_manifest.nodes:
			var info: Dictionary = game.Dungeon.generate_room(seed, game.floor_manifest, id)
			if info.template_id == "flowerbed_siege" and not info.hazard_slots.is_empty():
				game.room_id = id
				break
		if game.room_id != game.floor_manifest.entrance_id:
			break
	game.enter_room()
	if not require(game.room_template == "flowerbed_siege" and not game.ground_hazards.patches.is_empty(),
			"Seed search did not produce the playable Flowerbed Siege"):
		return
	var knight: Dictionary = game.foes[0]
	var combat = game.ForgottenEncounters
	if not require(knight.kind == combat.HEDGE_KNIGHT and game.codex.entries(0)[knight.kind].discovered,
			"Flowerbed Siege did not spawn or discover Hedge Knight"):
		return
	game.barrels.clear()
	var patch: Dictionary = game.ground_hazards.patches[0]
	var spot: Vector2 = game.target(patch)
	game.player = spot
	game.mercy = 0.0
	var original_hp: int = game.hp
	patch.left = 0.01
	game.ground_hazards.tick(game, spot, 0.02)
	if not require(patch.phase == 1 and game.hp == original_hp, "Warning dealt damage before bloom"):
		return
	patch.left = 0.01
	game.ground_hazards.tick(game, spot, 0.02)
	game.mercy = 0.0
	game.ground_hazards.tick(game, spot, 0.02)
	if not require(game.hp == original_hp - game.GardenGroundHazards.DAMAGE, "A single bloom must damage at most once"):
		return
	knight.x = spot.x - 55.0
	knight.y = spot.y
	combat.arm(game, knight, "lance")
	if not require(combat.defend(game, knight, 20) == 5, "Knight shield did not cover the front"):
		return
	game.player = spot + Vector2(-85, 0)
	if not require(combat.defend(game, knight, 20) == 20, "Knight shield incorrectly covered its back"):
		return
	combat.release(game, knight)
	knight.clock = knight.duration * 0.4
	var old_knight_hp: int = knight.hp
	combat.lunge(game, knight)
	if not require(patch.phase == 3 and knight.hp == old_knight_hp - 10 and knight.phase == combat.RECOVERY,
			"Bloom did not catch the charge"):
		return
	patch.phase = 1
	patch.left = 0.4
	game.player = spot + Vector2(-34, 0)
	game.facing = Vector2.RIGHT
	game.foes.clear()
	for _swing in range(3):
		game.attack_time = 0.0
		game.act("attack")
	if not require(patch.phase == 3, "Lilyblade's third swing did not clip the thorns"):
		return
	game.checkpoint()
	game.resume_run()
	if not require(game.ground_hazards.patches[0].phase == 3, "Trimmed thorns grew back after resume"):
		return
	print("PASS: seeded Flowerbed Siege, Hedge Knight counterplay, single-hit blooms, Lilyblade trim and save/resume.")
	quit()
