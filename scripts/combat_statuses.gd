extends RefCounted

const POISON = "poison"
const BLEED = "bleed"
const BURN = "burn"
const CHILL = "chill"
const ROOT = "thornbound"
const MARKED = "marked"
const GUARDBREAK = "guardbreak"
const FOE_STATE = "combat_status"
const IDS = [POISON, BLEED, BURN, CHILL, ROOT, MARKED, GUARDBREAK]
const PULSES = {POISON: 0.76, BLEED: 0.52, BURN: 0.63}
const TINTS = {
	POISON: Color("#c7e980"), BLEED: Color("#f294a8"), BURN: Color("#ffb477"),
	CHILL: Color("#a6dbff"), ROOT: Color("#93ddb2"), MARKED: Color("#ffe390"),
	GUARDBREAK: Color("#e9a8fb"),
}
const MAX_DURATION = 8.0
const FREEZE_MEMORY = 7.0

var _hero: Dictionary = {}
var _game: WeakRef


func bind(game: Node) -> void:
	_game = weakref(game)


func reset() -> void:
	_hero.clear()


func snapshot() -> Dictionary:
	return _hero.duplicate(true)


func restore(saved: Variant) -> void:
	_hero = sanitized(saved)


func restore_foes(foes: Array) -> void:
	for foe: Dictionary in foes:
		if foe.has(FOE_STATE):
			foe[FOE_STATE] = sanitized(foe[FOE_STATE])
			if foe[FOE_STATE].is_empty():
				foe.erase(FOE_STATE)


static func sanitized(saved: Variant) -> Dictionary:
	if not saved is Dictionary or saved.is_empty():
		return {}
	var restored := {}
	var effects: Variant = saved.get("effects", {})
	if effects is Dictionary:
		for id: String in IDS:
			var entry: Variant = effects.get(id)
			if not entry is Dictionary:
				continue
			var left := clampf(float(entry.get("left", 0.0)), 0.0, MAX_DURATION)
			if left <= 0.0:
				continue
			if not restored.has("effects"):
				restored.effects = {}
			var record = {"left": left, "power": clampf(float(entry.get("power", 1.0)), 0.5, 3.0),
				"source": str(entry.get("source", "")).left(48), "credit": credit_group(str(entry.get("credit", "hero")))}
			if entry.has("online_damage_owner"):
				record.online_damage_owner = str(entry.online_damage_owner).left(64)
			if PULSES.has(id):
				record.next = clampf(float(entry.get("next", PULSES[id])), 0.0, float(PULSES[id]))
			if id == CHILL:
				record.stacks = clampi(int(entry.get("stacks", 1)), 1, 5)
			restored.effects[id] = record
	var frozen := clampf(float(saved.get("frozen", 0.0)), 0.0, 0.4)
	var memory := clampf(float(saved.get("cold_memory", 0.0)), 0.0, FREEZE_MEMORY)
	if frozen > 0.0:
		restored.frozen = frozen
	if memory > 0.0:
		restored.cold_memory = memory
		restored.cold_resist = clampi(int(saved.get("cold_resist", 0)), 0, 2)
	return restored


static func name_for(id: String) -> String:
	return ROOT if id == "root" else id


static func credit_group(credit: String) -> String:
	return credit if credit in ["hero", "hazard", "enemy"] else "hazard"


func apply_hero(id: String, duration: float, potency := 1.0, source := "", credit := "enemy") -> bool:
	var game = _game.get_ref() if _game != null else null
	if game != null and (game.hp <= 0 or game.ultimates.cue_time > 0.0 or game.endless.protected_at(game.player)):
		return false
	id = name_for(id)
	if game != null and id == POISON and game.relics.has_relic("mothercap_veil"):
		duration *= 0.7
	if game != null and id == ROOT and game.relics.has_relic("thorn_veil"):
		duration *= 0.7
	return apply(_hero, id, duration, potency, source, credit, false, true)


func apply_foe(foe: Dictionary, id: String, duration: float, potency := 1.0,
		source := "", credit := "hero") -> bool:
	id = name_for(id)
	if not IDS.has(id) or not is_finite(duration) or duration <= 0.0 or not is_finite(potency):
		return false
	var game = _game.get_ref() if _game != null else null
	if not accepts_status(game, foe):
		return false
	if not foe.has(FOE_STATE):
		foe[FOE_STATE] = {}
	var applied := apply(foe[FOE_STATE], id, duration, potency, source, credit, bool(foe.get("boss", false)), false)
	# Record the player who most recently applied the effect so later status
	# pulses are credited to its source rather than the enemy's current target.
	if applied and game != null and game.has_meta("online_player_id") and credit_group(credit) == "hero":
		var entry: Dictionary = entry_of(foe[FOE_STATE], id)
		if not entry.is_empty():
			entry.online_damage_owner = str(game.get_meta("online_player_id")).left(64)
	return applied


static func accepts_status(game, foe: Dictionary) -> bool:
	if int(foe.get("hp", 0)) <= 0 or foe.get("web_anchor", false) or foe.get("flower_node", false):
		return false
	if game == null:
		return true
	if game.ultimates.cue_time > 0.0 or game.endless.protected_at(game.target(foe)):
		return false
	# This gate is pure. Melee defense can alter stances or consume protection on contact.
	var core_boss := bool(foe.get("boss", false)) and int(foe.get("biome", game.active_biome)) == int(game.AstralCore.CORE)
	return not core_boss or (foe.get("nodes_spawned", false) and game.AstralCore.shield_lives(game) == 0)


static func apply(state: Dictionary, id: String, duration: float, potency: float, source: String,
		credit: String, boss: bool, hero: bool) -> bool:
	if not IDS.has(id) or not is_finite(duration) or duration <= 0.0 or not is_finite(potency):
		return false
	potency = clampf(potency, 0.5, 3.0)
	var left := clampf(duration, 0.0, MAX_DURATION)
	if boss and id == ROOT:
		left = minf(left, 1.25)
	if not state.has("effects"):
		state.effects = {}
	var effects: Dictionary = state.effects
	var entry: Dictionary = effects.get(id, {})
	if entry.is_empty():
		entry = {"left": left, "power": potency, "source": source.left(48), "credit": credit_group(credit)}
		effects[id] = entry
		if PULSES.has(id):
			entry.next = float(PULSES[id])
	else:
		entry.left = maxf(float(entry.left), left)
		# A weaker refresh keeps both the existing pulse schedule and its credit.
		if potency > float(entry.power):
			entry.power = potency
			entry.source = source.left(48)
			entry.credit = credit_group(credit)
	if id == CHILL and float(state.get("frozen", 0.0)) <= 0.0:
		entry.stacks = mini(5, int(entry.get("stacks", 0)) + 1)
		var resistance := int(state.get("cold_resist", 0))
		if not boss and int(entry.stacks) >= 3 + resistance:
			state.frozen = 0.28 if hero else 0.38
			entry.left = maxf(float(entry.left), float(state.frozen))
			state.cold_memory = FREEZE_MEMORY
			state.cold_resist = mini(2, resistance + 1)
			entry.stacks = 1
	return true


static func effects_of(state: Dictionary) -> Dictionary:
	return state.get("effects", {})


static func entry_of(state: Dictionary, id: String) -> Dictionary:
	return effects_of(state).get(id, {})


static func foe_state(foe: Dictionary) -> Dictionary:
	return foe.get(FOE_STATE, {})


func has_hero(id: String) -> bool:
	return not entry_of(_hero, name_for(id)).is_empty()


static func has_foe(foe: Dictionary, id: String) -> bool:
	id = name_for(id)
	return not entry_of(foe_state(foe), id).is_empty() or (id == MARKED and float(foe.get("camellia_mark", 0.0)) > 0.0)


func cleanse_hero(id: String) -> bool:
	id = name_for(id)
	if id == CHILL:
		_hero.erase("frozen")
	var removed := erase_effect(_hero, id)
	if id == ROOT and _game != null:
		var game = _game.get_ref()
		if game != null and game.ground_hazards.snare_time > 0.0:
			game.ground_hazards.snare_time = 0.0
			removed = true
	return removed


func cleanse_foe(foe: Dictionary, id: String) -> bool:
	id = name_for(id)
	var state := foe_state(foe)
	if id == CHILL:
		state.erase("frozen")
	var removed := erase_effect(state, id)
	if id == MARKED:
		removed = foe.erase("camellia_mark") or removed
	return removed


static func erase_effect(state: Dictionary, id: String) -> bool:
	var effects := effects_of(state)
	var removed := effects.erase(id)
	if effects.is_empty():
		state.erase("effects")
	return removed


static func precision_mark_bonus(foe: Dictionary) -> int:
	var mark := entry_of(foe_state(foe), MARKED)
	if mark.is_empty():
		return 0
	return mini(9 if foe.get("boss", false) else 15, roundi(float(mark.power) * 5.0))


func consume_foe_mark(foe: Dictionary) -> int:
	var amount := precision_mark_bonus(foe)
	if amount > 0:
		cleanse_foe(foe, MARKED)
	return amount


func hero_healing(amount: int) -> int:
	return scaled_healing(amount, has_hero(POISON))


static func foe_healing(foe: Dictionary, amount: int) -> int:
	return scaled_healing(amount, has_foe(foe, POISON))


static func scaled_healing(amount: int, poisoned: bool) -> int:
	return maxi(1, floori(float(amount) * 0.80)) if poisoned and amount > 0 else amount


static func guarded_damage(foe: Dictionary, normal: int, blocked: int) -> int:
	if blocked <= 0 or normal - blocked < 2 or not has_foe(foe, GUARDBREAK):
		return blocked
	return mini(normal - 1, blocked + maxi(1, roundi(float(normal - blocked) * 0.42)))


func hero_movement_scale() -> float:
	return movement_scale(_hero, false)


static func foe_movement_scale(foe: Dictionary) -> float:
	return movement_scale(foe_state(foe), bool(foe.get("boss", false)))


static func movement_scale(state: Dictionary, boss: bool) -> float:
	if float(state.get("frozen", 0.0)) > 0.0:
		return 0.0
	var chill := entry_of(state, CHILL)
	var cold := 1.0 - 0.10 * int(chill.get("stacks", 0))
	var rooted := not entry_of(state, ROOT).is_empty()
	return maxf(0.82 if boss else 0.0, minf(cold, 0.38 if rooted else 1.0))


func tick_hero(game, delta: float, moving_or_attacking: bool) -> void:
	if _hero.is_empty():
		return
	advance_clocks(_hero, delta)
	for id: String in IDS:
		var result := advance_effect(_hero, id, delta, moving_or_attacking)
		if int(result.get("damage", 0)) > 0:
			game.damage_hero_from_status(int(result.damage))


func tick_foe(game, foe: Dictionary, delta: float, moving_or_attacking: bool) -> void:
	var state := foe_state(foe)
	if state.is_empty():
		return
	advance_clocks(state, delta)
	for id: String in IDS:
		var owner := str(entry_of(state, id).get("online_damage_owner", ""))
		var result := advance_effect(state, id, delta, moving_or_attacking)
		var damage := int(result.get("damage", 0))
		if damage <= 0 or not accepts_status(game, foe):
			continue
		if foe.get("boss", false):
			damage = mini(damage, 6)
		if float(foe.get("ward_time", 0.0)) > 0.0:
			damage = maxi(1, ceili(float(damage) * 0.42))
		if foe.has("bloomheart_phase"):
			damage = game.AstralCore.capstone_damage(foe, damage)
		# Status pulses have no hit procs, knockback, flinch, stun or meter gain.
		var previous_health := maxi(0, int(foe.hp))
		foe.hp = maxi(0, int(foe.hp) - damage)
		if not owner.is_empty() and str(result.get("credit", "")) == "hero":
			var totals: Dictionary = foe.get("online_status_damage", {})
			totals[owner] = int(totals.get(owner, 0)) + previous_health - int(foe.hp)
			foe.online_status_damage = totals
		if int(foe.hp) <= 0:
			foe.status_kill = {"effect": id, "credit": result.credit, "source": result.source}
			break
	if state.is_empty():
		foe.erase(FOE_STATE)


static func advance_clocks(state: Dictionary, delta: float) -> void:
	if state.has("frozen"):
		state.frozen = maxf(0.0, float(state.frozen) - delta)
		if float(state.frozen) == 0.0:
			state.erase("frozen")
	if state.has("cold_memory"):
		state.cold_memory = maxf(0.0, float(state.cold_memory) - delta)
		if float(state.cold_memory) == 0.0:
			state.erase("cold_memory")
			state.erase("cold_resist")


static func advance_effect(state: Dictionary, id: String, delta: float, moving_or_attacking: bool) -> Dictionary:
	var entry := entry_of(state, id)
	if entry.is_empty() or delta <= 0.0:
		return {}
	var prior := float(entry.left)
	var elapsed := minf(prior, delta)
	entry.left = maxf(0.0, prior - delta)
	var result := {}
	if PULSES.has(id):
		entry.next = float(entry.next) - elapsed
		if float(entry.next) <= 0.0001:
			var interval := float(PULSES[id])
			var pulses := maxi(1, 1 + floori(-float(entry.next) / interval))
			entry.next = maxf(0.0001, float(entry.next) + pulses * interval)
			if id != BLEED or moving_or_attacking:
				var base := 3.0 if id == BURN else 2.0
				result = {"damage": maxi(1, roundi(base * float(entry.power))) * mini(4, pulses),
					"source": entry.source, "credit": entry.credit}
	if float(entry.left) <= 0.0:
		erase_effect(state, id)
	return result


func draw(game) -> void:
	var canvas: Node2D = game.world_canvas
	draw_icons(canvas, _hero, game.player + Vector2(0, 17), 1.0)
	for foe: Dictionary in game.foes:
		if int(foe.hp) > 0 and foe.has(FOE_STATE):
			draw_icons(canvas, foe_state(foe), game.target(foe) + Vector2(0, 17), 0.84)


static func draw_icons(canvas: Node2D, state: Dictionary, center: Vector2, opacity: float) -> void:
	var effects := effects_of(state)
	if effects.is_empty():
		return
	var origin := center - Vector2((effects.size() - 1) * 4.5, 0.0)
	for id: String in IDS:
		if not effects.has(id):
			continue
		draw_icon(canvas, id, origin, opacity)
		origin.x += 9.0


static func draw_icon(canvas: Node2D, id: String, point: Vector2, opacity: float) -> void:
	var tint := Color(TINTS[id], opacity)
	canvas.draw_circle(point, 4.5, Color(0.11, 0.08, 0.16, opacity * 0.92), true, -1.0, true)
	match id:
		POISON:
			canvas.draw_circle(point + Vector2(0, -0.8), 1.8, tint, true, -1.0, true)
			canvas.draw_circle(point + Vector2(1.5, 1.7), 0.8, tint, true, -1.0, true)
		BLEED, BURN:
			canvas.draw_colored_polygon(PackedVector2Array([point + Vector2(0, -3), point + Vector2(2.5, 1.3),
				point + Vector2(0, 2.7), point + Vector2(-2.5, 1.3)]), tint)
			if id == BURN:
				canvas.draw_line(point, point + Vector2(1, 2), Color("#fff1b1"), 1.05, true)
		CHILL:
			for angle: float in [0.0, PI / 3.0, PI * 2.0 / 3.0]:
				var axis := Vector2.from_angle(angle) * 3.0
				canvas.draw_line(point - axis, point + axis, tint, 1.0, true)
		ROOT:
			canvas.draw_polyline(PackedVector2Array([point + Vector2(-3, 1), point + Vector2(-1, -2.5),
				point + Vector2(1.0, 2.5), point + Vector2(3, -1)]), tint, 1.1, true)
		MARKED:
			canvas.draw_arc(point, 2.7, 0.0, TAU, 15, tint, 1.0, true)
			canvas.draw_circle(point, 0.9, tint, true, -1.0, true)
		GUARDBREAK:
			canvas.draw_polyline(PackedVector2Array([point + Vector2(-2, -2), point + Vector2(2, -2),
				point + Vector2(0, 2.7), point + Vector2(-2, -2)]), tint, 1.05, true)
