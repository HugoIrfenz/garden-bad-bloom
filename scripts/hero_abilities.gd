extends RefCounted

const Statuses = preload("res://scripts/combat_statuses.gd")
const Talents = preload("res://scripts/run_talents.gd")
const Elegy = preload("res://scripts/elegy_magic.gd")

const Encounters = preload("res://scripts/forgotten_encounters.gd")
const Relics = preload("res://scripts/relic_effects.gd")
const Visuals = preload("res://scripts/hero_combat_visuals.gd")
const THORNMAIL_COUNT = 5
const THORNMAIL_SPREAD = 0.14
const THORNMAIL_DAMAGE = 6
const THORNMAIL_SPEED = 460.0
const THORNMAIL_LIFE = 0.42
const ROSEWALL_THORNS = 7
const ROSEWALL_THORN_POWER = 8
const ROSEWALL_RADIUS = 88.0
const ROSEWALL_BLOOM_TIME = 0.36
const LEDGER_RADIUS = 58.0
const REFLECTION_POWER = 0.55
const REFLECTION_LIFE = 0.94
const BOUQUET_ARM_TIME = 0.17
const BOUQUET_LIFE = 2.25
const BOUQUET_RADIUS = 24.0
const BOUQUET_DAMAGE = 11
const GUARD_DURATION = 0.90
const GUARD_UNUSED_RECHARGE = 1.0
const GUARD_ABSORB_RECHARGE = 5.0
const PERFECT_WINDOW = 0.24
const VERSE_WINDUP = 0.59
const VERSE_RADIUS = 49.0
const FROST_RADIUS := 53.0
const FROST_RECHARGE := 3.6
const FROST_VISUAL_TIME := 0.52
const LEAP_DURATION = 0.22
const LEAP_REACH = 84.0
const LEAP_CONE = 64.0
const SNARE_ARM_TIME = 0.22
const SNARE_RADIUS = 37.0
const SNARE_LIFETIME = 4.6
const PAINT_LIFETIME = 1.65
const PAINT_HALF_WIDTH = 19.0
const COOLDOWNS = [GUARD_UNUSED_RECHARGE, 2.30, 3.0, 3.65, 2.04, 0.0, 0.0]

static func cooldown_for(hero: int) -> float:
	return COOLDOWNS[clampi(hero, 0, COOLDOWNS.size() - 1)]

static func cooldown_for_game(game) -> float:
	if int(game.hero) == 0:
		var abilities = game.get("abilities")
		return abilities.guard_recharge() if abilities != null else GUARD_UNUSED_RECHARGE
	var cooldown := cooldown_for(int(game.hero)) + (Elegy.RECHARGE_COST if Elegy.has_refrain(game) else 0.0)
	var relics = game.get("relics")
	if int(game.hero) == 2 and relics != null and relics.has_relic(Relics.ORCHID_SPRING):
		cooldown *= 0.8
	return cooldown

static func ranged_skill_landmark(game, hero: int) -> Vector2:
	var ranger := hero == 3
	var origin: Vector2 = game.player
	var aim: Vector2 = game.assisted_aim(182.0 if ranger else 111.0, ranger)
	var direction: Vector2 = origin.direction_to(aim) if aim.is_finite() else game.facing.normalized()
	if direction.is_zero_approx():
		direction = Vector2.UP
	var distance := origin.distance_to(aim) if aim.is_finite() else (104.0 if ranger else 72.0)
	return Encounters.clear_endpoint(game, origin, direction, distance, 24.0 if ranger else 17.0)

var _effect: Dictionary = {}
var _guard_absorbed := false
var _relic_bolts: Array[Dictionary] = []
var _iron_bouquets: Array[Dictionary] = []
var _elegy := Elegy.new()
var _frost: Dictionary = {}
var _counter_left := 0.0
var _cast_serial := 0
var _rosewall_center := Vector2.ZERO
var _rosewall_bloom := 0.0

func reset() -> void:
	_effect.clear()
	_guard_absorbed = false
	_relic_bolts.clear()
	_iron_bouquets.clear()
	_elegy.reset()
	_frost.clear()
	_counter_left = 0.0
	_cast_serial = 0
	_rosewall_bloom = 0.0

func snapshot() -> Dictionary:
	return {"effect": _effect.duplicate(true), "counter": _counter_left, "serial": _cast_serial,
		"guard_absorbed": _guard_absorbed,
		"relic_bolts": _relic_bolts.duplicate(true), "iron_bouquets": _iron_bouquets.duplicate(true),
		"elegy_magic": _elegy.snapshot(), "frost": _frost.duplicate()}

func restore(data: Dictionary) -> void:
	var effect: Variant = data.get("effect", {})
	_effect = effect.duplicate(true) if effect is Dictionary else {}
	_guard_absorbed = bool(data.get("guard_absorbed", false))
	_counter_left = maxf(0.0, float(data.get("counter", 0.0)))
	_cast_serial = maxi(0, int(data.get("serial", 0)))
	_rosewall_bloom = 0.0
	_relic_bolts = restore_effects(data.get("relic_bolts", data.get("thorn_bolts", [])),
		["x", "y", "dx", "dy", "life"])
	_iron_bouquets = restore_effects(data.get("iron_bouquets", []), ["x", "y", "age"])
	_elegy.restore(data.get("elegy_magic"))
	_frost = data.get("frost", {}).duplicate()

static func restore_effects(saved: Variant, fields: Array) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if saved is Array:
		for effect in saved:
			if effect is Dictionary and effect.has_all(fields):
				effects.append(effect.duplicate())
	return effects

func locks_movement() -> bool:
	return _effect.get("kind", "") == "leap"

func active_verse_zone() -> Vector2:
	if _effect.get("kind", "") in ["verse", "verse_bloom"]:
		return effect_position()
	return Vector2.INF

func take_paint_trail() -> Array[Vector2]:
	if _effect.get("kind", "") != "paint":
		return []
	var trail: Array[Vector2] = [effect_position(), Vector2(_effect.ex, _effect.ey)]
	_effect.clear()
	return trail

func elevation() -> float:
	if not locks_movement():
		return 0.0
	var progress := clampf(1.0 - float(_effect.time) / LEAP_DURATION, 0.0, 1.0)
	return sin(PI * progress) * 22.0

func action_pose() -> Dictionary:
	if not _frost.is_empty() and float(_frost.left) > FROST_VISUAL_TIME - 0.25:
		return {"direction": Vector2(_frost.dx, _frost.dy),
			"phase": (FROST_VISUAL_TIME - float(_frost.left)) / 0.25, "skill": true, "impact": 0.0}
	if _effect.is_empty():
		return {}
	var time := float(_effect.time)
	var phase := 0.0
	var skill := true
	match str(_effect.kind):
		"guard":
			phase = 1.0 - time / guard_stance_duration()
		"verse":
			phase = 0.63 * (1.0 - time / VERSE_WINDUP)
		"verse_bloom":
			phase = 0.66 + 0.34 * (1.0 - time / 0.31)
		"leap":
			phase = 1.0 - time / LEAP_DURATION
		"followup":
			phase = 0.55 + 0.45 * (1.0 - time / 0.18)
		"leap_impact":
			if not bool(_effect.get("finishing_strike", false)):
				return {}
			phase = 1.0 - time / 0.23
			skill = false
		"snare":
			if time < SNARE_LIFETIME - 0.28:
				return {}
			phase = (SNARE_LIFETIME - time) / 0.28
		"paint":
			if time < PAINT_LIFETIME - 0.26:
				return {}
			phase = (PAINT_LIFETIME - time) / 0.26
		_:
			return {}
	return {"direction": effect_direction(), "phase": clampf(phase, 0.0, 1.0), "skill": skill,
		"impact": clampf(float(_effect.get("guard_impact", 0.0)) / 0.18, 0.0, 1.0)}

func cast_frost(game) -> void:
	var center: Vector2 = ranged_skill_landmark(game, 1)
	var origin: Vector2 = game.player
	var heading := origin.direction_to(center)
	_frost = {"x": center.x, "y": center.y, "dx": heading.x, "dy": heading.y, "left": FROST_VISUAL_TIME}
	for foe: Dictionary in game.foes:
		var point: Vector2 = game.target(foe)
		if center.distance_to(point) <= FROST_RADIUS and not Encounters.blocked(game, center, point, 13.0):
			if hero_hit(game, foe, 5 + int(game.bonus / 3.0)):
				game.combat_status.apply_foe(foe, Statuses.CHILL, 1.7, 1.0, "winter_verse")
				stun_foe(foe, 0.90)
	game.dodge_time = game.dodge_cooldown()
	game.sound.play("vivianne", 1.28)
	game.checkpoint.call_deferred()

func cast(game) -> bool:
	if game.skill_time > 0.0 or locks_movement() or guard_remaining() > 0.0 \
			or (game.hero != 0 and game.dash_remaining > 0.0):
		return false
	var origin: Vector2 = game.player
	var direction: Vector2 = game.facing.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	var strength := clampi(int(game.resource), 0, 5)
	var refund := 0
	match int(game.hero):
		0:
			_guard_absorbed = false
			_effect = directed_effect("guard", GUARD_DURATION, origin, direction, strength)
			_effect.duration = GUARD_DURATION
			game.skill_time = GUARD_UNUSED_RECHARGE
			return true
		1:
			var center := ranged_skill_landmark(game, 1)
			if not center.is_equal_approx(origin):
				direction = origin.direction_to(center)
			_effect = directed_effect("verse", VERSE_WINDUP, center, direction, strength)
			var talents = game.get("talents")
			if talents != null:
				_effect.talent_power = talents.take_quiet_power()
			_effect.refrain = Elegy.has_refrain(game)
			_effect.ink = Elegy.has_ink(game)
			_effect.evolved = Elegy.is_evolved(game)
			game.skill_time = cooldown_for_game(game)
		2:
			_cast_serial += 1
			_effect = directed_effect("leap", LEAP_DURATION, origin, direction, strength)
			_effect.chain_id = _cast_serial
			game.skill_time = 0.0
			var orchid = orchid_state(game)
			if orchid != null:
				refund = orchid.take_refund(game, strength)
		3:
			var destination := Encounters.clear_endpoint(game, origin, direction, 100.0, game.BARREL_CLEARANCE)
			if destination.distance_to(origin) < 8.0:
				return false
			game.dash_remaining = 0.18
			game.dash_vector = origin.direction_to(destination) * origin.distance_to(destination) / game.dash_remaining
			game.dash_evaded = false
			game.mercy = maxf(float(game.mercy), 0.225)
			game.skill_time = cooldown_for(3)
			var thread = game.get("snare_thread")
			if thread != null:
				thread.pin_skill(game, destination)
			var talents = game.get("talents")
			if talents != null:
				talents.arm_snare_bloom(destination)
			_effect.clear()
		4:
			var destination := Encounters.clear_endpoint(game, origin, direction, 120.0, game.BARREL_CLEARANCE)
			if destination.distance_to(origin) < 8.0:
				return false
			_cast_serial += 1
			_effect = directed_effect("paint", PAINT_LIFETIME, origin, direction, strength)
			_effect.ex = destination.x
			_effect.ey = destination.y
			game.player = destination
			game.mercy = maxf(float(game.mercy), 0.11)
			for foe in game.foes:
				var target: Vector2 = game.target(foe)
				if Encounters.segment_gap(target, origin, destination) <= PAINT_HALF_WIDTH and not Encounters.blocked(game, destination, target, 15.0):
					hero_hit(game, foe, 14 + 2 * strength + game.bonus)
			game.skill_time = cooldown_for(4)
		_:
			return false
	game.resource = refund
	if refund > 0:
		game.checkpoint.call_deferred()
	return true

static func orchid_state(game):
	if int(game.hero) != 2:
		return null
	var relics = game.get("relics")
	return relics.orchid if relics != null else null

func note_orchid_input(game, sequence: int) -> void:
	var orchid = orchid_state(game)
	if orchid != null:
		orchid.note_input(game, sequence)

func note_orchid_hit(game, foe: Dictionary, sequence: int) -> void:
	var orchid = orchid_state(game)
	if orchid != null and orchid.note_hit(game, foe, sequence, hero_hit):
		game.checkpoint.call_deferred()

func take_orchid_overclock(game) -> bool:
	var orchid = orchid_state(game)
	return orchid != null and orchid.take_overclock(game)

func try_parry(game, source: Vector2, damage := 0, projectile: Dictionary = {}) -> bool:
	if game.hero != 0 or guard_remaining() <= 0.0:
		return false
	var toward_source: Vector2 = game.player.direction_to(source) if source.is_finite() else Vector2.ZERO
	if toward_source.is_zero_approx():
		toward_source = effect_direction()
	var perfect := guard_is_perfect()
	var relics = game.get("relics")
	var should_save := not bool(_effect.get("absorbed", false))
	if should_save:
		_effect.absorbed = true
		_guard_absorbed = true
		game.skill_time = GUARD_ABSORB_RECHARGE
		if relics != null:
			game.skill_time *= relics.skill_cooldown_factor()
	if float(_effect.get("guard_impact", 0.0)) <= 0.10:
		var sound = game.get("sound")
		if sound != null:
			sound.play("guard", 1.0)
		_effect.guard_impact = 0.18
		_effect.guard_impact_angle = toward_source.angle()
	if perfect:
		if not bool(_effect.get("perfect_rewarded", _effect.get("rewarded", false))):
			_effect.perfect_rewarded = true
			_counter_left = 1.28
			var resolve_gain := 1 if _effect.get("ordinary_rewarded", false) else 2
			game.resource = mini(5, int(game.resource) + resolve_gain)
			var talents = game.get("talents")
			if talents != null and talents.perfect_guard():
				should_save = true
			if relics:
				_effect.ledger_triggered = true
				var armory = game.get("armory")
				var evolved: bool = armory != null and armory.for_hero(0) == Relics.ROSEWALL_EXECUTION
				should_save = relics.on_royal_guard(true, evolved) or should_save
				if evolved or relics.has_relic(Relics.THORNMAIL):
					launch_thornmail(game.player, toward_source, evolved)
					should_save = true
		if damage > 0 and relics and relics.has_relic(Relics.COUNTERCLOCK_LOCKET) and not bool(_effect.get("reflected", false)):
			should_save = reflect_projectile(game, projectile, damage, relics.iron_bouquet_active()) or should_save
	else:
		if not bool(_effect.get("ordinary_rewarded", _effect.get("rewarded", false))) and not bool(_effect.get("perfect_rewarded", false)):
			_effect.ordinary_rewarded = true
			game.resource = mini(5, int(game.resource) + 1)
		if relics and not bool(_effect.get("ledger_triggered", false)):
			_effect.ledger_triggered = true
			should_save = relics.on_royal_guard(false) or should_save
	if should_save and game.has_method("checkpoint"):
		game.checkpoint.call_deferred()
	return true

func guard_remaining() -> float:
	return float(_effect.time) if _effect.get("kind", "") == "guard" else 0.0

func guard_is_perfect() -> bool:
	var left := guard_remaining()
	return left > 0.0 and left >= guard_stance_duration() - PERFECT_WINDOW

func guard_recharge() -> float:
	return GUARD_ABSORB_RECHARGE if _guard_absorbed else GUARD_UNUSED_RECHARGE

func guard_stance_duration() -> float:
	return maxf(0.01, float(_effect.get("duration", 0.42)))

func launch_thornmail(origin: Vector2, direction: Vector2, rosewall := false) -> void:
	var count := ROSEWALL_THORNS if rosewall else THORNMAIL_COUNT
	for i in range(count):
		var angle = (i - (count - 1) * 0.5) * THORNMAIL_SPREAD
		var thorn := direction.rotated(angle)
		var bolt := {"x": origin.x, "y": origin.y, "dx": thorn.x, "dy": thorn.y, "life": THORNMAIL_LIFE}
		if rosewall:
			bolt.power = ROSEWALL_THORN_POWER
			bolt.rosewall = true
		_relic_bolts.append(bolt)

func resolve_guard_followthrough(game, anchor: Vector2, struck: PackedInt32Array, power: int, rosewall: bool) -> void:
	var radius := ROSEWALL_RADIUS if rosewall else LEDGER_RADIUS
	var closest := radius * radius
	var adjacent: Dictionary = {}
	if rosewall:
		_rosewall_center = anchor
		_rosewall_bloom = ROSEWALL_BLOOM_TIME
	for index in range(game.foes.size()):
		var foe: Dictionary = game.foes[index]
		if index in struck or int(foe.hp) <= 0:
			continue
		var point: Vector2 = game.target(foe)
		var distance := anchor.distance_squared_to(point)
		if distance > closest or Encounters.blocked(game, anchor, point, 14.0):
			continue
		if rosewall:
			hero_hit(game, foe, maxi(1, roundi(power * 0.72)))
		else:
			closest = distance
			adjacent = foe
	if not adjacent.is_empty() and hero_hit(game, adjacent, maxi(1, power)):
		game.armory.add_trace("ribbon", anchor, game.target(adjacent), Color("#f7d895"))

func reflect_projectile(game, projectile: Dictionary, damage: int, plants_bouquet: bool) -> bool:
	if projectile.is_empty() or not projectile.has_all(["dx", "dy", "damage"]) or projectile.get("terrain", false):
		return false
	var direction := -Vector2(projectile.dx, projectile.dy).normalized()
	if direction == Vector2.ZERO:
		return false
	_effect.reflected = true
	var point: Vector2 = game.player
	var speed := clampf(float(projectile.get("speed", 408.0)) * 1.2, 260.0, 540.0)
	# A reflected shot lives only in the friendly relic list. It never re-enters
	# the hostile projectile loop or any on-strike and parry triggers.
	_relic_bolts.append({"x": point.x, "y": point.y, "dx": direction.x, "dy": direction.y,
		"life": REFLECTION_LIFE, "speed": speed, "power": maxi(1, floori(damage * REFLECTION_POWER)),
		"reflected": true, "plants_bouquet": plants_bouquet})
	return true

func tick_relic_bolts(game, delta: float) -> void:
	for index in range(_relic_bolts.size() - 1, -1, -1):
		var bolt := _relic_bolts[index]
		var start := Vector2(bolt.x, bolt.y)
		var direction := Vector2(bolt.dx, bolt.dy)
		var reach := float(bolt.get("speed", THORNMAIL_SPEED)) * minf(delta, float(bolt.life))
		var end := Encounters.clear_endpoint(game, start, direction, reach, 15.0)
		var target := first_relic_target(game, start, end, direction)
		bolt.life = float(bolt.life) - delta
		var landed := float(bolt.life) <= 0.0 or end.distance_to(start) + 1.0 < reach
		if not target.is_empty():
			var point: Vector2 = game.target(target)
			if start != end:
				end = Geometry2D.get_closest_point_to_segment(point, start, end)
			hero_hit(game, target, int(bolt.get("power", THORNMAIL_DAMAGE)))
			landed = true
		if landed:
			if bolt.get("plants_bouquet", false):
				_iron_bouquets.append({"x": end.x, "y": end.y, "age": 0.0, "spent": false})
			_relic_bolts.remove_at(index)
		else:
			bolt.x = end.x
			bolt.y = end.y

static func first_relic_target(game, start: Vector2, end: Vector2, direction: Vector2) -> Dictionary:
	var closest: Dictionary = {}
	var best_distance := start.distance_to(end) + 15.0
	for foe: Dictionary in game.foes:
		if int(foe.hp) <= 0:
			continue
		var point: Vector2 = game.target(foe)
		var forward := (point - start).dot(direction)
		if forward < -4.0 or forward >= best_distance or Encounters.segment_gap(point, start, end) > 14.0:
			continue
		if Encounters.blocked(game, start, point, 15.0):
			continue
		closest = foe
		best_distance = forward
	return closest

func tick_iron_bouquets(game, delta: float) -> void:
	for index in range(_iron_bouquets.size() - 1, -1, -1):
		var patch := _iron_bouquets[index]
		patch.age = float(patch.age) + delta
		if float(patch.age) >= BOUQUET_LIFE:
			_iron_bouquets.remove_at(index)
		elif float(patch.age) >= BOUQUET_ARM_TIME and not patch.spent:
			var center := Vector2(patch.x, patch.y)
			for foe: Dictionary in game.foes:
				var point: Vector2 = game.target(foe)
				if point.distance_squared_to(center) <= BOUQUET_RADIUS * BOUQUET_RADIUS and not Encounters.blocked(game, center, point, 10.0):
					if hero_hit(game, foe, BOUQUET_DAMAGE):
						patch.spent = true
						patch.age = maxf(float(patch.age), BOUQUET_LIFE - 0.15)
						break

func counter_bonus(game, foe: Dictionary) -> int:
	if _counter_left <= 0.0 or game.hero != 0 or int(foe.hp) <= 0:
		return 0
	_counter_left = 0.0
	var strength := clampi(int(game.resource), 0, 5)
	game.resource = 0
	return 10 + strength * 2

static func consume_stun(foe: Dictionary, delta: float) -> bool:
	var time := float(foe.get("hero_stun", 0.0))
	if time <= 0.0:
		return false
	foe.hero_stun = maxf(0.0, time - delta)
	return true

func tick_guard(delta: float) -> void:
	if guard_remaining() <= 0.0:
		return
	_effect.time = maxf(0.0, float(_effect.time) - delta)
	_effect.guard_impact = maxf(0.0, float(_effect.get("guard_impact", 0.0)) - delta)
	if float(_effect.time) <= 0.0:
		_effect.clear()

func tick(game, delta: float, advance_guard := true) -> void:
	if not _frost.is_empty():
		_frost.left = float(_frost.left) - delta
		if _frost.left <= 0.0:
			_frost.clear()
	var orchid = orchid_state(game)
	if orchid != null:
		orchid.tick(game, delta)
	_elegy.tick(game, delta, hero_hit)
	tick_iron_bouquets(game, delta)
	tick_relic_bolts(game, delta)
	_rosewall_bloom = maxf(0.0, _rosewall_bloom - delta)
	_counter_left = maxf(0.0, _counter_left - delta)
	if _effect.is_empty():
		return
	if _effect.get("kind", "") == "guard":
		if advance_guard:
			tick_guard(delta)
		return
	var before := float(_effect.time)
	_effect.time = maxf(0.0, before - delta)
	match str(_effect.kind):
		"verse":
			if float(_effect.time) <= 0.0:
				resolve_verse(game)
				return
		"leap":
			var travel := LEAP_REACH / LEAP_DURATION * minf(delta, before)
			game.player = Encounters.clear_endpoint(game, game.player, effect_direction(), travel, game.BARREL_CLEARANCE)
			if float(_effect.time) <= 0.0:
				resolve_leap(game)
				return
		"followup":
			if float(_effect.time) <= 0.0:
				resolve_followup(game)
				return
		"snare":
			if float(_effect.time) > 0.0 and float(_effect.time) <= SNARE_LIFETIME - SNARE_ARM_TIME:
				resolve_snare(game)
		"paint":
			if float(_effect.time) > 0.0:
				resolve_paint(game)
	if float(_effect.time) <= 0.0:
		_effect.clear()

func resolve_verse(game) -> void:
	var center := effect_position()
	var amount := 20 + int(_effect.strength) * 4 + int(game.bonus) + int(_effect.get("talent_power", 0))
	for foe in game.foes:
		var point: Vector2 = game.target(foe)
		if point.distance_to(center) <= VERSE_RADIUS and not Encounters.blocked(game, center, point, 12.0):
			hero_hit(game, foe, amount)
	_elegy.verse_lands(game, center, amount, bool(_effect.get("refrain", false)),
		bool(_effect.get("ink", false)), bool(_effect.get("evolved", false)))
	_effect.kind = "verse_bloom"
	_effect.time = 0.31

func note_elegy_hit(game, center: Vector2, sequence: int) -> void:
	_elegy.note_basic_hit(game, center, sequence)

func note_elegy_crescendo(game, center: Vector2) -> void:
	_elegy.spell_trace(game, center)

func buffer_leap() -> void:
	if _effect.get("kind", "") == "leap" and float(_effect.time) <= 0.13:
		_effect.recast = true

func resolve_leap(game) -> void:
	var center: Vector2 = game.player
	var direction := effect_direction()
	var hit := false
	var splash_hit := false
	var talents = game.get("talents")
	var meteor: bool = talents != null and talents.owns(Talents.POCKET_METEOR) and int(_effect.strength) >= 3
	for foe in game.foes:
		if within_cone(game, foe, center, direction, LEAP_CONE, 0.54):
			if hero_hit(game, foe, 12 + int(_effect.strength) * 2 + int(game.bonus)):
				stun_foe(foe, 0.58)
				if not hit:
					foe.nixia_chain_id = int(_effect.get("chain_id", -1))
				hit = true
		elif meteor:
			var point: Vector2 = game.target(foe)
			if point.distance_squared_to(center) <= Talents.METEOR_RADIUS * Talents.METEOR_RADIUS \
					and not Encounters.blocked(game, center, point, 12.0) and hero_hit(game, foe, 7):
				stun_foe(foe, 0.38)
				splash_hit = true
	if meteor:
		talents.record_meteor(center)
	game.skill_time = 0.0 if hit or splash_hit else game.skill_cooldown()
	_effect.x = center.x
	_effect.y = center.y
	_effect.kind = "followup" if hit else "leap_impact"
	_effect.chain_hits = 1
	_effect.time = 0.18 if hit else 0.20
	if (hit or splash_hit) and bool(_effect.get("recast", false)):
		game.act.call_deferred("skill")

func resolve_followup(game) -> void:
	var center := effect_position()
	var hit := false
	for foe in game.foes:
		if int(foe.get("nixia_chain_id", -2)) == int(_effect.get("chain_id", -1)) and int(foe.hp) > 0 and within_cone(game, foe, center, effect_direction(), LEAP_CONE + 8.0, 0.47):
			hit = hero_hit(game, foe, 18 + int(_effect.strength) * 2 + int(game.bonus))
			break
	_effect.chain_hits = int(_effect.get("chain_hits", 1)) + (1 if hit else 0)
	_effect.kind = "followup" if hit and int(_effect.chain_hits) < 3 else "leap_impact"
	_effect.time = 0.18 if _effect.kind == "followup" else 0.23
	_effect.finishing_strike = _effect.kind == "leap_impact" and hit
	game.sound.play("nixia", 0.83)

func resolve_snare(game) -> void:
	var center := effect_position()
	for foe in game.foes:
		var point: Vector2 = game.target(foe)
		if point.distance_to(center) > SNARE_RADIUS or Encounters.blocked(game, center, point, 13.0):
			continue
		if not hero_hit(game, foe, 15 + int(_effect.strength) * 3 + int(game.bonus)):
			continue
		if not bool(foe.boss):
			var pulled: Vector2 = game.slide_with_cover(point, (center - point).limit_length(21.0))
			foe.x = pulled.x
			foe.y = pulled.y
		stun_foe(foe, 1.05 + int(_effect.strength) * 0.07)
		var statuses = game.get("combat_status")
		if statuses != null:
			statuses.apply_foe(foe, Statuses.ROOT, 1.15, 1.0, "camellia_snare")
			statuses.apply_foe(foe, Statuses.MARKED, 4.2, 2.0, "camellia_snare")
		else:
			foe.camellia_mark = maxf(float(foe.get("camellia_mark", 0.0)), 4.2)
		var talents = game.get("talents")
		if talents != null:
			talents.arm_snare_bloom(center)
		_effect.kind = "snare_latch"
		_effect.time = 0.34
		return

func resolve_paint(game) -> void:
	var begin := effect_position()
	var end := Vector2(_effect.ex, _effect.ey)
	for foe in game.foes:
		if int(foe.get("hero_paint_mark", 0)) == _cast_serial or int(foe.hp) <= 0:
			continue
		var point: Vector2 = game.target(foe)
		var nearest := Geometry2D.get_closest_point_to_segment(point, begin, end)
		if point.distance_to(nearest) > PAINT_HALF_WIDTH or Encounters.blocked(game, nearest, point, 14.0):
			continue
		if hero_hit(game, foe, 6 + int(_effect.strength) + int(game.bonus)):
			foe.hero_paint_mark = _cast_serial
			stun_foe(foe, 0.29)

static func within_cone(game, foe: Dictionary, center: Vector2, direction: Vector2, distance: float, angle: float) -> bool:
	var point: Vector2 = game.target(foe)
	var gap := point - center
	return gap.length() <= distance and (gap.length_squared() < 16.0 or gap.normalized().dot(direction) >= cos(angle)) and not Encounters.blocked(game, center, point, 15.0)

static func hero_hit(game, foe: Dictionary, amount: int) -> bool:
	return damage_foe(game, foe, game.player_hit_amount(amount))

static func damage_foe(game, foe: Dictionary, amount: int) -> bool:
	if int(foe.hp) <= 0:
		return false
	var damage: int = game.defend_foe(foe, amount)
	foe.hp -= damage
	foe.flash = 0.14
	if damage > 0:
		game.sound.play("hit", 1.08)
	return damage > 0

static func stun_foe(foe: Dictionary, duration: float) -> void:
	if int(foe.hp) <= 0:
		return
	var actual_duration := minf(0.17, duration) if bool(foe.boss) else duration
	foe.hero_stun = maxf(float(foe.get("hero_stun", 0.0)), actual_duration)
	if not bool(foe.boss):
		foe.phase = Encounters.APPROACH
		foe.clock = 0.25

static func directed_effect(kind: String, time: float, position: Vector2, direction: Vector2, strength: int) -> Dictionary:
	return {"kind": kind, "time": time, "x": position.x, "y": position.y,
		"dx": direction.x, "dy": direction.y, "strength": strength}

func effect_position() -> Vector2:
	return Vector2(_effect.x, _effect.y)

func effect_direction() -> Vector2:
	return Vector2(_effect.dx, _effect.dy)

func draw_effects(game, actor_position := Vector2.INF) -> void:
	var is_local := not actor_position.is_finite()
	if is_local:
		actor_position = game.player
	var canvas: Node2D = game.world_canvas
	var orchid = orchid_state(game) if is_local else null
	if orchid != null:
		orchid.draw(game)
	_elegy.draw(game)
	if not _frost.is_empty():
		var center := Vector2(_frost.x, _frost.y).round()
		var left := clampf(float(_frost.left) / FROST_VISUAL_TIME, 0.0, 1.0)
		var radius := FROST_RADIUS * (0.42 + 0.58 * (1.0 - left))
		paint_ring(canvas, center, radius, Color("#b8efff"), left)
		for index in range(6):
			var ray := Vector2.from_angle(index * TAU / 6.0 - PI * 0.5)
			var tip := (center + ray * radius).round()
			canvas.draw_line(center, tip, Color("#c7eeff", left), 2.0)
			for turn in [-0.51, 0.51]:
				canvas.draw_line(tip, (tip - ray.rotated(turn) * 11.0).round(), Color("#fbffff", left), 2.0)
			Visuals.spark(canvas, tip, 5.0, Color("#e8fcff", left))
	for foe: Dictionary in game.foes:
		if Statuses.has_foe(foe, Statuses.CHILL) and float(foe.get("hero_stun", 0.0)) > 0.0:
			var ground: Vector2 = game.target(foe)
			for index in range(3):
				Visuals.spark(canvas, (ground + Vector2((index - 1) * 12.0, 6.0 - 6.0 * (index % 2))).round(), 7.0, Color("#b9ecff", 0.82))
	draw_iron_bouquets(canvas)
	draw_relic_bolts(canvas)
	if _rosewall_bloom > 0.0:
		draw_rosewall_bloom(canvas)
	if _counter_left > 0.0:
		canvas.draw_circle(actor_position + Vector2(0.0, -45.0), 4.0, Color("#ffe6a3"), true, -1.0, true)
	if _effect.is_empty():
		return
	var center := effect_position()
	var remaining := float(_effect.time)
	match str(_effect.kind):
		"guard":
			var angle := effect_direction().angle()
			var hue := Color("#ffe1a1") if guard_is_perfect() else Color("#85c7fc")
			var normal := effect_direction()
			var shield: Vector2 = actor_position + normal * 29.0
			var edge := normal.orthogonal() * 13.0
			var border := PackedVector2Array([shield + normal * 14.0, shield + edge,
				shield - normal * 9.0 + edge * 0.72, shield - normal * 9.0 - edge * 0.72,
				shield - edge, shield + normal * 14.0])
			canvas.draw_colored_polygon(border, Color(hue, 0.16))
			canvas.draw_polyline(border, Color(hue, 0.9), 1.65, true)
			canvas.draw_arc(actor_position, 35.0, 0.0, TAU, 52, Color(hue, 0.20), 6.0, true)
			canvas.draw_arc(actor_position, 38.0, 0.0, TAU, 52, Color(hue, 0.80), 1.6, true)
			var impact := clampf(float(_effect.get("guard_impact", 0.0)) / 0.18, 0.0, 1.0)
			if impact > 0.0:
				var struck_at := float(_effect.get("guard_impact_angle", angle))
				var point: Vector2 = actor_position + Vector2.from_angle(struck_at) * 36.0
				canvas.draw_arc(actor_position, 38.0 + (1.0 - impact) * 10.0, struck_at - 0.48, struck_at + 0.48,
					18, Color("#fff0bf", impact), 3.6, true)
				Visuals.spark(canvas, point, 10.0 * impact, Color("#eaf7ff", impact))
		"verse", "verse_bloom":
			var blooming: bool = _effect.kind == "verse_bloom"
			var progress := remaining / 0.31 if blooming else 1.0 - remaining / VERSE_WINDUP
			paint_ring(canvas, center, VERSE_RADIUS, Color("#f396c6"), progress)
			var spin = float(game.visual_clock) * (1.4 if blooming else 0.76)
			Visuals.flower(canvas, center, 40.0 if blooming else 32.0 + 6.0 * progress, spin, Color("#f9a9da", 0.60 * progress))
			Visuals.flower(canvas, center, 21.0, -spin * 1.4, Color("#aa7fdc", 0.38 + 0.35 * progress))
			for petal in range(6):
				var angle := float(petal) * TAU / 6.0 + float(game.visual_clock) * 0.75
				var tip := center + Vector2.from_angle(angle) * (38.0 if blooming else 42.0)
				canvas.draw_line(center, tip, Color(0.77, 0.26, 0.49, 0.26 * progress), 1.5, true)
				Visuals.spark(canvas, tip, 3.0 + 3.0 * progress, Color("#ffdafa", 0.75 * progress))
		"leap":
			var point: Vector2 = actor_position
			var trailing := effect_direction() * 16.0
			canvas.draw_line(point - trailing, point, Color("#bb83fa"), 3.0, true)
		"followup", "leap_impact":
			var angle := effect_direction().angle()
			var intensity: float = clampf(remaining * 4.2, 0.0, 0.95)
			var finishing := bool(_effect.get("finishing_strike", false))
			var palette := Color("#ffccf4") if finishing else Color("#bb81fa")
			var radius := LEAP_CONE + (8.0 if finishing else 0.0)
			canvas.draw_arc(center, radius, angle - 0.58, angle + 0.58, 22,
				Color(palette, intensity), 8.0 if finishing else 4.0, true)
			if finishing:
				canvas.draw_arc(center, radius - 10.0, angle - 0.38, angle + 0.38, 22,
					Color("#fff1cb", intensity), 2.5, true)
			elif _effect.kind == "followup":
				canvas.draw_arc(center + Vector2(0, 8), 12.0 + (1.0 - intensity) * 26.0, 0.0, TAU, 32,
					Color(palette, intensity * 0.74), 2.4, true)
			for sector in range(5):
				var reach := 29.0 + (1.0 - intensity) * 34.0 + (8.0 if finishing else 0.0)
				var direction := Vector2.from_angle(angle - 0.55 + sector * 0.27)
				var point := center + direction * reach
				canvas.draw_line(center + direction * (reach - 12.0), point, Color(palette, intensity), 2.5, true)
				Visuals.spark(canvas, point, 3.0 + intensity * 5.0, Color("#f4d7fe", intensity))
		"snare", "snare_latch":
			var latch: bool = _effect.kind == "snare_latch"
			var strength := remaining / 0.34 if latch else clampf((SNARE_LIFETIME - remaining) / SNARE_ARM_TIME, 0.22, 0.68)
			paint_ring(canvas, center, SNARE_RADIUS, Color("#f6b9a8"), strength)
			Visuals.flower(canvas, center, SNARE_RADIUS * 0.86, 0.37, Color("#ffbcad", 0.35 + strength * 0.58))
			for branch in range(5):
				var angle := float(branch) * TAU / 5.0
				canvas.draw_line(center, center + Vector2.from_angle(angle) * 24.0, Color(1.0, 0.73, 0.67, strength), 1.4, true)
				if latch:
					Visuals.spark(canvas, center + Vector2.from_angle(angle) * 31.0, 3.0 + 5.0 * strength, Color("#fff1c1", strength))
		"paint":
			var end := Vector2(_effect.ex, _effect.ey)
			var strength := clampf(remaining / 0.75, 0.0, 1.0)
			canvas.draw_line(center, end, Color(0.25, 0.78, 0.81, 0.18 * strength), PAINT_HALF_WIDTH * 2.0, true)
			canvas.draw_line(center, end, Color(0.68, 0.48, 1.0, 0.61 * strength), 8.0, true)
			canvas.draw_line(center + Vector2(0.0, -2.0), end + Vector2(0.0, -2.0), Color(0.61, 1.0, 0.97, 0.83 * strength), 2.0, true)
			var side := center.direction_to(end).orthogonal()
			for spot in range(8):
				var sign_value := -1.0 if spot % 2 == 0 else 1.0
				var drip := center.lerp(end, (spot + 1.0) / 9.0) + side * sign_value * (4.0 + fposmod(spot * 5.9, 12.0))
				canvas.draw_circle(drip, 2.2 + fposmod(spot * 2.1, 1.8), Color("#a8ffe7", strength * 0.82), true, -1.0, true)

func draw_relic_bolts(canvas: Node2D) -> void:
	for bolt in _relic_bolts:
		var center := Vector2(bolt.x, bolt.y)
		var direction := Vector2(bolt.dx, bolt.dy)
		var side := direction.orthogonal()
		var alpha := clampf(float(bolt.life) / 0.11, 0.0, 1.0)
		if bolt.get("reflected", false):
			canvas.draw_line(center - direction * 22.0, center, Color("#91dff7", alpha * 0.6), 4.0, true)
			canvas.draw_circle(center, 4.6, Color("#fff0b2", alpha), true, -1.0, true)
			canvas.draw_arc(center, 8.5, 0.0, TAU, 12, Color("#86d6d4", alpha * 0.74), 1.0, true)
		elif bolt.get("rosewall", false):
			canvas.draw_line(center - direction * 22.0, center, Color("#e57d9f", alpha * 0.65), 3.2, true)
			canvas.draw_colored_polygon(PackedVector2Array([center + direction * 9.0, center + side * 4.0,
				center - direction * 7.0, center - side * 4.0]), Color("#ffd395", alpha))
		else:
			canvas.draw_line(center - direction * 17.0, center, Color("#a1d27d", alpha * 0.55), 3.0, true)
			canvas.draw_colored_polygon(PackedVector2Array([center + direction * 8.0,
				center - direction * 4.0 + side * 3.5, center - direction * 4.0 - side * 3.5]),
				Color("#ddf2aa", alpha))

func draw_rosewall_bloom(canvas: Node2D) -> void:
	var remaining := _rosewall_bloom / ROSEWALL_BLOOM_TIME
	var progress := 1.0 - remaining * remaining
	var radius := lerpf(14.0, ROSEWALL_RADIUS, progress)
	var center := _rosewall_center
	canvas.draw_arc(center, radius, 0.0, TAU, 48, Color("#f08daf", remaining * 0.83), 2.1, true)
	canvas.draw_arc(center, radius * 0.84, -0.8, TAU - 0.8, 44, Color("#ffdb9b", remaining * 0.66), 1.2, true)
	for index in range(8):
		var direction := Vector2.from_angle(index * TAU / 8.0 + progress * 0.28)
		var point := (center + direction * radius).round()
		Visuals.spark(canvas, point, 3.0 + remaining * 3.0, Color("#ffd5b8", remaining))

func draw_iron_bouquets(canvas: Node2D) -> void:
	for patch in _iron_bouquets:
		var center := Vector2(patch.x, patch.y)
		var age := float(patch.age)
		var life_fade := clampf((BOUQUET_LIFE - age) / 0.3, 0.0, 1.0)
		var bloom := clampf(age / BOUQUET_ARM_TIME, 0.0, 1.0)
		paint_ring(canvas, center, BOUQUET_RADIUS, Color("#b5d47a"), life_fade * (0.35 + bloom * 0.65))
		for index in range(6):
			var direction := Vector2.from_angle(index * TAU / 6.0 + 0.17)
			var base := center + direction * 6.0
			var tip := center + direction * lerpf(9.0, 18.0, bloom)
			var shoulder := direction.orthogonal() * 2.3
			canvas.draw_colored_polygon(PackedVector2Array([tip, base + shoulder, base - shoulder]),
				Color("#d1e7a0", life_fade))

static func paint_ring(canvas: Node2D, center: Vector2, radius: float, color: Color, strength: float) -> void:
	canvas.draw_circle(center, radius, Color(color, 0.11 * strength), true, -1.0, true)
	canvas.draw_arc(center, radius, 0.0, TAU, 42, Color(color, 0.38 + strength * 0.45), 1.6, true)
	canvas.draw_arc(center, radius - 5.0, -PI * 0.5, -PI * 0.5 + TAU * strength, 42, color, 2.2, true)
