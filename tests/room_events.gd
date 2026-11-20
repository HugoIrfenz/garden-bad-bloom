extends SceneTree

const Events = preload("res://scripts/room_events.gd")
const Relics = preload("res://scripts/relic_effects.gd")
const Dungeon = preload("res://scripts/dungeon_generation.gd")
const RunItems = preload("res://scripts/run_items.gd")
const RunCurses = preload("res://scripts/run_curses.gd")

class EncounterRoom:
	const HEALTH = [125]
	const RESOURCES = ["Resolve"]
	const HUNT_TIME = 20.0
	var hero = 0
	var active_biome = 0
	var hp = 55
	var petals = 40
	var bonus = 1
	var resource = 3
	var screen = "room_choice"
	var room_kind = "event"
	var room_complete = false
	var relics = Relics.new()
	var pocket = RunItems.new()
	var curses = RunCurses.new()
	var run_seed = 0
	var floor_index = 0
	var room_id = ""
	var floor_manifest: Dictionary = {}

	func open_arcade_round(_game_id: String) -> void:
		screen = "minigame"

	func healing_amount(amount: int, source := "standard") -> int:
		return clampi(amount, 0, HEALTH[hero] - hp) if curses.healing_block(source).is_empty() else 0

var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	test_all_choices()
	test_disabled_choices()
	test_seeded_routes(0, "sleeping_root")
	test_seeded_routes(1, "cap_inspection")
	test_seeded_routes(2, "wrong_bell")
	test_seeded_routes(3, "quiet_fox")
	if failures.is_empty():
		print("PASS: authored events, four seeded biome pools, pocket and relic exchanges, and resumable timed, secret, and elite fights.")
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func test_all_choices() -> void:
	var authored_ids = {}
	for biome in range(7):
		var card = Events.card(biome)
		expect(not authored_ids.has(card.id), "A biome reused the same authored event as another biome.")
		authored_ids[card.id] = true
		test_card_choices(biome, card)
	for biome: int in Events.EVENT_POOLS:
		for variant in Events.EVENT_POOLS[biome].alternatives:
			expect(not authored_ids.has(variant.id), "An alternate event reused an authored ID.")
			authored_ids[variant.id] = true
			test_card_choices(biome, variant)

func test_card_choices(biome: int, card: Dictionary) -> void:
	for index in range(card.actions.size()):
		var room = event_fixture(biome, card.id)
		if card.actions[index].get("spend_item", false):
			room.pocket.take("clockwise_tonic")
			room.pocket.haste = 2.0
		var result = Events.preview(room, index)
		expect(result.available, "Fixture could not take %s" % result.title)
		expect(not result.summary.is_empty(), "Missing preview for %s" % result.title)
		if not result.encounter.is_empty():
			expect(result.summary.begins_with(Events.ENCOUNTER_PREVIEWS[result.encounter]), "The action did not disclose the fight type and loot.")
			expect(not result.hunt or result.summary.ends_with("20s for bonus Petals"), "The hunt did not disclose its bonus window.")
			continue # The live path exercises rebuilding the room and restoring the fight.
		expect(Events.apply(room, index), "Could not apply %s" % result.title)
		expect(room.hp == result.hp and room.petals == result.petals
			and room.resource == result.resource and room.bonus == result.bonus,
			"Actual changes did not match preview for %s" % result.title)
		expect(result.relic.is_empty() or room.relics.has_relic(result.relic),
			"Event relic was unavailable in the live registry.")
		expect(result.item.is_empty() or room.pocket.held == result.item, "Could not equip the advertised pocket item.")
		expect(result.spent_item.is_empty() or (room.pocket.held.is_empty() and room.pocket.haste == 2.0),
			"The offering did not consume the held item and preserve the active tonic.")
		room.room_complete = true
		expect(not Events.apply(room, index), "A completed event could repeat.")

func test_disabled_choices() -> void:
	var room = EncounterRoom.new()
	room.active_biome = 0
	room.petals = 5
	expect(Events.preview(room, 0).reason == "Requires 10 Petals" and not Events.apply(room, 0) and room.petals == 5,
		"An unaffordable compliment mutated the purse.")
	room.active_biome = 3
	room.hp = 14
	expect(Events.preview(room, 0).reason == "Requires at least 15 HP" and not Events.apply(room, 0) and room.hp == 14,
		"A lethal trade was offered or consumed HP.")
	room.active_biome = 2
	room.petals = 40
	room.relics.equip(Relics.GLASS_EYELASH)
	expect(not Events.preview(room, 0).available and not Events.apply(room, 0) and room.petals == 40,
		"Duplicate relic took payment.")
	room.active_biome = 4
	room.hp = 121
	var heal = Events.preview(room, 0)
	expect(heal.hp == 125 and heal.summary == "+4 HP", "Heal preview did not expose its actual capped value.")
	room.hp = 125
	expect(not Events.preview(room, 0).available, "The healing choice activated at full HP.")
	room.active_biome = 5
	room.resource = 4
	var refuel = Events.preview(room, 0)
	expect(refuel.resource == 5 and refuel.summary == "−8 HP  ·  +1 Resolve",
		"The Moon Fountain did not preview its exact remaining resource gain.")
	var repair := event_fixture(2, "clock_repair")
	repair.pocket.take("petal_bomb")
	var repair_offer := Events.preview(repair, 0)
	expect(not repair_offer.available and repair_offer.reason == "Pocket already holds Petal Bomb"
		and not Events.apply(repair, 0) and repair.petals == 40 and repair.pocket.held == "petal_bomb",
		"The repair offered to overwrite a held item or charged for an unavailable tonic.")
	var audition := event_fixture(2, "copper_choir_audition")
	audition.resource = 1
	var audition_offer := Events.preview(audition, 0)
	expect(not audition_offer.available and audition_offer.reason == "Requires 2 Resolve"
		and not Events.apply(audition, 0) and audition.resource == 1 and audition.relics.owned.is_empty(),
		"The audition granted the relic or drained charge when the player could not pay.")
	var flower := event_fixture(3, "weeping_flower")
	var offering := Events.preview(flower, 0)
	expect(not offering.available and offering.reason == "Requires an item in your pocket"
		and not Events.apply(flower, 0) and flower.hp == 55, "The flower accepted an empty offering.")
	flower.pocket.take("royal_teacup")
	flower.hp = 122
	offering = Events.preview(flower, 0)
	expect(offering.available and offering.summary == "+3 HP  ·  Give up Royal Teacup",
		"The flower did not identify the item and exact HP gain.")
	flower.hp = 125
	expect(not Events.apply(flower, 0) and flower.pocket.held == "royal_teacup",
		"The flower consumed a pocket item when it could not restore HP.")

func event_fixture(biome: int, card_id: String) -> EncounterRoom:
	var room := EncounterRoom.new()
	room.active_biome = biome
	room.room_id = "fixture"
	var pool: Dictionary = Events.EVENT_POOLS.get(biome, {})
	room.floor_manifest = {"nodes": {"fixture": {pool.get("key", "test_event_id"): card_id}}}
	return room

func test_seeded_routes(biome: int, legacy_fixture: String) -> void:
	var found = find_events(biome)
	expect(found.size() == Events.EVENT_POOLS[biome].alternatives.size() + 1,
		"Some cards could not generate for biome %d." % biome)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for event_id: String in found:
		var route = found[event_id]
		if not walk_to_event(game, biome, route):
			return
		expect(Events.card_for(game).id == event_id, "The live room didn't bind the chosen event.")
		var peek = Events.preview(game, 0)
		game.resume_run()
		expect(Events.card_for(game).id == event_id and Events.preview(game, 0) == peek,
			"The selection or effects changed after resume.")
		if not peek.encounter.is_empty():
			verify_encounter(game, biome, route, peek.encounter)
			continue
		if not peek.minigame.is_empty():
			game.tap(game.RouteView.FIRST_ACTION.get_center())
			expect(game.screen == "minigame" and game.arcade.id == peek.minigame and game.petals == peek.petals,
				"The event did not start its promised minigame or charge its stake.")
			game.arcade.round.state = "loss"
			game.arcade.sync_outcome(game)
			game.arcade.settle(game)
			game.resume_run()
			expect(game.room_complete and not Events.apply(game, 0), "A finished minigame event did not persist.")
			continue
		game.tap(game.RouteView.FIRST_ACTION.get_center())
		expect(game.room_complete and game.hp == peek.hp and game.petals == peek.petals
			and game.resource == peek.resource and game.bonus == peek.bonus,
			"The live event did not commit exactly its preview.")
		game.resume_run()
		expect(game.room_complete and not Events.apply(game, 0), "A resumed completed room allowed a second event choice.")
		expect(peek.item.is_empty() or game.pocket.held == peek.item, "The event pocket item did not survive a checkpoint.")
		expect(peek.relic.is_empty() or game.relics.has_relic(peek.relic), "The event relic did not survive a checkpoint.")
		expect(peek.spent_item.is_empty() or game.pocket.held.is_empty(), "Reloading restored a spent offering.")

	if not found.has(legacy_fixture) or not walk_to_event(game, biome, found[legacy_fixture]):
		return
	var legacy = game.RunProfile.read_json(game.SAVE)
	legacy.floor_manifest.nodes[game.room_id].erase(Events.EVENT_POOLS[biome].key)
	game.RunProfile.write_json(game.SAVE, legacy)
	game.resume_run()
	expect(game.screen == "room_choice" and Events.card_for(game).id == Events.card(biome).id,
		"An already open, pre-variant event did not keep its original card.")
	game.free()

func verify_encounter(game, biome: int, route: Dictionary, kind: String) -> void:
	var visits: Array[String] = game.route_history.duplicate()
	var initial_petals := int(game.petals)
	game.tap(game.RouteView.FIRST_ACTION.get_center())
	expect(game.screen == "fight" and game.room_kind == kind and not game.room_complete
		and not game.foes.is_empty() and game.room_clock == 0.0 and game.room_id == route.room
		and game.route_history == visits, "The %s did not begin in the same route node exactly once." % kind)
	var stage: Dictionary = game.RunProfile.read_json(game.SAVE)
	game.resume_run()
	expect(game.screen == "fight" and game.room_kind == kind and not game.room_complete
		and game.foes.size() == stage.get("foes", []).size() and not game.foes.is_empty()
		and game.route_history == visits and not Events.apply(game, 0), "The %s did not resume at the combat stage." % kind)
	var expected_petals: int = initial_petals + game.RunEconomy.room_petals(kind, game.floor_index, true)
	finish_encounter(game, game.HUNT_TIME - 1.0)
	expect(game.pending_chest and game.petals == expected_petals,
		"Clearing the %s did not award the advertised chest and bonus Petals." % kind)
	game.resume_run()
	expect(game.pending_chest and game.petals == expected_petals,
		"Reloading the cleared %s lost or repeated the reward." % kind)
	if kind == "challenge":
		game.RunProfile.write_json(game.SAVE, stage)
		game.resume_run()
		finish_encounter(game, game.HUNT_TIME + 1.0)
		expect(game.pending_chest and game.petals == initial_petals + game.RunEconomy.room_petals(kind, game.floor_index, false),
			"Clearing after the hunt deadline did not preserve the ordinary chest reward.")
	if walk_to_event(game, biome, route):
		var alternate := Events.preview(game, 1)
		game.tap(game.RouteView.SECOND_ACTION.get_center())
		game.resume_run()
		expect(game.room_complete and game.room_kind == "event" and game.foes.is_empty()
			and game.hp == alternate.hp and game.petals == alternate.petals and game.resource == alternate.resource
			and game.pocket.held == alternate.item and not Events.apply(game, 1),
			"The safe option started a fight or failed to persist the reward.")

func finish_encounter(game, time: float) -> void:
	game.room_clock = time
	game.room_arrival = 0.0
	game.foes.clear()
	game._physics_process(0.016)

func find_events(biome: int) -> Dictionary:
	var found := {}
	var expected_count: int = Events.EVENT_POOLS[biome].alternatives.size() + 1
	var fixture = EncounterRoom.new()
	fixture.active_biome = biome
	fixture.floor_index = biome
	for seed_value in range(1, 120):
		fixture.run_seed = seed_value
		fixture.floor_manifest = Dungeon.generate_floor(seed_value, fixture.floor_index)
		for room_id: String in fixture.floor_manifest.nodes:
			if fixture.floor_manifest.nodes[room_id].kind != "event":
				continue
			fixture.room_id = room_id
			Events.bind_card(fixture)
			var event_id: String = Events.card_for(fixture).id
			if not found.has(event_id):
				found[event_id] = {"seed": seed_value, "room": room_id}
		if found.size() == expected_count:
			break
	return found

func walk_to_event(game, biome: int, route: Dictionary) -> bool:
	game.start_run()
	game.run_seed = route.seed
	game.floor_index = biome
	game.load_floor()
	game.enter_room()
	var path = path_to(game.floor_manifest.nodes, game.room_id, route.room)
	if path.is_empty():
		expect(false, "An authored event was not reachable from the entrance.")
		return false
	for room_id: String in path:
		game.complete_room()
		game.player = game.room_exits[room_id]
		game.interact()
		if game.room_id != room_id:
			expect(false, "Normal door interaction did not enter the seeded event route.")
			return false
	game.hp = 55
	game.petals = 40
	game.resource = 3
	game.bonus = 1
	if Events.card_for(game).id == "weeping_flower":
		game.pocket.take("clockwise_tonic")
	game.player = game.chest_position
	game.interact()
	expect(game.screen == "room_choice", "Normal room interaction did not open the event.")
	return game.screen == "room_choice"

func path_to(nodes: Dictionary, start: String, target: String) -> Array[String]:
	for exit_id: String in nodes[start].exits:
		var path: Array[String] = [exit_id]
		if exit_id == target:
			return path
		var remaining = path_to(nodes, exit_id, target)
		if not remaining.is_empty():
			path.append_array(remaining)
			return path
	return []
