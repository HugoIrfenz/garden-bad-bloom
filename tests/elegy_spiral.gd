extends SceneTree

const Game = preload("res://main.tscn")
const Elegy = preload("res://scripts/elegy_magic.gd")
var issues := PackedStringArray()


func _initialize() -> void:
	call_deferred("verify")


func verify() -> void:
	var game = Game.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	test_echo(game)
	test_ink(game)
	test_evolved_shots(game)
	if issues.is_empty():
		print("PASS: Elegy echo timing, resumable pulls and convergence, curved shots and per-shot residue cap.")
	else:
		for issue in issues:
			push_error(issue)
	quit(int(not issues.is_empty()))


func prepare(game) -> void:
	game.hero = 1
	game.start_run(true)
	game.player = Vector2(180.0, 190.0)
	game.facing = Vector2.RIGHT
	game.room_arrival = 0.0
	game.attack_time = 0.0
	game.mercy = 0.0
	game.foes.clear()
	game.bolts.clear()
	game.barrels.clear()


func actor(game, at: Vector2, boss := false) -> Dictionary:
	var foe := {"x": at.x, "y": at.y, "hp": 100, "max": 100, "phase": 0,
		"boss": boss, "kind": 3 if boss else 0, "clock": 1.0, "biome": 0}
	game.foes.append(foe)
	return foe


func magic_state(game) -> Dictionary:
	return game.abilities.snapshot().elegy_magic


func test_echo(game) -> void:
	prepare(game)
	var foe := actor(game, Vector2(274.0, 190.0))
	game.relics.equip(Elegy.REFRAIN)
	game.act("skill")
	expect(is_equal_approx(game.skill_time, 3.55), "Refrain did not raise Midnight Verse recharge.")
	game.abilities.tick(game, 0.60)
	expect(foe.hp == 80 and not magic_state(game).echo.is_empty(), "Midnight Verse did not queue one later echo.")
	game.checkpoint()
	game.resume_run()
	game.barrels.clear()
	foe = game.foes[0]
	game.abilities.tick(game, 0.52)
	expect(foe.hp == 80, "The restored echo fired before its delay.")
	game.abilities.tick(game, 0.03)
	expect(foe.hp == 70 and magic_state(game).echo.is_empty(), "The restored echo did not hit once at half power.")
	game.abilities.tick(game, 0.73)
	expect(foe.hp == 70, "An echo used its own impact to schedule another echo.")


func test_ink(game) -> void:
	prepare(game)
	game.relics.equip(Elegy.INK)
	var foe := actor(game, Vector2(306.0, 190.0))
	var boss := actor(game, Vector2(302.0, 199.0), true)
	game.abilities.note_elegy_crescendo(game, Vector2(273.0, 190.0))
	game.abilities.note_elegy_crescendo(game, Vector2(275.0, 190.0))
	expect(magic_state(game).wells.size() == 1 and magic_state(game).residues.is_empty(),
		"An overlap did not consume one pair into a well.")
	game.abilities.tick(game, 0.19)
	expect(float(foe.x) < 306.0 and is_equal_approx(float(boss.x), 302.0) and foe.hp == 100,
		"Black Rose Ink should pull ordinary foes while leaving bosses fixed and deal no burst by itself.")


func test_evolved_shots(game) -> void:
	prepare(game)
	game.armory.reset(1, Elegy.WEAPON)
	var foe := actor(game, Vector2(274.0, 190.0))
	game.act("attack")
	game.update_bolts(0.09)
	expect(not game.bolts.is_empty() and absf(float(game.bolts[0].y) - 190.0) > 1.0,
		"The evolved bolt did not bend from its launch heading.")
	for i in range(45):
		game.update_bolts(1.0 / 60.0)
	expect(foe.hp == 86 and magic_state(game).residues.size() == 1,
		"The actual evolved projectile hit did not leave one trace.")
	game.abilities.note_elegy_hit(game, Vector2(274.0, 190.0), game.armory.basic_sequence)
	expect(magic_state(game).residues.size() == 1 and magic_state(game).wells.is_empty(),
		"The same basic attack left two traces.")
	game.attack_time = 0.0
	game.act("attack")
	for i in range(45):
		game.update_bolts(1.0 / 60.0)
	expect(foe.hp == 72 and magic_state(game).wells.size() == 1, "Two evolved shots failed to form a damaging well.")
	game.abilities.tick(game, 0.35)
	game.checkpoint()
	game.resume_run()
	game.barrels.clear()
	foe = game.foes[0]
	game.abilities.tick(game, 0.10)
	expect(foe.hp == 63 and bool(magic_state(game).wells[0].bloomed), "Resumed convergence did not bloom precisely once.")
	game.abilities.tick(game, 0.40)
	expect(foe.hp == 63 and magic_state(game).wells.is_empty(), "Convergence dealt repeated damage or failed to expire.")


func expect(condition: bool, detail: String) -> void:
	if not condition:
		issues.append(detail)
