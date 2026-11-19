extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Dungeon = preload("res://scripts/dungeon_generation.gd")
const Art = preload("res://scripts/garden_art.gd")
const Chandelier = preload("res://scripts/hollow_chandelier.gd")
const Statuses = preload("res://scripts/combat_statuses.gd")
const TILE_ART = preload("res://assets/art/garden_hazards.png")
const TILE_REGIONS = [
	Rect2(125, 197, 303, 168), Rect2(622, 156, 286, 228), Rect2(1111, 177, 286, 200),
	Rect2(97, 553, 333, 370), Rect2(621, 694, 288, 223), Rect2(1110, 598, 292, 315),
]
const RADIUS = 23.0
const RESET_DELAY = 2.8
const WARNING = 0.82
const BLOOM = 0.68
const DAMAGE = 9
const ROOT_DURATION = 0.92
const ROOT_BREAK_DASH = 0.30
const GLASS_WARNING = 0.98
const GLASS_COOLDOWN = 0.44
const SPORE_RADIUS = 31.0
const DRAIN_RADIUS = 31.0
const LILY_PAD_RADIUS = 10.5
const THREAD_HALF_WIDTH = 8.0
const TYPES = {
	"flowerbed_siege": "thorns",
	"petal_courtyard": "roots",
	"sunken_greenhouse": "glass",
	"fungal_crossroad": "spores",
	"leech_pond": "drain",
	"redroot_corridor": "thread",
	"chandelier_hall": "chandelier",
}

var patches: Array[Dictionary] = []
var snare_time = 0.0
var _combat_status: WeakRef

func bind_combat_status(statuses: RefCounted) -> void:
	_combat_status = weakref(statuses)

func setup(room: Dictionary) -> void:
	patches.clear()
	snare_time = 0.0
	var kind: String = TYPES.get(room.template_id, "")
	if kind.is_empty() or room.kind not in ["combat", "elite", "challenge", "secret"]:
		return
	if kind == "chandelier":
		var chandelier := Chandelier.place(room)
		if not chandelier.is_empty():
			patches.append(chandelier)
		return
	var placed: Array[Vector2] = []
	for anchor: Vector2 in room.hazard_slots:
		var center = anchor
		# Both touch layouts have action buttons just below the outer lanes.
		if center.y > 197.0 and (center.x < 181.0 or center.x > 683.0):
			center.y = 197.0
		if kind == "glass":
			center.x = clampf(center.x, 235.0, 610.0)
		if not Dungeon.clear_of(center, room.cover, 45.0) or not Dungeon.clear_of(center, room.spawns, 41.0):
			continue
		if not Dungeon.routes_reachable(room.cover + placed + [center], room.exit_positions.values() + [room.reward]):
			continue
		placed.append(center)
		patches.append({"x": center.x, "y": center.y, "phase": 0, "kind": kind,
			"left": 1.65 + patches.size() * 0.93, "contact": false, "slant": 1 if patches.size() % 2 == 0 else -1})

func restore(saved: Variant, saved_snare: float) -> void:
	snare_time = clampf(saved_snare, 0.0, ROOT_DURATION)
	# A save from before the room mechanic shipped keeps its current encounter intact.
	if not saved is Array:
		patches.clear()
		return
	for i in range(mini(saved.size(), patches.size())):
		var patch: Variant = saved[i]
		if patch is Dictionary:
			patches[i].phase = clampi(int(patch.get("phase", 0)), 0, 3)
			patches[i].left = maxf(0.0, float(patch.get("left", RESET_DELAY)))
			patches[i].contact = bool(patch.get("contact", false))
			patches[i].next_tick = clampf(float(patch.get("next_tick", 0.0)), 0.0, 0.60)

func tick(game, before: Vector2, delta: float) -> void:
	snare_time = maxf(0.0, snare_time - delta)
	for patch in patches:
		if patch.kind == "chandelier":
			Chandelier.tick(game, patch, delta)
			continue
		if int(patch.phase) == 3:
			continue
		if str(patch.kind) == "glass":
			tick_glass(game, patch, delta)
			continue
		var is_vent = patch.kind == "spores"
		var is_drain = patch.kind == "drain"
		patch.left -= delta
		if patch.left <= 0.0:
			match int(patch.phase):
				0:
					patch.phase = 1
					patch.left += WARNING
					game.sound.play("warning", 0.82)
				1:
					patch.phase = 2
					patch.left += 1.30 if is_vent or is_drain else BLOOM
					patch.contact = false
					patch.next_tick = 0.0
				2:
					patch.phase = 0
					patch.left += RESET_DELAY
		if is_vent:
			tick_vent(game, patch, delta)
			continue
		if is_drain:
			tick_drain(game, patch, delta)
			continue
		if patch.kind == "thread":
			tick_thread(game, patch, before)
			continue
		if patch.phase == 2 and not patch.contact and Geometry.segment_gap(game.target(patch), before, game.player) <= RADIUS:
			patch.contact = true
			if str(patch.kind) == "roots":
				if game.mercy <= 0.0:
					if game.combat_status.apply_hero(Statuses.ROOT, ROOT_DURATION, 1.0, "root_grapple", "hazard"):
						game.sound.play("hurt", 0.78)
			else:
				game.damage_hero(DAMAGE)

func tick_vent(game, patch: Dictionary, delta: float) -> void:
	if patch.phase != 2:
		return
	patch.next_tick = maxf(0.0, float(patch.get("next_tick", 0.0)) - delta)
	if patch.next_tick <= 0.0 and game.player.distance_to(game.target(patch)) <= SPORE_RADIUS:
		patch.next_tick = 0.60
		var before := int(game.hp)
		game.damage_hero(5)
		if int(game.hp) < before:
			game.combat_status.apply_hero(Statuses.POISON, 2.5, 1.0, "spore_vent", "hazard")

func tick_drain(game, patch: Dictionary, delta: float) -> void:
	if patch.phase != 2:
		return
	patch.next_tick = maxf(0.0, float(patch.get("next_tick", 0.0)) - delta)
	var center: Vector2 = game.target(patch)
	var distance: float = center.distance_to(game.player)
	if patch.next_tick > 0.0 or distance <= LILY_PAD_RADIUS or distance > DRAIN_RADIUS:
		return
	patch.next_tick = 0.60
	var before: int = game.hp
	game.damage_hero(5)
	var stolen = before - int(game.hp)
	if stolen <= 0:
		return
	var closest: Dictionary = {}
	var nearest = 200.0 * 200.0
	for foe: Dictionary in game.foes:
		var gap: float = center.distance_squared_to(game.target(foe))
		if int(foe.hp) > 0 and int(foe.hp) < int(foe.max) and gap < nearest and not foe.get("web_anchor", false):
			nearest = gap
			closest = foe
	if not closest.is_empty():
		closest.hp = mini(int(closest.max), int(closest.hp) + Statuses.foe_healing(closest, stolen))

func tick_thread(game, patch: Dictionary, before: Vector2) -> void:
	if patch.phase != 2 or patch.contact:
		return
	var center: Vector2 = game.target(patch)
	var axis = thread_axis(patch)
	var start = center - axis
	var finish = center + axis
	var crossing: Variant = Geometry2D.segment_intersects_segment(before, game.player, start, finish)
	if crossing != null or Geometry.segment_gap(game.player, start, finish) <= THREAD_HALF_WIDTH:
		patch.contact = true
		var hp_before := int(game.hp)
		game.damage_hero(10)
		if int(game.hp) < hp_before:
			game.combat_status.apply_hero(Statuses.BLEED, 2.8, 0.8, "crimson_thread", "hazard")

static func thread_axis(patch: Dictionary) -> Vector2:
	return Vector2(48.0, 17.0 * int(patch.slant))

func sever_melee(game, position: Vector2, facing: Vector2, reach: float) -> void:
	for patch in patches:
		if patch.kind != "thread" or patch.phase == 3:
			continue
		var center: Vector2 = game.target(patch)
		var axis = thread_axis(patch)
		for anchor in [center - axis, center + axis]:
			var gap: Vector2 = anchor - position
			var aimed = gap.is_zero_approx() or gap.normalized().dot(facing) >= 0.15
			if gap.length() <= reach and aimed and not Geometry.blocked(game, position, anchor, 15.0):
				patch.phase = 3
				game.sound.play("hit", 1.09)
				break

func sever_bolt(game, start: Vector2, finish: Vector2) -> bool:
	for patch in patches:
		if patch.kind != "thread" or patch.phase == 3:
			continue
		var center: Vector2 = game.target(patch)
		var axis = thread_axis(patch)
		for anchor in [center - axis, center + axis]:
			if Geometry.segment_gap(anchor, start, finish) <= 11.0:
				patch.phase = 3
				game.sound.play("hit", 1.09)
				return true
	return false

func tick_glass(game, patch: Dictionary, delta: float) -> void:
	var center: Vector2 = game.target(patch)
	if patch.phase == 0:
		if game.player.distance_to(center) <= 53.0:
			patch.phase = 1
			patch.left = GLASS_WARNING
			game.sound.play("warning", 1.17)
		return
	patch.left -= delta
	if patch.left > 0.0:
		return
	if patch.phase == 2:
		patch.phase = 3
		return
	patch.phase = 2
	patch.left = GLASS_COOLDOWN
	game.sound.play("hit", 1.26)
	for index in range(6):
		var direction = Vector2.from_angle(glass_angle(index))
		game.bolts.append({"x": center.x, "y": center.y, "dx": direction.x, "dy": direction.y,
			"speed": 130.0, "life": 0.85, "damage": 7, "radius": 7.0, "glass_shard": true})

func break_snare() -> float:
	var statuses = _combat_status.get_ref() if _combat_status != null else null
	if statuses != null and statuses.cleanse_hero(Statuses.ROOT):
		return ROOT_BREAK_DASH
	if snare_time <= 0.0:
		return 1.0
	snare_time = 0.0
	return ROOT_BREAK_DASH

func movement_scale() -> float:
	var statuses = _combat_status.get_ref() if _combat_status != null else null
	return 0.38 if snare_time > 0.0 or (statuses != null and statuses.has_hero(Statuses.ROOT)) else 1.0

static func glass_angle(index: int) -> float:
	return -PI * 0.5 + TAU * (float(index) + 0.5) / 6.0

func disarm() -> void:
	snare_time = 0.0
	var statuses = _combat_status.get_ref() if _combat_status != null else null
	if statuses != null:
		statuses.cleanse_hero(Statuses.ROOT)
	for patch in patches:
		patch.phase = 3
		if patch.kind == "chandelier":
			patch.left = 0.0

func trim(game, position: Vector2, facing: Vector2, reach: float) -> bool:
	var trimmed = false
	for patch in patches:
		var offset: Vector2 = game.target(patch) - position
		if patch.kind == "thorns" and patch.phase != 3 and offset.length() <= reach and (offset.is_zero_approx() or offset.normalized().dot(facing) >= 0.15):
			patch.phase = 3
			trimmed = true
	return trimmed

func catch_charge(game, start: Vector2, finish: Vector2) -> bool:
	for patch in patches:
		if patch.kind == "thorns" and patch.phase == 2 and Geometry.segment_gap(game.target(patch), start, finish) <= RADIUS:
			patch.phase = 3
			return true
	return false

func draw(game) -> void:
	var canvas: Node2D = game.world_canvas
	for patch in patches:
		var point: Vector2 = game.target(patch)
		if patch.kind == "chandelier":
			Chandelier.draw(game, patch, point)
			continue
		if patch.kind == "glass":
			draw_glass(game, patch, point)
			continue
		if patch.kind == "spores":
			draw_vent(game, patch, point)
			continue
		if patch.kind == "drain":
			draw_drain(canvas, patch, point, game.visual_clock)
			continue
		if patch.kind == "thread":
			draw_thread(canvas, patch, point)
			continue
		if patch.phase == 3:
			# Clipped stems stay visible after removing the hazard.
			canvas.draw_circle(point, 12, Color(0.10, 0.19, 0.14, 0.36), true, -1.0, true)
			continue
		canvas.draw_circle(point, RADIUS, Color(0.10, 0.15, 0.12, 0.58), true, -1.0, true)
		if patch.phase == 1:
			Geometry.paint_circle(canvas, point, RADIUS, clampf(1.0 - float(patch.left) / WARNING, 0, 1))
		var height = 4.0 if patch.phase == 0 else 12.0
		var tint = Color("#a8ba70") if patch.phase == 0 else Color("#e0b78e")
		if patch.kind == "roots":
			var moving = 1.0 + sin(game.visual_clock * 8.0) * 0.07 if patch.phase == 2 else 1.0
			draw_tile(canvas, 3 if patch.phase == 2 else 0, point, (34.0 if patch.phase == 2 else 19.0) * moving)
			continue
		for i in range(6):
			var angle = i * TAU / 6.0
			var base = (point + Vector2.from_angle(angle) * (8.0 + 6.0 * (i % 2))).round()
			var spike = base + Vector2(-4 + i, -height)
			canvas.draw_colored_polygon(PackedVector2Array([base + Vector2(-4, 1), spike, base + Vector2(4, 1)]), tint)
	if snare_time > 0.0:
		var center: Vector2 = game.player
		canvas.draw_arc(center, 18.0, 0.0, TAU, 30, Color("#e9ce8c"), 2.0, true)
		draw_roots(canvas, center, 2, Color("#c1a46d"))

static func draw_roots(canvas: Node2D, point: Vector2, phase: int, color: Color) -> void:
	var length = 22.0 if phase == 2 else 11.0
	for i in range(5):
		var direction = Vector2.from_angle(i * TAU / 5.0)
		canvas.draw_polyline(PackedVector2Array([point + direction * length,
			point + direction * (length * 0.48) + direction.orthogonal() * 6.0,
			point + direction.orthogonal() * 2.0]), color, 2.0, true)

static func draw_glass(game, patch: Dictionary, point: Vector2) -> void:
	var canvas: Node2D = game.world_canvas
	if patch.phase >= 2:
		draw_tile(canvas, 4, point, 26.0, Color(0.82, 0.92, 0.95, 0.74))
		return
	var glint = Color.WHITE
	if patch.phase == 1:
		var progress = clampf(1.0 - float(patch.left) / GLASS_WARNING, 0.0, 1.0)
		glint = Color.WHITE.lerp(Color(1.3, 1.55, 1.6), progress)
		for index in range(6):
			var direction = Vector2.from_angle(glass_angle(index))
			var end = Geometry.clear_endpoint(game, point, direction, 110.5, 16.0)
			Geometry.paint_lane(canvas, point, end, 7.0, progress)
	draw_tile(canvas, 1, point, 26.0, glint)

static func draw_vent(game, patch: Dictionary, point: Vector2) -> void:
	var canvas: Node2D = game.world_canvas
	draw_tile(canvas, 5 if patch.phase == 2 else 2, point, 30.0 if patch.phase == 2 else 23.0)
	if patch.phase not in [1, 2]:
		return
	if patch.phase == 1:
		Geometry.paint_circle(canvas, point, SPORE_RADIUS, clampf(1.0 - float(patch.left) / WARNING, 0.0, 1.0))
		return
	canvas.draw_circle(point, SPORE_RADIUS, Color(0.52, 0.79, 0.45, 0.24), true, -1.0, true)
	canvas.draw_arc(point, SPORE_RADIUS, 0.0, TAU, 42, Color("#c4eba5"), 1.4, true)
	for i in range(7):
		var life = fposmod(game.visual_clock * 0.82 + i / 7.0, 1.0)
		var offset = Vector2.from_angle(i * 2.4 + life * 2.0) * life * (SPORE_RADIUS - 3.0)
		canvas.draw_circle((point + offset).round(), 2.0, Color(0.85, 1.0, 0.55, 1.0 - life), true, -1.0, true)

static func draw_tile(canvas: Node2D, index: int, point: Vector2, height: float, tint := Color.WHITE) -> void:
	Art.paint_actor(canvas, TILE_ART, TILE_REGIONS[index], point + Vector2(0, 10.0),
		height, 0.0, Vector2.ONE, tint)

static func draw_drain(canvas: Node2D, patch: Dictionary, point: Vector2, clock: float) -> void:
	var active = int(patch.phase) == 2
	var radius = DRAIN_RADIUS if active else 22.0
	canvas.draw_circle(point, radius, Color(0.47, 0.13, 0.25, 0.57 if active else 0.30), true, -1.0, true)
	if int(patch.phase) == 1:
		Geometry.paint_circle(canvas, point, DRAIN_RADIUS, clampf(1.0 - float(patch.left) / WARNING, 0.0, 1.0))
	elif active:
		canvas.draw_arc(point, DRAIN_RADIUS, 0.0, TAU, 40, Color("#ffe2af"), 1.6, true)
		canvas.draw_arc(point, DRAIN_RADIUS - fposmod(clock * 23.0, 13.0), 0.0, TAU, 40, Color(0.91, 0.45, 0.59, 0.54), 1.2, true)
	canvas.draw_circle(point, LILY_PAD_RADIUS, Color("#74906b"), true, -1.0, true)
	canvas.draw_line(point, point + Vector2(6, -6), Color("#d8db9b"), 1.2, true)

static func draw_thread(canvas: Node2D, patch: Dictionary, point: Vector2) -> void:
	var axis = thread_axis(patch)
	var from = point - axis
	var to = point + axis
	var active = int(patch.phase) == 2
	var cut = int(patch.phase) == 3
	if int(patch.phase) == 1:
		Geometry.paint_lane(canvas, from, to, THREAD_HALF_WIDTH, clampf(1.0 - float(patch.left) / WARNING, 0.0, 1.0))
	elif active:
		canvas.draw_line(from, to, Color(1.0, 0.26, 0.48, 0.52), 12.0, true)
	if not cut:
		canvas.draw_line(from, to, Color("#ffd4ae") if active else Color("#ac6b7d"), 1.7, true)
	for anchor: Vector2 in [from, to]:
		canvas.draw_circle(anchor, 8.0, Color("#4a2437"), true, -1.0, true)
		canvas.draw_line(anchor + Vector2(-4, 3), anchor + Vector2(1, -6), Color("#edbe94") if not cut else Color("#78666a"), 2.3, true)
