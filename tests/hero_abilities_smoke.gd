extends SceneTree

const Abilities = preload("res://scripts/hero_abilities.gd")

class QuietAudio:
	func play(_cue: String, _tone: float) -> void:
		pass

class Battle:
	const BARREL_CLEARANCE = 26.0
	var player := Vector2(80.0, 100.0)
	var facing := Vector2.RIGHT
	var hero := 0
	var resource := 0
	var bonus := 0
	var skill_time := 0.0
	var dash_remaining := 0.0
	var dash_vector := Vector2.ZERO
	var dash_evaded := false
	var mercy := 0.0
	var foes: Array[Dictionary] = []
	var barrels: Array[Vector2] = []
	var sound := QuietAudio.new()

	func assisted_aim(_maximum: float, _prefer_marks := false) -> Vector2:
		return Vector2.INF

	func target(foe: Dictionary) -> Vector2:
		return Vector2(foe.x, foe.y)

	func defend_foe(_foe: Dictionary, amount: int) -> int:
		return amount

	func player_hit_amount(amount: int) -> int:
		return amount

	func clamp_position(point: Vector2) -> Vector2:
		return point.clamp(Vector2(20.0, 20.0), Vector2(580.0, 335.0))

	func slide_with_cover(point: Vector2, step: Vector2) -> Vector2:
		return clamp_position(point + step)

	func add_foe(point: Vector2, boss := false) -> Dictionary:
		var foe := {"hp": 90, "x": point.x, "y": point.y, "phase": 1, "clock": 1.0, "boss": boss}
		foes.append(foe)
		return foe

var _failures := PackedStringArray()

func _initialize() -> void:
	test_royal_guard()
	test_midnight_verse()
	test_unauthorized_access()
	test_tidy_arrangement()
	test_graffiti_cut()
	if _failures.is_empty():
		print("PASS: guard, delayed blast, chained leap, skill dash, cover-blocked blink, and save round-trips.")
	else:
		for failure in _failures:
			push_error(failure)
	quit(0 if _failures.is_empty() else 1)

func expect(condition: bool, issue: String) -> void:
	if not condition:
		_failures.append(issue)

func reload_ability(ability) -> void:
	var restored: Dictionary = JSON.parse_string(JSON.stringify(ability.snapshot()))
	ability.reset()
	ability.restore(restored)

func test_royal_guard() -> void:
	var game := Battle.new()
	var ability = Abilities.new()
	var enemy := game.add_foe(Vector2(112.0, 100.0))
	expect(ability.cast(game), "Angela could not raise her shield.")
	expect(is_equal_approx(game.skill_time, 1.0), "An unused shield should recharge in one second.")
	expect(ability.damage_after_guard(game, 20, Vector2(38.0, 100.0)) == 0, "Angela's shield failed to absorb a rear hit.")
	expect(is_equal_approx(game.skill_time, 5.0), "The first absorption did not start the five-second recharge.")
	game.skill_time = 4.75
	expect(ability.damage_after_guard(game, 20, Vector2.INF) == 0, "Angela's shield failed to absorb a directionless hit.")
	expect(ability.damage_after_guard(game, 20, Vector2(145.0, 100.0)) == 0, "The perfect window took damage.")
	expect(ability.damage_after_guard(game, 20, Vector2(139.0, 100.0)) == 0, "A perfect guard failed against a second frontal contact.")
	expect(game.resource == 2 and is_equal_approx(game.skill_time, 4.75), "Repeated contacts granted extra Resolve or restarted the recharge.")
	reload_ability(ability)
	expect(is_equal_approx(ability.guard_recharge(), 5.0), "The longer shield recharge was lost across save.")
	expect(ability.counter_bonus(game, enemy) == 14, "Perfect guard's counter did not survive the snapshot.")
	expect(ability.counter_bonus(game, enemy) == 0 and game.resource == 0, "A counter was spent more than once.")
	ability.tick(game, 0.20)
	expect(ability.damage_after_guard(game, 20, Vector2(145.0, 100.0)) == 0, "A regular frontal guard leaked damage.")
	ability.tick(game, 1.00)
	expect(ability.damage_after_guard(game, 20, Vector2(145.0, 100.0)) == 20, "Angela's guard did not expire.")

func test_midnight_verse() -> void:
	var game := Battle.new()
	game.hero = 1
	game.resource = 3
	var foe := game.add_foe(Vector2(184.0, 100.0))
	var distant := game.add_foe(Vector2(252.0, 125.0))
	var ability = Abilities.new()
	expect(ability.cast(game), "Vivianne's verse did not cast.")
	ability.tick(game, 0.30)
	expect(foe.hp == 90, "Vivianne's blast resolved during its windup.")
	reload_ability(ability)
	game.player = Vector2(344.0, 250.0)
	ability.tick(game, 0.31)
	expect(foe.hp == 58 and distant.hp == 90 and game.resource == 0, "Vivianne's blast lost its position, damage, or range across save.")
	ability.tick(game, 0.33)
	expect(foe.hp == 58, "Vivianne's blast damaged the same target more than once.")

func test_unauthorized_access() -> void:
	var game := Battle.new()
	game.hero = 2
	var foe := game.add_foe(Vector2(204.0, 100.0))
	var behind := game.add_foe(Vector2(133.0, 100.0))
	var ability = Abilities.new()
	expect(ability.cast(game) and ability.locks_movement(), "Nixia's leap did not enter its movement phase.")
	ability.tick(game, 0.10)
	expect(game.player.x > 80.0 and game.player.x < 164.0, "Nixia did not travel over time.")
	reload_ability(ability)
	ability.tick(game, 0.13)
	expect(is_equal_approx(game.player.x, 164.0) and not ability.locks_movement(), "Nixia's landing was inconsistent after save.")
	expect(foe.hp == 78 and behind.hp == 90 and Abilities.consume_stun(foe, 0.08), "Nixia's leap did not stun its forward cone.")
	ability.tick(game, 0.19)
	expect(foe.hp == 60 and behind.hp == 90, "Nixia's follow-up missed or struck a foe behind the landing.")
	reload_ability(ability)
	ability.tick(game, 0.19)
	expect(foe.hp == 42 and behind.hp == 90, "Nixia's third hit did not survive a checkpoint.")

func test_tidy_arrangement() -> void:
	var game := Battle.new()
	game.hero = 3
	var ability = Abilities.new()
	expect(ability.cast(game), "Virelia's skill dash did not start.")
	expect(is_equal_approx(game.dash_remaining, 0.18) and is_equal_approx(game.dash_vector.length() * game.dash_remaining, 100.0), "Virelia's skill dash has the wrong distance or duration.")

func test_graffiti_cut() -> void:
	var game := Battle.new()
	game.hero = 4
	game.barrels = [Vector2(151.0, 100.0)]
	var front := game.add_foe(Vector2(109.0, 100.0))
	var behind := game.add_foe(Vector2(183.0, 100.0))
	var ability = Abilities.new()
	expect(ability.cast(game), "Zaria's blink did not cast.")
	expect(game.player.x > 80.0 and game.player.x < 125.0 and behind.hp == 90, "Zaria's blink or cut passed through cover.")
	expect(front.hp == 76, "Zaria's blink did not slash its route.")
	ability.tick(game, 0.10)
	expect(front.hp == 70 and Abilities.consume_stun(front, 0.15), "Zaria's paint lacked its independent trail effect.")
	reload_ability(ability)
	ability.tick(game, 0.20)
	expect(front.hp == 70 and behind.hp == 90, "A restored paint mark damaged an already affected foe.")
	var arrived := game.add_foe(Vector2(88.0, 113.0))
	ability.tick(game, 0.20)
	expect(arrived.hp == 84, "Zaria's lingering paint ignored a new entrant.")
