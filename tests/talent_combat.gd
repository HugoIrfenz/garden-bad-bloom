extends SceneTree

const Game = preload("res://main.tscn")
const Talents = preload("res://scripts/run_talents.gd")
const Statuses = preload("res://scripts/combat_statuses.gd")
var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var game = Game.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	test_guard(game)
	test_quill(game)
	test_meteor(game)
	test_snare(game)
	test_ink(game)
	if failures.is_empty():
		print("PASS: each heroine's talent triggers in combat with bounded effects and resumable talent state.")
	else:
		for failure in failures:
			push_error(failure)
	quit(int(not failures.is_empty()))


func prepare(game, hero: int, talent: String) -> void:
	game.hero = hero
	game.start_run(true)
	game.player = Vector2(180, 216)
	game.facing = Vector2.RIGHT
	game.mercy = 0.0
	game.room_arrival = 0.0
	game.attack_time = 0.0
	game.dodge_time = 0.0
	game.foes.clear()
	game.bolts.clear()
	game.barrels.clear()
	expect(game.talents.offer(hero).get("id", "") == talent and game.talents.choose(talent, hero),
		"The talent was unavailable to its intended heroine.")
	expect(not game.talents.choose(talent, hero), "The milestone let the same talent be equipped twice.")


func actor(game, point: Vector2) -> Dictionary:
	var foe := {"x": point.x, "y": point.y, "hp": 100, "max": 100, "phase": 0,
		"boss": false, "kind": 0, "clock": 2.0, "biome": 0}
	game.foes.append(foe)
	return foe


func test_guard(game) -> void:
	prepare(game, 0, Talents.WARMSTEEL)
	var foe := actor(game, Vector2(230, 216))
	game.act("skill")
	game.damage_hero(8, game.target(foe))
	expect(game.talents.warm_left > 0.0, "A perfect guard did not prime Warmsteel.")
	game.checkpoint()
	game.resume_run()
	game.barrels.clear()
	foe = game.foes[0]
	game.act("attack")
	expect(game.talents.warm_left == 0.0 and Statuses.has_foe(foe, Statuses.BURN),
		"Warmsteel did not survive resume and ignite on the next real attack.")


func test_quill(game) -> void:
	prepare(game, 1, Talents.QUIET_QUILL)
	actor(game, Vector2(238, 216))
	game.talents.tick(game, 0.95, false, false)
	game.act("dodge")
	expect(is_equal_approx(game.talents.quiet_charge, Talents.QUIET_TIME), "Vivianne's stationary frost cast should preserve Quiet Quill's charge.")
	game.talents.tick(game, 0.016, true, false)
	expect(game.talents.quiet_charge == 0.0, "Moving did not clear Quiet Quill's charge.")
	game.talents.tick(game, 0.95, false, false)
	game.act("skill")
	var effect: Dictionary = game.abilities.snapshot().effect
	expect(int(effect.get("talent_power", 0)) == Talents.QUIET_POWER and game.talents.quiet_charge == 0.0,
		"The charged skill did not carry and consume Quiet Quill's power.")


func test_meteor(game) -> void:
	prepare(game, 2, Talents.POCKET_METEOR)
	var foe := actor(game, Vector2(246, 243))
	game.resource = 3
	game.act("skill")
	game.abilities.tick(game, 0.23)
	expect(foe.hp < 100 and float(foe.get("hero_stun", 0.0)) > 0.0 and not game.talents.meteor.is_empty(),
		"Pocket Meteor did not stagger the foe outside the leap's forward cone.")


func test_snare(game) -> void:
	prepare(game, 3, Talents.SNARE_BLOOM)
	actor(game, Vector2(280, 216))
	var outer := actor(game, Vector2(280, 262))
	game.act("skill")
	game.abilities.tick(game, 0.24)
	expect(not game.talents.bloom.is_empty() and not Statuses.has_foe(outer, Statuses.ROOT),
		"Snare Bloom was not scheduled at the dash endpoint.")
	game.checkpoint()
	game.resume_run()
	game.barrels.clear()
	outer = game.foes[1]
	game.talents.tick(game, Talents.BLOOM_DELAY + 0.01, false, false)
	expect(Statuses.has_foe(outer, Statuses.ROOT) and bool(game.talents.bloom.active),
		"The resumed outer ring did not snare its target after its warning.")


func test_ink(game) -> void:
	prepare(game, 4, Talents.INK_FOOTSTEPS)
	var foe := actor(game, Vector2(209, 222))
	game.act("dodge")
	game._physics_process(0.052)
	expect(not game.talents.ink.is_empty() and game.talents.foe_movement_scale(game, foe) < 1.0,
		"The actual dodge did not lay a slow trail under its pursuer.")
	game.checkpoint()
	game.resume_run()
	game.barrels.clear()
	expect(game.talents.foe_movement_scale(game, game.foes[0]) < 1.0, "Ink Footsteps disappeared on resume.")


func expect(condition: bool, detail: String) -> void:
	if not condition:
		failures.append(detail)
