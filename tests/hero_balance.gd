extends SceneTree

var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func setup(game, heroine: int) -> void:
	game.hero = heroine
	game.start_run(true)
	game.set_physics_process(false)
	game.foes.clear()
	game.barrels.clear()
	game.bolts.clear()
	game.player = Vector2(180, 216)
	game.facing = Vector2.RIGHT
	game.attack_time = 0.0
	game.dash_remaining = 0.0

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	setup(game, 0)
	game.foes.append({"x": 250.0, "y": 216.0, "hp": 100, "max": 100, "boss": false, "phase": 0, "clock": 1.0, "kind": 0})
	game.resource = 5
	game.act("ultimate")
	check(is_equal_approx(game.ultimates.cue_time, game.HeroUltimates.CUTIN_DURATION * 0.75), "Angela's ultimate cue was not shortened.")
	game.ultimates.tick(game, 0.7)
	check(game.bolts.size() == 1 and game.bolts[0].ultimate == "blade_wave", "Angela's ultimate did not fire its blade wave.")
	setup(game, 1)
	for index in range(3):
		game.attack_time = 0.0
		game.act("attack")
	check(game.bolts.size() == 5, "Vivianne should fire one, one, then three projectiles.")
	var normal_life: float = game.bolts[0].life
	game.relics.equip(game.Relics.ROSE_LENS)
	game.bolts.clear()
	game.attack_time = 0.0
	game.act("attack")
	check(is_equal_approx(float(game.bolts[0].life), normal_life * 1.2), "Rose Lens did not increase projectile range.")
	setup(game, 1)
	game.curses.restore([game.RunCurses.LILY])
	for index in range(3):
		game.attack_time = 0.0
		game.act("attack")
		game.tick_lily_repeat(1.0)
	check(game.bolts.size() == 10, "Cursed Lily should repeat the third attack for six projectiles.")
	setup(game, 2)
	game.relics.equip(game.Relics.ORCHID_SPRING)
	check(is_equal_approx(game.skill_cooldown(), 1.92), "Orchid Spring did not shorten the skill cooldown.")
	game.act("skill")
	game.abilities.tick(game, 0.23)
	check(game.abilities.snapshot().effect.kind == "leap_impact", "A missed Nixia skill incorrectly triggered a follow-up.")
	setup(game, 3)
	check(game.player_hit_amount(100) == 90, "Virelia's damage adjustment was not applied.")
	game.act("skill")
	check(game.dash_remaining > 0.0 and is_zero_approx(game.dodge_time), "Virelia's skill dash should have a separate dodge cooldown.")
	setup(game, 4)
	check(is_equal_approx(game.skill_cooldown(), 2.04), "Zaria's skill cooldown was not reduced.")
	game.relics.equip(game.Relics.IRIS_DICE)
	var doubled := 0
	for index in range(500):
		if game.player_hit_amount(10) == 20:
			doubled += 1
	check(doubled > 35 and doubled < 115, "Iris Dice did not produce a plausible double-damage rate.")
	for heroine in range(1, 5):
		var id: String = game.RelicSources.SIGNATURES[heroine]
		check(id in game.Prep.relic_options(heroine) and game.RelicSources.hero_for(id) == heroine, "Signature relic is unavailable or has the wrong owner.")
		check(not game.RelicSources.can_offer(id, (heroine + 1) % 5), "Signature relic is available to the wrong heroine.")
	if failures.is_empty():
		print("PASS: heroine balance, Cursed Lily projectile repeat and signature relics.")
	else:
		for failure in failures:
			push_error(failure)
	quit(int(not failures.is_empty()))
