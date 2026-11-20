extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_run()
	game.floor_index = 6
	game.load_floor()
	game.room_id = game.floor_manifest.boss_id
	game.enter_room()
	var boss: Dictionary = game.foes[0]
	var boss_hp: int = boss.hp
	game._physics_process(0.016)
	if not require(game.foes.size() == 1 and game.room_arrival > 0.0, "The boss acted during its arrival"):
		return
	game._physics_process(game.BOSS_ARRIVAL)
	if not require(game.foes.size() == 6, "Main entry failed to spawn the capstone flower shield"):
		return
	game.strike(boss)
	if not require(boss.hp == boss_hp, "Main strike ignored the flower shield"):
		return
	game.checkpoint()
	game.resume_run()
	if not require(game.foes.size() == 6, "Active save lost capstone nodes"):
		return
	boss = game.foes[0]
	for foe in game.foes:
		if foe.get("flower_node", false):
			for _i in range(4):
				game.strike(foe)
	game._physics_process(0.016)
	if not require(game.foes.size() == 1, "Main attack could not destroy all shield nodes"):
		return
	if not verify_phases(game, boss):
		return
	game.HeroAbilities.damage_foe(game, game.foes[0], 10)
	game._physics_process(0.016)
	if not require(game.boss_victory.left > 0.0, "Capstone defeat did not start the victory sequence"):
		return
	game.checkpoint()
	game.resume_run()
	if not require(game.boss_victory.left > 0.0, "Capstone victory sequence did not resume"):
		return
	game._physics_process(game.boss_victory.left)
	game._physics_process(0.016)
	if not require(game.screen == "clear", "The capstone defeat did not clear a normal-floor campaign"):
		return
	game.tap(game.View.FIRST_OPTION.get_center())
	if not require(game.floor_index == 7 and game.screen == "fight", "Clear continuation did not create an Endless floor"):
		return
	print("PASS: five capstone phases, resumable wards and final warning, and Endless continuation.")
	quit(0)

func verify_phases(game, boss: Dictionary) -> bool:
	var core = game.AstralCore
	var geometry = game.ForgottenEncounters
	game.barrels.clear()
	game.player = Vector2(432, 284)
	game.mercy = 100.0
	boss.phase = geometry.APPROACH
	boss.clock = 0.0
	# Rewind the rotation as well as the phase when constructing this fixture;
	# the boss may already have armed its first move as the entrance ended.
	boss.bloomheart_cycle = 0
	# Keep random boss footwork from interrupting this attack-rotation test.
	boss.x = 432.0
	boss.y = 172.0
	boss.footwork_cd = 100.0
	boss.hop_left = 0.0
	boss.slide_left = 0.0
	game.bolts.clear()
	for phase in range(core.CAPSTONE_ROTATIONS.size()):
		game.update_foes(0.016)
		if not require(core.stage(boss) == phase and boss.phase == geometry.WINDUP and boss.move == core.CAPSTONE_ROTATIONS[phase][0],
				"Bloomheart skipped the opening warning for phase %d." % (phase + 1)):
			return false
		game.HeroAbilities.damage_foe(game, boss, int(boss.max))
		game.HeroAbilities.damage_foe(game, boss, int(boss.max))
		if not require(boss.hp == maxi(1, core.capstone_floor(boss)), "Burst damage skipped a Bloomheart phase."):
			return false
		if phase == core.CAPSTONE_THRESHOLDS.size():
			var sites: Array = boss.rite_sites.duplicate(true)
			var maximum: int = boss.max
			game.checkpoint()
			game.resume_run()
			boss = game.foes[0]
			if not require(same_sites(boss.rite_sites, sites) and boss.max == maximum and core.stage(boss) == phase,
					"The final warning or its safe zones changed after resume."):
				return false
		game.update_foes(float(boss.clock) + 0.016)
		if not require(boss.phase == geometry.LUNGE, "A warned Bloomheart attack never became active."):
			return false
		if phase == core.CAPSTONE_THRESHOLDS.size():
			game.mercy = 0.0
			var health: int = game.hp
			game.player = core.rite_site(boss, 0)
			game.update_foes(float(core.RITE_PULSES[0]) + 0.016)
			if not require(game.hp == health, "The first refuge did not protect the player."):
				return false
			var next_site: Vector2 = core.rite_site(boss, 1)
			game.player.x = 60.0 if next_site.x > 432.0 else 802.0
			game.update_foes(float(core.RITE_PULSES[1]) - float(core.RITE_PULSES[0]))
			if not require(game.hp < health, "Standing outside the next refuge did not deal damage."):
				return false
			game.mercy = 100.0
		game.update_foes(float(boss.clock) + 0.016)
		if not require(boss.phase == geometry.RECOVERY, "Bloomheart did not leave a counterattack opening."):
			return false
		if phase < core.CAPSTONE_THRESHOLDS.size():
			game.update_foes(float(boss.clock) + 0.016)
	return true

func same_sites(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for index in range(a.size()):
		if not is_equal_approx(float(a[index][0]), float(b[index][0])) or not is_equal_approx(float(a[index][1]), float(b[index][1])):
			return false
	return true
