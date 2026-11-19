extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	game.run_seed = 15304
	game.load_floor()
	for node: Dictionary in game.floor_manifest.nodes.values():
		if node.kind == "treasure":
			game.room_id = node.id
			break
	game.enter_room()
	var offered: String = game.reward_weapon_id
	if not check(game.Weapons.available(game.hero, "").has(offered), "Treasure did not promise a compatible weapon"):
		return
	game.player = game.chest_position
	game.interact()
	game._physics_process(0.6)
	game.resume_run()
	if not check(game.screen == "reward" and game.reward_weapon_id == offered, "The weapon offer changed on resume"):
		return
	game.tap(game.View.Reward.RELIC_RECT.get_center())
	game.resume_run()
	if not check(game.armory.for_hero(game.hero) == offered and game.room_complete and game.codex.knows_weapon(offered),
			"Equipping the weapon failed to commit the room and discovery"):
		return
	if not check(game.starting_weapon_options().has(offered) and not game.equip_weapon("pocket_thunder"),
			"Preparation did not expose the discovery or accepted another class’s weapon"):
		return

	game.hero = 4
	game.armory.reset(game.hero, "clockface_shank")
	game.player = Vector2(420, 230)
	game.facing = Vector2.RIGHT
	game.barrels.clear()
	game.armory.basic_sequence = 3
	game.armory.begin_attack(game, "clockface_shank")
	var snapshot: Dictionary = game.armory.snapshot()
	game.armory.restore(game.hero, snapshot)
	var target := {"x": 455.0, "y": 230.0, "phase": 0, "clock": 0.3, "hp": 30, "max": 30, "boss": false, "kind": 0}
	game.foes = [target]
	game.armory.tick(game, 0.35)
	if not check(target.hp == 23 and game.armory.echo.is_empty(), "The saved echo did not cause exactly one weaker swing"):
		return
	game.armory.tick(game, 0.35)
	if not check(target.hp == 23, "A resolved echo hit twice"):
		return

	game.relics.equip(game.Relics.HONEST_RECEIPT)
	game.relics.record_sale("market_1", 4, true)
	var relics: Dictionary = game.relics.snapshot()
	game.relics.reset()
	game.relics.restore(relics)
	if not check(game.relics.receipt_credit("market_1") == 0 and game.relics.receipt_credit("market_2") == 5
			and game.relics.rose_counter_ready(6) and not game.relics.rose_counter_ready(7),
			"Receipt credit or Rose Receipt expiration did not survive restoration"):
		return
	game.relics.record_sale("market_2", 7, true)
	game.relics.spend_rose_counter()
	if not check(game.relics.receipt_credit("market_2") == 0 and not game.relics.rose_counter_ready(7),
			"Receipt credit or a spent counter persisted beyond its single use"):
		return
	print("PASS: saved treasure comparison, weapon equip/discovery, queued fourth-swing echo, and receipt state.")
	quit()
