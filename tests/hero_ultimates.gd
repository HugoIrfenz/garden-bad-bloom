extends SceneTree

var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	test_last_stand(game)
	test_elegy(game)
	test_security_breach(game)
	test_perfect_bloom(game)
	test_beautiful_disaster(game)
	test_cut_in_freeze(game)
	test_ranged_aim_and_kit(game)
	if failures.is_empty():
		print("PASS: five charged ultimates, saved guard/counter and spell timing, colliding launches, guided marks and paint-trail synergy.")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func expect(condition: bool, failure: String) -> void:
	if not condition:
		failures.append(failure)

func setup(game, hero: int) -> void:
	game.hero = hero
	game.start_run(true)
	game.barrels.clear()
	game.foes.clear()
	game.bolts.clear()
	game.player = Vector2(160.0, 216.0)
	game.facing = Vector2.RIGHT
	game.attack_time = 0.0
	game.dodge_time = 0.0
	game.mercy = 0.0
	game.room_arrival = 0.0

func actor(game, point: Vector2, boss := false) -> Dictionary:
	var foe = {"x": point.x, "y": point.y, "hp": 160, "max": 160, "kind": 0,
		"phase": 0, "clock": 0.8, "boss": boss}
	game.foes.append(foe)
	return foe

func test_ranged_aim_and_kit(game) -> void:
	var clear_point := Vector2(162.0, 286.0)
	setup(game, 1)
	actor(game, Vector2(235.0, 216.0))
	actor(game, clear_point)
	game.barrels.append(Vector2(192.0, 216.0))
	expect(game.assisted_aim(111.0).is_equal_approx(clear_point), "Combat aim targeted a foe through cover.")
	game.act("skill")
	expect(game.abilities.active_verse_zone().is_equal_approx(clear_point), "Vivianne did not place her spell at the visible foe.")
	game.act("attack")
	var witch_bolt: Dictionary = game.bolts[0]
	expect(float(witch_bolt.dy) > 0.95, "Vivianne's basic spell did not use the same visible target.")
	game.act("dodge")
	expect(game.dash_remaining == 0.0 and game.dodge_time > 0.0, "Vivianne dodge button should cast frost instead of a dash.")

	setup(game, 3)
	var marked := Vector2(241.0, 249.0)
	actor(game, Vector2(232.0, 217.0))
	var foe := actor(game, marked)
	game.HeroUltimates.mark_foe(foe, 3.0)
	game.act("skill")
	expect(game.dash_remaining > 0.0 and game.dash_vector.x > 0.0, "Virelia's skill did not dash in her facing direction.")
	game.dash_remaining = 0.0
	game.act("attack")
	var ranger_arrow: Dictionary = game.bolts[0]
	expect(float(ranger_arrow.speed) < float(witch_bolt.speed) and float(ranger_arrow.life) > float(witch_bolt.life),
		"Ranger arrows should travel slower with enough lifetime to carry further than Vivianne's magic.")
	game.act("dodge")
	expect(is_equal_approx(game.dash_remaining, game.DASH_DURATIONS[3]) and is_equal_approx(game.dash_vector.length() * game.dash_remaining, game.DASH_DISTANCES[3]),
		"Virelia's dodge did not use her configured duration and distance.")

	setup(game, 2)
	var close_foe := actor(game, Vector2(185.0, 216.0))
	var distant_foe := actor(game, Vector2(210.0, 216.0))
	game.act("attack")
	expect(close_foe.hp < distant_foe.hp and distant_foe.hp < 160, "Nixia did not gain a close-range strike bonus.")
	game.act("dodge")
	expect(is_equal_approx(game.dash_remaining, game.DASH_DURATIONS[2]) and is_equal_approx(game.dash_vector.length() * game.dash_remaining, game.DASH_DISTANCES[2]),
		"Nixia's dodge did not use her configured duration and distance.")

func cast(game) -> void:
	game.resource = 5
	expect(game.ultimate_ready(), "Fully charged ultimate was unavailable for hero %d." % game.hero)
	game.act("ultimate")
	expect(game.resource == 0 and not game.ultimate_ready(), "Ultimate did not consume its charge for hero %d." % game.hero)
	expect(game.ultimates.cue_hero == game.hero and game.ultimates.cue_time > 0, "Ultimate did not start its portrait sequence.")
	game.ultimates.tick(game, 0.94)
	expect(game.ultimates.cue_time <= 0, "Ultimate did not activate after its portrait cleared.")

func reload(game) -> void:
	game.checkpoint()
	game.resume_run()
	game.barrels.clear()

func test_last_stand(game) -> void:
	setup(game, 0)
	var enemy = actor(game, Vector2(210.0, 216.0))
	game.resource = 4
	game.act("ultimate")
	expect(not game.ultimate_ready() and game.resource == 4, "Angela spent an incomplete ultimate meter.")
	cast(game)
	game.damage_hero(20)
	expect(game.hp == 113, "Last Stand did not partially mitigate incoming damage.")
	reload(game)
	enemy = game.foes[0]
	var basic_damage: int = game.Weapons.item(game.Weapons.starter(0)).damage
	game.strike(enemy)
	expect(enemy.hp == 160 - basic_damage - 13, "Last Stand's empowered counter was lost after resume.")
	game.strike(enemy)
	expect(enemy.hp == 160 - 2 * basic_damage - 13, "Last Stand's saved counter fired more than once.")
	game.ultimates.tick(game, 4.5)
	game.mercy = 0.0
	game.damage_hero(20)
	expect(game.hp == 93, "Last Stand's mitigation did not expire.")

func test_elegy(game) -> void:
	setup(game, 1)
	var overlap = actor(game, Vector2(260.0, 216.0))
	var final_only = actor(game, Vector2(343.0, 216.0))
	cast(game)
	game.ultimates.tick(game, 0.29)
	expect(overlap.hp == 160, "Elegy hit before its first crescendo.")
	game.ultimates.tick(game, 0.02)
	expect(overlap.hp == 147 and final_only.hp == 160, "Elegy's first zone hit the wrong targets.")
	reload(game)
	game.ultimates.tick(game, 0.91)
	expect(game.foes[0].hp == 94 and game.foes[1].hp == 141,
		"Elegy's resumed crescendos did not amplify overlapping zones.")

func test_security_breach(game) -> void:
	setup(game, 2)
	var launched = actor(game, Vector2(210.0, 216.0))
	var collateral = actor(game, Vector2(270.0, 216.0))
	var boss = actor(game, Vector2(164.0, 260.0), true)
	cast(game)
	game.ultimates.tick(game, 0.65)
	expect(launched.hp == 140 and collateral.hp == 160 and boss.hp == 140,
		"SECURITY BREACH did not resolve its four melee impacts.")
	game.ultimates.tick(game, 0.11)
	expect(game.target(launched).x > 210.0 and collateral.hp == 154 and game.target(boss) == Vector2(164.0, 260.0),
		"SECURITY BREACH failed to launch a small enemy into collateral while leaving the boss in place.")
	reload(game)
	game.ultimates.tick(game, 0.11)
	expect(game.foes[1].hp == 154 and game.target(game.foes[0]).x > 278.0,
		"A saved SECURITY BREACH launch stopped early or struck its collateral twice.")

func test_perfect_bloom(game) -> void:
	setup(game, 3)
	var enemy = actor(game, Vector2(268.0, 245.0))
	game.HeroUltimates.mark_foe(enemy, 3.0)
	cast(game)
	game.ultimates.tick(game, 0.18)
	expect(game.bolts.size() == 5, "Perfect Bloom did not fire a five-arrow fan.")
	if game.bolts.size() != 5:
		return
	var center: Dictionary = game.bolts[2]
	game.update_bolts(0.08)
	expect(float(center.dy) > 0.0, "The center arrow did not bend toward the marked target.")
	for frame in range(36):
		game.update_bolts(1.0 / 60.0)
	expect(enemy.hp == 118 and game.resource == 0, "Perfect Bloom did not respect its marked bonus, per-target cap, damage adjustment, or cost.")

func test_beautiful_disaster(game) -> void:
	setup(game, 4)
	var enemy = actor(game, Vector2(210.0, 216.0))
	game.resource = 1
	game.act("skill")
	game.abilities.tick(game, 0.02)
	expect(int(enemy.get("hero_paint_mark", 0)) > 0, "Graffiti Cut did not leave a reactive paint mark.")
	var old_hp: int = enemy.hp
	cast(game)
	var start: Vector2 = game.player
	game.ultimates.tick(game, 0.13)
	expect(game.ultimates.locks_movement() and game.player.distance_to(start) > 3.0 and game.bolts.is_empty(),
		"Beautiful Disaster did not move the player over a real dash segment.")
	reload(game)
	game.ultimates.tick(game, 0.64)
	var result: Dictionary = game.ultimates.snapshot()
	expect(result.effect.strokes.size() == 3 and game.bolts.is_empty(), "Beautiful Disaster did not finish its three saved painted strikes.")
	var rewarded_paint = int(game.foes[0].get("hero_paint_mark", -1)) == 0 and old_hp - int(game.foes[0].hp) >= 25
	expect(rewarded_paint and int(game.foes[0].get("disaster_count", 0)) <= 2,
		"Beautiful Disaster did not consume its paint bonus or exceeded its hit cap.")

func test_cut_in_freeze(game) -> void:
	setup(game, 2)
	var enemy = actor(game, Vector2(214.0, 216.0))
	game.resource = 5
	game.act("ultimate")
	var hp: int = game.hp
	var clock: float = enemy.clock
	game.damage_hero(10)
	game._physics_process(0.42)
	expect(game.hp == hp and enemy.hp == 160 and is_equal_approx(float(enemy.clock), clock),
		"Damage or enemy time advanced while the ultimate portrait was visible.")
	reload(game)
	expect(game.ultimates.cue_hero == 2 and game.ultimates.cue_time > 0.0,
		"The queued cut-in did not survive the run save.")
	game._physics_process(0.55)
	expect(game.ultimates.cue_time == 0.0 and game.foes[0].hp == 160 and is_equal_approx(float(game.foes[0].clock), clock),
		"The gameplay effect fired while the cut-in was clearing.")
	game._physics_process(0.15)
	expect(game.foes[0].hp < 160, "The ultimate did not begin after the cut-in cleared.")
