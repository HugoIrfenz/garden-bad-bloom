extends SceneTree

var issues := PackedStringArray()

func _initialize() -> void:
	call_deferred("run")

func expect(passed: bool, issue: String) -> void:
	if not passed:
		issues.append(issue)

func fixture(game, guard_delay: float = 0.0) -> void:
	game.barrels.clear()
	game.boss_victory.reset()
	game.room_arrival = 0.0
	game.screen = "fight"
	game.foes = [{"x": 400, "y": 208, "hp": 80, "max": 80, "kind": 0,
		"boss": false, "phase": 0, "clock": 0.8}]
	game.bolts.clear()
	game.abilities.reset()
	game.player = Vector2(300, 208)
	game.facing = Vector2.RIGHT
	game.skill_time = 0.0
	game.dash_remaining = 0.0
	game.mercy = 0.0
	game.resource = 0
	game.hp = 100
	game.act("skill")
	game.abilities.tick(game, guard_delay)

func hostile_shot(game, from_front: bool = true, terrain: bool = false) -> void:
	var side := 1.0 if from_front else -1.0
	game.bolts.append({"x": 300 + 19.0 * side if not terrain else 300.0, "y": 208,
		"dx": -side if not terrain else 0.0, "dy": 0.0,
		"life": 1.0, "speed": 160.0, "damage": 20, "terrain": terrain})
	game.update_bolts(0.05)

func reflected_count(game) -> int:
	var shots: Array = game.abilities.snapshot().relic_bolts
	return shots.filter(func(bolt): return bolt.get("reflected", false)).size()

func acquire_locket(game) -> void:
	game.start_run()
	game.floor_index = 0
	game.load_floor()
	game.room_id = game.floor_manifest.boss_id
	game.enter_room()
	for relic_id in [game.Relics.WEDDING_RING, game.Relics.GLASS_EYELASH,
			game.Relics.LAST_TEASPOON, game.Relics.HONEST_RECEIPT, game.Relics.THORNMAIL]:
		game.relics.equip(relic_id)
	expect(game.relics.boss_offer(1048, 3) != game.Relics.COUNTERCLOCK_LOCKET, "A heroine without Royal Guard was offered Counterclock Locket.")
	for foe in game.foes:
		foe.hp = 0
	game._physics_process(0.016)
	# Boss deaths now play their authored fall before the reward appears.
	game._physics_process(2.0)
	game._physics_process(0.016)
	expect(game.reward_relic_id == game.Relics.COUNTERCLOCK_LOCKET, "The locket was absent from Angela’s boss reward pool.")
	game.player = game.chest_position
	game.open_chest()
	game._physics_process(0.5)
	game.tap(game.View.Reward.RELIC_RECT.get_center())
	game.tap(game.View.Reward.RELIC_EQUIP.get_center())
	expect(game.relics.iron_bouquet_active(), "The reward card did not complete Iron Bouquet.")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	acquire_locket(game)
	fixture(game)
	hostile_shot(game)
	expect(game.hp == 100 and game.bolts.is_empty() and reflected_count(game) == 1,
		"A timely frontal block did not consume the enemy bolt and reflect it once.")
	var state = game.abilities.snapshot()
	var reflected: Array = state.relic_bolts.filter(func(bolt): return bolt.get("reflected", false))
	if not reflected.is_empty():
		expect(reflected[0].dx > 0.99 and int(reflected[0].power) == 11 and reflected[0].plants_bouquet,
			"The reflected bolt did not reverse its direction, reduce its damage, or enable Iron Bouquet.")
	expect(state.relic_bolts.size() == 6 and state.iron_bouquets.is_empty(),
		"Thornmail’s fan was missing or Iron Bouquet planted before landing.")

	game.checkpoint()
	game.resume_run()
	game.barrels.clear()
	hostile_shot(game)
	expect(reflected_count(game) == 1 and game.hp == 100,
		"Resume allowed reflection to trigger twice in the same guard.")
	game.abilities.tick(game, 0.41)
	var landed: Array = game.abilities.snapshot().iron_bouquets
	expect(landed.size() == 1 and game.bolts.is_empty() and reflected_count(game) == 0 and game.foes[0].hp < 80,
		"The reflected shot did not damage an opponent and leave exactly one friendly patch.")
	if not landed.is_empty():
		expect(float(landed[0].x) > 380.0, "Iron Bouquet did not plant at the actual landing point.")

	game.checkpoint()
	game.resume_run()
	game.barrels.clear()
	var before: int = game.foes[0].hp
	game.abilities.tick(game, 0.09)
	expect(game.foes[0].hp == before, "The restored patch damaged the enemy before arming.")
	game.abilities.tick(game, 0.09)
	var after: int = game.foes[0].hp
	game.abilities.tick(game, 0.06)
	expect(after == before - 11 and game.foes[0].hp == after and game.hp == 100,
		"The restored Iron Bouquet patch failed its one enemy-only strike.")
	expect(game.abilities.snapshot().relic_bolts.is_empty(), "A reflected hit recursively generated more projectiles.")

	fixture(game)
	game.damage_hero(20, Vector2(390, 208))
	hostile_shot(game)
	expect(reflected_count(game) == 1,
		"A perfect melee guard incorrectly consumed the locket’s projectile reflection.")

	fixture(game, 0.28)
	hostile_shot(game)
	expect(game.hp == 100 and reflected_count(game) == 0, "A late guard must absorb the shot without reflecting it.")
	fixture(game)
	hostile_shot(game, false)
	expect(game.hp == 100 and reflected_count(game) == 1, "A perfect guard failed to reflect a shot from behind.")
	fixture(game)
	hostile_shot(game, true, true)
	expect(game.hp == 100 and reflected_count(game) == 0, "The stationary hazard should be stopped without reflection.")

	fixture(game)
	game.barrels.append(Vector2(360, 208))
	hostile_shot(game)
	game.abilities.tick(game, 0.45)
	var blocked: Array = game.abilities.snapshot().iron_bouquets
	expect(game.foes[0].hp == 80 and blocked.size() == 1 and float(blocked[0].x) < 350.0,
		"A reflected shot or its patch crossed cover.")

	fixture(game)
	game.foes[0].y = 300
	hostile_shot(game)
	game.abilities.tick(game, 1.0)
	var missed: Array = game.abilities.snapshot().iron_bouquets
	expect(game.foes[0].hp == 80 and missed.size() == 1 and float(missed[0].x) > 500.0,
		"A missed reflection did not plant at its range limit.")

	game.relics.reset()
	game.relics.equip(game.Relics.COUNTERCLOCK_LOCKET)
	fixture(game)
	hostile_shot(game)
	game.abilities.tick(game, 0.41)
	expect(game.foes[0].hp == 69 and game.abilities.snapshot().iron_bouquets.is_empty(),
		"Counterclock Locket alone did not return a weakened shot without a patch.")

	fixture(game, 0.75)
	var guarded_position: Vector2 = game.player
	var attacker := guarded_position + Vector2.LEFT * 34.0
	game.OptionalBosses.release_brasswing(game, {"optional_attack": 1}, attacker, Vector2.RIGHT)
	expect(game.player == guarded_position and game.hp == 100,
		"Brasswing moved Angela or dealt damage through a late guard.")

	game.abilities.reset()
	game.skill_time = 0.0
	game.dash_remaining = 0.12
	game.mercy = 0.12
	game.press_screen_touch(17, game.touch_position(game.SKILL))
	expect(game.abilities.guard_remaining() > 0.0, "A skill tap during a dodge did not raise the guard.")
	game.ground_hazards.patches.assign([{
		"x": guarded_position.x, "y": guarded_position.y, "kind": "roots",
		"phase": 2, "left": 0.40, "contact": false,
	}])
	game.mercy = 0.0
	game.ground_hazards.tick(game, guarded_position, 0.016)
	expect(not game.combat_status.has_hero(game.CombatStatuses.ROOT) and game.skill_time == 5.0,
		"Root Grapple bypassed the guard or failed to start recharge.")

	for issue in issues:
		push_error(issue)
	if issues.is_empty():
		print("PASS: Angela-only locket acquisition, projectile reflection, Iron Bouquet landing, cover and single-use save/resume.")
	quit(0 if issues.is_empty() else 1)
