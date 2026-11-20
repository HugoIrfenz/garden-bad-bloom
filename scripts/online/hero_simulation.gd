extends Node

# A host-side heroine uses the same abilities, weapons, movement, and cooldowns
# as the solo game. The room and foes are supplied by the shared campaign.
var game: Node2D
var player_id := ""
var last_room_id := ""
var last_room_serial := -1
var thread_samples: Array[Dictionary] = []
var frame_active := false
var score_member: Dictionary = {}
const CAST_NAMESPACE_SIZE := 1000000

func setup(id: String, hero: int, campaign) -> void:
	player_id = id
	var garden_script: Script = load("res://garden.gd")
	game = garden_script.new()
	game.network_simulation = true
	game.set_meta("online_player_id", id)
	game.name = "HeroSimulation"
	add_child(game)
	game.hero = hero
	var member: Dictionary = campaign.party.players[id]
	score_member = member
	var weapon := str(member.get("starting_weapon", ""))
	if not game.Weapons.usable_by(weapon, hero):
		weapon = ""
	game.armory.reset(hero, weapon)
	game.abilities.reset()
	game.ultimates.reset()
	game.guest_combat.reset(true)
	game.luna_combat.reset(true)
	game.relics.reset()
	var relic := str(member.get("starting_relic", ""))
	if relic in game.Prep.relic_options(hero):
		game.relics.equip(relic)
	game.curses.restore()
	game.combat_status.reset()
	game.talents.reset()
	game.upgrades.reset()
	game.hp = int(campaign.party.players[id].hp)
	game.screen = "fight"
	bind_room(campaign)

func bind_room(campaign) -> void:
	# Mirror the per-room resets in Garden.enter_room without spawning a second
	# set of enemies. These include once-per-room relics and talent state.
	game.cancel_bow_charge()
	game.twin_moon_sequences.clear()
	game.second_chance_used = false
	game.princes_pin_used = false
	game.velvet_ribbon_used = false
	game.velvet_ribbon_left = 0.0
	game.boss_victory.reset()
	game.armory.enter_room()
	game.painted_evolution.reset()
	game.talents.enter_room()
	game.snare_thread.reset()
	game.lily_combo = 0
	game.lily_combo_time = 0.0
	game.lily_finisher_flash = false
	game.lily_repeat.clear()
	game.lily_repeat_visual = false
	game.flash = 0.0
	game.elite_heal_drops.clear()
	game.dash_remaining = 0.0
	game.dash_evaded = false
	game.visual_velocity = Vector2.ZERO
	thread_samples.clear()
	frame_active = false
	game.run_seed = campaign.seed
	game.floor_index = campaign.floor_index
	game.floor_manifest = campaign.manifest
	game.room_id = campaign.room_id
	game.depth = campaign.depth
	game.route = campaign.route
	game.set_room_props(campaign.room)
	game.endless.begin_room(campaign.manifest, int(campaign.room.encounter_seed))
	game.room_generation = int(campaign.room.version)
	game.barrels.assign(campaign.room.cover)
	game.foes = campaign.foes
	game.player = campaign.party.players[player_id].position
	game.room_complete = bool(campaign.party.players[player_id].get("room_done", false))
	game.bolts.clear()
	game.abilities.reset()
	game.ultimates.reset(true)
	# Heroine picks are exclusive in a party. Give each heroine her own cast
	# IDs, since all of their ultimate projectiles hit the same foe objects.
	game.ultimates._cast_serial = int(game.hero) * CAST_NAMESPACE_SIZE
	game.guest_combat.reset()
	game.luna_combat.reset()
	# Match the solo encounter introduction, including each boss's cut-in.
	# The shared enemy simulation waits for the party's arrival to finish.
	game.room_arrival = game.BOSS_ARRIVAL if game.entrance_boss() else (game.ROOM_ARRIVAL if not game.foes.is_empty() else 0.0)
	game.mercy = 0.7
	last_room_id = campaign.room_id
	last_room_serial = int(campaign.room_serial)

func advance(campaign, delta: float, direction: Vector2) -> void:
	if last_room_id != campaign.room_id or game.floor_index != campaign.floor_index or last_room_serial != int(campaign.room_serial):
		bind_room(campaign)
	game.foes = campaign.foes
	game.room_complete = bool(campaign.party.players[player_id].get("room_done", false))
	game.hp = int(campaign.party.players[player_id].hp)
	game.stick = direction
	game.visual_clock += delta
	game.room_clock = campaign.room_elapsed
	if game.screen != "fight":
		return
	frame_active = true
	# The rest of the party's enemies continue moving during a local cut-in or
	# boss celebration, so existing threads must still capture their positions.
	thread_samples = game.snare_thread.sample_foes(game)
	# A boss defeat has the same short celebration as solo. The shared room
	# waits for this timer before issuing rewards.
	if game.boss_victory.left > 0.0:
		game.boss_victory.tick(game, delta)
		game.collect_elite_heals()
		campaign.party.players[player_id].hp = int(game.hp)
		return
	# A cut-in locks only this heroine; it does not stop the shared world.
	var before_damage := _foe_health()
	if not game.ultimates.tick_cutin(game, delta):
		var frame: Dictionary = game.advance_hero_frame(delta, direction)
		if game.room_arrival <= 0.0:
			game.endless.tick(game, delta)
			game.update_bolts(delta)
		_credit_damage(before_damage)
		thread_samples = game.snare_thread.sample_foes(game)
		game.collect_elite_heals()
		if game.room_arrival <= 0.0 and game.optional_arena_boss() == game.OptionalBosses.BRASSWING and not campaign.foes.is_empty():
			game.OptionalBosses.tick_rails(game)
		if game.room_arrival <= 0.0 and not game.room_complete and not campaign.foes.is_empty():
			game.ground_hazards.tick(game, frame.before, delta)
			game.clockwork_floor.tick(game, delta)
		var stride: bool = game.player.distance_to(frame.before) > 78.0 * delta
		game.combat_status.tick_hero(game, delta, stride or game.flash > 0.0)
		game.talents.tick(game, delta, game.player.distance_to(frame.before) > 3.0 * delta, bool(frame.dodging))
	else:
		_credit_damage(before_damage)
	campaign.party.players[player_id].hp = int(game.hp)
	campaign.party.update_position(player_id, game.player)

func finish_frame(delta: float) -> void:
	if not frame_active:
		return
	var before_damage := _foe_health()
	game.snare_thread.tick(game, thread_samples, delta)
	_credit_damage(before_damage)
	thread_samples.clear()
	frame_active = false
	game.abilities.tick_guard(delta)

func act(campaign, action: String, charge := 0.0) -> void:
	if last_room_id != campaign.room_id or game.floor_index != campaign.floor_index or last_room_serial != int(campaign.room_serial):
		bind_room(campaign)
	game.foes = campaign.foes
	game.room_complete = bool(campaign.party.players[player_id].get("room_done", false))
	game.hp = int(campaign.party.players[player_id].hp)
	var before_damage := _foe_health()
	if action in ["mode_0", "mode_1", "mode_2"]:
		if game.hero == 6:
			game.choose_whi_mode(int(action.right(1)))
	elif action in ["attack", "dodge", "skill", "ultimate"]:
		game.act(action, clampf(charge, 0.0, 1.0))
	_credit_damage(before_damage)
	campaign.party.players[player_id].hp = int(game.hp)
	campaign.party.update_position(player_id, game.player)

func use_pocket(campaign) -> void:
	game.foes = campaign.foes
	game.hp = int(campaign.party.players[player_id].hp)
	var before_damage := _foe_health()
	game.use_pocket()
	_credit_damage(before_damage)
	campaign.party.players[player_id].hp = int(game.hp)

# Actors run one at a time on the host, so the health lost inside this
# heroine's action belongs to her. Clamp overkill to the health actually lost.
func _foe_health() -> Dictionary:
	var health := {}
	for foe: Dictionary in game.foes:
		var id := int(foe.get("online_id", 0))
		if id > 0:
			health[id] = maxi(0, int(foe.get("hp", 0)))
	return health

func _credit_damage(before: Dictionary) -> void:
	var total := 0
	for foe: Dictionary in game.foes:
		var id := int(foe.get("online_id", 0))
		if before.has(id):
			total += maxi(0, int(before[id]) - maxi(0, int(foe.get("hp", 0))))
	if total > 0:
		score_member.damage_dealt = int(score_member.get("damage_dealt", 0)) + total

func snapshot() -> Dictionary:
	var state: Dictionary = game.build_run_snapshot().duplicate(true)
	state.online_ultimate_namespace = 1
	state.reward_relic_preview = game.menu_motion.reward_relic_preview
	state.presentation = {"flash": game.flash, "damage_flash": game.damage_flash, "visual_velocity": game.visual_velocity,
		"walk_distance": game.walk_distance, "facing": game.facing,
		"attack_facing": game.attack_visual_facing,
		"guest_action_left": game.guest_combat.action_until,
		"guest_action_variant": game.guest_combat.action_variant,
		"luna_action_left": game.luna_combat.action_left,
		"luna_wolf": game.luna_combat.in_wolf(),
		"hero_traces": game.guest_combat.traces.duplicate(true),
		"luna_traces": game.luna_combat.traces.duplicate(true)}
	# The shared campaign already carries these potentially large structures.
	for key in ["foes", "floor_manifest", "route_history"]:
		state.erase(key)
	return state

func restore(state: Dictionary, campaign) -> bool:
	if state.is_empty() or int(state.get("hero", -1)) != int(campaign.party.players[player_id].hero):
		return false
	var combined: Dictionary = game.build_run_snapshot()
	combined.merge(state.duplicate(true), true)
	combined.floor_manifest = campaign.manifest
	combined.foes = campaign.foes
	combined.room_id = campaign.room_id
	combined.floor_index = campaign.floor_index
	combined.route_history = campaign.history
	game.restore_run_snapshot(combined, true)
	game.menu_motion.reward_relic_preview = str(state.get("reward_relic_preview", ""))
	game.foes = campaign.foes
	if int(state.get("online_ultimate_namespace", 0)) < 1:
		_migrate_legacy_cast_ids()
	game.player = campaign.party.players[player_id].position
	last_room_id = campaign.room_id
	last_room_serial = int(campaign.room_serial)
	return true

func _migrate_legacy_cast_ids() -> void:
	var offset: int = int(game.hero) * CAST_NAMESPACE_SIZE
	if offset <= 0:
		return
	var previous_cast: int = int(game.ultimates._cast_serial)
	game.ultimates._cast_serial = offset + previous_cast
	for bolt: Variant in game.bolts:
		if bolt is Dictionary and bolt.has("ultimate_cast"):
			bolt.ultimate_cast = offset + int(bolt.ultimate_cast)
	for foe: Dictionary in game.foes:
		# Older snapshots recorded only one cast per foe; preserve its hit cap
		# under the migrated ID when it matches this heroine's active cast.
		if int(foe.get("ultimate_cast", -1)) == previous_cast:
			var counts: Variant = foe.get("ultimate_hit_counts", {})
			if not counts is Dictionary:
				counts = {}
			var key := str(offset + previous_cast)
			if not counts.has(key):
				counts[key] = int(foe.get("ultimate_hits", 0))
			foe.ultimate_hit_counts = counts
		if int(game.hero) == 4 and int(foe.get("disaster_cast", -1)) == previous_cast:
			foe.disaster_cast = offset + previous_cast
