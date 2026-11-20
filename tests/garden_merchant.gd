extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func open_room(game, kind: String) -> bool:
	game.floor_index = 2
	for seed_value in range(100):
		game.run_seed = seed_value
		game.load_floor()
		for node: Dictionary in game.floor_manifest.nodes.values():
			if node.kind == kind:
				game.room_id = node.id
				game.enter_room()
				game.player = game.chest_position
				game.interact()
				return game.screen == "room_choice"
	return false

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	if not check(open_room(game, "shop"), "A seeded merchant did not open through the in-world prop"):
		return
	var view = game.RouteView.ShopView
	var merchant = game.merchant
	var orig_stock: Array[Dictionary] = merchant.stock(game)
	if not check(orig_stock.size() >= 5 and orig_stock[2].id != orig_stock[3].id
			and game.Weapons.DEFINITIONS.has(orig_stock[4].id),
			"The shop did not offer two distinct pocket items and a compatible weapon"):
		return
	game.tap(view.stock_rect(1).get_center())
	if not check(game.bonus == 0 and game.petals == 0, "Unaffordable stock was sold"):
		return
	game.petals = 90
	game.hp -= 28
	var hp: int = game.hp
	game.tap(view.stock_rect(0).get_center())
	game.resume_run()
	game.tap(view.stock_rect(0).get_center())
	if not check(game.hp == hp + game.RunEconomy.SHOP_HEAL and game.petals == 90 - game.RunEconomy.SHOP_TEA_PRICE and game.screen == "room_choice",
			"Tea transaction was replayed or closed the merchant"):
		return
	game.tap(view.stock_rect(1).get_center())
	var stock: Array[Dictionary] = merchant.stock(game)
	var last_item: String = stock[3].id
	var cost: int = merchant.reroll_price(game)
	game.tap(view.REFRESH.get_center())
	game.resume_run()
	game.tap(view.REFRESH.get_center())
	stock = merchant.stock(game)
	if not check(game.petals == 90 - game.RunEconomy.SHOP_TEA_PRICE - 22 - cost and game.bonus == 2 and stock[1].blocked == "Sold"
			and stock[2].id == last_item and stock[3].id != orig_stock[2].id and stock[3].id != last_item,
			"The saved refresh duplicated payment, missed new stock, or restored sold inventory"):
		return
	var packed: String = stock[3].id
	game.tap(view.stock_rect(3).get_center())
	game.resume_run()
	var balance: int = game.petals
	game.tap(view.stock_rect(2).get_center())
	if not check(game.pocket.held == packed and game.petals == balance and merchant.stock(game)[2].blocked != "",
			"Purchasing with a full pocket caused a duplicate charge"):
		return
	game.tap(view.LEAVE.get_center())
	game.resume_run()
	if not check(game.room_complete and game.screen == "fight", "Leaving the shop failed to unlock its route"):
		return

	if not check(open_room(game, "rest") and merchant.rerolls == 0, "Merchant stock leaked to the next room"):
		return
	game.hp = 69
	game.tap(game.RouteView.SECOND_ACTION.get_center())
	game.resume_run()
	game.tap(game.RouteView.FIRST_ACTION.get_center())
	if not check(game.room_complete and game.hp == 69 and game.bonus == 3,
			"Honing did not grant an exclusive saved rest reward"):
		return
	print("PASS: seeded merchant stock, multiple independent purchases, saved reroll, pocket constraints, and rest honing.")
	quit()
