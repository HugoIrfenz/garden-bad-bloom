extends SceneTree

const Dungeon = preload("res://scripts/dungeon_generation.gd")
const Curses = preload("res://scripts/run_curses.gd")
const Abilities = preload("res://scripts/hero_abilities.gd")

var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("verify")

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	test_altar(game)
	test_damage_and_healing(game)
	test_shop_and_rest(game)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: deterministic altar vows, legacy bargains, saved effects, source-aware healing, direct hits, and merchant charges.")
	quit(0 if failures.is_empty() else 1)

func test_altar(game) -> void:
	game.start_run()
	if not open_room(game, "curse"):
		return
	var offers: Array[Dictionary] = game.curses.offers(game)
	expect(offers.size() == 2 and offers[0].id != offers[1].id, "The altar did not seed two distinct choices.")
	if offers.size() != 2:
		return
	var saved: Dictionary = game.RunProfile.read_json(game.SAVE)
	game.resume_run()
	expect(game.curses.offers(game) == offers, "Reloading the altar changed the displayed bargains.")
	game.tap(game.RouteView.FIRST_ACTION.get_center())
	game.tap(game.RouteView.SECOND_ACTION.get_center())
	game.resume_run()
	expect(game.room_complete and game.curses.active == [offers[0].id], "The altar allowed two vows or lost the accepted curse.")
	var node: Dictionary = saved.floor_manifest.nodes[saved.room_id]
	node.erase(Curses.ALTAR_KEY)
	saved.erase("curses")
	saved.hp = 60
	saved.bonus = 1
	game.RunProfile.write_json(game.SAVE, saved)
	game.resume_run()
	var legacy: Array[Dictionary] = game.curses.offers(game)
	expect(legacy.size() == 1 and legacy[0].title == "Blood Price", "An old open altar did not preserve Blood Price.")
	game.tap(game.RouteView.FIRST_ACTION.get_center())
	expect(game.room_complete and game.hp == 42 and game.bonus == 4 and game.curses.active.is_empty(),
		"Blood Price did not apply its original cost and reward.")

func test_damage_and_healing(game) -> void:
	game.start_run(true)
	game.hp = 80
	game.curses.restore([Curses.LILY, Curses.LILY, "unknown"])
	expect(game.curses.active == [Curses.LILY], "Restoring curses accepted duplicate or unknown IDs.")
	for source in ["rest", "event", "shop", "reward", "standard"]:
		expect(game.healing_amount(20, source) == 0, "Cursed Lily left %s healing open." % source)
	expect(game.healing_amount(20, "shrine") == 20, "Cursed Lily blocked the exceptional shrine source.")
	if not game.foes.is_empty():
		var direct: Dictionary = game.foes[0].duplicate(true)
		var environment: Dictionary = direct.duplicate(true)
		var initial := int(direct.hp)
		Abilities.hero_hit(game, direct, 9)
		Abilities.damage_foe(game, environment, 9)
		expect(int(direct.hp) == initial - 18 and int(environment.hp) == initial - 9,
			"Cursed Lily did not scale hero hits separately from neutral damage.")
	game.curses.restore([Curses.DEBT])
	game.hp = 44
	expect(game.player_hit_amount(20) == 20, "Red Moon Debt activated above 35% HP.")
	game.hp = 43
	expect(game.player_hit_amount(20) == 28, "Red Moon Debt did not grant the low-HP hit bonus.")
	game.start_run(true)
	expect(game.curses.active.is_empty(), "A fresh run inherited a prior curse.")

func test_shop_and_rest(game) -> void:
	game.start_run()
	game.curses.restore([Curses.DEBT, Curses.CUP])
	if not open_room(game, "shop"):
		return
	game.hp = 80
	game.petals = 100
	var offers: Array[Dictionary] = game.merchant.stock(game)
	var tea: Dictionary = offers[0]
	expect(tea.price == 14 and offers[1].price == 18 and game.merchant.reroll_price(game) == 6,
		"Shop quotes did not combine the healing debt and stock discount.")
	expect(game.merchant.buy(game, 0) and game.hp == 100 and game.petals == 100 - int(tea.price),
		"Purchasing Dew Tea used a different price or heal than shown.")
	game.resume_run()
	expect(game.petals == 86 and game.curses.active == [Curses.DEBT, Curses.CUP], "Shop checkpoint lost the purchase or curses.")
	if not open_room(game, "rest"):
		return
	game.hp = 80
	var bonus := int(game.bonus)
	game.tap(game.RouteView.FIRST_ACTION.get_center())
	expect(game.hp == 80 and not game.room_complete, "No Second Cup allowed routine rest healing.")
	game.tap(game.RouteView.SECOND_ACTION.get_center())
	expect(game.room_complete and game.bonus == bonus + 1, "No Second Cup blocked the weapon-honing exit option.")

func open_room(game, kind: String) -> bool:
	for seed in range(1, 80):
		var manifest := Dungeon.generate_floor(seed, 0)
		for id: String in manifest.nodes:
			if manifest.nodes[id].kind != kind:
				continue
			game.run_seed = seed
			game.floor_index = 0
			game.floor_manifest = manifest
			game.room_id = id
			game.enter_room()
			game.player = game.chest_position
			game.interact()
			return game.screen == "room_choice"
	expect(false, "Could not seed a %s room." % kind)
	return false
