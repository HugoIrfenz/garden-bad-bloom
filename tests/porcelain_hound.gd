extends SceneTree

const Game = preload("res://main.tscn")
const Hound = preload("res://scripts/porcelain_hound.gd")
const Geometry = preload("res://scripts/forgotten_encounters.gd")
const START := Vector2(310.0, 214.0)
const TARGET := Vector2(440.0, 214.0)
var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func run() -> void:
	var game = Game.instantiate()
	root.add_child(game)
	game.start_run()
	game.set_physics_process(false)
	test_placement(game)
	test_flank(game)
	test_path_and_resume(game)
	test_cover(game)
	if failures.is_empty():
		print("PASS: seeded Palace hound placement, Codex discovery, locked zigzag hits, safe wedge, flank interrupt and cover recovery.")
	else:
		for message in failures:
			push_error(message)
	quit(0 if failures.is_empty() else 1)


func test_placement(game) -> void:
	var sought := ["broken_ballroom", "chandelier_hall"]
	var observed := {}
	var poses := {}
	game.floor_index = 4
	for seed in range(20, 60):
		game.run_seed = seed
		game.load_floor()
		for node: Dictionary in game.floor_manifest.nodes.values():
			game.room_id = node.id
			var layout: Dictionary = game.current_room()
			if layout.kind in game.Dungeon.FRIENDLY_KINDS or layout.spawns.is_empty():
				continue
			if layout.template_id not in sought or observed.has(layout.template_id):
				continue
			game.enter_room()
			var foe: Dictionary = game.foes[0]
			var initial: Vector2 = game.target(foe)
			var count: int = game.foes.filter(func(candidate): return int(candidate.kind) == Hound.KIND).size()
			expect(count == 1 and int(foe.kind) == Hound.KIND, "Signature room did not spawn one Hound at its first anchor.")
			expect(initial.is_equal_approx(layout.spawns[0]), "The Hound did not use the seeded spawn.")
			var first_side := int(foe.get("hound_side", 0))
			game.enter_room()
			expect(game.target(game.foes[0]).is_equal_approx(initial) and int(game.foes[0].get("hound_side", 0)) == first_side,
				"The Hound's seeded position or scratch direction changed.")
			expect(abs(first_side) == 1, "The room did not provide a valid scratch direction.")
			observed[layout.template_id] = true
			poses[layout.template_id] = game.room_id
		if observed.size() == sought.size():
			break
	expect(observed.size() == sought.size(), "Both Palace templates should occur in sampled campaign seeds.")
	var archive = game.Codex.new()
	archive.load_local()
	var entry: Dictionary = archive.entries(4)[Hound.KIND]
	expect(entry.name == "Porcelain Hound" and entry.discovered and not entry.boss,
		"The ordinary Hound Codex entry did not survive a reload.")
	if not poses.is_empty() and game.floor_manifest.nodes.has(poses.values().back()):
		game.room_id = poses.values().back()


func prepare(game) -> Dictionary:
	game.hero = 0
	game.screen = "fight"
	game.active_biome = 4
	game.barrels.clear()
	game.foes.clear()
	game.bolts.clear()
	game.room_arrival = 0.0
	game.mercy = 0.0
	game.attack_time = 0.0
	game.hp = 120
	game.player = TARGET
	var hound := {"biome": 4, "kind": Hound.KIND, "boss": false, "phase": Geometry.APPROACH,
		"x": START.x, "y": START.y, "hp": 50, "max": 50, "clock": 0.0, "hound_side": 1}
	game.foes.append(hound)
	return hound


func test_flank(game) -> void:
	var hound := prepare(game)
	game.update_foes(0.01)
	expect(hound.phase == Geometry.WINDUP and hound.move == Hound.MOVE and game.hp == 120,
		"The Hound did not lock a visible warning before attacking.")
	var marked := Hound.weak_side(hound)
	game.player = START + marked * 36.0
	game.facing = -marked
	game.act("attack")
	expect(hound.hound_interrupted and hound.hp == 31, "A real hit from the marked flank should deal extra damage and interrupt.")
	game.update_foes(0.01)
	expect(hound.phase == Geometry.RECOVERY and hound.clock > 1.0 and Hound.weak_side(hound).is_equal_approx(marked),
		"The interrupt should recover immediately and keep the same exposed side.")
	game.update_foes(0.34)
	expect(game.hp == 120 and hound.phase == Geometry.RECOVERY, "The interrupted Hound still dealt damage.")
	hound = prepare(game)
	game.update_foes(0.01)
	game.player = START + Geometry.direction(hound) * 38.0
	game.facing = -Geometry.direction(hound)
	game.act("attack")
	var frontal_damage := 50 - int(hound.hp)
	expect(frontal_damage > 0 and frontal_damage < 19 and not hound.hound_interrupted and game.target(hound).is_equal_approx(START),
		"A frontal hit should deal reduced damage without moving the marked charge off its warning.")


func test_path_and_resume(game) -> void:
	var hound := prepare(game)
	game.update_foes(0.01)
	var turn := Hound.turn(hound)
	var end := Geometry.aim(hound)
	expect(absf((turn - START).cross(end - turn)) > 1000.0, "The warning should show a real turn.")
	game.update_foes(0.84)
	game.update_foes(0.12)
	expect(hound.phase == Geometry.LUNGE and float(hound.hound_distance) > 50.0, "The Hound did not follow its warned first leg.")
	var previous: Vector2 = game.target(hound)
	game.checkpoint()
	game.resume_run()
	game.barrels.clear()
	hound = game.foes[0]
	expect(Hound.turn(hound).is_equal_approx(turn) and Geometry.aim(hound).is_equal_approx(end)
		and game.target(hound).is_equal_approx(previous) and hound.phase == Geometry.LUNGE,
		"The warned zigzag or current position was lost across a mid-rush resume.")
	game.update_foes(1.0)
	expect(game.target(hound).is_equal_approx(end) and game.hp == 108 and hound.hound_hit,
		"The resumed second leg should hit the player waiting at the original target.")
	game.update_foes(0.3)
	expect(game.hp == 108, "One rush damaged the player twice.")
	hound = prepare(game)
	game.update_foes(0.01)
	game.player = START.lerp(Geometry.aim(hound), 0.47)
	game.update_foes(0.84)
	game.update_foes(1.0)
	expect(game.hp == 120, "A coarse tick hit along the straight chord between the two warning legs.")


func test_cover(game) -> void:
	var hound := prepare(game)
	var block := START + Vector2.RIGHT.rotated(0.61) * 75.0
	game.barrels.append(block)
	game.update_foes(0.01)
	expect(hound.hound_trips and Hound.turn(hound).is_equal_approx(Geometry.aim(hound)),
		"The warning should stop at cover and omit the unreachable second leg.")
	game.update_foes(0.84)
	game.update_foes(1.0)
	var position: Vector2 = game.target(hound)
	expect(hound.phase == Geometry.RECOVERY and hound.clock > 1.0 and position.distance_to(block) >= game.BARREL_CLEARANCE
		and game.hp == 120, "Cover collision should stop the rush and give a longer punish window.")
