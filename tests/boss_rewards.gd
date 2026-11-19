extends SceneTree

var issues := PackedStringArray()

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	if not condition:
		issues.append(message)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.selected_relic = game.Relics.WEDDING_RING
	game.start_run()
	game.run_seed = 124377
	defeat_boss(game, 0)
	var first_offer: String = game.reward_relic_id
	expect(game.screen == "fight" and game.pending_chest and not first_offer.is_empty()
		and first_offer != game.Relics.WEDDING_RING, "Boss chest offered no relic or a relic already equipped.")
	expect(game.boss_relic_offer() == first_offer, "The boss offer was not deterministic.")

	var previous_format = game.RunProfile.read_json(game.SAVE)
	previous_format.erase("reward_relic_id")
	game.RunProfile.write_json(game.SAVE, previous_format)
	game.resume_run()
	expect(game.reward_relic_id == first_offer, "A pre-offer save did not restore the same deterministic relic.")
	game.player = game.chest_position
	game.open_chest()
	game.resume_run()
	game._physics_process(0.5)
	game.resume_run()
	expect(game.screen == "reward" and game.reward_relic_id == first_offer, "The relic rerolled in the open reward screen.")
	game.tap(game.View.Reward.RELIC_RECT.get_center())
	expect(game.View.Reward.relic_preview_open(game) and not game.relics.has_relic(first_offer),
		"Inspecting the boss relic consumed the reward before confirmation.")
	game.tap(game.View.Reward.RELIC_BACK.get_center())
	expect(not game.View.Reward.relic_preview_open(game) and game.reward_relic_id == first_offer,
		"Backing out of inspection changed the boss offer.")
	game.tap(game.View.Reward.RELIC_RECT.get_center())
	game.tap(game.View.Reward.RELIC_EQUIP.get_center())
	game.resume_run()
	expect(game.screen == "fight" and game.room_complete and game.reward_relic_id.is_empty()
		and game.relics.has_relic(first_offer) and game.relics.owned.size() == 2,
		"Taking a relic did not persist ownership and unlock travel.")
	game.tap(game.View.Reward.RELIC_RECT.get_center())
	expect(game.relics.owned.size() == 2, "An already claimed reward could be applied again.")

	defeat_boss(game, 1)
	var last_offer: String = game.reward_relic_id
	expect(not last_offer.is_empty() and not game.relics.has_relic(last_offer), "The next boss offered a duplicate relic.")
	game.relics.equip(last_offer)
	for relic_id in [game.Relics.WEDDING_RING, game.Relics.GLASS_EYELASH,
			game.Relics.LAST_TEASPOON, game.Relics.THORNMAIL, game.Relics.COUNTERCLOCK_LOCKET,
			game.Relics.HONEST_RECEIPT, game.Relics.GUARDIANS_LEDGER]:
		game.relics.equip(relic_id)
	defeat_boss(game, 2)
	expect(game.pending_chest and game.reward_relic_id.is_empty(), "Owning all eligible relics did not fall back to the two base cards.")
	defeat_boss(game, 6)
	expect(game.screen == "clear" and game.reward_relic_id.is_empty(), "The capstone was incorrectly routed into the relic screen.")

	if issues.is_empty():
		print("PASS: seeded boss relics, owned exclusions, old saves, chest/loot replay, persisted ownership, and capstone routing.")
	else:
		for issue in issues:
			push_error(issue)
	quit(0 if issues.is_empty() else 1)

func defeat_boss(game, floor: int) -> void:
	game.floor_index = floor
	game.load_floor()
	game.room_id = game.floor_manifest.boss_id
	game.enter_room()
	for foe in game.foes:
		foe.hp = 0
	game._physics_process(0.016)
