extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Abilities = preload("res://scripts/hero_abilities.gd")
const Elegy = preload("res://scripts/elegy_magic.gd")
const Statuses = preload("res://scripts/combat_statuses.gd")
const Visuals = preload("res://scripts/hero_combat_visuals.gd")
const GuestRoster = preload("res://scripts/guest_roster.gd")
const SPIN_FIRST_BEAT := 0.10
const SPIN_INTERVAL := 0.34
const SPIN_DIZZY_THRESHOLD := 2.7
const SPIN_LIMIT := 4.2
const SPIN_HEAL_INTERVAL := 2.0
const REFRAIN_DELAY := 0.54
const NAMES = ["Last Stand", "Elegy of Thorns", "SECURITY BREACH", "Perfect Bloom", "Beautiful Disaster", "Whirl of Ruin", "Holy Transcendence", "Frenzy Shift"]
const CHARGE = 5
const AURA_TIME = 3.0
const BLADE_WAVE_DAMAGE := 23
const VALKYRIE_RECOVERY := 12.0
const BREACH_RECOVERY := 12.0
const BREACH_TIME := 0.92
const VERSE_BEATS = [0.30, 0.73, 1.17]
const COMBO_BEATS = [0.13, 0.29, 0.45, 0.63]
const BREACH_DAMAGE := [4, 3, 4, 9]
const ARROW_BEAT = [0.18]
const DISASTER_BEATS = [0.08, 0.34, 0.60]
const DISASTER_DASH_TIME = 0.14
const CUTIN_DURATION = 0.92
const ELEGY_RADIUS = 57.0
const BREACH_RADIUS = 65.0
const OVERCLOCK_RADIUS := 82.0
const VOLLEY_TURNS = [-0.42, -0.21, 0.0, 0.21, 0.42]
const BLOOM_SPEED = 365.0
const BLOOM_LIFE = 0.83
const CRESCENDO = Color("#e98ad2")
const ORCHID = Color("#d89cff")
const CAMELLIA = Color("#ffcfb3")
const IRIS = Color("#79e5e4")

var _effect: Dictionary = {}
var _launches: Array = []
var _cast_serial = 0
var _foe_serial = 0
var cue_time = 0.0
var cue_hero = -1
var valkyrie_recovery := 0.0
var breach_recovery := 0.0

func reset(keep_recovery := false) -> void:
	if not keep_recovery:
		valkyrie_recovery = 0.0
		breach_recovery = 0.0
	else:
		var interrupted: int = cue_hero if cue_time > 0.0 else int(_effect.get("hero", -1))
		begin_recovery(interrupted)
	_effect.clear()
	_launches.clear()
	_cast_serial = 0
	_foe_serial = 0
	cue_time = 0.0
	cue_hero = -1

func snapshot() -> Dictionary:
	return {"effect": _effect.duplicate(true), "launches": _launches.duplicate(true),
		"cast_serial": _cast_serial, "foe_serial": _foe_serial,
		"cue_time": cue_time, "cue_hero": cue_hero, "valkyrie_recovery": valkyrie_recovery, "breach_recovery": breach_recovery}

func restore(data: Variant) -> void:
	if not data is Dictionary:
		reset()
		return
	var effect: Variant = data.get("effect", {})
	var launches: Variant = data.get("launches", [])
	_effect = effect.duplicate(true) if effect is Dictionary else {}
	_launches = launches.duplicate(true) if launches is Array else []
	for launch: Dictionary in _launches:
		launch.contacts = launch.contacts.map(func(id): return int(id))
	valkyrie_recovery = clampf(float(data.get("valkyrie_recovery", 0.0)), 0.0, VALKYRIE_RECOVERY)
	breach_recovery = clampf(float(data.get("breach_recovery", 0.0)), 0.0, BREACH_RECOVERY)
	match int(_effect.get("hero", -1)):
		0: _effect.duration = AURA_TIME
		2: _effect.duration = BREACH_TIME
	_cast_serial = maxi(0, int(data.get("cast_serial", 0)))
	_foe_serial = maxi(0, int(data.get("foe_serial", 0)))
	cue_hero = clampi(int(data.get("cue_hero", -1)), -1, NAMES.size() - 1)
	cue_time = clampf(float(data.get("cue_time", 0.0)), 0.0, CUTIN_DURATION) if cue_hero >= 0 else 0.0
	if int(_effect.get("hero", -1)) == 4 and not _effect.has("strokes"):
		if int(_effect.get("step", 0)) == 0:
			_effect.strokes = []
			_effect.dash = {}
		else:
			# Legacy in-flight shards keep resolving via the saved projectile list.
			_effect.clear()

func locks_movement() -> bool:
	return cue_time > 0.0 or not (_effect.get("dash", {}) as Dictionary).is_empty()

func valkyrie_active() -> bool:
	return int(_effect.get("hero", -1)) == 0

func mina_spinning() -> bool:
	return int(_effect.get("hero", -1)) == GuestRoster.MINA

func recovery_left(hero: int) -> float:
	match hero:
		0: return valkyrie_recovery
		2: return breach_recovery
	return 0.0

static func recovery_duration(hero: int) -> float:
	match hero:
		0: return VALKYRIE_RECOVERY
		2: return BREACH_RECOVERY
	return 0.0

func begin_recovery(hero: int) -> void:
	match hero:
		0: valkyrie_recovery = VALKYRIE_RECOVERY
		2: breach_recovery = BREACH_RECOVERY

func can_cast(game) -> bool:
	return game.hero not in [GuestRoster.WHI, GuestRoster.LUNA] and recovery_left(game.hero) <= 0.0 \
		and cue_time <= 0.0 and _effect.is_empty() and _launches.is_empty() and game.resource >= CHARGE \
		and game.dash_remaining <= 0.0 and not game.abilities.locks_movement()

func cast(game) -> bool:
	if not can_cast(game):
		return false
	begin_cutin(int(game.hero))
	game.resource = 0
	return true

func begin_cutin(hero: int) -> void:
	cue_hero = hero
	cue_time = CUTIN_DURATION * (0.75 if hero == 0 else 1.0)

func tick_cutin(game, delta: float) -> bool:
	if cue_time <= 0.0:
		return false
	cue_time = maxf(0.0, cue_time - delta)
	if cue_time <= 0.0:
		var hero: int = cue_hero
		cue_hero = -1
		if hero == GuestRoster.WHI:
			game.guest_combat.begin_trance(game)
		elif hero == GuestRoster.LUNA:
			game.luna_combat.transform(game)
		else:
			activate_cast(game, hero)
	return true

func activate_cast(game, hero: int) -> void:
	var relic_floor: int = game.floor_index if game.floor_index >= 0 else game.depth >> 2
	if game.relics.spend_sixth_seat(relic_floor):
		game.hp += game.healing_amount(6)
	var origin: Vector2 = game.player
	var facing: Vector2 = game.facing.normalized()
	if hero in [1, 3, 4]:
		facing = game.assisted_direction(165.0 if hero == 1 else (280.0 if hero == 3 else 190.0), hero == 3)
	if facing == Vector2.ZERO:
		facing = Vector2.UP
	_cast_serial += 1
	_effect = {"hero": hero, "elapsed": 0.0, "step": 0, "x": origin.x, "y": origin.y,
		"dx": facing.x, "dy": facing.y}
	match hero:
		0:
			_effect.counter = false
			_effect.duration = AURA_TIME
			game.attack_time = minf(float(game.attack_time), 0.17)
			game.skill_time = maxf(0.0, float(game.skill_time) - 1.0)
			add_bolt(game, origin, facing, "blade_wave", 460.0, 0.55)
		1:
			_effect.duration = 1.48
			var zones: Array = []
			for site in elegy_landmarks(game):
				zones.append([site.x, site.y])
			_effect.zones = zones
			if Elegy.has_refrain(game):
				_effect.refrain_step = 0
				_effect.duration = 1.98
		2:
			_effect.orchid_overclock = game.abilities.take_orchid_overclock(game)
			_effect.duration = BREACH_TIME
		3:
			_effect.duration = 1.13
		4:
			_effect.duration = 1.32
			_effect.strokes = []
			_effect.dash = {}
			var trail: Array[Vector2] = game.abilities.take_paint_trail()
			if not trail.is_empty():
				_effect.trail = [[trail[0].x, trail[0].y], [trail[1].x, trail[1].y]]
		GuestRoster.MINA:
			_effect.duration = SPIN_LIMIT
	game.sound.hero_ultimate(hero)

static func elegy_landmarks(game) -> Array[Vector2]:
	var origin: Vector2 = game.player
	var focus: Vector2 = game.assisted_aim(165.0)
	var facing: Vector2 = game.assisted_direction(165.0)
	var distance := clampf(origin.distance_to(focus), 72.0, 116.0) if focus.is_finite() else 98.0
	var sites: Array[Vector2] = []
	for step: float in [distance * 0.53, distance, distance + 43.0]:
		sites.append(Geometry.clear_endpoint(game, origin, facing, step, 19.0))
	return sites

func damage_after_aura(amount: int) -> int:
	if amount <= 0 or int(_effect.get("hero", -1)) != 0:
		return amount
	var reduced = maxi(1, ceili(amount * 0.58))
	if reduced < amount:
		_effect.counter = true
	return reduced

func counter_bonus() -> int:
	if int(_effect.get("hero", -1)) != 0 or not bool(_effect.get("counter", false)):
		return 0
	_effect.counter = false
	return 13

static func mark_foe(foe: Dictionary, duration: float) -> void:
	foe.camellia_mark = maxf(float(foe.get("camellia_mark", 0.0)), duration)

func tick(game, delta: float, player_before := Vector2.INF) -> void:
	if tick_cutin(game, delta):
		return
	valkyrie_recovery = maxf(0.0, valkyrie_recovery - delta)
	breach_recovery = maxf(0.0, breach_recovery - delta)
	for foe: Dictionary in game.foes:
		if foe.has("camellia_mark"):
			foe.camellia_mark = maxf(0.0, float(foe.camellia_mark) - delta)
	tick_launches(game, delta)
	if _effect.is_empty():
		return
	_effect.elapsed = float(_effect.elapsed) + delta
	var hero = int(_effect.hero)
	if hero == GuestRoster.MINA:
		tick_mina_spin(game, player_before)
		return
	var beats: Array = []
	match hero:
		1: beats = VERSE_BEATS
		2: beats = COMBO_BEATS
		3: beats = ARROW_BEAT
		4: beats = DISASTER_BEATS
	while int(_effect.step) < beats.size() and float(_effect.elapsed) >= float(beats[int(_effect.step)]):
		var step = int(_effect.step)
		match hero:
			1: resolve_elegy(game, step)
			2: resolve_breach(game, step)
			3: fire_bloom(game)
			4:
				tick_disaster_dash(game, float(beats[step]))
				begin_disaster_dash(game, step)
		_effect.step = step + 1
	if hero == 1 and _effect.has("refrain_step"):
		var echo_step := int(_effect.refrain_step)
		while echo_step < VERSE_BEATS.size() and float(_effect.elapsed) >= float(VERSE_BEATS[echo_step]) + REFRAIN_DELAY:
			resolve_elegy(game, echo_step, true)
			echo_step += 1
		_effect.refrain_step = echo_step
	if hero == 4:
		tick_disaster_dash(game, float(_effect.elapsed))
	if float(_effect.elapsed) >= float(_effect.duration):
		_effect.clear()
		begin_recovery(hero)

func tick_mina_spin(game, player_before: Vector2) -> void:
	var elapsed := float(_effect.elapsed)
	var prop: Vector2 = game.guest_combat.spin_prop(game, player_before)
	if prop.is_finite():
		_effect.clear()
		game.guest_combat.stop_spin(game, prop, false)
		return
	var last_hit_time := minf(elapsed, SPIN_LIMIT)
	var step := int(_effect.step)
	var beat_time := SPIN_FIRST_BEAT + step * SPIN_INTERVAL
	while beat_time <= last_hit_time:
		if not game.guest_combat.spin(game, step):
			_effect.clear()
			game.guest_combat.stop_spin(game, Vector2.INF, beat_time >= SPIN_DIZZY_THRESHOLD)
			return
		step += 1
		_effect.step = step
		var passed_heal := floori(beat_time / SPIN_HEAL_INTERVAL)
		if passed_heal > 0 and passed_heal > floori((beat_time - SPIN_INTERVAL) / SPIN_HEAL_INTERVAL):
			game.guest_combat.recover_from_spin_hit(game)
		beat_time = SPIN_FIRST_BEAT + step * SPIN_INTERVAL
	if elapsed >= SPIN_LIMIT:
		_effect.clear()
		game.guest_combat.stop_spin(game, Vector2.INF, true)

func resolve_elegy(game, step: int, echo := false) -> void:
	var center = point_from(_effect.zones[step])
	var other_zone: Vector2 = game.abilities.active_verse_zone()
	for foe: Dictionary in game.foes:
		var point: Vector2 = game.target(foe)
		if point.distance_to(center) > ELEGY_RADIUS or Geometry.blocked(game, center, point, 12.0):
			continue
		var overlapping = other_zone.is_finite() and point.distance_to(other_zone) <= Abilities.VERSE_RADIUS 			and not Geometry.blocked(game, other_zone, point, 12.0)
		for earlier in range(step):
			var prior = point_from(_effect.zones[earlier])
			if point.distance_to(prior) <= ELEGY_RADIUS and not Geometry.blocked(game, prior, point, 12.0):
				overlapping = true
				break
		var power := 13 + step * 3 + (9 if overlapping else 0) + int(game.bonus)
		Abilities.hero_hit(game, foe, power / 2 if echo else power)
	game.abilities.note_elegy_crescendo(game, center)
	if echo:
		game.sound.play("vivianne", 0.89 + step * 0.07)

func resolve_breach(game, step: int) -> void:
	var center: Vector2 = game.player
	var ending = step == COMBO_BEATS.size() - 1
	var radius := breach_radius()
	for foe: Dictionary in game.foes:
		var point: Vector2 = game.target(foe)
		if point.distance_to(center) > radius or Geometry.blocked(game, center, point, 15.0):
			continue
		var bonus := int(game.bonus) if ending else mini(int(game.bonus), 9)
		var damage := int(BREACH_DAMAGE[step]) + floori(bonus * 0.5)
		if not Abilities.hero_hit(game, foe, damage):
			continue
		Abilities.stun_foe(foe, 0.24 if not ending else 0.36)
		if ending and not bool(foe.boss) and int(foe.hp) > 0:
			var direction = center.direction_to(point)
			if direction == Vector2.ZERO:
				direction = effect_direction()
			_launches.append({"foe_id": foe_id(foe), "dx": direction.x, "dy": direction.y,
				"left": 0.22, "contacts": []})

func breach_radius() -> float:
	return OVERCLOCK_RADIUS if _effect.get("orchid_overclock", false) else BREACH_RADIUS

func tick_launches(game, delta: float) -> void:
	for index in range(_launches.size() - 1, -1, -1):
		var launch: Dictionary = _launches[index]
		var flying = find_foe(game.foes, int(launch.foe_id))
		if flying.is_empty() or int(flying.hp) <= 0:
			_launches.remove_at(index)
			continue
		var begin: Vector2 = game.target(flying)
		var travel = 340.0 * minf(delta, float(launch.left))
		var finish = Geometry.clear_endpoint(game, begin, Vector2(launch.dx, launch.dy), travel, 24.0)
		for other: Dictionary in game.foes:
			if int(other.hp) <= 0 or int(other.get("ultimate_target_id", 0)) == int(launch.foe_id):
				continue
			var point: Vector2 = game.target(other)
			if Geometry.segment_gap(point, begin, finish) > 24.0 or Geometry.blocked(game, begin, point, 14.0):
				continue
			var id = foe_id(other)
			if id in launch.contacts:
				continue
			launch.contacts.append(id)
			Abilities.hero_hit(game, other, 6 + floori(mini(int(game.bonus), 10) * 0.5))
			Abilities.stun_foe(other, 0.18)
		flying.x = finish.x
		flying.y = finish.y
		launch.left = float(launch.left) - delta
		if float(launch.left) <= 0.0 or begin.distance_to(finish) < travel * 0.25:
			_launches.remove_at(index)

func fire_bloom(game) -> void:
	var origin: Vector2 = game.player
	for turn: float in VOLLEY_TURNS:
		add_bolt(game, origin, effect_direction().rotated(turn), "bloom", BLOOM_SPEED, BLOOM_LIFE)

func begin_disaster_dash(game, index: int) -> void:
	if index == 0 and _effect.has("trail"):
		damage_disaster_path(game, point_from(_effect.trail[0]), point_from(_effect.trail[1]), -1, 11)
	var origin: Vector2 = game.player
	var aim: Vector2 = game.assisted_aim(172.0)
	var direction = effect_direction().rotated([0.0, 0.83, -0.74][index])
	var distance = 107.0 if index < 2 else 129.0
	if aim.is_finite():
		direction = origin.direction_to(aim)
		distance = clampf(origin.distance_to(aim) + 28.0, 64.0, 133.0)
	var finish = Geometry.clear_endpoint(game, origin, direction, distance, game.BARREL_CLEARANCE)
	if finish.distance_to(origin) < 19.0:
		finish = Geometry.clear_endpoint(game, origin, direction.rotated(PI * 0.5), distance * 0.76, game.BARREL_CLEARANCE)
	var began = float(DISASTER_BEATS[index])
	_effect.dash = {"from": [origin.x, origin.y], "to": [finish.x, finish.y],
		"cursor": [origin.x, origin.y], "index": index, "time": began}
	_effect.strokes.append({"from": [origin.x, origin.y], "to": [origin.x, origin.y], "time": began})
	game.facing = origin.direction_to(finish) if finish != origin else direction
	game.mercy = maxf(float(game.mercy), DISASTER_DASH_TIME + 0.06)
	game.sound.play("zaria", 1.01 + 0.10 * index)

func tick_disaster_dash(game, now: float) -> void:
	if not locks_movement():
		return
	var dash: Dictionary = _effect.dash
	var start = point_from(dash.from)
	var destination = point_from(dash.to)
	var progress = clampf((now - float(dash.time)) / DISASTER_DASH_TIME, 0.0, 1.0)
	var next = start.lerp(destination, smoothstep(0.0, 1.0, progress))
	var previous = point_from(dash.cursor)
	var index = int(dash.index)
	game.player = next
	dash.cursor = [next.x, next.y]
	_effect.strokes[index].to = dash.cursor
	damage_disaster_path(game, previous, next, index, 12 if index == 0 else (18 if index == 1 else 24))
	if progress >= 1.0:
		_effect.dash = {}

func damage_disaster_path(game, begin: Vector2, end: Vector2, stroke: int, power: int) -> void:
	var bit = 1 << (stroke + 1)
	var width = 23.0 if stroke < 2 else 30.0
	for foe: Dictionary in game.foes:
		if int(foe.hp) <= 0:
			continue
		var point: Vector2 = game.target(foe)
		if Geometry.segment_gap(point, begin, end) > width or Geometry.blocked(game, begin, point, 11.0):
			continue
		var new_hit = int(foe.get("disaster_cast", -1)) != _cast_serial
		var hits = 0 if new_hit else int(foe.disaster_count)
		var marks = 0 if new_hit else int(foe.disaster_strokes)
		if hits >= 2 or (marks & bit) != 0:
			continue
		var painted = int(foe.get("hero_paint_mark", 0)) > 0
		if not Abilities.hero_hit(game, foe, power + mini(int(game.bonus), 10) + (12 if painted else 0)):
			continue
		if painted:
			foe.hero_paint_mark = 0
		foe.disaster_cast = _cast_serial
		foe.disaster_count = hits + 1
		foe.disaster_strokes = marks | bit
		Abilities.stun_foe(foe, 0.17)

func add_bolt(game, origin: Vector2, direction: Vector2, kind: String, speed: float, lifetime: float) -> void:
	game.bolts.append({"x": origin.x, "y": origin.y, "dx": direction.x, "dy": direction.y,
		"life": lifetime, "speed": speed, "ultimate": kind, "ultimate_cast": _cast_serial})

func steer_bolt(game, bolt: Dictionary, delta: float) -> void:
	if bolt.get("ultimate", "") != "bloom":
		return
	var direction = Vector2(bolt.dx, bolt.dy).normalized()
	var origin: Vector2 = game.target(bolt)
	var desired: Vector2 = game.facing.normalized()
	var nearest = 245.0
	for foe: Dictionary in game.foes:
		if int(foe.hp) <= 0 or not Statuses.has_foe(foe, Statuses.MARKED):
			continue
		if hit_capped(foe, bolt):
			continue
		var toward: Vector2 = game.target(foe) - origin
		var gap = toward.length()
		if gap >= nearest or toward.normalized().dot(direction) < 0.76 				or Geometry.blocked(game, origin, game.target(foe), 12.0):
			continue
		nearest = gap
		desired = toward.normalized()
	if desired == Vector2.ZERO or direction.dot(desired) <= 0.62:
		return
	var turn_rate = 4.2 if nearest < 245.0 else 0.44
	var turn = clampf(direction.angle_to(desired), -delta * turn_rate, delta * turn_rate)
	direction = direction.rotated(turn)
	bolt.dx = direction.x
	bolt.dy = direction.y

func resolve_bolt(game, bolt: Dictionary, begin: Vector2, end: Vector2) -> bool:
	var best: Dictionary = {}
	var nearest = INF
	var direction = begin.direction_to(end)
	for foe: Dictionary in game.foes:
		if int(foe.hp) <= 0 or hit_capped(foe, bolt):
			continue
		var center: Vector2 = game.target(foe)
		var hit_radius := 35.0 if bolt.ultimate == "blade_wave" else (27.0 if bool(foe.boss) else 14.0)
		if Geometry.segment_gap(center, begin, end) > hit_radius:
			continue
		var distance = (center - begin).dot(direction)
		if distance < nearest:
			nearest = distance
			best = foe
	if best.is_empty():
		return false
	var cast_id := int(bolt.ultimate_cast)
	var hit_count := cast_hit_count(best, cast_id)
	var counts: Variant = best.get("ultimate_hit_counts", {})
	if not counts is Dictionary:
		counts = {}
	counts[str(cast_id)] = hit_count + 1
	best.ultimate_hit_counts = counts
	# Keep these fields for compatibility with existing saves and consumers.
	best.ultimate_cast = cast_id
	best.ultimate_hits = hit_count + 1
	var power = 13 + int(game.bonus)
	var mark_bonus := 0
	if bolt.ultimate == "blade_wave":
		power = BLADE_WAVE_DAMAGE + int(game.bonus)
	elif bolt.ultimate == "bloom":
		mark_bonus = Statuses.precision_mark_bonus(best)
		if mark_bonus > 0:
			power += mark_bonus
		elif float(best.get("camellia_mark", 0.0)) > 0.0:
			power += 10
	else:
		var painted = int(best.get("hero_paint_mark", 0)) > 0
		if painted:
			best.hero_paint_mark = 0
			power += 10
		if float(best.get("hero_stun", 0.0)) > 0.0:
			power += 4
		if bolt.ultimate == "trail_shard":
			power += 3
	var landed := Abilities.hero_hit(game, best, power)
	if landed and mark_bonus > 0:
		game.combat_status.consume_foe_mark(best)
	return bolt.ultimate != "blade_wave"

func hit_capped(foe: Dictionary, bolt: Dictionary) -> bool:
	# Cap each volley at two hits per target, including bosses and trail echoes.
	var limit := 1 if bolt.ultimate == "blade_wave" else 2
	return cast_hit_count(foe, int(bolt.ultimate_cast)) >= limit

static func cast_hit_count(foe: Dictionary, cast_id: int) -> int:
	var counts: Variant = foe.get("ultimate_hit_counts", {})
	if counts is Dictionary and counts.has(str(cast_id)):
		return maxi(0, int(counts[str(cast_id)]))
	# Old solo saves contain just the last cast and hit count.
	if int(foe.get("ultimate_cast", -1)) == cast_id:
		return maxi(0, int(foe.get("ultimate_hits", 0)))
	return 0

func foe_id(foe: Dictionary) -> int:
	if not foe.has("ultimate_target_id"):
		_foe_serial += 1
		foe.ultimate_target_id = _foe_serial
	return int(foe.ultimate_target_id)

static func find_foe(foes: Array, id: int) -> Dictionary:
	for foe: Dictionary in foes:
		if int(foe.get("ultimate_target_id", 0)) == id:
			return foe
	return {}

static func point_from(raw: Array) -> Vector2:
	return Vector2(raw[0], raw[1])

func effect_direction() -> Vector2:
	return Vector2(_effect.dx, _effect.dy)

func draw_effects(game, actor_position := Vector2.INF) -> void:
	var canvas: Node2D = game.world_canvas
	for foe: Dictionary in game.foes:
		if float(foe.get("camellia_mark", 0.0)) > 0.0 and int(foe.hp) > 0:
			var center: Vector2 = game.target(foe)
			var radius = 8.0 + sin(game.visual_clock * 6.0) * 1.5
			canvas.draw_arc(center + Vector2(0, 9), radius, 0.0, TAU, 18, Color("#ffe390"), 1.5, true)
	if _effect.is_empty():
		return
	var progress = clampf(float(_effect.elapsed) / float(_effect.duration), 0.0, 1.0)
	var center: Vector2 = actor_position if actor_position.is_finite() else game.player
	match int(_effect.hero):
		0:
			var glow = 0.72 + sin(game.visual_clock * 10.0) * 0.16
			var tint = Color("#ffdf9a") if _effect.counter else Color("#87caff")
			var crest := center - Vector2(0, 24)
			for flank: float in [-1.0, 1.0]:
				for feather in range(4):
					var base := (crest + Vector2(flank * (8.0 + feather * 3.0), feather * 3.0)).round()
					var tip := (base + Vector2(flank * (29.0 - feather * 3.0),
						-23.0 + feather * 6.0 + sin(game.visual_clock * 9.0 + feather * 0.5) * 4.0)).round()
					canvas.draw_polyline(PackedVector2Array([base, ((base + tip) * 0.5 + Vector2(0, 5)).round(), tip]),
						Color("#f3ce8d", glow * (0.62 - feather * 0.09)), 2.0)
					Visuals.spark(canvas, tip, 3.0, Color("#fff0cd", glow * 0.70))
			canvas.draw_arc(center, 41, 0.0, TAU, 44, Color(tint, glow), 2.1, true)
			canvas.draw_arc(center, 47, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - progress), 44,
				Color(tint, 0.77), 2.9, true)
		1:
			for index in range(_effect.zones.size()):
				var point = point_from(_effect.zones[index])
				var elapsed_from_hit = float(_effect.elapsed) - float(VERSE_BEATS[index])
				var bloom = clampf(1.0 - elapsed_from_hit * 3.2, 0.0, 1.0) if elapsed_from_hit >= 0.0 else 0.19
				Abilities.paint_ring(canvas, point, ELEGY_RADIUS, CRESCENDO, bloom)
				if _effect.has("refrain_step"):
					var age: float = elapsed_from_hit - REFRAIN_DELAY
					if age >= 0.0 and age < 0.27:
						Abilities.paint_ring(canvas, point, ELEGY_RADIUS * (0.72 + age), Color("#fce3ff"), 1.0 - age / 0.27)
		2:
			var overclocked := bool(_effect.get("orchid_overclock", false))
			var radius := breach_radius()
			var phase = fposmod(float(_effect.elapsed) * 6.6, 1.0)
			var stroke = effect_direction().angle() - 1.1 + phase * 1.8
			canvas.draw_arc(center, radius * (0.77 + phase * 0.23), stroke,
				stroke + 1.7, 25, Color(ORCHID, (1.0 - phase) * 0.85), 4.5, true)
			if overclocked:
				canvas.draw_arc(center, radius * (0.64 + phase * 0.24), stroke + PI,
					stroke + PI + 1.3, 24, Color("#ffe2a4", (1.0 - phase) * 0.82), 2.4, true)
		3:
			if int(_effect.step) == 0:
				canvas.draw_arc(center, 39.0, effect_direction().angle() - 0.48,
					effect_direction().angle() + 0.48, 20, CAMELLIA, 3.2, true)
		4:
			if _effect.has("trail"):
				canvas.draw_line(point_from(_effect.trail[0]), point_from(_effect.trail[1]),
					Color(IRIS, (1.0 - progress) * 0.42), 12.0, true)
			for index in range(_effect.strokes.size()):
				draw_disaster_stroke(canvas, _effect.strokes[index], float(_effect.elapsed), index)

static func draw_disaster_stroke(canvas: Node2D, stroke: Dictionary, elapsed: float, index: int) -> void:
	var origin = point_from(stroke.from)
	var end = point_from(stroke.to)
	if end.distance_squared_to(origin) < 2.0:
		return
	var age = maxf(0.0, elapsed - float(stroke.time))
	var freshness = clampf(1.0 - age / 1.18, 0.0, 1.0)
	var palette = [IRIS, Color("#c299ff"), Color("#ff99c4")]
	var color: Color = palette[index]
	var side = origin.direction_to(end).orthogonal()
	canvas.draw_line(origin, end, Color(color, 0.18 * freshness), 48.0 if index == 2 else 39.0, true)
	canvas.draw_line(origin + side * 4.0, end - side * 3.0, Color(color, freshness * 0.83), 9.0, true)
	canvas.draw_line(origin - side * 4.0, end + side * 4.0, Color("#e9fffb", freshness * 0.86), 2.2, true)
	for i in range(5):
		var point = origin.lerp(end, (i + 1.0) / 6.0)
		var fleck = point + side * (1.0 if i % 2 == 0 else -1.0) * (12.0 + age * 20.0)
		canvas.draw_circle(fleck, 3.0 - i * 0.33, Color(color, freshness * 0.83), true, -1.0, true)
	Visuals.spark(canvas, end, 13.0 * freshness, Color(color, freshness))

static func draw_bolt(canvas: Node2D, bolt: Dictionary, point: Vector2, direction: Vector2) -> void:
	if bolt.ultimate == "blade_wave":
		var side := direction.orthogonal()
		canvas.draw_arc(point - direction * 12.0, 27.0, direction.angle() - 0.8, direction.angle() + 0.8, 18, Color("#d9f5ff"), 5.0, true)
		canvas.draw_line(point - side * 23.0, point + side * 23.0, Color("#87caff", 0.55), 3.0, true)
		return
	var tint = CAMELLIA if bolt.ultimate == "bloom" else IRIS
	var edge = direction.orthogonal()
	canvas.draw_line(point - direction * 20.0, point, Color(tint, 0.67), 3.6, true)
	canvas.draw_colored_polygon(PackedVector2Array([point + direction * 6.0, point - direction * 5.0 + edge * 5.0,
		point - direction * 4.0, point - direction * 5.0 - edge * 5.0]), tint)
