extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	var items = game.pocket
	var offered: String = items.offer(game)
	game.screen = "reward"
	game.pending_chest = true
	game.checkpoint()
	game.resume_run()
	if not require(game.RunItems.IDS.has(offered) and items.offer(game) == offered,
			"The seeded chest offer changed after resume"):
		return
	game.tap(game.View.Reward.RELIC_RECT.get_center())
	game.resume_run()
	if not require(game.room_complete and items.held == offered and items.offer(game).is_empty(),
			"Packing an item must atomically fill the pocket and finish the reward"):
		return

	items.restore("royal_teacup")
	game.resource = 3
	game.use_pocket()
	if not require(items.held == "royal_teacup", "The teacup was spent with no resource to recover"):
		return
	game.resource = 1
	game.tap(game.touch_position(game.POCKET))
	game.resume_run()
	if not require(items.held.is_empty() and game.resource == 3, "The pocket control did not restore and save resource"):
		return

	items.restore("clockwise_tonic")
	game.use_pocket()
	game.resume_run()
	var recovery: float = 0.9
	game.dodge_time = recovery
	game._physics_process(0.1)
	if not require(is_equal_approx(game.dodge_time, recovery - 0.14) and is_equal_approx(items.haste, 5.9),
			"Saved tonic did not accelerate the actual Dodge recovery"):
		return

	items.restore("petal_bomb")
	game.player = Vector2(400, 200)
	game.barrels.clear()
	game.use_pocket()
	if not require(items.held == "petal_bomb", "Bomb with no real target was spent"):
		return
	game.foes = [foe_at(Vector2(471, 200)), foe_at(Vector2(506, 233)), foe_at(Vector2(600, 272))]
	game.use_pocket()
	if not require(items.held.is_empty() and game.foes[0].hp == 12 and game.foes[1].hp == 12 and game.foes[2].hp == 50,
			"Bomb hit geometry ignored the assisted target or blast radius"):
		return
	game.start_run()
	if not require(items.held.is_empty() and items.haste == 0.0, "Pocket effects carried into a fresh run"):
		return
	print("PASS: deterministic pocket offer, single-slot transaction, resource, haste, and aimed bomb.")
	quit()

func foe_at(point: Vector2) -> Dictionary:
	return {"x": point.x, "y": point.y, "hp": 50, "max": 50, "boss": false, "kind": 0,
		"phase": 0, "clock": 1.0, "tx": point.x, "ty": point.y}
