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
	game.act("skill")
	game.abilities.tick(game, 0.23)
	check(game.abilities.snapshot().effect.kind == "leap_impact", "A missed Nixia skill incorrectly triggered a follow-up.")
	check(is_equal_approx(game.skill_time, 3.0), "A missed leap did not start the three-second cooldown on landing.")
	game.skill_time = 0.0
	game.relics.equip(game.Relics.ORCHID_SPRING)
	game.act("skill")
	game.abilities.tick(game, 0.23)
	check(is_equal_approx(game.skill_time, 2.4), "Orchid Spring did not shorten Nixia's miss cooldown.")
	setup(game, 3)
	check(game.player_hit_amount(100) == 90, "Virelia's damage adjustment was not applied.")
	game.act("skill")
	check(game.dash_remaining > 0.0 and is_zero_approx(game.dodge_time), "Virelia's skill dash should have a separate dodge cooldown.")
	setup(game, 4)
	check(game.hp == 65, "Zaria did not start with her new max health.")
	game.hp = 90
	game.checkpoint()
	game.resume_run()
	check(game.hp == 65, "Zaria retained health above her new maximum after resuming.")
	game.act("dodge")
	check(is_equal_approx(game.dodge_time, 0.5), "Zaria's Dodge did not use her new recharge time.")
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
	test_guest_heroines(game)
	if failures.is_empty():
		print("PASS: heroine balance, Cursed Lily projectile repeat and signature relics.")
	else:
		for failure in failures:
			push_error(failure)
	quit(int(not failures.is_empty()))

func test_guest_heroines(game) -> void:
	var roster = game.GuestRoster
	check(game.RunProfile.SEED_OFFERS["hero_mina"] == 200 and game.RunProfile.SEED_OFFERS["hero_whi"] == 200,
		"Guest heroine unlocks did not cost 200 Garden Seeds.")
	game.profile.set_data({"garden_seeds": 0, "unlocks": ["hero_mina", "hero_whi"]})
	setup(game, roster.MINA)
	game.act("dodge")
	game.act("skill")
	check(game.dash_remaining <= 0.0 and is_equal_approx(game.skill_time, game.GuestCombat.RAGE_COOLDOWN) and is_equal_approx(game.guest_combat.rage_left, game.GuestCombat.RAGE_TIME), "Mina should have no dodge and a two-second rage skill.")
	var victim := {"x": 230.0, "y": 216.0, "hp": 300, "max": 300, "boss": false, "kind": 0, "phase": 0, "clock": 2.0}
	game.foes.append(victim)
	game.room_arrival = 0.0
	game.guest_combat.tick(game, 10.0)
	var ramp: float = game.guest_combat.damage_factor()
	game.act("attack")
	var after_slam: int = victim.hp
	game.attack_time = 0.0
	game.act("attack")
	check(ramp > 1.0 and 300 - after_slam > after_slam - int(victim.hp) and game.guest_combat.next_slam,
		"Mina's attack sequence or time-based Battle Temper was missing.")
	game.foes.clear()
	game.guest_combat.tick(game, 0.016)
	check(is_equal_approx(game.guest_combat.damage_factor(), 1.0), "Mina retained Battle Temper after combat.")
	setup(game, roster.WHI)
	victim = {"x": 800.0, "y": 216.0, "hp": 300, "max": 300, "boss": false, "kind": 0, "phase": 0, "clock": 2.0}
	game.foes.append(victim)
	game.act("attack")
	check(game.guest_combat.landed_modes == 1, "Holy did not land from across the arena.")
	victim.x = 210.0
	game.attack_time = 0.0
	game.choose_whi_mode(1)
	game.act("attack")
	game.attack_time = 0.0
	game.choose_whi_mode(2)
	game.act("attack")
	var before_first: int = victim.hp
	check(game.guest_combat.judgment_hits == 5 and game.ultimates.cue_time <= 0.0,
		"Whi's first three-stance chain should queue five hits without a cut-in.")
	game.guest_combat.tick(game, 0.8)
	check(before_first - int(victim.hp) == 40 and game.guest_combat.combo_window > 0.0,
		"Whi's first chain did not land five hits and open the combo window.")
	for mode in range(3):
		victim.x = 210.0
		game.attack_time = 0.0
		game.choose_whi_mode(mode)
		game.act("attack")
	var before: int = victim.hp
	var grace: int = game.resource
	check(game.ultimates.cue_hero == roster.WHI and game.ultimates.cue_time > 0.0 and not game.ultimate_ready(),
		"Whi did not start her automatic cut-in after the second three-stance chain.")
	game.ultimates.tick_cutin(game, 0.25)
	check(int(victim.hp) == before and game.guest_combat.judgment_hits == 5,
		"Whi struck before her portrait cleared.")
	game.checkpoint()
	game.resume_run()
	victim = game.foes[0]
	check(game.ultimates.cue_hero == roster.WHI and game.ultimates.cue_time > 0.0,
		"Whi lost her cut-in after resuming.")
	game.ultimates.tick_cutin(game, float(game.ultimates.cue_time))
	game.guest_combat.tick(game, 0.8)
	check(before - int(victim.hp) == 40 and game.guest_combat.judgment_hits == 0 and game.resource == grace,
		"Whi's cut-in changed the five automatic hits or spent her Grace.")
	check(game.guest_combat.trance_left > 0.0 and game.guest_combat.mode == 0, "Whi did not enter Holy trance after her cut-in.")
