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
	if not test_wedding_ring(game) or not test_piercing_shot(game) or not test_piercing_slash(game) or not test_teaspoon(game):
		return
	game.selected_relic = game.Relics.WEDDING_RING
	game.start_run(true)
	if not require(game.relics.owned.is_empty(), "An older run was given an unselected relic"):
		return
	print("PASS: preparation relic, actual dash contact, piercing bolts and slashes, wide cone, floor protection, saves, and clean legacy starts.")
	quit()

func start_with(game, relic_id: String, hero: int) -> void:
	game.hero = hero
	game.selected_relic = relic_id
	game.start_run()
	game.take_exit(game.room_exits.keys()[0])
	game.barrels.clear()
	game.foes.clear()
	game.bolts.clear()
	game.player = Vector2(140, 140)
	game.facing = Vector2.RIGHT
	game.attack_time = 0.0
	game.dodge_time = 0.0
	game.mercy = 0.0

func test_wedding_ring(game) -> bool:
	start_with(game, game.Relics.WEDDING_RING, 0)
	game.hp = 12
	game.damage_hero(12)
	game.checkpoint()
	game.resume_run()
	if not require(game.hp == 1 and game.mercy >= game.Relics.RING_GRACE - 0.001
			and not game.relics.ring_available(0), "Wedding Ring did not persist its charge and grace after lethal damage"):
		return false
	game.damage_hero(3)
	if not require(game.hp == 1, "Wedding Ring grace did not block the next hit"):
		return false
	game.mercy = 0.0
	game.damage_hero(3)
	if not require(game.hp <= 0, "Wedding Ring fired twice on one floor"):
		return false
	game.next_floor()
	game.hp = 3
	game.mercy = 0.0
	game.damage_hero(10)
	return require(game.hp == 1, "Wedding Ring did not recharge on the next floor")

func avoid_real_bolt(game) -> bool:
	game.act("dodge")
	if not require(not game.relics.pierce_armed, "Dodge without a hazard granted Glass Eyelash early"):
		return false
	var origin: Vector2 = game.player - Vector2(5, 0)
	game.bolts.append({"x": origin.x, "y": origin.y, "dx": 1.0, "dy": 0.0, "life": 1.0, "damage": 9})
	var hp: int = game.hp
	game.update_bolts(0.016)
	return require(game.relics.pierce_armed and game.hp == hp and game.bolts.is_empty(),
		"An actual dash contact did not grant Glass Eyelash or applied damage")

func test_piercing_shot(game) -> bool:
	# Vivianne's former dodge is now Frost, so use Virelia's ranged dodge kit.
	start_with(game, game.Relics.GLASS_EYELASH, 3)
	if not avoid_real_bolt(game):
		return false
	game.foes.append(actor(Vector2(278, 140)))
	game.foes.append(actor(Vector2(230, 140)))
	game.foes.append(actor(Vector2(178, 140)))
	game.act("attack")
	game.update_bolts(0.12)
	if not require(game.foes[2].hp < 60 and game.foes[1].hp == 60 and game.bolts.size() == 1
			and not game.relics.pierce_armed, "Piercing bolt did not hit the first foe and keep traveling"):
		return false
	var initial_damage: int = game.foes[2].hp
	game.checkpoint()
	game.resume_run()
	game.barrels.clear()
	game.update_bolts(0.12)
	return require(game.foes[2].hp == initial_damage and game.foes[1].hp < 60
		and game.foes[0].hp == 60 and game.bolts.is_empty(), "Saved projectile did not preserve its first contact and one extra pierce")

func test_piercing_slash(game) -> bool:
	start_with(game, game.Relics.GLASS_EYELASH, 0)
	if not avoid_real_bolt(game):
		return false
	game.foes.append(actor(Vector2(176, 140)))
	game.foes.append(actor(Vector2(226, 140)))
	game.foes.append(actor(Vector2(226, 172)))
	game.act("attack")
	return require(game.foes[0].hp < 60 and game.foes[1].hp < 60 and game.foes[2].hp == 60,
		"Piercing slash did not extend through just one additional foe in line")

func test_teaspoon(game) -> bool:
	start_with(game, game.Relics.LAST_TEASPOON, 0)
	game.hp = 1
	game.foes.append(actor(Vector2(176, 140)))
	game.foes.append(actor(Vector2(126, 186)))
	game.act("attack")
	var side_health: int = game.foes[1].hp
	game.checkpoint()
	game.resume_run()
	game.barrels.clear()
	game.attack_time = 0.0
	game.act("attack")
	return require(side_health < 60 and game.foes[1].hp == side_health and game.relics.teaspoon_spent,
		"Last Teaspoon widens one attack and stays spent after resume")

func actor(position: Vector2) -> Dictionary:
	return {"x": position.x, "y": position.y, "hp": 60, "max": 60, "kind": 0,
		"phase": 0, "clock": 0.8, "boss": false}
