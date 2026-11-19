extends SceneTree

const Game = preload("res://main.tscn")
const Statuses = preload("res://scripts/combat_statuses.gd")
var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var game = Game.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run(true)
	game.room_arrival = 0.0
	game.barrels.clear()
	test_pulses_and_resume(game)
	test_controls_and_mark(game)
	test_protection_and_credit(game)
	if failures.is_empty():
		print("PASS: status cadence and resume, root release, Chill, mark use, Guardbreak and protected-status kill attribution.")
	else:
		for failure in failures:
			push_error(failure)
	quit(int(not failures.is_empty()))


func foe_at(biome := 0, boss := false) -> Dictionary:
	return {"x": 326.0, "y": 212.0, "hp": 50, "max": 50, "biome": biome,
		"kind": 3 if boss else 0, "phase": 0, "clock": 1.2, "boss": boss}


func test_pulses_and_resume(game) -> void:
	var status = game.combat_status
	var foe := foe_at()
	game.foes = [foe]
	status.apply_foe(foe, Statuses.POISON, 2.5, 2.0, "venom", "hero")
	status.tick_foe(game, foe, 0.44, false)
	status.apply_foe(foe, Statuses.POISON, 2.5, 1.0, "cloud", "hazard")
	expect(foe.hp == 50 and Statuses.foe_healing(foe, 10) == 8, "Poison fired early or failed to suppress healing.")
	game.checkpoint()
	game.resume_run()
	foe = game.foes[0]
	status.tick_foe(game, foe, 0.33, false)
	expect(foe.hp == 46, "Resume or a weaker refresh altered the first poison pulse.")
	status.cleanse_foe(foe, Statuses.POISON)
	status.apply_foe(foe, Statuses.BLEED, 2.0)
	status.tick_foe(game, foe, 0.53, false)
	expect(foe.hp == 46, "Bleed damaged a stationary target.")
	status.tick_foe(game, foe, 0.52, true)
	expect(foe.hp == 44, "Movement or attacking failed to trigger the next bleed pulse.")
	status.cleanse_foe(foe, Statuses.BLEED)
	status.apply_foe(foe, Statuses.BURN, 1.5)
	status.tick_foe(game, foe, 0.64, false)
	expect(foe.hp == 41, "Burn failed to pulse without movement.")


func test_controls_and_mark(game) -> void:
	var status = game.combat_status
	for i in range(2):
		status.apply_hero(Statuses.CHILL, 2.5)
	expect(is_equal_approx(status.hero_movement_scale(), 0.8), "Chill should ramp with individual applications.")
	status.apply_hero(Statuses.CHILL, 2.5)
	expect(is_zero_approx(status.hero_movement_scale()), "Three fresh Chill stacks did not freeze normal walking.")
	status.tick_hero(game, 0.29, false)
	for i in range(2):
		status.apply_hero(Statuses.CHILL, 2.5)
	expect(status.hero_movement_scale() > 0.0, "Freeze resistance did not raise the next threshold.")
	status.cleanse_hero(Statuses.CHILL)
	status.apply_hero("root", 0.9)
	expect(game.ground_hazards.movement_scale() < 0.5 and status.has_hero(Statuses.ROOT), "Root alias did not reach live movement.")
	expect(game.ground_hazards.break_snare() < 1.0 and not status.has_hero(Statuses.ROOT), "A dodge did not break Thornbound.")
	var foe: Dictionary = game.foes[0]
	status.apply_foe(foe, Statuses.MARKED, 3.0, 2.0)
	expect(Statuses.precision_mark_bonus(foe) == 10 and status.consume_foe_mark(foe) == 10
		and not Statuses.has_foe(foe, Statuses.MARKED), "The modern precision bonus could not be previewed and consumed once.")
	status.apply_foe(foe, Statuses.GUARDBREAK, 2.0)
	expect(Statuses.guarded_damage(foe, 20, 5) > 5 and Statuses.guarded_damage(foe, 20, 0) == 0,
		"Guardbreak should recover some grounded shield damage while zero damage remains protected.")


func test_protection_and_credit(game) -> void:
	var status = game.combat_status
	var boss := foe_at(6, true)
	game.foes = [boss]
	expect(not status.apply_foe(boss, Statuses.POISON, 3.0), "Bloomheart's intact shield accepted a status.")
	boss.nodes_spawned = true
	expect(status.apply_foe(boss, Statuses.POISON, 3.0), "Bloomheart should accept poison once exposed.")
	var node := foe_at(6)
	node.flower_node = true
	game.foes.append(node)
	status.tick_foe(game, boss, 0.77, false)
	expect(boss.hp == 50 and not status.apply_foe(node, Statuses.BURN, 2.0), "A pulse slipped through the renewed shield.")
	var foe := foe_at()
	foe.hp = 6
	game.foes = [foe]
	status.apply_foe(foe, Statuses.POISON, 3.0, 3.0, "venom")
	status.apply_foe(foe, Statuses.POISON, 4.0, 1.0, "cloud", "hazard")
	status.tick_foe(game, foe, 0.77, false)
	expect(foe.hp == 0 and foe.get("status_kill", {}) == {"effect": Statuses.POISON, "credit": "hero", "source": "venom"},
		"A weaker refresh stole lethal status credit or spawned a second damage event.")


func expect(condition: bool, detail: String) -> void:
	if not condition:
		failures.append(detail)
