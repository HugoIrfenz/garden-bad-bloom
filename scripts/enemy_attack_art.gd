extends RefCounted

const INK := Color("#342138")
const BRONZE := Color("#a36845")
const GOLD := Color("#ddae64")
const HIGHLIGHT := Color("#fff0b8")
const CELADON := Color("#b6d48d")
const MINT := Color("#e0edaa")
const PORCELAIN := Color("#efd0d0")


static func bolt(canvas: Node2D, projectile: Dictionary, point: Vector2,
		direction: Vector2, biome: int, clock: float) -> void:
	var known_style := ["pea", "petal", "gear", "petal", "tea", "star", "star"]
	var style := str(projectile.get("art", known_style[clampi(biome, 0, known_style.size() - 1)]))
	if projectile.get("terrain", false):
		slime_pool(canvas, point, float(projectile.radius), float(projectile.life), clock)
		return
	match style:
		"gear":
			gear(canvas, point, clock * 9.6 + point.x * 0.01, 8.0)
		"tea", "ghost_tea":
			cup(canvas, point, direction, clock, style == "ghost_tea")
		"petal":
			petal(canvas, point, direction, clock)
		"star":
			var spin := clock * 1.75
			crystal(canvas, point, spin, 7.0, Color("#b899ee"))
			crystal(canvas, (point - direction * 12.0).round(), -spin, 2.5, Color("#e2c3f4", 0.76))
		_:
			var tail := point - direction * 9.0
			for i in range(3):
				var mote := tail - direction * float(i * 5) + direction.orthogonal() * float(i - 1) * 3.0
				canvas.draw_rect(Rect2(mote.round(), Vector2.ONE * (3.0 - i * 0.5)), Color(MINT, 0.56 - i * 0.15))
			canvas.draw_set_transform(point.round(), direction.angle())
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(-5, -3), Vector2(-2, -6), Vector2(3, -6), Vector2(6, -2),
				Vector2(6, 2), Vector2(2, 5), Vector2(-3, 5), Vector2(-6, 2)]), INK)
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(-4, -3), Vector2(-1, -5), Vector2(3, -4), Vector2(5, -1),
				Vector2(4, 3), Vector2(0, 4), Vector2(-4, 2)]), CELADON)
			canvas.draw_rect(Rect2(0, -4, 3, 2), MINT)
			canvas.draw_rect(Rect2(-3, 1, 3, 2), Color("#68804e"))
			canvas.draw_set_transform(Vector2.ZERO)


static func slime_pool(canvas: Node2D, point: Vector2, radius: float, life: float, clock: float) -> void:
	var opacity := smoothstep(0.0, 0.26, life)
	var rim := PackedVector2Array()
	for i in range(18):
		var axis := Vector2.from_angle(i * TAU / 18.0)
		var wobble := 0.92 + 0.06 * sin(i * 2.3 + clock * 5.2)
		rim.append((point + axis * radius * wobble).round())
	canvas.draw_colored_polygon(rim, Color("#536a3d", opacity * 0.90))
	rim.append(rim[0])
	canvas.draw_polyline(rim, Color("#8aa151", opacity * 0.95), 2.0)
	for i in range(5):
		var phase := fposmod(clock * 1.15 + 0.42 * i, 1.0)
		var bubble := (point + Vector2.from_angle(i * 2.4) * radius * (0.24 + i * 0.12)
			- Vector2(0, 5.0 * phase)).round()
		var pale := Color(MINT, opacity * sin(phase * PI))
		canvas.draw_rect(Rect2(bubble - Vector2(1, 2), Vector2(3, 4)), pale)
		canvas.draw_rect(Rect2(bubble + Vector2(-3, 0), Vector2(7, 2)), pale)
	for i in range(3):
		var toe := (point + Vector2(-9 + i * 9, 4 - (i % 2) * 10)).round()
		canvas.draw_colored_polygon(PackedVector2Array([toe + Vector2(-4, 2), toe + Vector2(-1, -2),
			toe + Vector2(2, -11), toe + Vector2(5, 2)]), Color("#57614a", opacity))
		canvas.draw_line(toe + Vector2(-1, -1), toe + Vector2(2, -10), Color(MINT, opacity), 1.0)


static func petal(canvas: Node2D, point: Vector2, direction: Vector2, clock: float) -> void:
	var twist := cos(clock * 9.0 + point.x * 0.025)
	canvas.draw_set_transform(point.round(), direction.angle() + twist * 0.18, Vector2(1.0, 0.72 + absf(twist) * 0.28))
	var edge := PackedVector2Array([Vector2(-10, 0), Vector2(-5, -3), Vector2(-1, -6), Vector2(6, -5),
		Vector2(9, -2), Vector2(6, 3), Vector2(1, 5), Vector2(-5, 3)])
	canvas.draw_colored_polygon(edge, INK)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-7, 0), Vector2(-1, -4), Vector2(6, -4),
		Vector2(7, -2), Vector2(5, 2), Vector2(0, 3)]), Color("#da779c"))
	canvas.draw_polyline(PackedVector2Array([Vector2(-5, 0), Vector2(0, -2), Vector2(5, -3)]), Color("#ffd8c6"), 1.4)
	canvas.draw_set_transform(Vector2.ZERO)


static func gear(canvas: Node2D, point: Vector2, angle: float, radius: float) -> void:
	var cog := PackedVector2Array()
	for i in range(32):
		var reach := radius if i % 4 in [1, 2] else radius * 0.74
		cog.append(point.round() + Vector2.from_angle(angle + i * TAU / 32.0) * reach)
	canvas.draw_colored_polygon(cog, BRONZE)
	cog.append(cog[0])
	canvas.draw_polyline(cog, GOLD, 1.4)
	canvas.draw_circle(point.round(), radius * 0.38, INK)
	for i in range(4):
		var axis := Vector2.from_angle(angle + i * TAU * 0.25)
		canvas.draw_rect(Rect2((point + axis * radius * 0.59).round(), Vector2(1, 2)), HIGHLIGHT)


static func cup(canvas: Node2D, point: Vector2, direction: Vector2, clock: float, ghost := false) -> void:
	var tilt := clampf(direction.x, -1.0, 1.0) * 0.50
	var tint := Color("#c5b4f0") if ghost else PORCELAIN
	for i in range(3):
		var rise := fposmod(clock * 0.95 + i * 0.28, 1.0)
		var steam := (point - Vector2(0, 7.0 + rise * 10.0) - direction * rise * 10.0).round()
		canvas.draw_rect(Rect2(steam, Vector2(2.0 + 2.0 * rise, 2.0)), Color(tint, (1.0 - rise) * 0.62))
	canvas.draw_set_transform(point.round(), tilt, Vector2(-1.0 if direction.x < 0.0 else 1.0, 1))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-7, -5), Vector2(4, -6), Vector2(7, -3),
		Vector2(10, -2), Vector2(9, 2), Vector2(6, 3), Vector2(4, 6), Vector2(-4, 6), Vector2(-7, 3)]), INK)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-6, -3), Vector2(6, -3), Vector2(4, 4),
		Vector2(-3, 4), Vector2(-5, 2)]), tint)
	canvas.draw_rect(Rect2(-5, -4, 10, 2), Color("#a66573"))
	canvas.draw_rect(Rect2(-3, -1, 2, 3), Color("#fff2e0"))
	canvas.draw_rect(Rect2(0, 2, 3, 1), Color("#906185"))
	canvas.draw_rect(Rect2(6, -1, 2, 2), tint)
	canvas.draw_set_transform(Vector2.ZERO)


static func crown(canvas: Node2D, point: Vector2, ratio: float) -> void:
	var rotation := ratio * TAU * 1.95
	var face := cos(rotation)
	var foot := point.round()
	canvas.draw_rect(Rect2(foot + Vector2(-5, 3), Vector2(11, 3)), Color("#342138", 0.61))
	canvas.draw_set_transform(foot - Vector2(0, 5), sin(rotation) * 0.26, Vector2(0.57 + 0.43 * absf(face), 1.0))
	var edge := PackedVector2Array([Vector2(-15, -8), Vector2(-7, -3), Vector2(-1, -12), Vector2(5, -3),
		Vector2(14, -8), Vector2(10, 6), Vector2(6, 8), Vector2(-8, 8), Vector2(-12, 5)])
	canvas.draw_colored_polygon(edge, INK)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-12, -5), Vector2(-7, -1), Vector2(-1, -9),
		Vector2(6, -1), Vector2(12, -5), Vector2(9, 5), Vector2(-9, 5)]), GOLD)
	canvas.draw_line(Vector2(-10, 3), Vector2(9, 3), HIGHLIGHT, 1.8)
	if face >= 0.0:
		canvas.draw_rect(Rect2(-2, -3, 5, 6), Color("#964467"))
		canvas.draw_rect(Rect2(-1, -3, 2, 2), Color("#ffd8cb"))
	canvas.draw_set_transform(Vector2.ZERO)


static func clock_hand(canvas: Node2D, from: Vector2, to: Vector2, clock: float) -> void:
	var span := from.distance_to(to)
	if span < 1.0:
		return
	var heading := from.angle_to_point(to)
	canvas.draw_set_transform(from.round(), heading, Vector2(span / 137.0, 1.0))
	span = 137.0
	var silhouette := PackedVector2Array([Vector2(-12, -6), Vector2(-3, -9), Vector2(25, -6),
		Vector2(span * 0.63, -3), Vector2(span - 17, -7), Vector2(span, 0),
		Vector2(span - 17, 7), Vector2(span * 0.63, 3), Vector2(25, 6), Vector2(-3, 9), Vector2(-12, 6)])
	canvas.draw_colored_polygon(silhouette, INK)
	canvas.draw_polyline(PackedVector2Array([Vector2(0, -5), Vector2(24, -4), Vector2(span * 0.63, -2),
		Vector2(span - 15, -4), Vector2(span - 3, 0)]), GOLD, 2.3)
	canvas.draw_line(Vector2(10, 1), Vector2(span - 20, 1), HIGHLIGHT, 1.0)
	canvas.draw_set_transform(Vector2.ZERO)
	gear(canvas, from, clock * 6.0, 10.0)


static func brambles(canvas: Node2D, from: Vector2, to: Vector2, strength: float) -> void:
	var reach := from.distance_to(to)
	if reach < 8.0:
		return
	var heading := from.direction_to(to)
	var side := heading.orthogonal()
	var count := maxi(2, int(reach / 20.0))
	var root := PackedVector2Array([from])
	for i in range(1, count):
		var ratio := float(i) / count
		var sign_value := 1.0 if i % 2 == 0 else -1.0
		var foot := (from.lerp(to, ratio) + side * sign_value * 7.0).round()
		root.append(foot)
		var tip := (foot + side * sign_value * 12.0 + heading * 7.0 - Vector2(0, 12) * strength).round()
		canvas.draw_colored_polygon(PackedVector2Array([foot - heading * 7.0,
			foot + heading * 8.0 + side * sign_value * 3.0, tip]), Color("#72504d", 0.9 * strength))
		canvas.draw_line(foot - heading * 7.0, tip, Color("#bbaa77", strength), 1.4)
	root.append(to)
	canvas.draw_polyline(root, Color("#4b343c", strength), 6.0)
	canvas.draw_polyline(root, Color("#93774b", strength), 2.3)


static func crystal(canvas: Node2D, point: Vector2, spin: float, size: float, tint: Color) -> void:
	canvas.draw_set_transform(point.round(), spin)
	var vertices := PackedVector2Array([Vector2(-size, -1), Vector2(-2, -size * 0.71),
		Vector2(size * 0.43, -size), Vector2(size, 0), Vector2(2, size * 0.63), Vector2(-size * 0.46, size * 0.56)])
	canvas.draw_colored_polygon(vertices, tint)
	canvas.draw_colored_polygon(PackedVector2Array([vertices[1], vertices[2], vertices[3], Vector2.ZERO]),
		tint.lightened(0.41))
	canvas.draw_colored_polygon(PackedVector2Array([vertices[0], Vector2.ZERO, vertices[4], vertices[5]]),
		tint.darkened(0.40))
	canvas.draw_set_transform(Vector2.ZERO)


static func meteor(canvas: Node2D, point: Vector2, height: float, ratio: float, tint: Color) -> void:
	var tip := point - Vector2(height * 0.40, height)
	for i in range(5):
		var distance := i * (6 + height * 0.048)
		var trail := tip - Vector2(-2.0 + distance * .4, distance)
		crystal(canvas, trail, ratio * 2.1 + i * .6, 6.0 - i * 0.8, Color(tint, 1.0 - i * 0.18))
	crystal(canvas, tip, ratio * 3.0, 10.0, tint)


static func shatter(canvas: Node2D, point: Vector2, fade: float, tint: Color) -> void:
	for i in range(7):
		var direction := Vector2.from_angle(i * TAU / 7.0 + 0.11 * (i % 3))
		var burst := point + direction * (6.0 + (1.0 - fade) * (11 + i * 2)) - Vector2(0, sin(fade * PI) * 8.0)
		crystal(canvas, burst, direction.angle() + (1.0 - fade), 3.0 + i % 3, Color(tint, fade))


static func saucer(canvas: Node2D, point: Vector2, ratio: float) -> void:
	var spin := ratio * TAU * 7.0
	canvas.draw_set_transform(point.round(), sin(spin) * 0.49, Vector2(1.0, 0.38 + absf(cos(spin)) * 0.57))
	canvas.draw_circle(Vector2.ZERO, 13.0, INK)
	canvas.draw_circle(Vector2(-1.0, -1.0), 11.4, PORCELAIN)
	canvas.draw_arc(Vector2.ZERO, 9.0, 0, TAU, 24, Color("#a06eab"), 1.2)
	canvas.draw_circle(Vector2.ZERO, 5.0, Color("#b487b0"))
	for axis in [Vector2(0, -8), Vector2(-8, 0), Vector2(0, 8), Vector2(8, 0)]:
		canvas.draw_rect(Rect2(axis - Vector2.ONE, Vector2(2, 2)), Color("#593b74"))
	canvas.draw_set_transform(Vector2.ZERO)
