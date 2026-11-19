extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func enter_rest(game, hero: int, floor: int) -> bool:
	game.hero = hero
	game.start_run()
	game.run_seed = 15304
	game.floor_index = floor
	game.load_floor()
	for node: Dictionary in game.floor_manifest.nodes.values():
		if node.kind != "rest":
			continue
		game.room_id = node.id
		game.enter_room()
		game.player = game.chest_position
		game.interact()
		game.tap(game.RouteView.FORGE_ACTION.get_center())
		return game.screen == "forge"
	return false

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	if not check(enter_rest(game, 0, 3), "Angela could not inspect weapon evolution in a real rest room"):
		return
	if not check(game.evolution_offer().requirements.size() == 3 and not game.forge_weapon(),
			"Forging accepted a missing ingredient or missing mastery"):
		return
	game.resume_run()
	if not check(game.screen == "forge" and not game.room_complete
			and game.evolution_offer().id == "rosewall_execution", "The open forge did not resume"):
		return
	game.leave_forge()
	if not check(game.screen == "room_choice" and not game.room_complete, "Back consumed the rest room"):
		return
	game.relics.equip("relic_thornmail")
	game.relics.equip("guardians_ledger")
	game.tap(game.RouteView.FORGE_ACTION.get_center())
	if not check(not game.forge_weapon(), "The blade ignored Royal Guard mastery"):
		return
	game.relics.royal_guard_mastery = 3
	if not check(game.forge_weapon(), "The complete Rosewall recipe could not be forged"):
		return
	game.resume_run()
	if not check(game.screen == "fight" and game.room_complete
			and game.armory.for_hero(0) == "rosewall_execution" and game.codex.knows_weapon("rosewall_execution")
			and game.relics.has_relic("relic_thornmail") and game.relics.has_relic("guardians_ledger")
			and not game.forge_weapon(), "Forging changed the wrong state or could run twice"):
		return
	if not check(not game.starting_weapon_options().has("rosewall_execution"), "A run-only evolution became starting gear"):
		return

	if not check(enter_rest(game, 1, 4), "Vivianne could not inspect her forge"):
		return
	game.relics.equip("rosebound_refrain")
	game.checkpoint()
	game.resume_run()
	if not check(game.screen == "forge" and not game.forge_weapon(), "Elegy Spiral accepted a missing relic"):
		return
	game.relics.equip("black_rose_ink")
	if not check(game.forge_weapon(), "The complete Elegy Spiral recipe could not be forged"):
		return
	game.resume_run()
	if not check(game.armory.for_hero(1) == "elegy_spiral" and game.room_complete
			and game.codex.knows_weapon("elegy_spiral"), "The forged grimoire or its discovery was lost"):
		return
	print("PASS: forge route, preview, saved room, mastery, both evolutions, kept ingredients and ledger discoveries.")
	quit()
