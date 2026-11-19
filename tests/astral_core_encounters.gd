extends SceneTree

const Encounters = preload("res://scripts/astral_core_encounters.gd")
const Geometry = preload("res://scripts/forgotten_encounters.gd")

func _initialize() -> void:
	call_deferred("verify")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func actor(biome: int, kind: int, point: Vector2) -> Dictionary:
	return {"biome": biome, "kind": kind, "x": point.x, "y": point.y, "hp": 100, "max": 100,
		"boss": kind == 3, "phase": Geometry.APPROACH, "clock": 0.0}

func tick(game, foe: Dictionary, seconds: float) -> void:
	foe.clock -= seconds
	Encounters.advance(game, foe, seconds)

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.hp = 125
	game.player = Vector2(437, 200)
	var wisp = actor(Encounters.ASTRAL, 0, Vector2(340, 200))
	tick(game, wisp, 0.01)
	if not require(wisp.move == "mote" and wisp.phase == Geometry.WINDUP, "Wisp did not signal its homing attack"):
		return
	tick(game, wisp, 0.90)
	game.player.y += 55.0
	for _frame in range(10):
		tick(game, wisp, 0.016)
	if not require(float(wisp.orb[1]) > 200.0 and absf(float(wisp.orb[2])) <= 0.19,
			"Mote tracking did not turn at the limited angular rate"):
		return

	game.player = Vector2(437, 200)
	var bloom = actor(Encounters.ASTRAL, 1, Vector2(340, 200))
	tick(game, bloom, 0.01)
	var first = Encounters.spoke_ends(game, bloom, 0.0)
	var rotated = Encounters.spoke_ends(game, bloom, 0.5)
	if not require(first.size() == 4 and not first[0].is_equal_approx(rotated[0]), "Bloom's spokes did not rotate"):
		return
	if not require(first.all(func(end): return Geometry.segment_gap(game.player, Vector2(340, 200), end) > 20.0),
			"Bloom attack did not preserve the intended initial safe wedge"):
		return

	var moth = actor(Encounters.ASTRAL, 2, Vector2(340, 200))
	tick(game, moth, 0.01)
	var false_end = Vector2(moth.mirror[0], moth.mirror[1])
	var real_end = Geometry.aim(moth)
	if not require(false_end.distance_to(real_end) > 40.0, "Moth false and real markers overlap"):
		return
	tick(game, moth, 0.84)
	tick(game, moth, 0.42)
	if not require(game.target(moth).is_equal_approx(real_end), "Moth committed to its false marker"):
		return

	var florist = actor(Encounters.ASTRAL, 3, Vector2(340, 200))
	tick(game, florist, 0.01)
	if not require(florist.move == "constellation" and Encounters.paths(game, florist).size() == 2,
			"Florist phase one did not show two lanes"):
		return
	florist.hp = 49
	if not require(Encounters.paths(game, florist).size() == 2, "Florist changed geometry during a displayed warning"):
		return
	Encounters.arm(game, florist, "constellation")
	if not require(Encounters.paths(game, florist).size() == 3, "Florist phase two did not reorder the constellation"):
		return

	var rose = actor(Encounters.CORE, 1, Vector2(330, 200))
	tick(game, rose, 0.01)
	var start = Encounters.glitch_curve(Vector2(330, 200), Vector2.RIGHT, 1, 80.0)
	var switched = Encounters.glitch_curve(Vector2(330, 200), Vector2.RIGHT, 1, 210.0)
	if not require(rose.move == "glitch" and (start.y - 200.0) * (switched.y - 200.0) < 0.0,
			"Glitch Rose lanes did not swap after the crossing"):
		return

	var root_foe = actor(Encounters.CORE, 2, Vector2(350, 210))
	var second_root = actor(Encounters.CORE, 2, Vector2(520, 210))
	game.foes = [root_foe, second_root]
	tick(game, root_foe, 0.01)
	tick(game, second_root, 0.01)
	if not require(second_root.phase == Geometry.APPROACH, "A second Fractured Root began a simultaneous warning"):
		return
	var original = Encounters.tile_for(game, game.player)
	if not require(root_foe.fracture_parity != (original.x + original.y) % 2,
			"Fractured Root did not signal the unstable tile"):
		return
	var before: int = game.hp
	game.mercy = 0
	tick(game, root_foe, 1.17)
	tick(game, second_root, 0.25)
	if not require(second_root.phase == Geometry.APPROACH, "A second Fractured Root began during a live grid"):
		return
	tick(game, root_foe, 0.16)
	if not require(game.hp < before, "Fractured Root's unstable floor did not apply damage"):
		return
	var injured: int = game.hp
	game.player.y += float(game.ARENA.size.y) / 3.0
	game.mercy = 0
	tick(game, root_foe, 0.51)
	if not require(game.hp == injured, "Reaching a lit stable tile did not avoid the second pulse"):
		return
	tick(game, root_foe, 0.32)
	tick(game, second_root, 0.01)
	if not require(root_foe.phase == Geometry.RECOVERY and second_root.phase == Geometry.WINDUP,
			"The waiting root did not attack after the previous grid cleared"):
		return

	var boss = actor(Encounters.CORE, 3, Vector2(333, 212))
	game.foes = [boss]
	tick(game, boss, 0.01)
	tick(game, boss, 0.01)
	if not require(Encounters.shield_lives(game) == 5 and Encounters.defend(game, boss, 20) == 0,
			"Bloomheart did not make its five nodes a real damage gate"):
		return
	for foe in game.foes:
		if foe.get("flower_node", false):
			foe.hp = 0
	if not require(Encounters.defend(game, boss, 20) == 20, "Bloomheart did not expose its heart after the nodes died"):
		return
	boss.hp = 68
	var second = Encounters.choose(boss)
	boss.hp = 34
	if not require(second == "echo" and Encounters.choose(boss) == "gravity",
			"Bloomheart did not change attacks at 70 and 35 percent"):
		return
	print("PASS: Astral and Core enemies, boss phase tells, projectiles, safe tiles, and Bloomheart node gate.")
	quit(0)
