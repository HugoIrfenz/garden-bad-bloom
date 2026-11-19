extends SceneTree

const Rules = preload("res://scripts/endless_mutators.gd")
const Dungeon = preload("res://scripts/dungeon_generation.gd")

func _initialize() -> void:
	call_deferred("run")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func select_test() -> bool:
	var seen = {}
	var count = {}
	for seed_value in range(3, 28):
		for floor_index in range(7, 24):
			var first = Dungeon.generate_floor(seed_value, floor_index)
			var second = Dungeon.generate_floor(seed_value, floor_index)
			Rules.configure_floor(first, seed_value)
			Rules.configure_floor(second, seed_value)
			if not require(first.mutators == second.mutators and first.bounty_kind == second.bounty_kind,
					"Endless floor rule selection changed between identical seeds"):
				return false
			if not require(first.mutators.size() in [1, 2, 3], "Floor selected invalid mutator count"):
				return false
			if not require(first.biome == 2 or Rules.CLOCK not in first.mutators, "Fast Clock escaped Clockwork"):
				return false
			for a in range(first.mutators.size()):
				for b in range(a + 1, first.mutators.size()):
					if not require(Rules.compatible(first.mutators[a], first.mutators[b]), "Floor selected a disallowed pair"):
						return false
				seen[first.mutators[a]] = true
			count[first.mutators.size()] = true
	return require(seen.size() == Rules.RULES.size() and count.size() == 3, "All five rules and counts were not represented")

func force_floor(game, ids: Array[String]) -> void:
	game.start_run()
	game.run_seed = 21480
	game.floor_index = 11
	game.load_floor()
	game.floor_manifest.mutators = ids
	game.floor_manifest.bounty_kind = 0
	game.room_id = game.floor_manifest.nodes[game.floor_manifest.entrance_id].exits[0]
	game.enter_room()

func run() -> void:
	if not select_test():
		return
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var volatile_only: Array[String] = [Rules.VOLATILE]
	force_floor(game, volatile_only)
	for index in range(game.foes.size()):
		game.foes[index].x = 220.0 + index * 70.0
		game.foes[index].y = 200.0
		game.foes[index].hp = 0
	game._physics_process(0.016)
	if not require(game.endless.fuses.size() == Rules.MAX_FUSES and not game.pending_chest, "Volatile Corpses missed cap or did not hold rewards"):
		return
	var fuse: Dictionary = game.endless.fuses[0]
	var saved_time = float(fuse.remaining)
	game.checkpoint()
	game.endless.fuses.clear()
	game.resume_run()
	if not require(game.endless.fuses.size() == Rules.MAX_FUSES and is_equal_approx(game.endless.fuses[0].remaining, saved_time),
			"Saved corpses lost their countdown"):
		return
	game.player = Vector2(fuse.x, fuse.y)
	game.mercy = 0.0
	var before: int = game.hp
	game._physics_process(0.7)
	if not require(game.hp == before, "Corpse blast happened before the tell expired"):
		return
	game._physics_process(0.7)
	if not require(game.hp < before and game.pending_chest and game.endless.fuses.is_empty(), "Volatile Corpses did not detonate and unlock reward"):
		return

	var tea_rules: Array[String] = [Rules.TEA, Rules.HUNT, Rules.BOUNTY]
	force_floor(game, tea_rules)
	if not require(game.foes[0].get("hunt_elite", false), "Big Game room did not spawn a gold-marked elite"):
		return
	game.endless.tick(game, 2.3)
	var place: Vector2 = game.endless.position(game.endless.tea)
	var saved_elapsed = game.endless.elapsed
	game.checkpoint()
	game.resume_run()
	if not require(game.endless.protected_at(place) and is_equal_approx(game.endless.elapsed, saved_elapsed), "Tea circle and timing did not restore"):
		return
	game.player = place
	game.foes[0].x = place.x
	game.foes[0].y = place.y
	var health: int = game.hp
	game.mercy = 0.0
	game.damage_hero(30)
	var elite: Dictionary = game.foes[0]
	if not require(game.hp == health and game.defend_foe(elite, 20) == 0, "Tea Time did not protect both sides"):
		return
	var petals: int = game.petals
	elite.kind = game.endless.bounty_kind
	elite.hp = 0
	game.update_foes(0.016)
	if not require(game.petals == petals + 14, "Big Game and Bounty did not pay their exact Petals"):
		return

	var clock = Rules.new()
	clock.begin_room({"mutators": [Rules.CLOCK]}, 0)
	if not require(is_equal_approx(clock.move_delta({"phase": 0, "biome": 2}, 1.0), 1.24)
			and is_equal_approx(clock.move_delta({"phase": 1, "biome": 2}, 1.0), 1.0)
			and is_equal_approx(clock.move_delta({"phase": 0, "biome": 1}, 1.0), 1.0),
			"Fast Clock modified a non-Clockwork enemy or a windup"):
		return
	print("PASS: 425 deterministic Endless selections, conflicts and scope, capped volatile fuse resume, tea shelter resume and elite bounties.")
	quit(0)
