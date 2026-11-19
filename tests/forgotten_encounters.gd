extends SceneTree

const Encounters = preload("res://scripts/forgotten_encounters.gd")

func _initialize() -> void:
	call_deferred("verify")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func at(kind: int, point: Vector2) -> Dictionary:
	return {"kind": kind, "x": point.x, "y": point.y, "hp": 100, "max": 100,
		"boss": kind == Encounters.GARDENER, "phase": Encounters.APPROACH, "clock": 0.0}

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.screen = "fight"
	game.hp = 125
	game.player = Vector2(380, 210)
	var tulip = at(Encounters.TULIP, Vector2(300, 210))
	game.foes = [tulip]
	game.update_foes(0.016)
	if not require(tulip.phase == Encounters.WINDUP and game.hp == 125, "Tulip hit before telegraph"):
		return
	game.checkpoint()
	game.resume_run()
	tulip = game.foes[0]
	if not require(tulip.move == "lunge" and tulip.tx > 400.0, "Tulip lost the locked attack after resume"):
		return
	game.player.y = 253.0
	game.update_foes(0.70)
	for _frame in range(20):
		game.update_foes(0.016)
	if not require(tulip.phase == Encounters.RECOVERY and game.hp == 125 and tulip.x > 400.0,
			"Side-stepping did not avoid the Tulip lunge"):
		return

	game.player = Vector2(380, 210)
	var slug = at(Encounters.SLUG, Vector2(300, 210))
	game.foes = [slug]
	game.update_foes(0.016)
	game.update_foes(0.70)
	if not require(game.bolts.size() == 3 and game.bolts[0].terrain, "Slug did not leave thorn slime"):
		return
	if not require(Encounters.defend(game, slug, 20) < 20, "Slug shell did not guard its front"):
		return
	game.player = Vector2(275, 210)
	if not require(Encounters.defend(game, slug, 20) == 20, "Slug shell stopped a rear hit"):
		return
	game.bolts.clear()

	game.player = Vector2(462, 210)
	var shooter = at(Encounters.PEA_SHOOTER, Vector2(300, 210))
	game.foes = [shooter]
	game.update_foes(0.016)
	game.update_foes(0.77)
	if not require(game.bolts.size() == 3 and game.bolts[0].dy < game.bolts[2].dy,
			"Pea-Shooter did not launch a three-shot fan"):
		return
	game.barrels.append(Vector2(370, 210))
	for _frame in range(100):
		game.update_bolts(0.016)
	if not require(game.hp == 125, "Cover did not stop the centered enemy shot"):
		return
	game.bolts.clear()
	game.barrels.clear()

	game.player = Vector2(370, 210)
	var boss = at(Encounters.GARDENER, Vector2(300, 210))
	game.foes = [boss]
	game.update_foes(0.016)
	if not require(boss.move == "shears" and boss.phase == Encounters.WINDUP, "Gardener did not aim shears"):
		return
	game.update_foes(0.80)
	if not require(game.hp < 125, "Gardener shears failed to deal damage"):
		return
	game.update_foes(1.20)
	game.update_foes(0.016)
	if not require(boss.move == "rain" and Encounters.rain_points(game, boss).size() == 3, "Gardener rain did not follow shears"):
		return
	boss.hp = 50
	if not require(Encounters.rain_points(game, boss).size() == 3, "Gardener changed a hazard after telegraph started"):
		return
	game.update_foes(1.0)
	game.update_foes(1.20)
	game.update_foes(0.016)
	if not require(boss.move == "roots" and Encounters.root_offsets(boss).size() == 3, "Gardener phase two did not add root lanes"):
		return

	print("PASS: Tulip lunge, Thorn Slug slime and shell, Pea-Shooter fan and cover, Gardener phases and telegraph persistence.")
	quit(0)
