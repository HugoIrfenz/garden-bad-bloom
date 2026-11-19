extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run(true)
	for id: String in game.OptionalBosses.NAMES:
		var biome := -1
		for index in range(game.Dungeon.OPTIONAL_BOSS_PAIRS.size()):
			if id in game.Dungeon.OPTIONAL_BOSS_PAIRS[index]:
				biome = index
				break
		if not exercise(game, biome, id):
			push_error("Optional boss route, checkpoint or reward failed for %s." % id)
			quit(1)
			return
	if not exercise_older_floor(game):
		push_error("An existing floor changed or failed to unlock detours on its next floor.")
		quit(1)
		return
	print("PASS: 26 approach rooms, 39 optional attacks, saved phase transitions and victories, music, rewards and campaign rejoin.")
	quit()

func exercise(game, biome: int, boss_id: String) -> bool:
	game.floor_index = biome
	for seed in range(64):
		game.run_seed = seed
		game.load_floor()
		if game.floor_manifest.optional_boss_route.boss == boss_id:
			break
	var detour: Dictionary = game.floor_manifest.optional_boss_route
	if detour.boss != boss_id:
		return false
	game.room_id = detour.entry
	game.enter_room()
	game.room_complete = true
	for stage in range(detour.rooms.size()):
		var id: String = detour.rooms[stage]
		game.take_exit(id)
		if game.room_id != id:
			return false
		if stage == 2:
			break
		var lesson: Array = game.OptionalBosses.APPROACHES[boss_id][stage]
		if game.foes.is_empty() or game.room_title != lesson[0] or not game.optional_arena_boss().is_empty():
			return false
		game.room_arrival = 0.0
		game.update_foes(1.0)
		var scout: Dictionary = game.foes[0]
		if scout.boss or scout.phase != 1 or int(scout.optional_attack) != int(lesson[1]):
			return false
		game.checkpoint()
		game.resume_run()
		scout = game.foes[0]
		if int(scout.optional_lesson) != int(lesson[1]) or scout.phase != 1:
			return false
		game.player = Vector2(90, 300)
		game.mercy = 5.0
		game.update_foes(float(scout.clock) + 0.01)
		if int(scout.get("optional_cycle", 0)) != 1:
			return false
		for foe: Dictionary in game.foes:
			foe.hp = 0
		game.update_foes(0.0)
		game.step_dungeon_room(0.0, Vector2.ZERO)
		if not game.pending_chest or not game.reward_relic_id.is_empty():
			return false
		game.finish_reward(0)
		if not game.room_complete:
			return false
	if game.foes.size() != 1 or game.foes[0].get("optional_boss") != detour.boss:
		return false
	if game.OptionalBosses.arena_texture(boss_id) == null or not ResourceLoader.exists(game.OptionalBosses.SPRITES[boss_id]):
		return false
	game.sound.request(detour.boss)
	if game.sound.active_cue != detour.boss or not game.sound.deck[game.sound.deck_index].stream.loop:
		return false
	game.room_arrival = 0.0
	game.update_foes(1.0)
	var clock: float = game.foes[0].clock
	game.checkpoint()
	game.resume_run()
	if game.foes.size() != 1 or game.foes[0].phase != 1 or not is_equal_approx(game.foes[0].clock, clock):
		return false
	if not exercise_attack_cycle(game, boss_id) or not exercise_phase_transition(game, boss_id):
		return false
	game.enter_room()
	game.room_arrival = 0.0
	game.update_foes(1.0)
	if boss_id == game.OptionalBosses.QUEEN:
		var boss: Dictionary = game.foes[0]
		boss.merge({"x": 432.0, "y": 220.0, "dx": 1.0, "dy": 0.0, "optional_attack": 0}, true)
		game.barrels.clear()
		game.bolts.clear()
		game.OptionalBosses.release(game, boss)
		if game.bolts.size() != 7 or not is_equal_approx(float(game.bolts[3].dx), 1.0):
			return false
		boss.optional_second = true
		game.bolts.clear()
		game.OptionalBosses.release(game, boss)
		if game.bolts.size() != 7 or not is_equal_approx(float(game.bolts[3].dx), -1.0) or game.bolts[3].x <= boss.x:
			return false
	if boss_id == game.OptionalBosses.MOTHER:
		var boss: Dictionary = game.foes[0]
		boss.optional_attack = 1
		game.player = game.OptionalBosses.MUSHROOMS[0]
		game.mercy = 0.0
		var before: int = game.hp
		game.OptionalBosses.release(game, boss)
		if game.hp != before:
			return false
		boss.optional_second = true
		game.OptionalBosses.release(game, boss)
		if game.hp >= before:
			return false
		game.combat_status.cleanse_hero("poison")
	if boss_id == game.OptionalBosses.LIBRARIAN:
		var boss: Dictionary = game.foes[0]
		boss.merge({"x": 432.0, "y": 221.0, "dx": 1.0, "dy": 0.0, "optional_attack": 1,
			"optional_second": true}, true)
		game.barrels.clear()
		game.player = game.target(boss)
		game.OptionalBosses.release(game, boss)
		if boss.hour_echoes.size() != 6:
			return false
		game.checkpoint()
		game.resume_run()
		boss = game.foes[0]
		if boss.hour_echoes.size() != 6:
			return false
		game.mercy = 0.0
		var before: int = game.hp
		game.OptionalBosses.tick_hour_echoes(game, boss, 2.0)
		if not boss.hour_echoes.is_empty() or game.hp != before:
			return false
	if boss_id == game.OptionalBosses.SCARECROW:
		var foe: Dictionary = game.foes[0]
		foe.merge({"x": 210.0, "y": 219.0, "dx": 1.0, "dy": 0.0, "optional_attack": 1}, true)
		game.OptionalBosses.release(game, foe)
		if game.barrels.size() != 1 or float(foe.clock) < 2.0:
			return false
		game.checkpoint()
		game.resume_run()
		if game.barrels.size() != 1:
			return false
	if boss_id == game.OptionalBosses.BANDIT:
		var foe: Dictionary = game.foes[0]
		game.barrels.clear()
		foe.hp = floori(float(foe.max) * 0.4)
		foe.phase = 3
		foe.clock = 0.0
		game.OptionalBosses.advance(game, foe)
		if not foe.get("optional_second", false):
			return false
		game.player = Vector2(430, 250)
		foe.merge({"tx": 470.0, "ty": 250.0, "dx": 1.0, "dy": 0.0, "optional_attack": 2}, true)
		game.OptionalBosses.release(game, foe)
		if not game.player.is_equal_approx(Vector2(470, 250)) or game.bolts.is_empty() or game.bolts.back().radius != 29.0:
			return false
	if boss_id == game.OptionalBosses.BRASSWING:
		var boss: Dictionary = game.foes[0]
		boss.hp = int(boss.max) >> 1
		boss.phase = 3
		boss.clock = 0.0
		game.OptionalBosses.advance(game, boss)
		game.checkpoint()
		game.resume_run()
		if game.foes.size() != 3 or game.defend_foe(game.foes[0], 25) != 0:
			return false
		var cart: Rect2 = game.OptionalBosses.cart_rect(game.room_clock, 0)
		var drone: Dictionary = game.foes[1]
		drone.x = cart.get_center().x
		drone.y = cart.get_center().y
		game.OptionalBosses.advance(game, drone)
		if drone.hp != 0 or game.defend_foe(game.foes[0], 25) != 0:
			return false
		game.foes[2].hp = 0
		game.update_foes(0.0)
		if game.foes.size() != 1 or game.defend_foe(game.foes[0], 25) != 25:
			return false
	if boss_id == game.OptionalBosses.HOUR:
		var boss: Dictionary = game.foes[0]
		boss.merge({"optional_second": true, "optional_attack": 2}, true)
		game.OptionalBosses.release(game, boss)
		if boss.hour_echoes.size() != 3:
			return false
		game.checkpoint()
		game.resume_run()
		if game.foes[0].hour_echoes.size() != 3:
			return false
	if boss_id == game.OptionalBosses.BRIDE:
		var boss: Dictionary = game.foes[0]
		game.player = Vector2(430, 250)
		game.mercy = 0.0
		boss.merge({"tx": 430.0, "ty": 250.0, "optional_attack": 1}, true)
		var prior_hp: int = game.hp
		game.OptionalBosses.release(game, boss)
		if game.hp >= prior_hp or not game.combat_status.has_hero("root"):
			return false
		game.combat_status.cleanse_hero("root")
		boss.phase = 1
		game.tap(game.player)
		game.resume_run()
		boss = game.foes[0]
		if not boss.get("bride_ribbon_broken", false):
			return false
		game.mercy = 0.0
		prior_hp = game.hp
		game.OptionalBosses.release(game, boss)
		if game.hp != prior_hp or game.combat_status.has_hero("root"):
			return false
		boss.erase("bride_ribbon_broken")
		game.player += Vector2(65, 0)
		prior_hp = game.hp
		game.OptionalBosses.release(game, boss)
		if game.hp != prior_hp or game.combat_status.has_hero("root"):
			return false
	if boss_id == game.OptionalBosses.CHOIR:
		var foe: Dictionary = game.foes[0]
		foe.optional_second = true
		game.barrels.clear()
		var origin := Vector2(330, 212)
		var full_charge: Vector2 = game.OptionalBosses.choir_charge(game, foe, origin, Vector2.RIGHT)
		game.player = game.OptionalBosses.CHOIR_BELLS[0]
		game.tap(game.player)
		game.resume_run()
		foe = game.foes[0]
		game.barrels.clear()
		var muted_charge: Vector2 = game.OptionalBosses.choir_charge(game, foe, origin, Vector2.RIGHT)
		if int(foe.get("choir_muted", 0)) != 1 or muted_charge.x >= full_charge.x:
			return false
	if boss_id == game.OptionalBosses.PRINCE:
		var prince: Dictionary = game.foes[0]
		var mirror: Vector2 = game.OptionalBosses.PRINCE_MIRRORS[0]
		prince.merge({"tx": mirror.x, "ty": mirror.y, "optional_attack": 2}, true)
		game.OptionalBosses.release(game, prince)
		game.checkpoint()
		game.resume_run()
		prince = game.foes[0]
		game.OptionalBosses.tick_hour_echoes(game, prince, 0.46)
		if int(prince.get("prince_broken", 0)) != 1:
			return false
		game.checkpoint()
		game.resume_run()
		prince = game.foes[0]
		prince.optional_attack = 1
		if game.OptionalBosses.prince_patterns(game, prince, game.target(prince), Vector2.RIGHT).size() != 1:
			return false
	if boss_id == game.OptionalBosses.VELVET:
		var boss: Dictionary = game.foes[0]
		boss.merge({"optional_second": true, "optional_cycle": 0, "optional_attack": 0}, true)
		game.OptionalBosses.release(game, boss)
		game.player = game.OptionalBosses.VELVET_PUPPETS[0]
		game.tap(game.player)
		game.resume_run()
		boss = game.foes[0]
		if int(boss.get("velvet_severed", 0)) != 1:
			return false
		boss.optional_attack = 2
		game.bolts.clear()
		game.OptionalBosses.release(game, boss)
		if game.bolts.size() != 3:
			return false
	if boss_id == game.OptionalBosses.MOONS:
		var boss: Dictionary = game.foes[0]
		boss.hp = int(boss.max) >> 1
		boss.phase = 3
		boss.clock = 0.0
		game.OptionalBosses.advance(game, boss)
		game.checkpoint()
		game.resume_run()
		boss = game.foes[0]
		if not boss.get("optional_second", false):
			return false
		boss.optional_attack = 1
		game.player = Vector2(432, 226)
		game.mercy = 0.0
		var prior_hp: int = game.hp
		game.OptionalBosses.release(game, boss)
		if game.hp != prior_hp or game.player != Vector2(432, 226):
			return false
	if boss_id == game.OptionalBosses.CHAIR:
		var boss: Dictionary = game.foes[0]
		boss.hp -= game.defend_foe(boss, int(boss.max))
		boss.phase = 3
		boss.clock = 0.0
		game.OptionalBosses.advance(game, boss)
		if not boss.get("optional_second", false) or game.foes.size() != 3:
			return false
		game.foes[1].hp = 0
		game.checkpoint()
		game.resume_run()
		boss = game.foes[0]
		if game.defend_foe(boss, 10) != 0:
			return false
		game.foes[2].hp = 0
		if game.defend_foe(boss, 10) < 10:
			return false
		game.hp = 100
		game.barrels.clear()
		for attack in range(3):
			game.player = Vector2(432, 250)
			boss.merge({"x": 432.0, "y": 145.0, "dx": 0.0, "dy": 1.0,
				"tx": game.player.x, "ty": game.player.y, "optional_attack": attack}, true)
			game.mercy = 0.0
			var before: int = game.hp
			game.OptionalBosses.release(game, boss)
			if game.hp >= before:
				return false
		game.relics.equip(game.Relics.SIXTH_SEAT_TRINKET)
		var before: int = game.hp
		var amount: int = game.healing_amount(6)
		game.ultimates.activate_cast(game, int(game.hero))
		if amount <= 0 or game.hp != before + amount:
			return false
		game.checkpoint()
		game.resume_run()
		if game.relics.spend_sixth_seat(biome) or not game.relics.spend_sixth_seat(biome + 1):
			return false
		game.relics.owned.erase(game.Relics.SIXTH_SEAT_TRINKET)
	game.foes[0].hp = 0
	game.update_foes(0.0)
	if game.boss_victory.left <= 0.0:
		return false
	game.checkpoint()
	game.resume_run()
	game._physics_process(game.boss_victory.left)
	game._physics_process(0.016)
	var reward: String = game.OptionalBosses.REWARDS[detour.boss]
	game.resume_run()
	if not game.pending_chest or game.reward_relic_id != reward or game.screen == "clear":
		return false
	game.player = game.chest_position
	game.open_chest()
	game._physics_process(0.5)
	game.resume_run()
	if game.screen != "reward" or game.reward_relic_id != reward:
		return false
	game.tap(game.View.Reward.RELIC_RECT.get_center())
	game.tap(game.View.Reward.RELIC_EQUIP.get_center())
	game.resume_run()
	if not game.room_complete or not game.relics.has_relic(reward):
		return false
	game.tap(game.View.Reward.RELIC_EQUIP.get_center())
	if game.relics.owned.count(reward) != 1 or game.pending_chest:
		return false
	game.take_exit(detour.rejoin)
	return game.room_id == detour.rejoin and game.floor_index == biome

# Attack effects are ordered by their authored cycle. Use normal update dispatch.
func exercise_attack_cycle(game, boss_id: String) -> bool:
	var moves := {
		"queen_of_dandelions": ["bolts", "hit", "hit"],
		"first_scarecrow": ["bolts", "hit", "bolts"],
		"mother_of_spores": ["bolts", "hit", "bolts"],
		"truffle_bandit": ["move", "bolts", "bolts"],
		"baroness_brasswing": ["hit", "hit", "bolts"],
		"unfinished_hour": ["echoes", "echoes", "echoes"],
		"bride_of_thorns": ["bolts", "hit", "hit"],
		"antlered_choir": ["hit", "bolts", "hit"],
		"crownless_prince": ["echoes", "echoes", "echoes"],
		"madam_black_velvet": ["hit", "hit", "bolts"],
		"queen_of_two_moons": ["hit", "hit", "hit"],
		"nebula_librarian": ["bolts", "echoes", "echoes"],
		"empty_sixth_chair": ["hit", "hit", "hit"],
	}
	var boss: Dictionary = game.foes[0]
	var origin := Vector2(432, 180)
	var patterns: Array = moves[boss_id]
	game.barrels.clear()
	for attack in range(patterns.size()):
		boss.merge({"x": origin.x, "y": origin.y, "clock": 0.0, "phase": 3}, true)
		boss.erase("hour_echoes")
		game.bolts.clear()
		game.hp = 100
		game.mercy = 0.0
		game.player = Vector2(510, 213) if boss_id == "queen_of_two_moons" else Vector2(432, 262)
		game.update_foes(0.0)
		if boss.phase != 1 or int(boss.optional_attack) != attack:
			push_error("%s failed to telegraph attack %d" % [boss_id, attack])
			return false
		game.update_foes(float(boss.clock) + 0.01)
		var observed := false
		match patterns[attack]:
			"hit": observed = game.hp < 100
			"bolts": observed = not game.bolts.is_empty()
			"echoes": observed = not boss.get("hour_echoes", []).is_empty()
			"move": observed = game.target(boss).distance_to(origin) > 0.0
		if not observed or int(boss.optional_cycle) != attack + 1:
			push_error("%s attack %d failed to produce its expected %s" % [boss_id, attack, patterns[attack]])
			return false
	return true

func exercise_phase_transition(game, boss_id: String) -> bool:
	var thresholds := {
		"truffle_bandit": 0.4, "unfinished_hour": 0.6, "antlered_choir": 0.4,
		"madam_black_velvet": 0.45, "nebula_librarian": 0.4, "empty_sixth_chair": 0.4,
	}
	var boss: Dictionary = game.foes[0]
	var threshold_hp := floori(float(boss.max) * float(thresholds.get(boss_id, 0.5)))
	boss.merge({"hp": threshold_hp + 1, "phase": 3, "clock": 0.0}, true)
	game.update_foes(0.0)
	if boss.get("optional_second", false) or boss.phase != 1:
		push_error("%s changed phase above its threshold" % boss_id)
		return false
	boss.merge({"hp": threshold_hp, "phase": 3, "clock": 0.0}, true)
	game.update_foes(0.0)
	game.checkpoint()
	game.resume_run()
	boss = game.foes[0]
	if not boss.get("optional_second", false) or boss.phase != 3 or not is_equal_approx(float(boss.clock), 1.35):
		push_error("%s second-phase transition did not persist" % boss_id)
		return false
	return true

func exercise_older_floor(game) -> bool:
	game.floor_index = 1
	game.floor_manifest = game.Dungeon.generate_floor(game.run_seed, game.floor_index)
	var prior_nodes: Dictionary = JSON.parse_string(JSON.stringify(game.floor_manifest.nodes))
	game.room_id = game.floor_manifest.entrance_id
	game.enter_room()
	game.checkpoint()
	game.resume_run()
	if game.floor_manifest.has("optional_boss_route") or game.floor_manifest.nodes != prior_nodes:
		return false
	game.next_floor()
	return game.floor_index == 2 and game.floor_manifest.has("optional_boss_route")
