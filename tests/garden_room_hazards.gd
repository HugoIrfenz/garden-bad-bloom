extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func enter_template(game, template_id: String, floor_index := 0) -> bool:
	game.floor_index = floor_index
	for seed in range(250):
		game.run_seed = seed
		game.load_floor()
		for id in game.floor_manifest.nodes:
			var room: Dictionary = game.Dungeon.generate_room(seed, game.floor_manifest, id)
			if room.template_id != template_id:
				continue
			game.ground_hazards.setup(room)
			if game.ground_hazards.patches.is_empty():
				continue
			game.room_id = id
			game.enter_room()
			return true
	return false

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	if not require(enter_template(game, "petal_courtyard"), "No Petal Courtyard with rooted ground spawned"):
		return
	var patch: Dictionary = game.ground_hazards.patches[0]
	game.player = game.target(patch)
	game.mercy = 0.0
	var original_hp: int = game.hp
	patch.left = 0.001
	game.ground_hazards.tick(game, game.player, 0.016)
	if not require(patch.phase == 1 and game.ground_hazards.movement_scale() == 1.0, "Root warning slowed movement early"):
		return
	patch.left = 0.001
	game.ground_hazards.tick(game, game.player, 0.016)
	if not require(game.ground_hazards.movement_scale() < 0.5 and game.hp == original_hp, "Root contact failed to snare without HP loss"):
		return
	game.checkpoint()
	game.resume_run()
	game.dodge_time = 0.0
	game.act("dodge")
	if not require(game.ground_hazards.movement_scale() == 1.0 and game.dash_vector.length() * game.dash_remaining < 40.0,
			"Dodge failed to break the saved snare with a short dash"):
		return
	if not require(enter_template(game, "sunken_greenhouse"), "No Sunken Greenhouse with glass traps spawned"):
		return
	patch = game.ground_hazards.patches[0]
	game.player = game.target(patch)
	game.ground_hazards.tick(game, game.player, 0.016)
	if not require(patch.phase == 1 and game.bolts.is_empty(), "Glass did not warn before shattering"):
		return
	game.checkpoint()
	game.resume_run()
	patch = game.ground_hazards.patches[0]
	patch.left = 0.001
	game.ground_hazards.tick(game, game.player, 0.016)
	if not require(game.bolts.size() == 6 and game.bolts[0].glass_shard, "Glass did not emit the six telegraphed shards"):
		return
	game.checkpoint()
	game.resume_run()
	game.ground_hazards.tick(game, game.player, 0.50)
	if not require(game.bolts.size() == 6 and game.ground_hazards.patches[0].phase == 3,
			"The shattered panel fired twice after resume"):
		return
	if not verify_fungal_room(game):
		return
	if not verify_bloodbloom(game):
		return
	print("PASS: Root Grapple, Glass Shatter, Spore Vent, Mycelium Leaper, Leech Pond, Crimson Thread, and hazard save/resume.")
	quit()

func verify_fungal_room(game) -> bool:
	if not require(enter_template(game, "fungal_crossroad", 1), "No Fungal Crossroad with spore vents spawned"):
		return false
	var leaper: Dictionary = game.foes[0]
	var encounter = game.BiomeEncounters
	if not require(leaper.kind == encounter.MYCELIUM_LEAPER and game.codex.entries(1)[leaper.kind].discovered,
			"Crossroad did not introduce and discover the leaper"):
		return false
	game.barrels.clear()
	var vent: Dictionary = game.ground_hazards.patches[0]
	var spot: Vector2 = game.target(vent)
	leaper.x = spot.x - 135
	leaper.y = spot.y
	game.player = spot
	game.mercy = 0.0
	var hp: int = game.hp
	encounter.arm(game, leaper, "leap")
	encounter.release(game, leaper)
	leaper.clock = 0.20
	encounter.active(game, leaper)
	if not require(game.hp == hp, "The airborne part of the leap dealt damage"):
		return false
	game.checkpoint()
	game.resume_run()
	leaper = game.foes[0]
	vent = game.ground_hazards.patches[0]
	leaper.clock = 0.0
	encounter.active(game, leaper)
	if not require(game.hp == hp - 13 and leaper.phase == game.ForgottenEncounters.RECOVERY,
			"The restored leap missed its marked landing or skipped recovery"):
		return false
	vent.phase = 1
	vent.left = 0.001
	game.mercy = 0.0
	game.ground_hazards.tick(game, spot, 0.016)
	if not require(game.hp == hp - 18 and vent.phase == 2, "Spore vent failed to damage on bloom"):
		return false
	game.player = spot + Vector2(0, 50)
	game.mercy = 0.0
	game.ground_hazards.tick(game, spot, 0.63)
	return require(game.hp == hp - 18, "Leaving a spore cloud should stop damage")

func verify_bloodbloom(game) -> bool:
	if not require(enter_template(game, "leech_pond", 3), "No Leech Pond with active pools spawned"):
		return false
	var trap: Dictionary = game.ground_hazards.patches[0]
	var location: Vector2 = game.target(trap)
	var wounded: Dictionary = game.foes[0]
	wounded.x = location.x
	wounded.y = location.y + 62.0
	wounded.hp -= 10
	var before: int = game.hp
	var foe_hp: int = wounded.hp
	trap.phase = 2
	trap.left = 1.3
	trap.next_tick = 0.0
	game.mercy = 0.0
	game.player = location
	game.ground_hazards.tick(game, game.player, 0.016)
	if not require(game.hp == before, "The Leech Pond lily pad was not safe"):
		return false
	game.player += Vector2(23, 0)
	game.ground_hazards.tick(game, game.player, 0.016)
	if not require(game.hp == before - 5 and wounded.hp == foe_hp + 5, "Leech Pond did not transfer the stolen health"):
		return false
	if not require(enter_template(game, "redroot_corridor", 3), "No Redroot Corridor with severable threads spawned"):
		return false
	trap = game.ground_hazards.patches[0]
	location = game.target(trap)
	var anchor: Vector2 = location - game.GardenGroundHazards.thread_axis(trap)
	game.barrels.clear()
	game.ground_hazards.sever_melee(game, anchor - Vector2(20, 0), Vector2.RIGHT, 46.0)
	game.checkpoint()
	game.resume_run()
	return require(game.ground_hazards.patches[0].phase == 3, "A cut Crimson Thread rearmed after resume")
