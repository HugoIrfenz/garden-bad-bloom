extends SceneTree

const Encounters = preload("res://scripts/biome_encounters.gd")
const Geometry = preload("res://scripts/forgotten_encounters.gd")
const BossVisuals = preload("res://scripts/boss_combat_visuals.gd")

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
	game.player = Vector2(390, 210)
	var knife = actor(Encounters.MUSHROOM, 0, Vector2(300, 210))
	tick(game, knife, 0.01)
	if not require(knife.move == "knife" and knife.phase == Geometry.WINDUP and game.hp == 125, "Knife Shroom did not telegraph"):
		return
	game.player.y += 40.0
	tick(game, knife, 0.75)
	tick(game, knife, 0.6)
	if not require(knife.phase == Geometry.RECOVERY and knife.x > 440.0 and game.hp == 125,
			"Knife Shroom should commit to the marked lane and recover after a miss"):
		return

	game.player = Vector2(385, 210)
	var bomber = actor(Encounters.MUSHROOM, 1, Vector2(330, 210))
	var ally = actor(Encounters.MUSHROOM, 0, Vector2(315, 210))
	game.foes = [bomber, ally]
	tick(game, bomber, 0.01)
	if not require(bomber.move == "bomb" and bomber.phase == Geometry.WINDUP, "Puffball should fuse before exploding"):
		return
	game.player.y += 65.0
	tick(game, bomber, 0.99)
	if not require(ally.hp < 100 and game.hp == 125 and bomber.detonated, "Puffball blast should damage nearby fungi and miss outside radius"):
		return

	var butler = actor(Encounters.MUSHROOM, 2, Vector2(350, 210))
	game.foes = [ally, butler]
	game.player = Vector2(430, 210)
	tick(game, butler, 0.01)
	tick(game, butler, 0.8)
	if not require(ally.ward_time > 0.0 and Encounters.defend(game, ally, 20) < 20, "Butler failed to shield its ally"):
		return
	if not require(Encounters.defend(game, butler, 20) < 20, "Open umbrella failed to stop front attack"):
		return
	game.player.x = 290.0
	if not require(Encounters.defend(game, butler, 20) == 20, "Open umbrella unexpectedly stopped rear attack"):
		return

	var king = actor(Encounters.MUSHROOM, 3, Vector2(300, 190))
	game.foes = [king]
	game.player = Vector2(395, 190)
	tick(game, king, 0.01)
	var axes = Encounters.cross_axes(king)
	if not require(king.move == "cross" and absf(axes[0].dot(axes[1])) < 0.001, "Majesty did not draw an X-slash"):
		return
	if not require(BossVisuals.majesty_frame(king) == BossVisuals.MAJESTY_WARN, "Majesty did not raise his cleavers before the cross"):
		return
	tick(game, king, 0.89)
	if not require(game.hp == 125, "Diagonal safe wedge should remain outside the cross blades"):
		return
	if not require(BossVisuals.majesty_frame(king) == BossVisuals.MAJESTY_STRIKE, "Majesty did not slash on the cross release"):
		return
	king.hp = 49
	tick(game, king, 0.5)
	if not require(BossVisuals.majesty_frame(king) == BossVisuals.MAJESTY_RECOVER, "Majesty did not lower his weapons during recovery"):
		return
	tick(game, king, 0.5)
	if not require(king.attendants and game.foes.size() == 3, "Majesty must summon exactly two Knife Shrooms once"):
		return

	var bee = actor(Encounters.CLOCKWORK, 0, Vector2(300, 190))
	game.player = Vector2(421, 190)
	tick(game, bee, 0.01)
	if not require(bee.move == "needle" and bee.tx > 470.0, "Tin Bee did not lock its needle dash"):
		return

	var mouse = actor(Encounters.CLOCKWORK, 1, Vector2(300, 190))
	game.player = Vector2(354, 190)
	tick(game, mouse, 0.01)
	tick(game, mouse, 0.78)
	game.player = Vector2(300, 190) + Vector2.from_angle(0.6) * 58.0
	tick(game, mouse, 0.07)
	if not require(game.hp == 125, "Pendulum Mouse first slash hit the second sector prematurely"):
		return
	tick(game, mouse, 0.27)
	if not require(game.hp < 125, "Pendulum Mouse did not land its second beat"):
		return

	var rose = actor(Encounters.CLOCKWORK, 2, Vector2(300, 190))
	game.player = Vector2(420, 190)
	tick(game, rose, 0.01)
	tick(game, rose, 1.01)
	if not require(game.bolts.size() == 6 and is_zero_approx(game.bolts[0].dx + game.bolts[3].dx),
			"Clockwork Rose did not fire six evenly spaced petals"):
		return

	var bell = actor(Encounters.CLOCKWORK, 3, Vector2(300, 190))
	game.active_biome = Encounters.CLOCKWORK
	game.foes = [bell]
	game.room_arrival = 0.0
	game.update_foes(0.01)
	var slow: float = bell.duration
	if not require(bell.move == "hand", "Late Bell did not wind up its clock hand"):
		return
	bell.hp = 50
	bell.phase = Geometry.APPROACH
	bell.clock = 0.0
	game.update_foes(0.01)
	if not require(bell.duration < slow, "Late Bell did not accelerate a phase-two beat"):
		return
	print("PASS: Mushroom and Clockwork attacks, defense, cover, boss pose timing, add limits and phase tempos.")
	quit(0)
