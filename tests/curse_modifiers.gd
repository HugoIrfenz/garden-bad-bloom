extends SceneTree

const Curses = preload("res://scripts/run_curses.gd")
var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.hero = 0
	game.start_run(true)
	var base_attack: float = game.basic_attack_interval()
	var base_dodge: float = game.dodge_cooldown()
	game.curses.restore([Curses.QUICKTHORN])
	check(is_equal_approx(game.basic_attack_interval(), base_attack * 0.8), "Quickthorn did not shorten the attack interval.")
	game.hp = 100
	game.mercy = 0.0
	game.damage_hero(20)
	check(game.hp == 77, "Quickthorn did not increase incoming damage.")
	game.curses.restore([Curses.HEAVY_BLOOM])
	check(game.player_hit_amount(20) == 24 and is_equal_approx(game.curses.movement_factor(), 0.85), "Heavy Bloom's damage and movement factors are incorrect.")
	game.curses.restore([Curses.WILD_ROOTS])
	check(is_equal_approx(game.curses.movement_factor(), 1.15) and is_equal_approx(game.dodge_cooldown(), base_dodge * 1.3), "Wild Roots did not change movement and dodge recovery.")
	game.curses.restore([Curses.GOLDEN_BARGAIN])
	check(game.curses.room_reward(8) == 12 and game.shop_price(20) == 25, "Golden Bargain did not change room rewards and shop prices.")
	game.curses.restore([Curses.FRAGILE_GRACE])
	game.hp = 50
	check(is_equal_approx(game.dodge_cooldown(), base_dodge * 0.8) and game.healing_amount(20) == 15, "Fragile Grace did not change dodge recovery and healing.")
	game.curses.restore([Curses.WILD_ROOTS, Curses.FRAGILE_GRACE, Curses.CUP, Curses.GOLDEN_BARGAIN])
	check(is_equal_approx(game.dodge_cooldown(), base_dodge * 1.3 * 0.8) and game.shop_price(20) == 20, "Compatible curse modifiers did not stack multiplicatively.")
	game.curses.restore([Curses.LILY, Curses.FRAGILE_GRACE])
	check(game.healing_amount(20) == 0 and game.healing_amount(20, "shrine") == 15, "Fragile Grace conflicted with Cursed Lily's healing rules.")
	var added := [Curses.QUICKTHORN, Curses.HEAVY_BLOOM, Curses.WILD_ROOTS, Curses.GOLDEN_BARGAIN, Curses.FRAGILE_GRACE]
	game.curses.restore(added)
	game.checkpoint()
	game.curses.restore()
	game.resume_run()
	check(game.curses.active == added, "The five new curses did not survive a checkpoint.")
	for id: String in added:
		check(id in Curses.IDS and Curses.CATALOG.has(id) and game.curses.offer_block(id) != "", "A new curse is missing or can be offered twice.")
	game.curses.restore()
	game.room_kind = "curse"
	game.screen = "garden"
	game.room_id = "fixture"
	game.floor_index = 0
	var seen: Array[String] = []
	for seed in range(1, 100):
		game.run_seed = seed
		game.floor_manifest = {"nodes": {"fixture": {"kind": "curse"}}}
		game.curses.bind_altar(game)
		var offered: Array[Dictionary] = game.curses.offers(game)
		check(offered.size() == 2 and offered[0].id != offered[1].id, "The altar did not offer two distinct curses.")
		for card: Dictionary in offered:
			if card.id not in seen:
				seen.append(card.id)
	for id: String in added:
		check(id in seen, "A new curse could not appear at an altar.")
	if failures.is_empty():
		print("PASS: five curse tradeoffs, stacking, damage, healing and save recovery.")
	else:
		for failure in failures:
			push_error(failure)
	quit(int(not failures.is_empty()))
