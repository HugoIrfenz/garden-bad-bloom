extends RefCounted

# Runs the existing biome and boss behavior on the host against the party.
# Each enemy uses a living heroine's own guard/status context as its target.
signal defeated(foe: Dictionary)
signal player_fell(player_id: String)

var next_id := 1

func reset(campaign) -> void:
	next_id = 1
	# IDs from enemies that have already died remain reserved throughout this
	# room, including after host migration. Otherwise newly summoned foes can
	# collide with a projectile's remembered hit list or a codex receipt.
	for seen_id: Variant in campaign.seen_enemy_ids:
		next_id = maxi(next_id, int(seen_id) + 1)
	for foe: Dictionary in campaign.foes:
		next_id = maxi(next_id, int(foe.get("online_id", 0)) + 1)
		_assign_target_ids(foe)

func advance(campaign, heroes: Dictionary, delta: float) -> void:
	# Every phone sees the same entrance; enemies wait until all active
	# heroines are through their introduction, as they do in solo play.
	for id: String in heroes:
		var member: Dictionary = campaign.party.players[id]
		if member.alive and member.connected and not member.departed and float(heroes[id].game.room_arrival) > 0.0:
			return
	for index in range(campaign.foes.size() - 1, -1, -1):
		var foe: Dictionary = campaign.foes[index]
		if int(foe.hp) <= 0:
			_handle_death(campaign, heroes, foe)
			campaign.foes.remove_at(index)
			defeated.emit(foe.duplicate(true))
			continue
		var target_id := _nearest_living(campaign, heroes, Vector2(foe.x, foe.y))
		if target_id.is_empty():
			continue
		# Advance the canonical enemy once. Evaluate the same pre-advance attack
		# against every other heroine using isolated enemy state, so area attacks
		# and projectiles can affect more than one player without moving the boss
		# or spawning its minions multiple times in the authoritative world.
		var before: Dictionary = foe.duplicate(true)
		var target_bolts: Array = heroes[target_id].game.bolts
		var target_bolt_count := target_bolts.size()
		_resolve_for_player(campaign, heroes, target_id, foe, delta, true)
		var shared_projectiles: Array[Dictionary] = []
		for projectile_index in range(target_bolt_count, target_bolts.size()):
			var projectile: Variant = target_bolts[projectile_index]
			if projectile is Dictionary and projectile.has("damage"):
				shared_projectiles.append(projectile.duplicate(true))
		for id: String in heroes:
			if id == target_id:
				continue
			var member: Dictionary = campaign.party.players[id]
			if member.alive and member.connected and not member.departed:
				var recipient_bolts: Array = heroes[id].game.bolts
				var recipient_bolt_count := recipient_bolts.size()
				_resolve_for_player(campaign, heroes, id, before.duplicate(true), delta, false)
				# Shadow simulation resolves direct hits but its independently
				# aimed projectiles are not a second real enemy attack. Replicate
				# the host's actual projectile to each heroine instead, so all
				# phones see the same trajectory and can dodge it separately.
				for projectile_index in range(recipient_bolts.size() - 1, recipient_bolt_count - 1, -1):
					var generated: Variant = recipient_bolts[projectile_index]
					if generated is Dictionary and generated.has("damage"):
						recipient_bolts.remove_at(projectile_index)
				for projectile: Dictionary in shared_projectiles:
					recipient_bolts.append(projectile.duplicate(true))

	# Bosses may append attendants or hazards while advancing. Apply this room's
	# already-fixed party multiplier exactly once to every new enemy.
	for foe: Dictionary in campaign.foes:
		if foe.has("online_id"):
			continue
		foe.online_id = next_id
		next_id += 1
		_assign_target_ids(foe)
		var original_max := maxi(1, int(foe.get("max", 1)))
		var original_hp := clampi(int(foe.get("hp", original_max)), 0, original_max)
		foe.max = campaign.party.scale_health(original_max)
		foe.hp = clampi(roundi(float(original_hp) * float(foe.max) / original_max), 0, int(foe.max))

func _assign_target_ids(foe: Dictionary) -> void:
	# Solo gives each heroine its own counter, but online all heroines share
	# the same foe dictionaries. Shared IDs prevent two independently assigned
	# targets from colliding in piercing projectiles and chained ultimates.
	var id := int(foe.get("online_id", 0))
	if id > 0:
		foe.relic_target_id = id
		foe.ultimate_target_id = id

func _handle_death(campaign, heroes: Dictionary, foe: Dictionary) -> void:
	for id: String in heroes:
		var member: Dictionary = campaign.party.players[id]
		if not member.alive or member.departed:
			continue
		var game = heroes[id].game
		if not foe.get("web_anchor", false):
			game.endless.defeat(game, foe)
		if bool(foe.get("elite", false)) and bool(foe.get("elite_heal_drop", false)):
			game.elite_heal_drops.append({"x": float(foe.x), "y": float(foe.y)})
		if bool(foe.get("boss", false)) and game.active_biome < game.Art.ENEMY_ATLASES.size():
			game.boss_victory.begin(Vector2(foe.x, foe.y), -1.0 if game.player.x > float(foe.x) else 1.0)

func _resolve_for_player(campaign, heroes: Dictionary, id: String, foe: Dictionary, delta: float, authoritative: bool) -> void:
	var actor = heroes[id]
	var member: Dictionary = campaign.party.players[id]
	actor.game.foes = campaign.foes if authoritative else campaign.foes.duplicate(true)
	actor.game.hp = int(member.hp)
	actor.game.player = member.position
	actor.game.advance_one_foe(foe, delta)
	if authoritative:
		var status_totals: Variant = foe.get("online_status_damage", {})
		if status_totals is Dictionary:
			for owner: Variant in status_totals:
				if owner is String and campaign.party.players.has(owner):
					var scorer: Dictionary = campaign.party.players[owner]
					scorer.damage_dealt = int(scorer.get("damage_dealt", 0)) + maxi(0, int(status_totals[owner]))
		foe.erase("online_status_damage")
	actor.game.foes = campaign.foes
	member.hp = int(actor.game.hp)
	campaign.party.update_position(id, actor.game.player)
	if int(member.hp) <= 0 and member.alive:
		member.hp = 0
		member.alive = false
		member.door = ""
		campaign.motion.forget(id)
		player_fell.emit(id)

func _nearest_living(campaign, heroes: Dictionary, from: Vector2) -> String:
	var chosen := ""
	var nearest := INF
	for id: String in heroes:
		var player: Dictionary = campaign.party.players[id]
		if not player.alive or player.departed or not player.connected:
			continue
		var distance := from.distance_squared_to(player.position)
		if distance < nearest:
			nearest = distance
			chosen = id
	return chosen
