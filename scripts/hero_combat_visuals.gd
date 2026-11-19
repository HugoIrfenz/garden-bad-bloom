extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const BASIC_POSES = preload("res://assets/art/hero_basic_poses.png")
const SKILL_POSES = preload("res://assets/art/hero_skill_poses.png")
# The art extends past neighboring columns at different heights. Banded crops
# keep every weapon and boot while preserving the original transparent pixels.
const BASIC_BANDS = [
	[146, 340, [0, 435, 868, 1269, 1737, 2172]],
	[340, 541, [0, 403, 868, 1267, 1715, 2172]],
	[541, 651, [0, 434, 843, 1274, 1661, 2172]],
]
const SKILL_BANDS = [
	[111, 406, [0, 434, 875, 1260, 1710, 2172]],
	[406, 628, [0, 435, 868, 1196, 1705, 2172]],
]
const BASIC_ANCHORS = [
	Vector2(182, 634), Vector2(610, 635), Vector2(1014, 634), Vector2(1418, 635), Vector2(1873, 634),
]
const SKILL_ANCHORS = [
	Vector2(220, 604), Vector2(626, 605), Vector2(1012, 594), Vector2(1377, 607), Vector2(1880, 599),
]
const FROST = Color("#a3deff")
const GOLD = Color("#ffe2a0")
const ROSE = Color("#f1a4d4")
const ORCHID = Color("#d096ff")
const RIBBON = Color("#ffc6bb")
const IRIS = Color("#79e9e5")
const INK = Color("#bb94ff")
const LILY_ECHO = Color("#ebb0ff")

static func action_body(canvas: Node2D, hero: int, feet: Vector2, height: float, direction: Vector2,
		phase: float, skill: bool, tint: Color, impact := 0.0, repeat := false) -> void:
	phase = clampf(phase, 0.0, 1.0)
	var side := -1.0 if direction.x < -0.09 else 1.0
	var peak := sin(PI * phase)
	var impulse := sin(PI * smoothstep(0.0, 0.85, phase))
	var shift := pose_shift(hero, direction, phase)
	var lean: float = [0.17, -0.11, 0.23, -0.10, 0.20][hero]
	var stretch := Vector2(1.0 + peak * 0.05, 1.0 - peak * 0.05)
	if skill:
		var stride: float = [3.0, -2.0, 8.0, 3.0, 8.0][hero]
		shift = direction * stride * impulse
		lean *= 0.58
		stretch.y -= peak * (0.02 if hero in [1, 2] else 0.08)
	if impact > 0.0:
		shift -= direction * impact * 4.5
		stretch.x += impact * 0.07
	if repeat:
		shift += direction.orthogonal() * impulse * 4.0
		lean *= -0.64
	if direction.y < -0.67 and absf(direction.x) < 0.52:
		canvas.draw_set_transform((feet + shift).round(), lean * side * peak, stretch)
		Art.walk(canvas, hero, Vector2.ZERO, height, 0.0, Vector2.UP, false, tint)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	var atlas := SKILL_POSES if skill else BASIC_POSES
	var anchor: Vector2 = SKILL_ANCHORS[hero] if skill else BASIC_ANCHORS[hero]
	var bands: Array = SKILL_BANDS if skill else BASIC_BANDS
	var image_scale := height / 465.0
	canvas.draw_set_transform((feet + shift).round(), lean * side * peak, Vector2(stretch.x * side, stretch.y))
	for band: Array in bands:
		var rail: Array = band[2]
		var source := Rect2(float(rail[hero]), float(band[0]), float(rail[hero + 1] - rail[hero]), float(band[1] - band[0]))
		var destination := Rect2((source.position - anchor) * image_scale, source.size * image_scale)
		canvas.draw_texture_rect_region(atlas, destination, source, tint)
	canvas.draw_set_transform(Vector2.ZERO)

static func pose_shift(hero: int, direction: Vector2, phase: float) -> Vector2:
	var thrust := sin(PI * clampf(phase, 0.0, 1.0))
	var stride: float = [7.0, -4.0, 12.0, -5.0, 9.0][hero]
	var side := (sin(phase * TAU) * 4.0 if hero in [2, 4] else 0.0)
	return direction * stride * thrust + direction.orthogonal() * side

static func basic(canvas: Node2D, hero: int, center: Vector2, direction: Vector2, phase: float, finisher: bool,
		repeat := false) -> void:
	var tail := 1.0 - phase
	var angle := direction.angle()
	var side := direction.orthogonal()
	match hero:
		0:
			var slash := angle + (1.65 - phase * 2.75 if repeat else -1.75 + phase * 2.75)
			var reach := 37.0 + phase * 17.0
			var blade := LILY_ECHO if repeat else FROST
			canvas.draw_arc(center, reach, slash - 0.94, slash + 0.35, 31, Color(blade, tail * 0.80), 9.0, true)
			canvas.draw_arc(center, reach + 3.0, slash - 0.82, slash + 0.34, 31, Color.WHITE * Color(1, 1, 1, tail), 2.4, true)
			spark(canvas, center + Vector2.from_angle(slash + 0.3) * (reach + 3.0), 4.0 + 4.0 * tail, Color(blade, tail))
			if finisher:
				canvas.draw_arc(center, reach + 13.0, slash - 1.17, slash + 0.5, 32, Color(GOLD, tail), 4.0, true)
				for i in range(3):
					var arc_angle := slash - 0.65 + i * 0.5
					spark(canvas, center + Vector2.from_angle(arc_angle) * (reach + 18.0), 4.0, Color(GOLD, tail))
		1:
			var source := center + direction * 22.0 + side * (-6.0 if repeat else 2.0)
			flower(canvas, source, 13.0 + phase * 8.0, phase * (-1.4 if repeat else 0.92),
				Color(LILY_ECHO if repeat else ROSE, tail))
			canvas.draw_arc(source, 19.0 + phase * 3.0, -0.1, TAU, 28, Color(INK, tail * 0.68), 1.4, true)
			for i in range(3):
				var offset := Vector2.from_angle(angle + i * TAU / 3.0 + phase * 2.0) * (13.0 + phase * 15.0)
				spark(canvas, source + offset, 3.0, Color("#ffe5ef", tail))
		2:
			var step := smoothstep(0.0, 0.84, phase)
			var point := center + direction * (21.0 + step * 29.0) + side * (10.0 if repeat else -8.0)
			var purple := LILY_ECHO if repeat else ORCHID
			canvas.draw_line(point - direction * 22.0, point, Color(purple, tail), 6.5, true)
			spark(canvas, point, 15.0 - step * 6.0, Color("#f4d9fa", tail))
			canvas.draw_arc(point, 11.0 + step * 10.0, angle - 0.83, angle + 0.83, 18, Color(purple, tail), 3.2, true)
		3:
			var point := center + direction * 15.0 + side * (-7.0 if repeat else 0.0)
			var pull := point - direction * (17.0 - phase * 5.0)
			var bow := PackedVector2Array([point - side * 20.0, pull, point + side * 20.0])
			canvas.draw_polyline(bow, Color("#fff0c7", tail * 0.9), 1.6, true)
			var arrow := LILY_ECHO if repeat else RIBBON
			canvas.draw_arc(point, 20.0, angle - PI * 0.50, angle + PI * 0.50, 22, Color(arrow, tail), 2.8, true)
			canvas.draw_line(point, point + direction * (19.0 + phase * 29.0), Color(LILY_ECHO if repeat else GOLD, tail), 2.0, true)
		4:
			for i in range(2):
				var along := 0.62 if i == 0 else -0.59
				var point := center + direction * (15.0 + phase * 27.0) + side * (13.0 if i == 0 else -12.0)
				var swipe := direction.rotated(along) * (17.0 + phase * 9.0)
				var tint := LILY_ECHO if repeat else (IRIS if i == 0 else INK)
				canvas.draw_line(point - swipe, point + swipe, Color(tint, tail * 0.65), 8.4, true)
				canvas.draw_line(point - swipe * 0.68, point + swipe * 0.75, Color("#edffff", tail), 2.2, true)
				spark(canvas, point + swipe * 0.95, 4.0, Color(tint, tail))

static func repeat_projectile(canvas: Node2D, center: Vector2, direction: Vector2) -> void:
	canvas.draw_line(center - direction * 16.0, center - direction * 3.0,
		Color(LILY_ECHO, 0.72), 3.0, true)
	canvas.draw_arc(center, 6.0, direction.angle() - 1.2, direction.angle() + 1.2,
		15, LILY_ECHO, 1.4, true)

static func projectile(canvas: Node2D, hero: int, center: Vector2, direction: Vector2, clock: float) -> void:
	var side := direction.orthogonal()
	if hero == 1:
		canvas.draw_line(center - direction * 12.0, center, Color(INK, 0.56), 4.0, true)
		flower(canvas, center, 6.6, clock * 7.0, ROSE)
		canvas.draw_circle(center, 2, Color("#fff3fb"), true, -1.0, true)
	else:
		canvas.draw_line(center - direction * 22.0, center + direction * 6.0, Color(GOLD, 0.83), 2.1, true)
		canvas.draw_colored_polygon(PackedVector2Array([center + direction * 9.0,
			center + side * 4.0, center - direction * 4.0, center - side * 4.0]), Color("#fff0b8"))
		canvas.draw_line(center - direction * 21.0, center - direction * 12.0 + side * 4.0, RIBBON, 2.0, true)
		canvas.draw_line(center - direction * 21.0, center - direction * 12.0 - side * 4.0, RIBBON, 2.0, true)

static func step_sweep(canvas: Node2D, center: Vector2, direction: Vector2, tint: Color, alpha: float) -> void:
	var side := direction.orthogonal()
	for index in range(3):
		var point := center - direction * (12.0 + index * 10.0) + side * ((index - 1) * 7.0)
		canvas.draw_line(point - direction * (10.0 - 2.0 * index), point, Color(tint, alpha * 0.58), 2.3, true)

static func flower(canvas: Node2D, center: Vector2, radius: float, angle: float, tint: Color) -> void:
	var outline := PackedVector2Array()
	for i in range(41):
		var spin := float(i) * TAU / 40.0
		var shape := radius * (0.76 + 0.24 * cos(spin * 5.0))
		outline.append(center + Vector2.from_angle(angle + spin) * shape)
	canvas.draw_polyline(outline, tint, 2.05, true)

static func spark(canvas: Node2D, center: Vector2, radius: float, tint: Color) -> void:
	var outline := PackedVector2Array()
	for index in range(8):
		var length := radius if index % 2 == 0 else radius * 0.25
		outline.append(center + Vector2.from_angle(index * TAU / 8.0) * length)
	canvas.draw_colored_polygon(outline, tint)
