extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.tap(game.View.CONTINUE.get_center())
	game.tap(game.View.DESCEND.get_center())
	game.tap(game.Prep.ENTER.get_center())
	if not require(game.floor_index == 0 and game.room_kind == "transition" and game.foes.is_empty(),
			"New run did not start in the graph entrance"):
		return
	# Lock the graph under test to a known seed, then exercise the normal travel and purchase paths.
	game.run_seed = 15304
	game.route_history.clear()
	game.load_floor()
	game.enter_room()
	var saved_seed: int = game.run_seed
	var visited_before: int = game.route_history.size()
	var picked_branch = false
	var seen = {}
	for step in range(140):
		if game.screen == "clear":
			break
		if not require(game.screen == "fight", "Expected room travel after a committed action"):
			return
		seen[game.room_kind] = true
		if not finish_room(game):
			return
		if game.screen == "clear":
			break
		var chosen = choose_exit(game, seen, picked_branch)
		if not require(not chosen.is_empty(), "Completed room has no exit"):
			return
		if game.room_exits.size() == 2:
			var exit_ids: Array = game.room_exits.keys()
			var map_points: Dictionary = game.RouteView.map_layout(game.floor_manifest)
			var node: Dictionary = game.floor_manifest.nodes[game.room_id]
			if not require(exit_ids == node.exits and map_points[exit_ids[0]].y != map_points[exit_ids[1]].y
					and game.room_exits[exit_ids[0]].x < game.room_exits[exit_ids[1]].x,
					"Two live doors must agree with distinct, ordered edges in the map"):
				return
		var next: Dictionary = game.floor_manifest.nodes.get(chosen, {})
		var expected_floor: int = game.floor_index
		var expected_id: String = chosen
		if next.is_empty():
			expected_floor += 1
		else:
			picked_branch = picked_branch or next.branch == 1
		game.player = game.room_exits[chosen] + Vector2(0, 11)
		game.stick = Vector2.UP
		game._physics_process(0.016)
		game.stick = Vector2.ZERO
		if game.screen == "talent":
			game.resume_run()
			if not require(game.screen == "talent" and game.talents.offer(game.hero).has("id"),
					"The first chapter talent choice did not resume"):
				return
			game.tap(game.TalentView.LEARN.get_center())
			if not require(game.talents.milestone_resolved(), "Choosing the chapter talent did not persist"):
				return
		if not require(game.floor_index == expected_floor and (next.is_empty() or game.room_id == expected_id),
				"Walking through the chosen doorway took a different path"):
			return
		var traversed_id: String = game.room_id
		game.resume_run()
		if not require(game.room_id == traversed_id and game.run_seed == saved_seed,
				"Resume changed the selected path"):
			return
	if not require(game.screen == "clear" and game.floor_index == 6 and picked_branch and game.route_history.size() > visited_before,
			"Could not route through the campaign to the capstone"):
		return
	for kind in ["shop", "rest", "event", "curse", "treasure"]:
		if not require(seen.has(kind), "Fixture did not exercise " + kind):
			return
	game.resume_run()
	game.tap(game.View.FIRST_OPTION.get_center())
	if not require(game.screen == "fight" and game.floor_index == 7 and game.floor_manifest.endless
			and game.room_kind == "transition", "Capstone did not open an Endless floor"):
		return
	print("PASS: live seeded travel, branch and resume, chest and room choices, seven campaign chapters and Endless.")
	quit()

func finish_room(game) -> bool:
	if game.room_complete:
		return true
	if game.uses_room_choice():
		game.hp = 70
		game.petals += 30
		var old_hp: int = game.hp
		var old_petals: int = game.petals
		var old_bonus: int = game.bonus
		var old_resource: int = game.resource
		game.player = game.chest_position
		game.interact()
		game.resume_run()
		if not require(game.screen == "room_choice", "Room choice did not persist"):
			return false
		var action: Rect2 = game.RouteView.ShopView.stock_rect(1) if game.room_kind == "shop" else game.RouteView.FIRST_ACTION
		var expected_event := {}
		var quote: int = game.merchant.stock(game)[1].price if game.room_kind == "shop" else 0
		var rest_heal: int = game.healing_amount(30, "rest") if game.room_kind == "rest" else 0
		var old_curses: Array[String] = game.curses.snapshot()
		var curse_id := ""
		if game.room_kind == "rest" and rest_heal == 0:
			action = game.RouteView.SECOND_ACTION
		if game.room_kind == "curse":
			var bargains: Array[Dictionary] = game.curses.offers(game)
			if bargains.is_empty():
				action = game.RouteView.LEAVE_ACTION
			else:
				curse_id = bargains[0].id
		if game.room_kind == "event":
			action = game.RouteView.LEAVE_ACTION
			for index in range(2):
				var preview: Dictionary = game.RoomEvents.preview(game, index)
				if not preview.is_empty() and preview.available:
					expected_event = preview
					action = game.RouteView.FIRST_ACTION if index == 0 else game.RouteView.SECOND_ACTION
					break
		game.tap(action.get_center())
		game.resume_run()
		game.tap(action.get_center())
		if game.room_kind in ["challenge", "secret", "elite"] and (expected_event.get("hunt", false) or not str(expected_event.get("encounter", "")).is_empty()):
			return finish_room(game)
		match game.room_kind:
			"shop":
				if not require(game.petals == old_petals - quote and game.bonus == old_bonus + 2, "Shop checkout was not atomic"):
					return false
				game.tap(game.RouteView.ShopView.LEAVE.get_center())
			"rest":
				var expected_bonus := old_bonus + (1 if rest_heal == 0 else 0)
				if not require(game.hp == old_hp + rest_heal and game.bonus == expected_bonus, "Rest did not apply the offered option"):
					return false
			"event":
				if not require(game.hp == expected_event.get("hp", old_hp)
						and game.petals == expected_event.get("petals", old_petals)
						and game.bonus == expected_event.get("bonus", old_bonus)
						and game.resource == expected_event.get("resource", old_resource),
						"Event did not apply the displayed effects exactly once"):
					return false
				var relic_id = expected_event.get("relic", "")
				if not relic_id.is_empty() and not require(game.relics.has_relic(relic_id), "Event relic was not persisted"):
					return false
			"curse":
				if not curse_id.is_empty():
					old_curses.append(curse_id)
				if not require(game.curses.active == old_curses and game.hp == old_hp and game.bonus == old_bonus,
						"The seeded altar did not persist exactly one bound curse"):
					return false
		return require(game.room_complete, "Room choice did not unlock the door")

	if not game.foes.is_empty():
		var exits: Array = game.room_exits.values()
		game.player = exits[0]
		if not require(not game.click_room_exit(exits[0]), "Combat door opened before the encounter ended"):
			return false
		for foe in game.foes:
			foe.hp = 0
		game._physics_process(0.016)
	if game.screen == "clear":
		return true
	if not require(game.pending_chest, "Fight or treasure room did not offer a reward"):
		return false
	var earlier_petals: int = game.petals
	game.player = game.chest_position
	game.interact()
	game.resume_run()
	game._physics_process(0.45)
	if not require(game.screen == "reward" and game.petals == earlier_petals, "Chest changed after resume"):
		return false
	game.tap(game.View.Reward.THORN_EDGE_RECT.get_center())
	game.resume_run()
	return require(game.room_complete and not game.pending_chest, "Reward selection did not unlock the doors")

func choose_exit(game, seen: Dictionary, picked_branch: bool) -> String:
	var selected = ""
	for exit_id: String in game.room_exits:
		if selected.is_empty():
			selected = exit_id
		var node: Dictionary = game.floor_manifest.nodes.get(exit_id, {})
		if node.is_empty():
			continue
		if not seen.has(node.kind) and node.kind in ["shop", "rest", "event", "curse", "treasure"]:
			return exit_id
		if not picked_branch and node.branch == 1:
			selected = exit_id
	return selected
