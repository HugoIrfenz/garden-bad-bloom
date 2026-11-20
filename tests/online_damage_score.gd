extends SceneTree

const Campaign = preload("res://scripts/online/campaign_state.gd")
const Hero = preload("res://scripts/online/hero_simulation.gd")
const Enemies = preload("res://scripts/online/enemy_simulation.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var campaign = Campaign.new()
	campaign.begin(3012, {"a": {"hero": 0, "connected": true, "username": "Alice"},
		"b": {"hero": 2, "connected": true, "username": "Bob"}})
	campaign.run_id = "damage-score-check"
	for id: String in campaign.manifest.nodes:
		if campaign.manifest.nodes[id].kind == "combat":
			campaign.enter_room(id)
			break
	assert(not campaign.foes.is_empty())
	var foe: Dictionary = campaign.foes[0]
	campaign.foes.clear()
	campaign.foes.append(foe)
	foe.hp = 1000
	foe.max = 1000
	var point := Vector2(float(foe.x) - 20.0, float(foe.y))
	campaign.party.players.a.position = point
	campaign.party.players.b.position = point
	var a = Hero.new()
	var b = Hero.new()
	root.add_child(a)
	root.add_child(b)
	a.setup("a", 0, campaign)
	b.setup("b", 2, campaign)
	for actor in [a, b]:
		actor.game.barrels.clear()
		actor.game.room_arrival = 0.0
		actor.game.facing = Vector2.RIGHT
	var hp := int(foe.hp)
	a.act(campaign, "attack")
	var a_hit := hp - int(foe.hp)
	assert(a_hit > 0 and int(campaign.party.players.a.damage_dealt) == a_hit)
	hp = int(foe.hp)
	b.act(campaign, "attack")
	var b_hit := hp - int(foe.hp)
	assert(b_hit > 0 and int(campaign.party.players.b.damage_dealt) == b_hit)
	assert(int(campaign.party.players.a.damage_dealt) == a_hit)
	# Hits larger than remaining health count only the health actually lost.
	foe.hp = 2
	a.game.attack_time = 0.0
	a.act(campaign, "attack")
	assert(int(campaign.party.players.a.damage_dealt) == a_hit + 2)
	foe.hp = 100
	foe.phase = 0
	foe.clock = 10.0
	a.game.combat_status.apply_foe(foe, "burn", 2.0, 1.0, "score-check")
	# Status ownership must survive the same sanitization used on recovery.
	a.game.combat_status.restore_foes(campaign.foes)
	var enemies = Enemies.new()
	enemies.reset(campaign)
	enemies.advance(campaign, {"a": a, "b": b}, 0.7)
	assert(int(campaign.party.players.a.damage_dealt) > a_hit + 2)
	assert(int(campaign.party.players.b.damage_dealt) == b_hit)
	var before_bomb := int(foe.hp)
	b.game.player = Vector2(float(foe.x) - 20.0, float(foe.y))
	campaign.party.players.b.position = b.game.player
	b.game.pocket.take("petal_bomb")
	assert(campaign.use_pocket_player("b", {"a": a, "b": b}))
	assert(int(campaign.party.players.b.damage_dealt) == b_hit + before_bomb - maxi(0, int(foe.hp)))
	var restored = Campaign.new()
	assert(restored.restore(campaign.snapshot(100.0), 200.0))
	assert(restored.party.players.a.damage_dealt == campaign.party.players.a.damage_dealt)
	assert(restored.party.players.b.damage_dealt == campaign.party.players.b.damage_dealt)
	assert(restored.party.players.a.username == "Alice")
	print("PASS: independent hero damage, overkill, status credit and recovery")
	a.free()
	b.free()
	quit()
