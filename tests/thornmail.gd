extends SceneTree

var issues := PackedStringArray()

func _initialize() -> void:
	call_deferred("run")

func expect(passed: bool, issue: String) -> void:
	if not passed:
		issues.append(issue)

func fixture(game, arm_delay: float = 0.0, cover: bool = false) -> void:
	game.barrels.clear()
	if cover:
		game.barrels.append(Vector2(335, 208))
	game.foes = [{"x": 370, "y": 208, "hp": 40, "max": 40, "kind": 0,
		"boss": false, "phase": 0, "clock": 0.8}]
	game.abilities.reset()
	game.player = Vector2(300, 208)
	game.facing = Vector2.RIGHT
	game.skill_time = 0.0
	game.dash_remaining = 0.0
	game.mercy = 0.0
	game.resource = 0
	game.hp = 100
	game.act("skill")
	game.abilities.tick(game, arm_delay)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_run()
	game.floor_index = 0
	game.load_floor()
	game.room_id = game.floor_manifest.boss_id
	game.enter_room()
	for relic_id in [game.Relics.WEDDING_RING, game.Relics.GLASS_EYELASH, game.Relics.LAST_TEASPOON]:
		game.relics.equip(relic_id)
	game.relics.equip(game.Relics.COUNTERCLOCK_LOCKET)
	var reward_seed := 12345
	expect(game.relics.boss_offer(reward_seed, 1).is_empty(), "A different heroine was offered Thornmail.")
	for foe in game.foes:
		foe.hp = 0
	game._physics_process(0.016)
	expect(game.reward_relic_id == game.Relics.THORNMAIL, "The Garden boss did not offer the in-pool relic.")
	game.player = game.chest_position
	game.open_chest()
	game._physics_process(0.5)
	game.tap(game.View.Reward.RELIC_RECT.get_center())
	game.tap(game.View.Reward.RELIC_EQUIP.get_center())
	expect(game.relics.has_relic(game.Relics.THORNMAIL), "The reward card did not equip Thornmail.")

	fixture(game)
	game.damage_hero(20, Vector2(370, 208))
	game.damage_hero(20, Vector2(372, 209))
	expect(game.hp == 100 and game.abilities.snapshot().relic_bolts.size() == 5,
		"The perfect guard did not fire exactly five thorns once per cast.")
	game.checkpoint()
	game.resume_run()
	expect(game.relics.has_relic(game.Relics.THORNMAIL)
		and game.abilities.snapshot().relic_bolts.size() == 5, "The in-flight burst was not saved.")
	game.barrels.clear()
	game.abilities.tick(game, 0.25)
	expect(int(game.foes[0].hp) < 40 and game.resource == 2, "The burst missed or counted as a basic attack.")
	expect(game.abilities.counter_bonus(game, game.foes[0]) > 0, "The relic consumed the normal guard counter.")

	fixture(game, 0.20)
	game.damage_hero(20, Vector2(370, 208))
	expect(game.hp < 100 and game.abilities.snapshot().relic_bolts.is_empty(),
		"A regular guard triggered the relic.")
	fixture(game, 0.0, true)
	game.damage_hero(20, Vector2(370, 208))
	game.abilities.tick(game, 0.35)
	expect(game.foes[0].hp == 40, "The burst hit a foe behind cover.")

	for issue in issues:
		push_error(issue)
	if issues.is_empty():
		print("PASS: Thornmail boss acquisition, hero filtering, perfect timing, cover, counter and snapshot.")
	quit(0 if issues.is_empty() else 1)
