extends SceneTree

var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run(true)
	var elite_room := ""
	for seed in range(1, 50):
		game.run_seed = seed
		game.floor_index = 0
		game.floor_manifest = game.Dungeon.generate_floor(seed, 0)
		for id: String in game.floor_manifest.nodes:
			if game.floor_manifest.nodes[id].kind == "elite":
				elite_room = id
				break
		if not elite_room.is_empty():
			break
	check(not elite_room.is_empty(), "No elite room was generated.")
	if not elite_room.is_empty():
		game.room_id = elite_room
		game.enter_room()
		check(not game.foes.is_empty() and game.foes.all(func(foe): return bool(foe.get("elite", false))), "Every enemy in an elite room should be elite.")
		var foe: Dictionary = game.foes[0]
		foe.phase = game.ForgottenEncounters.WINDUP
		foe.clock = 1.0
		game.pace_elite_windup(foe, game.ForgottenEncounters.APPROACH)
		check(is_equal_approx(float(foe.clock), 0.8), "Elite windup did not become faster.")
		foe.elite_heal_drop = true
		foe.hp = 0
		game.update_foes(0.0)
		check(game.elite_heal_drops.size() == 1, "Defeated elite did not create its healing drop.")
		game.checkpoint()
		game.resume_run()
		check(game.elite_heal_drops.size() == 1, "Healing drop did not survive an interruption.")
		game.hp = 50
		game.player = Vector2(game.elite_heal_drops[0].x, game.elite_heal_drops[0].y)
		game.collect_elite_heals()
		check(game.hp == 58 and game.elite_heal_drops.is_empty(), "Healing drop did not restore health once.")
	var total := 0
	var elite_count := 0
	for seed in range(1, 31):
		game.run_seed = seed
		game.floor_index = 0
		game.floor_manifest = game.Dungeon.generate_floor(seed, 0)
		for id: String in game.floor_manifest.nodes:
			if game.floor_manifest.nodes[id].kind != "combat":
				continue
			game.room_id = id
			game.enter_room()
			for enemy: Dictionary in game.foes:
				total += 1
				if enemy.get("elite", false):
					elite_count += 1
			break
	check(elite_count > 0 and elite_count < total, "Ordinary rooms should sometimes, but not always, contain elites.")
	if failures.is_empty():
		print("PASS: elite rooms, faster windups, healing drops and save recovery.")
	else:
		for failure in failures:
			push_error(failure)
	quit(int(not failures.is_empty()))
