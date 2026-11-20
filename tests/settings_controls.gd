extends SceneTree

var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, issue: String) -> void:
	if not condition:
		failures.append(issue)

func touch(game, index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	game._unhandled_input(event)

func drag(game, index: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	game._unhandled_input(event)

func press_key(game, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._unhandled_input(event)

func capture(name: String) -> void:
	var directory := OS.get_environment("GARDEN_SETTINGS_QA")
	if directory.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(directory + "/" + name + ".png") == OK,
		"Did not save screenshot " + name)

func run() -> void:
	var main = load("res://main.tscn")
	var game = main.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	expect(Engine.max_fps == 60 and not game.preferences.left_handed, "Fresh preferences did not use default values.")
	game.tap(game.View.SETTINGS_LINK.get_center())
	expect(game.screen == "settings", "Settings did not open from the title menu.")
	game.tap(game.SettingsView.FPS_30.get_center())
	game.tap(game.SettingsView.LEFT_HAND.get_center())
	game.tap(game.SettingsView.MUSIC.get_center())
	game.tap(game.SettingsView.EFFECTS.get_center())
	expect(game.preferences.frame_cap == 30 and Engine.max_fps == 30 and game.preferences.left_handed,
		"Settings did not apply the selected values.")
	expect(not game.sound.music_enabled and not game.sound.effects_enabled,
		"The audio switches did not mute both independently.")
	expect(FileAccess.file_exists(game.Preferences.FILE_PATH) and not FileAccess.file_exists(game.SAVE),
		"Settings were not saved independently from runs.")
	await capture("settings-left")
	game.tap(game.SettingsView.BACK.get_center())
	expect(game.screen == "garden", "Settings Back did not return to the title.")
	game.start_run(true)
	var attack_point: Vector2 = game.touch_position(game.ATTACK)
	var joystick_point: Vector2 = game.touch_position(game.JOYSTICK)
	expect(is_equal_approx(attack_point.x, game.JOYSTICK.x) and is_equal_approx(joystick_point.x, game.ATTACK.x),
		"Left-handed layout misplaced the action or movement pad.")
	game.attack_time = 0.0
	var floating_point := Vector2(484, 188)
	touch(game, 0, floating_point, true)
	expect(game.joystick_id == 0 and game.joystick_origin == floating_point and game.stick == Vector2.ZERO,
		"Mirrored joystick did not capture a fresh origin away from its resting indicator.")
	drag(game, 0, floating_point + Vector2(6, 2))
	expect(game.stick == Vector2.ZERO, "A small drag escaped the deadzone.")
	drag(game, 0, floating_point + Vector2(36, 0))
	expect(game.stick.x > 0.55 and game.stick.x < 0.7 and is_zero_approx(game.stick.y),
		"Partial drag did not preserve analog movement.")
	drag(game, 1, floating_point - Vector2(190, 0))
	expect(game.stick.x > 0.35, "An uncaptured finger overrode the joystick.")
	drag(game, 0, floating_point - Vector2(190, 0))
	expect(game.stick == Vector2.LEFT, "A captured drag ceased working outside the movement region.")
	touch(game, 1, attack_point, true)
	expect(game.attack_time > 0.0 and game.joystick_id == 0,
		"Mirrored attack hitbox did not act during a concurrent joystick touch.")
	touch(game, 0, floating_point - Vector2(190, 0), false)
	expect(game.joystick_id == -1 and game.stick == Vector2.ZERO and game.joystick_origin == Vector2.ZERO,
		"Mirrored joystick did not release cleanly after leaving its region.")
	await capture("battle-left")

	game.resource = game.HeroUltimates.CHARGE
	var ultimate_point: Vector2 = game.touch_position(game.ULTIMATE)
	touch(game, 2, ultimate_point, true)
	expect(game.resource == 0 and not game.ultimate_ready(), "Mirrored Ultimate hitbox did not spend its charge.")
	game.ultimates.reset()
	game.resource = game.HeroUltimates.CHARGE
	press_key(game, KEY_U)
	expect(game.resource == 0, "The U shortcut did not trigger an available Ultimate.")

	game.ultimates.reset()
	game.hero = 1
	game.resource = game.HeroUltimates.CHARGE
	touch(game, 4, ultimate_point, true)
	game.visual_clock += 0.2
	expect(game.preview_action() == "ultimate" and game.ultimate_ready(),
		"Holding a ranged Ultimate did not show its preview while preserving charge.")
	touch(game, 4, ultimate_point + Vector2.UP * 74.0, false)
	expect(game.aim_touch_id < 0 and game.ultimate_ready(), "Sliding off an aimed ability did not cancel it.")
	var skill_point: Vector2 = game.touch_position(game.SKILL)
	var landing: Vector2 = game.HeroAbilities.ranged_skill_landmark(game, 1)
	touch(game, 5, skill_point, true)
	expect(is_zero_approx(game.skill_time), "A ranged Skill cast before release.")
	touch(game, 5, skill_point, false)
	expect(game.skill_time > 0.0 and game.abilities.active_verse_zone().is_equal_approx(landing),
		"The released skill did not use the world position shown by its preview.")
	game.hero = 0
	game.abilities.reset()

	var seed: int = game.run_seed
	var active_run: String = game.run_id
	game.hp = 67
	game.bonus = 4
	game.resource = 2
	game.run_time = 73.0
	for relic_id in game.Relics.DEFINITIONS:
		game.relics.equip(relic_id)
	touch(game, 0, floating_point, true)
	drag(game, 0, floating_point + Vector2.DOWN * 70)
	game.tap(game.View.PAUSE.get_center())
	expect(game.screen == "fight" and game.run_paused and game.joystick_id == -1 and game.stick == Vector2.ZERO,
		"Pause lost the run or kept the movement capture active.")
	var position: Vector2 = game.player
	game.attack_time = 0.0
	game.dodge_time = 0.0
	press_key(game, KEY_J)
	press_key(game, KEY_K)
	game._physics_process(0.10)
	game.tap(game.View.roster_hit(3).get_center())
	expect(game.player == position and game.run_time == 73.0 and game.attack_time == 0.0 and game.dodge_time == 0.0
		and game.hero == 0 and game.screen == "fight" and game.run_id == active_run,
		"The paused sheet accepted a combat action, advanced the clock, or changed the character.")
	await capture("pause-character")
	game.tap(game.PauseView.END_RUN.get_center())
	expect(game.confirm_end_run and game.run_paused and FileAccess.file_exists(game.SAVE),
		"End Run skipped the deliberate confirmation step.")
	await capture("pause-end-confirmation")
	game.tap(game.PauseView.CONFIRM_CANCEL.get_center())
	expect(game.run_paused and not game.confirm_end_run, "Backing out of End Run did not return to the character sheet.")
	game.tap(game.PauseView.RESUME.get_center())
	expect(game.screen == "fight" and not game.run_paused and game.player == position and game.run_id == active_run,
		"Resume did not return to the same live run.")
	touch(game, 0, floating_point, true)
	drag(game, 0, floating_point + Vector2.DOWN * 70)
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	expect(game.joystick_id == -1 and game.stick == Vector2.ZERO,
		"App backgrounding did not release held movement.")
	press_key(game, KEY_ESCAPE)
	expect(game.run_paused, "Escape did not open the character sheet.")
	game.tap(game.PauseView.END_RUN.get_center())
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saved: Dictionary = game.RunProfile.read_json(game.SAVE)
	expect(saved.get("screen") == "fight" and saved.get("run_id") == active_run and int(saved.get("hp", -1)) == game.hp,
		"App backgrounding with a pause confirmation saved the overlay instead of the live run.")
	game.free()
	Engine.max_fps = 0
	game = main.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	expect(Engine.max_fps == 30 and game.preferences.left_handed, "Preferences did not restore on a fresh scene.")
	expect(not game.sound.music_enabled and not game.sound.effects_enabled, "Audio preferences did not restore.")
	game.tap(game.View.CONTINUE.get_center())
	expect(game.screen == "fight" and game.run_seed == seed and Engine.max_fps == 30,
		"Continuing a run changed preferences or the active run.")
	expect(not game.run_paused and game.hp == 67 and game.resource == 2 and game.bonus == 4
		and game.relics.owned.size() == game.Relics.DEFINITIONS.size(), "A suspended run lost its build on reload.")
	game.screen = "roster"
	game.tap(game.View.roster_hit(3).get_center())
	expect(game.screen == "fight" and game.hero == 0 and game.run_id == active_run,
		"An active save allowed a roster tap to change the character.")
	game.tap(game.View.PAUSE.get_center())
	game.tap(game.PauseView.END_RUN.get_center())
	game.tap(game.PauseView.CONFIRM_END.get_center())
	var history: Array = game.profile.history()
	var summary: Dictionary = history[0] if not history.is_empty() else {}
	expect(game.screen == "summary" and not game.run_paused and not FileAccess.file_exists(game.SAVE)
		and summary.get("run_id") == active_run and summary.get("result") == "ended"
		and summary.get("cause") == "player_ended",
		"Confirmed End Run did not permanently finalize this run with its own outcome.")
	game.tap(game.View.SECOND_OPTION.get_center())
	game.tap(game.Hub.TITLE.get_center())
	game.tap(game.View.SETTINGS_LINK.get_center())
	game.tap(game.SettingsView.FPS_60.get_center())
	game.tap(game.SettingsView.RIGHT_HAND.get_center())
	game.tap(game.SettingsView.MUSIC.get_center())
	expect(Engine.max_fps == 60 and not game.preferences.left_handed, "Standard preferences could not be restored.")
	await capture("settings-right")
	var loaded_preferences = game.Preferences.new()
	loaded_preferences.load_local()
	expect(loaded_preferences.frame_cap == 60 and not loaded_preferences.left_handed,
		"Overwriting the settings file did not preserve new choices.")
	expect(loaded_preferences.music_enabled and not loaded_preferences.effects_enabled,
		"Turning music on did not preserve the separate effects preference.")
	game.tap(game.SettingsView.BACK.get_center())
	game.tap(game.View.CONTINUE.get_center())
	var before_swipe: int = game.hero
	var row_center: Vector2 = game.View.roster_hit(3).get_center()
	touch(game, 8, row_center, true)
	drag(game, 8, row_center - Vector2(0, 155))
	touch(game, 8, row_center - Vector2(0, 155), false)
	expect(game.roster_first == game.roster_last_first() and game.hero == before_swipe,
		"Swiping the roster selected a hero or failed to reveal its last rows.")
	var whi_tile: Vector2 = game.View.roster_hit(game.GuestRoster.WHI - game.roster_first).get_center()
	touch(game, 8, whi_tile, true)
	touch(game, 8, whi_tile, false)
	expect(game.hero == game.GuestRoster.WHI, "The last visible roster row did not select Whi.")
	game.tap(game.View.DESCEND.get_center())
	expect(game.screen == "seed_shop" and game.seed_shop_focus == "hero_whi",
		"Locked Whi did not lead to her shop offer.")
	game.tap(game.SeedShop.BACK.get_center())
	expect(game.screen == "roster" and game.hero >= game.roster_first and game.hero < game.roster_first + game.View.ROSTER_ROWS,
		"Returning from the shop scrolled the selected heroine out of view.")
	game.tap(game.View.ROSTER_UP.get_center())
	game.tap(game.View.ROSTER_UP.get_center())
	game.tap(game.View.ROSTER_UP.get_center())
	game.tap(game.View.roster_hit(3).get_center())
	expect(game.screen == "roster" and game.hero == 3, "A character could not be chosen after the prior run ended.")
	game.tap(game.View.DESCEND.get_center())
	game.tap(game.Prep.ENTER.get_center())
	touch(game, 5, Vector2(600, 183), true)
	expect(game.joystick_id == -1, "The right-handed joystick accepted a touch from the action side.")
	var left_point := Vector2(341, 162)
	touch(game, 6, left_point, true)
	expect(game.joystick_id == 6 and game.joystick_origin == left_point,
		"The right-handed joystick did not float on the left half of the field.")
	var canceled := InputEventScreenTouch.new()
	canceled.index = 6
	canceled.position = left_point
	canceled.canceled = true
	game._unhandled_input(canceled)
	expect(game.joystick_id == -1 and game.stick == Vector2.ZERO, "A canceled screen touch stayed captured.")
	game.pending_chest = true
	game.chest_position = Vector2(261, 220)
	game.player = game.chest_position + Vector2(0, 22)
	touch(game, 7, game.chest_position + Vector2(0, -53), true)
	expect(game.chest_open_time > 0.0 and game.joystick_id == -1,
		"The floating joystick captured a press on the reachable chest sprite.")
	game._physics_process(game.CHEST_OPEN_DURATION)
	game.tap(game.View.PAUSE.get_center())
	expect(game.screen == "reward" and game.run_paused, "A reward could not be paused before choosing loot.")
	game.tap(game.PauseView.RESUME.get_center())
	expect(game.screen == "reward" and not game.run_paused, "Resuming skipped the pending reward.")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: settings, mirrored floating controls, paused stats, active-run restore, and confirmed end flow.")
	quit(0 if failures.is_empty() else 1)
