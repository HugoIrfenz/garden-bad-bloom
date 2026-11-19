extends SceneTree

const Chandelier = preload("res://scripts/hollow_chandelier.gd")

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func enter_hall(game) -> bool:
	game.floor_index = 4
	for seed_value in range(125):
		game.run_seed = seed_value
		game.load_floor()
		for node: Dictionary in game.floor_manifest.nodes.values():
			var room: Dictionary = game.Dungeon.generate_room(game.run_seed, game.floor_manifest, node.id)
			if room.template_id == "chandelier_hall" and not Chandelier.place(room).is_empty():
				game.room_id = node.id
				game.enter_room()
				return true
	return false

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	if not check(enter_hall(game) and game.ground_hazards.patches.size() == 1, "Chandelier Hall did not offer a seeded trap"):
		return
	var patch: Dictionary = game.ground_hazards.patches[0]
	var drop: Vector2 = game.target(patch)
	var hp: int = game.hp
	game.ground_hazards.tick(game, game.player, 0.50)
	if not check(patch.phase == 0, "The chandelier triggered at the room entrance"):
		return
	game.player = drop
	game.mercy = 0.0
	game.ground_hazards.tick(game, drop, 0.016)
	if not check(patch.phase == 1 and game.hp == hp, "The chandelier did not warn before falling"):
		return
	game.ground_hazards.tick(game, drop, Chandelier.TELL)
	game.ground_hazards.tick(game, drop, Chandelier.FALL / 2.0)
	game.checkpoint()
	game.resume_run()
	patch = game.ground_hazards.patches[0]
	var foe: Dictionary = game.foes[0]
	foe.x = drop.x
	foe.y = drop.y
	foe.hp = 50
	game.player += Vector2(Chandelier.RADIUS + 7.0, 0.0)
	if not check(patch.phase == 2 and not patch.contact and game.hp == hp, "The fall did not resume before landing"):
		return
	game.ground_hazards.tick(game, game.player, Chandelier.FALL)
	if not check(patch.phase == 3 and patch.contact and foe.hp == 15 and game.hp == hp
			and float(foe.get("hero_stun", 0.0)) > 0, "Leaving the ring did not turn a landing into enemy damage"):
		return
	game.checkpoint()
	game.resume_run()
	patch = game.ground_hazards.patches[0]
	game.player = drop
	game.ground_hazards.tick(game, drop, 0.50)
	if not check(patch.phase == 3 and patch.contact and game.foes[0].hp == 15 and game.hp == hp,
			"An already broken chandelier landed twice"):
		return
	patch.phase = 2
	patch.left = 0.01
	patch.contact = false
	game.mercy = 0.0
	game.ground_hazards.tick(game, drop, 0.02)
	if not check(game.hp == hp - Chandelier.HERO_DAMAGE, "Staying in the marked circle did not take damage"):
		return
	print("PASS: seeded Palace chandelier, warning and fall checkpoint, reversible enemy counterplay, and a single impact.")
	quit()
