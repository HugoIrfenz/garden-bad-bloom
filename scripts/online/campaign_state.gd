extends RefCounted

const Dungeon = preload("res://scripts/dungeon_generation.gd")
const RoomEvents = preload("res://scripts/room_events.gd")
const RelicSources = preload("res://scripts/relic_sources.gd")
const DungeonView = preload("res://scripts/dungeon_route_view.gd")
const MerchantView = preload("res://scripts/merchant_view.gd")
const TalentView = preload("res://scripts/talent_view.gd")
const GuestRoster = preload("res://scripts/guest_roster.gd")
const OptionalBosses = preload("res://scripts/optional_bosses.gd")
const EncounterFactory = preload("res://scripts/encounter_factory.gd")
const EndlessRules = preload("res://scripts/endless_mutators.gd")
const Party = preload("res://scripts/online/party_state.gd")
const Motion = preload("res://scripts/online/player_motion.gd")
const NEXT_FLOOR := "next_floor"

var seed := 0
var run_id := ""
var floor_index := 0
var depth := 0
var manifest: Dictionary = {}
var room_id := ""
var room: Dictionary = {}
var party := Party.new()
var motion := Motion.new()
var endless := EndlessRules.new()
var foes: Array[Dictionary] = []
var route := 0
var history: Array[String] = []
var room_serial := 0
var room_phase := ""
var room_elapsed := 0.0
var terminal := ""
var pending_event_encounter := ""
var awards: Dictionary = {}
var award_receipts: Dictionary = {}
var seen_enemy_ids: Dictionary = {}
var discovery_wave := 0

func begin(run_seed: int, roster: Dictionary) -> void:
	seed = run_seed
	floor_index = 0
	depth = 0
	route = 0
	room_serial = 0
	terminal = ""
	pending_event_encounter = ""
	run_id = ""
	awards.clear()
	award_receipts.clear()
	history.clear()
	party.configure(roster)
	motion.clear()
	load_floor()
	enter_room(str(manifest.entrance_id))

func load_floor() -> void:
	manifest = Dungeon.generate_floor(seed, floor_index)
	Dungeon.add_optional_boss_route(manifest, seed)

func enter_room(id: String) -> bool:
	if not manifest.get("nodes", {}).has(id):
		return false
	var next := Dungeon.generate_room(seed, manifest, id)
	if next.is_empty():
		return false
	room_id = id
	pending_event_encounter = ""
	room_serial += 1
	room_elapsed = 0.0
	room = next
	route = int(manifest.nodes[id].branch)
	var node: Dictionary = manifest.nodes[id]
	var stage := int(node.get("optional_stage", -1))
	var optional_id := str(node.get("optional_boss", ""))
	if stage in [0, 1] or (stage == 2 and optional_id in [OptionalBosses.MOTHER, OptionalBosses.BRASSWING]):
		room.cover.clear()
	elif stage == 2 and optional_id == OptionalBosses.SCARECROW:
		room.cover.clear()
		var broken := int(node.get("broken_hay", 0))
		for index in range(OptionalBosses.HAY_POSTS.size()):
			if (broken & (1 << index)) == 0:
				room.cover.append(OptionalBosses.HAY_POSTS[index])
	history.append(id)
	var exits: Dictionary = room.exit_positions.duplicate()
	if room.kind == "boss":
		exits[NEXT_FLOOR] = Vector2(432, Dungeon.EXIT_Y)
	party.start_room(exits)
	EndlessRules.configure_floor(manifest, seed)
	endless.begin_room(manifest, int(room.encounter_seed))
	foes = EncounterFactory.spawn(room, manifest, room_id, floor_index, depth, route, endless)
	seen_enemy_ids.clear()
	discovery_wave = 0
	for index in range(foes.size()):
		var foe: Dictionary = foes[index]
		foe.online_id = index + 1
		seen_enemy_ids[foe.online_id] = true
		foe.max = party.scale_health(int(foe.max))
		foe.hp = foe.max
	motion.clear()
	for player: Dictionary in party.players.values():
		player.room_done = room.kind == "transition"
		player.room_serial = -1
		player.reward_given = false
		player.talent_presented = false
		if player.alive and not player.departed:
			player.position = room.entry
	room_phase = "cleared" if room.kind == "transition" else ("encounter" if not foes.is_empty() else "choices")
	if room.kind == "transition":
		party.room_cleared = true
	return true

func accept_unanimous_exit(now: float) -> bool:
	if not terminal.is_empty() or party.paused(now):
		return false
	var exit := party.unanimous_door()
	if exit.is_empty() or not party.doors.has(exit):
		return false
	if exit == NEXT_FLOOR:
		floor_index += 1
		load_floor()
		depth += 1
		return enter_room(str(manifest.entrance_id))
	if not manifest.nodes.has(exit):
		return false
	depth += 1
	return enter_room(exit)

func room_snapshot() -> Dictionary:
	return {
		"seed": seed, "floor_index": floor_index, "depth": depth, "room_id": room_id,
		"manifest": manifest.duplicate(true), "room": room.duplicate(true),
		"history": history.duplicate(), "room_health_multiplier": party.room_health_multiplier,
		"foes": foes.duplicate(true),
	}

func snapshot(now: float) -> Dictionary:
	return {"seed": seed, "run_id": run_id, "floor_index": floor_index, "depth": depth, "route": route,
		"manifest": manifest.duplicate(true), "room_id": room_id, "room": room.duplicate(true),
		"history": history.duplicate(), "foes": foes.duplicate(true),
		"party": party.snapshot(now), "endless": endless.snapshot(), "room_serial": room_serial,
		"room_phase": room_phase, "room_elapsed": room_elapsed, "terminal": terminal,
		"pending_event_encounter": pending_event_encounter,
		"awards": awards.duplicate(true), "award_receipts": award_receipts.duplicate(true),
		"seen_enemy_ids": seen_enemy_ids.duplicate(), "discovery_wave": discovery_wave}

func restore(data: Dictionary, now: float) -> bool:
	var saved_manifest: Variant = data.get("manifest")
	var saved_room: Variant = data.get("room")
	var saved_foes: Variant = data.get("foes")
	var saved_party: Variant = data.get("party")
	var saved_history: Variant = data.get("history")
	var saved_room_id := str(data.get("room_id", ""))
	if not saved_manifest is Dictionary or not saved_manifest.get("nodes") is Dictionary \
			or not saved_manifest.nodes.has(saved_room_id) or not saved_room is Dictionary \
			or not saved_room.has_all(["kind", "encounter_seed", "entry", "cover", "exit_positions"]) \
			or not saved_foes is Array or not saved_party is Dictionary or not saved_history is Array:
		return false
	for foe: Variant in saved_foes:
		if not foe is Dictionary or not foe.has_all(["x", "y", "hp", "max", "boss", "kind"]):
			return false
	var new_party := Party.new()
	if not new_party.restore(saved_party, now):
		return false
	seed = int(data.get("seed", 0))
	run_id = str(data.get("run_id", ""))
	floor_index = int(data.get("floor_index", 0))
	depth = int(data.get("depth", 0))
	route = int(data.get("route", 0))
	room_serial = int(data.get("room_serial", 0))
	room_phase = str(data.get("room_phase", "encounter"))
	room_elapsed = maxf(0.0, float(data.get("room_elapsed", 0.0)))
	terminal = str(data.get("terminal", ""))
	pending_event_encounter = str(data.get("pending_event_encounter", ""))
	var saved_awards: Variant = data.get("awards", {})
	awards = saved_awards.duplicate(true) if saved_awards is Dictionary else {}
	var saved_receipts: Variant = data.get("award_receipts", {})
	award_receipts = saved_receipts.duplicate(true) if saved_receipts is Dictionary else {}
	var saved_seen: Variant = data.get("seen_enemy_ids", {})
	seen_enemy_ids = saved_seen.duplicate() if saved_seen is Dictionary else {}
	discovery_wave = int(data.get("discovery_wave", 0))
	manifest = saved_manifest.duplicate(true)
	room_id = saved_room_id
	room = saved_room.duplicate(true)
	foes.assign(saved_foes.duplicate(true))
	history.assign(saved_history)
	party = new_party
	motion.clear()
	endless.begin_room(manifest, int(room.encounter_seed))
	endless.restore(data.get("endless", {}))
	return true

# Called after the host has advanced player and enemy combat. Every heroine
# receives her own original solo reward/event state; exits open after all
# living, connected members have finished their individual room interactions.
func tick_room(heroes: Dictionary, delta: float) -> void:
	if not terminal.is_empty():
		return
	for id: String in heroes:
		if not party.players.has(id):
			continue
		var member: Dictionary = party.players[id]
		if int(member.get("room_serial", -1)) != room_serial:
			_initialize_hero_room(id, heroes[id])
	if room_phase == "encounter":
		# The solo timed bonus starts after the room entrance animation. Keep
		# the shared timer aligned with the same point in the encounter.
		var arriving := false
		for id: String in heroes:
			var participant: Dictionary = party.players.get(id, {})
			if bool(participant.get("alive", false)) and bool(participant.get("connected", false)) \
					and not bool(participant.get("departed", false)) and float(heroes[id].game.room_arrival) > 0.0:
				arriving = true
				break
		if not arriving:
			room_elapsed += delta
		# Bosses can summon enemies after room entry. Record those discoveries for
		# every participant as well, including spectators, with a stable receipt.
		var new_discoveries: Array = []
		for foe: Dictionary in foes:
			var foe_id := int(foe.get("online_id", -1))
			if foe_id < 0 or seen_enemy_ids.has(foe_id):
				continue
			seen_enemy_ids[foe_id] = true
			var entry := {"kind": int(foe.get("kind", -1)), "biome": int(foe.get("biome", -1))}
			if foe.has("optional_boss"):
				entry.optional_boss = foe.optional_boss
			if foe.has("optional_lesson"):
				entry.optional_lesson = foe.optional_lesson
			new_discoveries.append(entry)
		if not new_discoveries.is_empty():
			discovery_wave += 1
			for id: String in heroes:
				if party.players.has(id) and not party.players[id].departed:
					queue_award(id, "seen:%d:wave:%d" % [room_serial, discovery_wave], 0, new_discoveries)
		var boss_falling := false
		if foes.is_empty():
			for id: String in heroes:
				var participant: Dictionary = party.players.get(id, {})
				if bool(participant.get("alive", false)) and bool(participant.get("connected", false)) \
						and not bool(participant.get("departed", false)) \
						and (float(heroes[id].game.boss_victory.left) > 0.0 or heroes[id].game.endless.holds_room()):
					boss_falling = true
					break
		if foes.is_empty() and not boss_falling:
			room_phase = "choices"
			for id: String in heroes:
				if party.players.has(id):
					_prepare_combat_reward(id, heroes[id])
	if room_phase != "choices":
		return
	for id: String in heroes:
		if not party.players.has(id):
			continue
		var member: Dictionary = party.players[id]
		if not member.alive or member.departed or not member.connected:
			continue
		var game = heroes[id].game
		if game.chest_open_time > 0.0:
			game.chest_open_time = maxf(0.0, game.chest_open_time - delta)
			if game.chest_open_time <= 0.0:
				game.prepare_reward_upgrades()
				game.screen = "reward"
		if game.screen == "minigame":
			game.arcade.tick(game, delta)
		member.hp = int(game.hp)
		_finish_hero_choice(member, game)
	_update_room_clear()
	if terminal == "clear":
		finish_online("clear", heroes)

func _finish_hero_choice(member: Dictionary, game) -> void:
	if not game.room_complete or game.screen == "talent":
		return
	# Solo offers a class talent when leaving each of the first two chapters.
	# Present it before the shared exit opens, independently for every heroine.
	if room.kind == "boss" and floor_index in [0, 1] and not bool(member.get("talent_presented", false)) \
			and not game.talents.offer(game.hero, game.chapter_talent_milestone()).is_empty():
		member.talent_presented = true
		member.room_done = false
		game.screen = "talent"
	else:
		member.room_done = true

func _initialize_hero_room(id: String, actor) -> void:
	var member: Dictionary = party.players[id]
	var game = actor.game
	# A room can change into an ambush without changing its map ID.
	if actor.last_room_id != room_id or game.floor_index != floor_index or str(game.room_kind) != str(room.kind):
		actor.bind_room(self)
	member.room_serial = room_serial
	game.room_complete = bool(member.get("room_done", false))
	game.screen = "fight"
	game.room_clock = 0.0
	game.pending_chest = room.kind == "treasure"
	game.chest_open_time = 0.0
	game.reward_relic_id = ""
	game.reward_weapon_id = ""
	game.merchant.reset()
	game.cap_board.reset()
	game.arcade.reset()
	RoomEvents.bind_card(game)
	game.curses.bind_altar(game)
	game.curses.enter_hostile_room(game)
	member.hp = int(game.hp)
	var charge: int = game.upgrades.enter_room(not foes.is_empty())
	if game.hero != game.GuestRoster.LUNA:
		game.resource = mini(game.HeroUltimates.CHARGE, int(game.resource) + charge)
	var discoveries: Array = []
	for foe: Dictionary in foes:
		var entry := {"kind": int(foe.get("kind", -1)), "biome": int(foe.get("biome", -1))}
		if foe.has("optional_boss"):
			entry.optional_boss = foe.optional_boss
		if foe.has("optional_lesson"):
			entry.optional_lesson = foe.optional_lesson
		discoveries.append(entry)
	queue_award(id, "seen:%d" % room_serial, 0, discoveries, [game.armory.for_hero(game.hero)], game.relics.owned)
	if game.pending_chest:
		game.reward_relic_id = RelicSources.treasure_offer(floor_index, game.hero, game.relics.owned)
		if game.reward_relic_id.is_empty():
			game.reward_weapon_id = game.reward_weapon_offer()

func _prepare_combat_reward(id: String, actor) -> void:
	var member: Dictionary = party.players[id]
	if bool(member.get("reward_given", false)) or member.departed:
		return
	var game = actor.game
	game.foes = foes
	game.room_clock = room_elapsed
	game.room_complete = false
	game.pending_chest = false
	game.screen = "fight"
	# Spectators stop advancing combat effects. An old volatile fuse cannot
	# resolve while they are dead, but should not prevent preparing their
	# personal reward if they are revived after the encounter.
	if not bool(member.alive):
		game.endless.fuses.clear()
	# Reuse the solo room economy and its character-specific weapon/relic offers.
	game.step_dungeon_room(0.0, Vector2.ZERO)
	member.reward_given = true
	if room.kind == "boss" and terminal.is_empty():
		var roll := Dungeon.stream_seed(seed, floor_index, room_id + ":" + id, "online-revive-drop")
		if posmod(roll, 5) == 0:
			member.revives = int(member.get("revives", 0)) + 1
	if game.screen == "clear":
		member.room_done = true
		member.final_clear = true

func _update_room_clear() -> void:
	var living := 0
	for member: Dictionary in party.players.values():
		if not member.alive or member.departed:
			continue
		living += 1
		if not member.connected or not bool(member.get("room_done", false)):
			return
	if living <= 0:
		return
	if not pending_event_encounter.is_empty():
		# Everyone has resolved their own event, so an encounter chosen by any
		# member can now begin without interrupting the remaining choices.
		var encounter_kind := pending_event_encounter
		var prior_history := history.duplicate()
		manifest.nodes[room_id].kind = encounter_kind
		if enter_room(room_id):
			history = prior_history
		return
	party.room_cleared = true
	room_phase = "cleared"
	if room.kind == "boss" and floor_index == Dungeon.BIOME_COUNT - 1:
		terminal = "clear"

func interact_player(id: String, heroes: Dictionary) -> bool:
	if room_phase not in ["encounter", "choices"] or not heroes.has(id) or not party.players.has(id):
		return false
	var member: Dictionary = party.players[id]
	if not member.alive or member.departed or not member.connected or bool(member.get("room_done", false)):
		return false
	if int(member.get("room_serial", -1)) != room_serial:
		_initialize_hero_room(id, heroes[id])
	var game = heroes[id].game
	if room_phase == "encounter":
		# Several optional bosses have usable arena mechanics (bells, strings,
		# and ribbons). Their interactions must reach the shared combat state.
		if game.screen != "fight":
			return false
		game.foes = foes
		game.player = member.position
		game.interact()
		member.hp = int(game.hp)
		return true
	if game.screen != "fight" or not (game.pending_chest or game.uses_room_choice()):
		return false
	var before_screen := str(game.screen)
	var before_chest := float(game.chest_open_time)
	game.interact()
	member.hp = int(game.hp)
	return before_screen != game.screen or before_chest != float(game.chest_open_time)

func tap_player(id: String, heroes: Dictionary, point: Vector2) -> bool:
	if not point.is_finite() or not Rect2(0, 0, 864, 390).has_point(point) or not heroes.has(id) or not party.players.has(id):
		return false
	var member: Dictionary = party.players[id]
	if not member.alive or member.departed or not member.connected:
		return false
	var game = heroes[id].game
	if room_phase == "encounter" and game.screen == "fight":
		# Touching a nearby optional-boss mechanism must modify the same foe
		# everyone is fighting, with the solo game's reach and tap checks.
		game.foes = foes
		game.player = member.position
		if game.optional_arena_boss() == OptionalBosses.CHOIR and OptionalBosses.mute_choir_bell(game, point):
			return true
		if game.optional_arena_boss() == OptionalBosses.VELVET and OptionalBosses.sever_velvet_string(game, point):
			return true
		return OptionalBosses.break_bride_ribbon(game, point)
	if game.screen not in ["reward", "room_choice", "forge", "minigame", "talent"]:
		return false
	if game.screen == "talent" and game.talents.milestone_resolved(game.chapter_talent_milestone()):
		# TalentView normally advances a solo dungeon directly. Online the
		# shared exit still requires a unanimous vote from the living party.
		if TalentView.PROCEED.has_point(point):
			game.screen = "fight"
			member.room_done = true
			_update_room_clear()
			return true
		return false
	# Never run the solo Luna purchase on an authority actor: it would write to
	# the host's profile. Ownership arrives from the authenticated player; a
	# stable award is delivered to that player's own profile instead.
	if game.screen == "room_choice" and game.room_kind == "shop" and not game.merchant.comparing_weapon:
		var revive_slot: int = game.merchant.REVIVE_SLOT
		if MerchantView.stock_rect(revive_slot).has_point(point):
			var offers: Array[Dictionary] = game.merchant.stock(game)
			var offer: Dictionary = offers[revive_slot]
			if offer.id == game.merchant.REVIVE_ITEM:
				if not str(offer.blocked).is_empty() or int(game.petals) < int(offer.price):
					return false
				game.petals -= int(offer.price)
				game.merchant.sold.append(str(offer.id))
				member.revives = int(member.get("revives", 0)) + 1
				game.relics.record_sale(game.room_id, game.depth, game.armory.for_hero(game.hero) == "royal_cleaver")
				return true
		var luna_slot: int = game.merchant.STOCK_COUNT
		if MerchantView.stock_rect(luna_slot).has_point(point):
			if not member.has("luna_unlocked") or bool(member.luna_unlocked) or int(game.petals) < GuestRoster.LUNA_PRICE:
				return false
			if not queue_award(id, "luna-purchase", 0, [], [], [], [GuestRoster.LUNA_UNLOCK]):
				return false
			game.petals -= GuestRoster.LUNA_PRICE
			member.luna_unlocked = true
			return true
	# The solo event handler calls Garden.enter_room(), which spawns its own
	# enemies and writes its local codex. Online there is one shared encounter
	# and each device owns its own codex, so commit the same choice here instead.
	if game.screen == "room_choice" and game.room_kind == "event":
		var choice_index: int = DungeonView.event_choice_at(point)
		var event_result: Dictionary = RoomEvents.preview(game, choice_index)
		if not event_result.is_empty() and bool(event_result.available) and not str(event_result.encounter).is_empty():
			if not str(event_result.relic).is_empty() and not game.relics.equip(event_result.relic):
				return false
			if not str(event_result.item).is_empty() and not game.pocket.take(event_result.item):
				return false
			if not str(event_result.spent_item).is_empty():
				game.pocket.held = ""
			game.hp = event_result.hp
			game.petals = event_result.petals
			game.resource = event_result.resource
			game.bonus = event_result.bonus
			if not str(event_result.relic).is_empty():
				queue_award(id, "relic:" + str(event_result.relic), 0, [], [], [str(event_result.relic)])
			member.hp = int(game.hp)
			if pending_event_encounter.is_empty():
				pending_event_encounter = str(event_result.encounter)
			game.complete_room()
			member.room_done = true
			_update_room_clear()
			return true
	var previous_kind := str(room.kind)
	var previous_weapon: String = game.armory.for_hero(game.hero)
	var previous_relics: Array = game.relics.owned.duplicate()
	game.handle_tap(point)
	var current_weapon: String = game.armory.for_hero(game.hero)
	if current_weapon != previous_weapon:
		queue_award(id, "weapon:" + current_weapon, 0, [], [current_weapon], [])
	for relic: String in game.relics.owned:
		if relic not in previous_relics:
			queue_award(id, "relic:" + relic, 0, [], [], [relic])
	member.hp = int(game.hp)
	_finish_hero_choice(member, game)
	# Some event choices turn this room into a shared combat encounter.
	var changed_kind := str(manifest.nodes[room_id].kind)
	if previous_kind == "event" and changed_kind in ["combat", "elite", "challenge", "secret"]:
		var existing_history := history.duplicate()
		if enter_room(room_id):
			history = existing_history
		return true
	_update_room_clear()
	return true

func use_pocket_player(id: String, heroes: Dictionary) -> bool:
	if not heroes.has(id) or not party.players.has(id):
		return false
	var member: Dictionary = party.players[id]
	if not member.alive or not member.connected or member.departed:
		return false
	var game = heroes[id].game
	if game.screen != "fight" or game.pocket.held.is_empty() or not game.pocket.usable(game):
		return false
	heroes[id].use_pocket(self)
	member.hp = int(game.hp)
	return true

func key_player(id: String, heroes: Dictionary, keycode: int) -> bool:
	if not heroes.has(id) or not party.players.has(id):
		return false
	var member: Dictionary = party.players[id]
	if not member.alive or not member.connected or member.departed:
		return false
	var game = heroes[id].game
	if game.screen != "minigame":
		return false
	if keycode in [KEY_ENTER, KEY_KP_ENTER] and game.arcade.outcome != "playing":
		game.arcade.settle(game)
	else:
		game.arcade.key(game, keycode)
	member.hp = int(game.hp)
	if game.room_complete:
		member.room_done = true
	_update_room_clear()
	return true

# Awards remain in the shared state until the owning device confirms durable
# local persistence. The ID is stable across reconnect and host transfer.
func queue_award(id: String, event_id: String, seeds: int, discoveries: Array = [], weapons: Array = [], relics: Array = [], unlocks: Array = []) -> bool:
	if run_id.is_empty() or not party.players.has(id) or event_id.is_empty() or seeds < 0:
		return false
	var award_id := run_id + ":" + event_id
	var player_receipts: Dictionary = award_receipts.get(id, {})
	var pending: Dictionary = awards.get(id, {})
	if player_receipts.has(award_id) or pending.has(award_id):
		return false
	pending[award_id] = {"id": award_id, "seeds": seeds, "foes": discoveries.duplicate(true),
		"weapons": weapons.duplicate(), "relics": relics.duplicate(), "unlocks": unlocks.duplicate()}
	awards[id] = pending
	return true

func acknowledge_award(id: String, award_id: String) -> bool:
	var pending: Dictionary = awards.get(id, {})
	if not pending.has(award_id):
		return false
	pending.erase(award_id)
	var receipts: Dictionary = award_receipts.get(id, {})
	receipts[award_id] = true
	award_receipts[id] = receipts
	return true

func finish_online(result: String, heroes: Dictionary) -> void:
	if result not in ["clear", "defeat", "ended"]:
		return
	terminal = result
	for id: String in heroes:
		if not party.players.has(id):
			continue
		var game = heroes[id].game
		queue_award(id, "run-finished", 1 + depth, [], [game.armory.for_hero(game.hero)], game.relics.owned)

# A voluntary departure ends only that player's participation, not the party.
func finish_player(id: String, heroes: Dictionary) -> bool:
	if not heroes.has(id) or not party.players.has(id):
		return false
	var game = heroes[id].game
	return queue_award(id, "run-finished", 1 + depth, [], [game.armory.for_hero(game.hero)], game.relics.owned)
