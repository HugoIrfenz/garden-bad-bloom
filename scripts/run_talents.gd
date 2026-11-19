extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Statuses = preload("res://scripts/combat_statuses.gd")
const FIRST_MILESTONE = "first_chapter"
const SECOND_MILESTONE = "second_chapter"
const MAX_SLOTS = 3
const CAMP_BLESSING = "camp_blessing"
const CAMP_DAMAGE = 1
const WARMSTEEL = "warmsteel"
const QUIET_QUILL = "quiet_quill"
const POCKET_METEOR = "pocket_meteor"
const SNARE_BLOOM = "snare_bloom"
const SEWING_THREAD = "sewing_thread"
const INK_FOOTSTEPS = "ink_footsteps"
const WARM_TIME = 4.5
const QUIET_TIME = 0.90
const QUIET_POWER = 7
const METEOR_RADIUS = 51.0
const METEOR_TIME = 0.32
const BLOOM_DELAY = 0.66
const BLOOM_FADE = 0.24
const BLOOM_INNER = 27.0
const BLOOM_OUTER = 56.0
const INK_RADIUS = 17.0
const INK_TIME = 1.65
const INK_SEGMENTS = 12
const CATALOG = [
	{"id": WARMSTEEL, "hero": 0, "name": "Warmsteel", "branch": "Guard", "accent": Color("#f9b283"),
		"detail": "A perfect guard heats the blade for 4.5 seconds. Your next attack ignites the first foe it hits."},
	{"id": QUIET_QUILL, "hero": 1, "name": "Quiet Quill", "branch": "Spell", "accent": Color("#d8a8ed"),
		"detail": "Stand still for 0.9 seconds to add 7 damage to your next skill. Moving or dodging clears the charge."},
	{"id": POCKET_METEOR, "hero": 2, "name": "Pocket Meteor", "branch": "Combo", "accent": Color("#e7a4ee"),
		"detail": "Leaping with at least 3 Momentum sends out a circular shock that staggers nearby foes."},
	{"id": SNARE_BLOOM, "hero": 3, "name": "Snare Bloom", "branch": "Precision", "accent": Color("#ecc894"),
		"detail": "When a trap catches a foe, an outer ring blooms a moment later and snares enemies in its path."},
	{"id": INK_FOOTSTEPS, "hero": 4, "name": "Ink Footsteps", "branch": "Chaos", "accent": Color("#91dfd6"),
		"detail": "Dodge to paint a trail that slows pursuing foes for 1.65 seconds."},
	{"id": SEWING_THREAD, "hero": 3, "name": "Sewing Thread", "branch": "Precision", "accent": Color("#eebac8"),
		"milestone": SECOND_MILESTONE, "detail": "Connect two Tidy Arrangement placements into a single-use tripwire that roots crossing foes."},
]

var chosen: Array[String] = []
var resolved: Array[String] = []
var outcomes: Dictionary = {}
var warm_left := 0.0
var warm_sequence := -1
var quiet_charge := 0.0
var meteor: Dictionary = {}
var bloom: Dictionary = {}
var ink: Dictionary = {}


func reset() -> void:
	chosen.clear()
	resolved.clear()
	outcomes.clear()
	enter_room()


func enter_room() -> void:
	warm_left = 0.0
	warm_sequence = -1
	quiet_charge = 0.0
	meteor.clear()
	bloom.clear()
	ink.clear()


static func definition(id: String) -> Dictionary:
	for row: Dictionary in CATALOG:
		if row.id == id:
			return row.duplicate()
	return {}


func owns(id: String) -> bool:
	return id in chosen


func milestone_resolved(milestone := FIRST_MILESTONE) -> bool:
	return milestone in resolved


func offer(hero: int, milestone := FIRST_MILESTONE) -> Dictionary:
	if milestone_resolved(milestone) or chosen.size() >= MAX_SLOTS:
		return {}
	for row: Dictionary in CATALOG:
		if int(row.hero) == hero and row.get("milestone", FIRST_MILESTONE) == milestone and not owns(row.id):
			return row.duplicate()
	return {}


func choose(id: String, hero: int, milestone := FIRST_MILESTONE) -> bool:
	if offer(hero, milestone).get("id", "") != id or id.is_empty():
		return false
	chosen.append(id)
	resolved.append(milestone)
	outcomes[milestone] = id
	return true


func decline(milestone := FIRST_MILESTONE) -> bool:
	if milestone not in [FIRST_MILESTONE, SECOND_MILESTONE] or milestone_resolved(milestone):
		return false
	resolved.append(milestone)
	outcomes[milestone] = CAMP_BLESSING
	return true


func outcome(milestone: String) -> String:
	return str(outcomes.get(milestone, ""))


func snapshot() -> Dictionary:
	return {"chosen": chosen.duplicate(), "resolved": resolved.duplicate(), "outcomes": outcomes.duplicate(), "warm_left": warm_left,
		"warm_sequence": warm_sequence, "quiet_charge": quiet_charge, "meteor": meteor.duplicate(),
		"bloom": bloom.duplicate(), "ink": ink.duplicate(true)}


func restore(hero: int, data: Variant) -> void:
	reset()
	if not data is Dictionary:
		return
	var slots: Variant = data.get("chosen", [])
	if slots is Array:
		for slot in slots:
			var id := str(slot)
			var row := definition(id)
			if int(row.get("hero", -1)) == hero and not owns(id) and chosen.size() < MAX_SLOTS:
				chosen.append(id)
	var milestones: Variant = data.get("resolved", [])
	for milestone in [FIRST_MILESTONE, SECOND_MILESTONE]:
		if milestones is Array and milestone in milestones:
			resolved.append(milestone)
	for id: String in chosen:
		var milestone: String = definition(id).get("milestone", FIRST_MILESTONE)
		if milestone not in resolved:
			resolved.append(milestone)
	var saved_outcomes: Variant = data.get("outcomes")
	if saved_outcomes is Dictionary:
		for milestone: String in resolved:
			var outcome_id := str(saved_outcomes.get(milestone, ""))
			if outcome_id == CAMP_BLESSING or owns(outcome_id):
				outcomes[milestone] = outcome_id
	if owns(WARMSTEEL):
		warm_left = clampf(float(data.get("warm_left", 0.0)), 0.0, WARM_TIME)
		warm_sequence = maxi(-1, int(data.get("warm_sequence", -1)))
	if owns(QUIET_QUILL):
		quiet_charge = clampf(float(data.get("quiet_charge", 0.0)), 0.0, QUIET_TIME)
	if owns(POCKET_METEOR):
		meteor = restore_site(data.get("meteor"), METEOR_TIME)
	if owns(SNARE_BLOOM):
		bloom = restore_site(data.get("bloom"), BLOOM_DELAY if not saved_active(data.get("bloom")) else BLOOM_FADE)
	if owns(INK_FOOTSTEPS):
		ink = restore_ink(data.get("ink"))


static func saved_active(data: Variant) -> bool:
	return data is Dictionary and bool(data.get("active", false))


static func restore_site(data: Variant, limit: float) -> Dictionary:
	if not data is Dictionary or not data.has_all(["x", "y", "left"]):
		return {}
	var left := clampf(float(data.left), 0.0, limit)
	if left <= 0.0 or not is_finite(float(data.x)) or not is_finite(float(data.y)):
		return {}
	return {"x": float(data.x), "y": float(data.y), "left": left, "active": saved_active(data)}


static func restore_ink(saved: Variant) -> Dictionary:
	if not saved is Dictionary or not saved.get("segments") is Array:
		return {}
	var left := clampf(float(saved.get("left", 0.0)), 0.0, INK_TIME)
	if left <= 0.0:
		return {}
	var segments: Array[Dictionary] = []
	for segment: Variant in saved.segments.slice(0, INK_SEGMENTS):
		if segment is Dictionary and segment.has_all(["x", "y", "ex", "ey"]):
			var from := Vector2(segment.x, segment.y)
			var to := Vector2(segment.ex, segment.ey)
			if from.is_finite() and to.is_finite() and from.distance_squared_to(to) > 0.04:
				segments.append({"x": from.x, "y": from.y, "ex": to.x, "ey": to.y})
	return {"segments": segments, "left": left} if not segments.is_empty() else {}


func perfect_guard() -> bool:
	if not owns(WARMSTEEL):
		return false
	warm_left = WARM_TIME
	return true


func begin_basic(sequence: int) -> void:
	if not owns(WARMSTEEL):
		return
	warm_sequence = sequence if warm_left > 0.0 else -1
	warm_left = 0.0


func after_basic_hit(game, foe: Dictionary, sequence: int) -> void:
	if sequence < 0 or sequence != warm_sequence:
		return
	warm_sequence = -1
	if int(foe.hp) > 0:
		game.combat_status.apply_foe(foe, Statuses.BURN, 2.55, 1.0, WARMSTEEL)


func take_quiet_power() -> int:
	if not owns(QUIET_QUILL) or quiet_charge < QUIET_TIME:
		return 0
	quiet_charge = 0.0
	return QUIET_POWER


func start_dodge() -> void:
	quiet_charge = 0.0
	if owns(INK_FOOTSTEPS):
		ink.clear()


func add_dash_step(game, from: Vector2, to: Vector2) -> void:
	if not owns(INK_FOOTSTEPS) or from.distance_squared_to(to) < 0.04:
		return
	if Geometry.blocked(game, from, to, 12.0):
		return
	if ink.is_empty():
		ink = {"segments": [], "left": INK_TIME}
	var segments: Array = ink.segments
	if not segments.is_empty():
		var latest: Dictionary = segments.back()
		var origin := Vector2(latest.x, latest.y)
		var previous_end := Vector2(latest.ex, latest.ey)
		if previous_end.is_equal_approx(from) and origin.direction_to(previous_end).dot(from.direction_to(to)) > 0.984 \
				and not Geometry.blocked(game, origin, to, 12.0):
			latest.ex = to.x
			latest.ey = to.y
			ink.left = INK_TIME
			return
	if segments.size() < INK_SEGMENTS:
		segments.append({"x": from.x, "y": from.y, "ex": to.x, "ey": to.y})
		ink.left = INK_TIME


func record_meteor(center: Vector2) -> void:
	meteor = {"x": center.x, "y": center.y, "left": METEOR_TIME}


func arm_snare_bloom(center: Vector2) -> void:
	if owns(SNARE_BLOOM):
		bloom = {"x": center.x, "y": center.y, "left": BLOOM_DELAY, "active": false}


func foe_movement_scale(game, foe: Dictionary) -> float:
	if ink.is_empty() or int(foe.hp) <= 0:
		return 1.0
	var point: Vector2 = game.target(foe)
	for segment: Dictionary in ink.segments:
		var from := Vector2(segment.x, segment.y)
		var to := Vector2(segment.ex, segment.ey)
		var closest := Geometry2D.get_closest_point_to_segment(point, from, to)
		if point.distance_squared_to(closest) <= INK_RADIUS * INK_RADIUS \
				and not Geometry.blocked(game, closest, point, 10.0) and Statuses.accepts_status(game, foe):
			return 0.86 if foe.get("boss", false) else 0.62
	return 1.0


func tick(game, delta: float, moving: bool, dodging: bool) -> void:
	if chosen.is_empty():
		return
	warm_left = maxf(0.0, warm_left - delta)
	if owns(QUIET_QUILL):
		quiet_charge = 0.0 if moving or dodging else minf(QUIET_TIME, quiet_charge + delta)
	decay(meteor, delta)
	decay(ink, delta)
	tick_bloom(game, delta)


static func decay(site: Dictionary, delta: float) -> void:
	if not site.is_empty():
		site.left = float(site.left) - delta
		if site.left <= 0.0:
			site.clear()


func tick_bloom(game, delta: float) -> void:
	if bloom.is_empty():
		return
	bloom.left = float(bloom.left) - delta
	if bloom.left > 0.0:
		return
	if bool(bloom.active):
		bloom.clear()
		return
	var center := Vector2(bloom.x, bloom.y)
	for foe: Dictionary in game.foes:
		var point: Vector2 = game.target(foe)
		var span := center.distance_squared_to(point)
		if span >= BLOOM_INNER * BLOOM_INNER and span <= BLOOM_OUTER * BLOOM_OUTER \
				and not Geometry.blocked(game, center, point, 12.0):
			game.combat_status.apply_foe(foe, Statuses.ROOT, 1.0, 1.0, SNARE_BLOOM)
	bloom.active = true
	bloom.left = BLOOM_FADE


func draw(game) -> void:
	if chosen.is_empty():
		return
	var canvas: Node2D = game.world_canvas
	var center: Vector2 = game.player
	if warm_left > 0.0:
		var facing: Vector2 = game.facing
		canvas.draw_arc(center, 20.0, facing.angle() - 0.58, facing.angle() + 0.58, 18, Color("#f7b47d"), 2.0, true)
	if quiet_charge > 0.0:
		var ratio := quiet_charge / QUIET_TIME
		canvas.draw_arc(center + Vector2(0, 9), 14.0, -PI * 0.5, ratio * TAU - PI * 0.5, 24,
			Color("#ddadee", 0.38 + ratio * 0.46), 1.7, true)
	if not meteor.is_empty():
		draw_meteor(canvas)
	if not bloom.is_empty():
		draw_bloom(canvas)
	if not ink.is_empty():
		draw_ink(canvas)


func draw_meteor(canvas: Node2D) -> void:
	var center := Vector2(meteor.x, meteor.y)
	var progress := 1.0 - float(meteor.left) / METEOR_TIME
	var radius := lerpf(14.0, METEOR_RADIUS, sqrt(progress))
	canvas.draw_arc(center, radius, 0.0, TAU, 44, Color("#d99beb", (1.0 - progress) * 0.62), 5.5, true)
	for index in range(8):
		var ray := Vector2.from_angle(float(index) * TAU / 8.0)
		canvas.draw_line(center + ray * (radius - 8.0), center + ray * radius,
			Color("#ffe4fb", 1.0 - progress), 1.8, true)


func draw_bloom(canvas: Node2D) -> void:
	var center := Vector2(bloom.x, bloom.y)
	var active := bool(bloom.active)
	var ratio := 1.0 - float(bloom.left) / (BLOOM_FADE if active else BLOOM_DELAY)
	var opacity := 1.0 - ratio if active else 0.4 + 0.45 * ratio
	var tint := Color("#f4d38e" if active else "#f3bcca", opacity)
	canvas.draw_arc(center, BLOOM_INNER, 0.0, TAU, 36, Color(tint, opacity * 0.55), 1.2, true)
	canvas.draw_arc(center, BLOOM_OUTER, 0.0, TAU, 56, tint, 2.1 if active else 1.2, true)
	for index in range(8):
		var angle := float(index) * TAU / 8.0
		var part := lerpf(BLOOM_INNER, BLOOM_OUTER, ratio)
		canvas.draw_line(center + Vector2.from_angle(angle) * (part - 4.0),
			center + Vector2.from_angle(angle) * part, tint, 2.2, true)


func draw_ink(canvas: Node2D) -> void:
	var fade := clampf(float(ink.left) / 0.34, 0.0, 1.0)
	for segment: Dictionary in ink.segments:
		var origin := Vector2(segment.x, segment.y)
		var end := Vector2(segment.ex, segment.ey)
		canvas.draw_line(origin, end, Color("#173d4b", 0.70 * fade), INK_RADIUS * 1.8, true)
		canvas.draw_line(origin, end, Color("#498b8c", 0.69 * fade), 7.0, true)
		var across := origin.direction_to(end).orthogonal()
		var count := maxi(1, roundi(origin.distance_to(end) / 18.0))
		for index in range(count):
			var point := origin.lerp(end, float(index + 1) / float(count + 1)) + across * sin(float(index) * 3.4) * 8.0
			canvas.draw_circle(point, 2.0 + float(index % 2), Color("#a8ded0", 0.65 * fade), true, -1.0, true)
