extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func enter_clockwork(game, template: String) -> bool:
	game.floor_index = 2
	for seed in range(300):
		game.run_seed = seed
		game.load_floor()
		for id in game.floor_manifest.nodes:
			var room: Dictionary = game.Dungeon.generate_room(seed, game.floor_manifest, id)
			if room.template_id == template:
				game.room_id = id
				game.enter_room()
				return true
	return false

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	var trap = game.ClockworkFloor
	if not require(enter_clockwork(game, "clockface_atrium"), "Seed search did not find Clockface Atrium"):
		return
	var clock = game.clockwork_floor
	var center: Vector2 = trap.CLOCK_CENTER
	var hp: int = game.hp
	game.player = center + Vector2(0, -70)
	game.mercy = 0.0
	clock.left = 0.001
	clock.tick(game, 0.016)
	if not require(clock.phase == trap.WINDUP and game.hp == hp, "Clock damaged the player during its tell"):
		return
	clock.left = 0.001
	clock.tick(game, 0.016)
	game.player = center + Vector2(70, 0)
	clock.tick(game, 0.016)
	if not require(clock.phase == trap.ACTIVE and game.hp == hp, "An unmarked sector dealt damage"):
		return
	game.player = center + Vector2(0, -70)
	clock.tick(game, 0.016)
	if not require(game.hp == hp - 12 and clock.player_hit, "Clock failed to hit inside the marked sector"):
		return
	game.checkpoint()
	game.resume_run()
	game.mercy = 0.0
	clock.tick(game, 0.016)
	if not require(game.hp == hp - 12, "Saved sector duplicated its already applied hit"):
		return
	var previous_angle: float = clock.sector_angle()
	clock.left = 0.001
	clock.tick(game, 0.016)
	if not require(not is_equal_approx(clock.sector_angle(), previous_angle), "Clock cycle did not advance"):
		return
	if not require(enter_clockwork(game, "greenhouse_rails"), "Seed search did not find Greenhouse Rails"):
		return
	var lane = Vector2(379.0, trap.RAIL_Y[0])
	var foe: Dictionary = game.foes[0]
	foe.x = lane.x
	foe.y = lane.y
	hp = game.hp
	var foe_hp: int = foe.hp
	game.player = lane
	game.barrels.append(lane)
	game.mercy = 0.0
	clock.phase = trap.ACTIVE
	clock.left = clock.active_duration() * 0.62
	clock.tick(game, 0.15)
	clock.hit_rail(game, lane, lane)
	if not require(game.hp == hp - 14 and foe.hp == foe_hp - 14 and not game.barrels.has(lane),
			"Gear did not sweep a single hit across player, enemy, and cover"):
		return
	game.checkpoint()
	game.resume_run()
	var saved_foe: Dictionary = game.foes[0]
	game.mercy = 0.0
	clock.hit_rail(game, lane, lane)
	if not require(clock.phase == trap.ACTIVE and game.hp == hp - 14 and saved_foe.hp == foe_hp - 14,
			"Resuming a gear sweep duplicated an impact"):
		return
	print("PASS: clock sector warning, safe wedges, cycle progression, rail collisions, and saved per-sweep hits.")
	quit()
