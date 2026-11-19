extends SceneTree

const Profile = preload("res://scripts/run_profile.gd")
const RUN = "user://run.json"

var issues := PackedStringArray()

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	if not condition:
		issues.append(message)

func run() -> void:
	test_live_migration_and_finish()
	test_atomic_recovery_and_replay()
	if issues.is_empty():
		print("PASS: old profile/save migration, stable run IDs, death and clear history, recoverable failed writes, and duplicate terminal replay.")
	else:
		for issue in issues:
			push_error(issue)
	quit(0 if issues.is_empty() else 1)

func test_live_migration_and_finish() -> void:
	var old = FileAccess.open("user://profile.txt", FileAccess.WRITE)
	old.store_string("19")
	old.close()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	expect(game.garden_seeds == 19 and game.profile.history().is_empty()
		and FileAccess.file_exists("user://profile.json"), "Legacy profile did not migrate its balance.")
	game.start_run(true)
	var first_fresh: String = game.run_id
	var state = Profile.read_json(RUN)
	expect(first_fresh.length() == 32 and state.run_id == first_fresh, "New run ID was not saved.")

	state.erase("run_id")
	Profile.write_json(RUN, state)
	game.resume_run()
	var legacy_id = Profile.legacy_run_id(game.run_seed, game.hero)
	game.checkpoint()
	expect(game.run_id == legacy_id and Profile.read_json(RUN).run_id == legacy_id, "Legacy active run did not gain a stable ID.")

	game.depth = 2
	game.hp = 0
	game._physics_process(0.016)
	var results: Array = game.profile.history()
	expect(game.screen == "summary" and results.size() == 1 and game.garden_seeds == 22
		and not FileAccess.file_exists(RUN), "Death did not commit the terminal result and award together.")
	if results.size() != 1:
		game.free()
		return
	var defeat: Dictionary = results[0]
	expect(defeat.result == "defeat" and defeat.cause == "hp_depleted"
		and defeat.run_id == legacy_id and int(defeat.depth) == 2, "Death history omitted its result, cause, or stage.")
	expect(Profile.stage_result(RUN, defeat) == OK, "Could not replay the terminal marker.")

	var restarted = load("res://main.tscn").instantiate()
	root.add_child(restarted)
	expect(restarted.screen == "summary" and restarted.garden_seeds == 22
		and restarted.profile.history().size() == 1 and not FileAccess.file_exists(RUN),
		"Boot replay awarded the old result a second time or failed cleanup.")
	game.free()

	restarted.start_run()
	expect(restarted.run_id != first_fresh and restarted.run_id != legacy_id, "Fresh run reused an existing ID.")
	restarted.floor_index = 6
	restarted.load_floor()
	restarted.room_id = restarted.floor_manifest.boss_id
	restarted.enter_room()
	restarted.room_arrival = 0.0
	restarted.foes[0].hp = 0
	restarted._physics_process(0.016)
	restarted._physics_process(restarted.boss_victory.left)
	restarted._physics_process(0.016)
	expect(restarted.screen == "clear", "Fixture did not reach the capstone clear.")
	restarted.tap(restarted.View.SECOND_OPTION.get_center())
	expect(restarted.confirm_end_run and FileAccess.file_exists(RUN), "Ending a clear did not ask for confirmation.")
	restarted.tap(restarted.PauseView.CONFIRM_END.get_center())
	results = restarted.profile.history()
	expect(restarted.screen == "summary" and restarted.garden_seeds == 23
		and results.size() == 2 and not FileAccess.file_exists(RUN), "Ending the clear did not record one bookable run.")
	if results.size() == 2:
		expect(results[0].result == "clear" and bool(results[0].campaign_cleared)
			and results[1].result == "defeat", "History lost newest-first outcome ordering.")
	restarted.free()

func test_atomic_recovery_and_replay() -> void:
	var directory = "user://blocked_profile"
	DirAccess.make_dir_absolute(directory)
	var active = directory.path_join("run.json")
	var store = Profile.new(directory)
	var summary = fixture("interrupt-before-profile", 8)
	var primary_block = directory.path_join("profile.json.tmp")
	DirAccess.make_dir_absolute(primary_block)
	Profile.stage_result(active, summary)
	expect(store.finish_staged(active) != OK and FileAccess.file_exists(active)
		and store.garden_seeds == 0, "Failed profile write cleared the only terminal checkpoint.")
	DirAccess.remove_absolute(primary_block)

	var backup_block = directory.path_join("profile.json.bak.tmp")
	DirAccess.make_dir_absolute(backup_block)
	expect(store.finish_staged(active) != OK and FileAccess.file_exists(active)
		and store.garden_seeds == 8 and store.history().size() == 1,
		"Failed backup did not preserve the already committed transaction marker.")
	DirAccess.remove_absolute(backup_block)
	var restarted = Profile.new(directory)
	expect(restarted.finish_staged(active) == OK and not FileAccess.file_exists(active)
		and restarted.garden_seeds == 8 and restarted.history().size() == 1,
		"Retry after a committed profile double-booked the reward.")

	for index in range(Profile.HISTORY_LIMIT + 1):
		var next = fixture("fixture-%d" % index, 1)
		var staged = Profile.stage_result(active, next)
		if staged != OK or restarted.finish_staged(active) != OK:
			issues.append("Could not fill the bounded run history.")
			return
	expect(restarted.history().size() == Profile.HISTORY_LIMIT and restarted.has_result(summary.run_id),
		"History retention erased the receipt needed for old replay protection.")
	var balance = restarted.garden_seeds
	Profile.stage_result(active, summary)
	expect(restarted.finish_staged(active) == OK and restarted.garden_seeds == balance,
		"A replay duplicated a result after it aged out of visible history.")

	Profile.write_json(active, {"screen": "fight", "run_id": "new-active-run"})
	expect(Profile.stage_result(active, summary) == ERR_BUSY
		and Profile.read_json(active).run_id == "new-active-run",
		"An older finalization overwrote an unrelated active run.")

func fixture(id: String, seeds: int) -> Dictionary:
	return {"run_id": id, "result": "clear", "seeds_earned": seeds}
