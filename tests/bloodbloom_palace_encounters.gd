extends SceneTree

const Encounters = preload("res://scripts/bloodbloom_palace_encounters.gd")
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
	game.player = Vector2(400, 200)
	var moth = actor(Encounters.BLOODBLOOM, 0, Vector2(320, 200))
	moth.hp = 70
	tick(game, moth, 0.01)
	if not require(moth.move == "siphon" and moth.phase == Geometry.WINDUP and game.hp == 125, "Moth dive skipped the tell"):
		return
	tick(game, moth, 0.76)
	tick(game, moth, 0.34)
	if not require(game.hp < 125 and moth.hp > 70, "Siphon Moth did not transfer health on a landed dive"):
		return

	game.mercy = 0
	game.player = Vector2(480, 200)
	game.barrels.assign([Vector2(440, 200)])
	var doe = actor(Encounters.BLOODBLOOM, 1, Vector2(345, 200))
	tick(game, doe, 0.01)
	if not require(doe.collided and doe.tx < 424.0, "Doe charge warning continued through the barrel"):
		return
	tick(game, doe, 0.89)
	tick(game, doe, 0.55)
	if not require(doe.phase == Geometry.RECOVERY and doe.clock > 1.4, "Cover did not extend Doe recovery"):
		return
	game.barrels.clear()

	game.player = Vector2(390, 200)
	var leech = actor(Encounters.BLOODBLOOM, 2, Vector2(345, 200))
	tick(game, leech, 0.01)
	tick(game, leech, 0.77)
	tick(game, leech, 0.18)
	if not require(leech.latched and leech.phase == Geometry.LUNGE, "Bloom Leech failed to latch after a landed attack"):
		return
	game.dash_remaining = 0.1
	tick(game, leech, 0.015)
	if not require(leech.phase == Geometry.RECOVERY, "A dodge failed to shake the latch"):
		return
	game.dash_remaining = 0.0

	var orchard = actor(Encounters.BLOODBLOOM, 3, Vector2(325, 200))
	orchard.hp = 50
	orchard.heart_angle = 0.0
	game.player = Vector2(398, 200)
	if not require(Encounters.defend(game, orchard, 20) > 20, "Orchard split heart did not expose extra damage"):
		return
	tick(game, orchard, 0.01)
	if not require(orchard.move == "lash" and Encounters.roots(game, orchard).size() == 3, "Orchard phase two did not mark its three root lanes"):
		return
	var safe_hp: int = game.hp
	game.mercy = 0.0
	Encounters.arm(game, orchard, "drain")
	tick(game, orchard, 1.01)
	game.player = Vector2(680, 200)
	tick(game, orchard, 0.15)
	if not require(game.hp == safe_hp and orchard.hp == 50, "Orchard drain hit outside the marked floor"):
		return

	game.player = Vector2(418, 210)
	var cup = actor(Encounters.PALACE, 0, Vector2(315, 210))
	tick(game, cup, 0.01)
	var outgoing = Encounters.flight_position(cup, 0, 0.25)
	var returning = Encounters.flight_position(cup, 0, 0.75)
	if not require(cup.move == "saucer" and outgoing.is_equal_approx(returning) and absf(outgoing.y - 210.0) > 15.0,
			"Saucer did not follow a curved, returning path"):
		return

	var curtain = actor(Encounters.PALACE, 1, Vector2(385, 200))
	tick(game, curtain, 0.01)
	tick(game, curtain, 0.82)
	if not require(game.hp == safe_hp, "Curtain threatened its clear center"):
		return
	game.player = Vector2(70, 200)
	curtain = actor(Encounters.PALACE, 1, Vector2(385, 200))
	tick(game, curtain, 0.01)
	tick(game, curtain, 0.82)
	if not require(game.hp < safe_hp, "Curtain did not harm the rim"):
		return

	game.player = Vector2(401, 210)
	var knight = actor(Encounters.PALACE, 2, Vector2(350, 210))
	tick(game, knight, 0.01)
	if not require(Encounters.defend(game, knight, 20) < 20, "Hollow Knight failed to resist a frontal attack"):
		return
	game.player.x = 290.0
	if not require(Encounters.defend(game, knight, 20) == 20, "Hollow Knight rear guard unexpectedly blocked damage"):
		return

	game.player = Vector2(425, 200)
	var duchess = actor(Encounters.PALACE, 3, Vector2(330, 200))
	tick(game, duchess, 0.01)
	tick(game, duchess, 0.85)
	if not require(duchess.move == "hot_tea" and game.bolts.size() == 5, "Duchess did not release a five-shot tea fan"):
		return
	duchess.hp = 50
	duchess.cycle = 3
	duchess.phase = Geometry.APPROACH
	duchess.clock = 0.0
	tick(game, duchess, 0.01)
	if not require(duchess.move == "saucer_ring" and duchess.flight_ranges.size() == 2, "Duchess did not gain the phase-two saucer attack"):
		return
	print("PASS: Bloodbloom drains and flank attacks, Orchard phase change, Palace returning saucers, curtain safe center, knight guard and Duchess phase change.")
	quit(0)
