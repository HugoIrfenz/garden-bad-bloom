extends RefCounted

const GOLD := Color("#ffe3a7")
const PINK := Color("#ffb9b1")
const BLUE := Color("#b4e5ee")
const FLOWERS := [Color("#a1d3ff"), Color("#f09cb4"), Color("#d7b8ff"), Color("#ffb6bc"), Color("#a3e7da")]
const BLOOM_FLOWERS := [Vector2(0.164, 0.586), Vector2(0.334, 0.598), Vector2(0.503, 0.573),
	Vector2(0.657, 0.597), Vector2(0.832, 0.609)]
const BLOOM_SEED := Vector2(0.503, 0.810)
const WATER_SPOUT := Vector2(0.531, 0.588)
const WATER_SOIL := Vector2(0.562, 0.689)
const TEAPOT := Vector2(0.523, 0.357)
const TEACUP := Vector2(0.534, 0.400)
const THORN_PATH := [Vector2(0.811, 0.604), Vector2(0.735, 0.625), Vector2(0.681, 0.626),
	Vector2(0.624, 0.653), Vector2(0.573, 0.627), Vector2(0.515, 0.659), Vector2(0.451, 0.651), Vector2(0.393, 0.695)]
const WEAPONS := [Vector2(0.521, 0.120), Vector2(0.399, 0.243), Vector2(0.704, 0.541),
	Vector2(0.268, 0.420), Vector2(0.945, 0.626)]
const WEAPON_TIMES := [1.47, 1.80, 2.13, 2.44, 2.76]


static func draw(canvas: Node2D, page: int, time: float, source: Rect2,
		texture_size: Vector2, image: Rect2, alpha: float) -> void:
	if alpha <= 0.0:
		return
	match page:
		0:
			dust(canvas, image, time, GOLD, alpha * 0.60, 19)
			var spout := on_image(WATER_SPOUT, source, texture_size, image)
			var soil := on_image(WATER_SOIL, source, texture_size, image)
			watering(canvas, spout, soil, time, alpha)
		1:
			var seed := on_image(BLOOM_SEED, source, texture_size, image)
			for index in range(BLOOM_FLOWERS.size()):
				var tip := on_image(BLOOM_FLOWERS[index], source, texture_size, image)
				flower_reveal(canvas, seed, tip, time, index, alpha)
			dust(canvas, image, time, GOLD, alpha * 0.73, 24)
		2:
			dust(canvas, image, time, PINK, alpha, 21)
			dapple(canvas, image, time, alpha)
			teatime(canvas, on_image(TEAPOT, source, texture_size, image),
				on_image(TEACUP, source, texture_size, image), time, alpha)
		3:
			var roots := PackedVector2Array()
			for location: Vector2 in THORN_PATH:
				roots.append(on_image(location, source, texture_size, image))
			blight(canvas, roots, time, alpha)
			dust(canvas, image, time * 1.22, Color("#e680ab"), alpha * 0.86, 25)
		4:
			dust(canvas, image, time, PINK, alpha * 0.65, 18)
			for index in range(WEAPONS.size()):
				var point := on_image(WEAPONS[index], source, texture_size, image)
				ready_weapon(canvas, point, index, time - WEAPON_TIMES[index], alpha)


static func on_image(normalized: Vector2, source: Rect2, texture_size: Vector2, image: Rect2) -> Vector2:
	return image.position + (normalized * texture_size - source.position) * image.size / source.size


static func dust(canvas: Node2D, image: Rect2, time: float, tint: Color, alpha: float, count: int) -> void:
	var air := Rect2(image.position + Vector2(19, 12), image.size - Vector2(38, 85))
	for index in range(count):
		var speed := 0.36 + (index % 5) * 0.12
		var phase := fposmod(time * 0.15 * speed + index * 0.137, 1.0)
		var x := fposmod(index * 73.37 + time * (2.15 + index % 3), air.size.x)
		var y := fposmod(index * 38.13 - time * 17.5 * speed, air.size.y)
		var point := (air.position + Vector2(x + sin(time * 1.1 + index) * 6.0, y)).round()
		var glow := alpha * sin(PI * phase) * (0.22 + (index % 4) * 0.095)
		if index % 6 == 0:
			pixel_glint(canvas, point, 4.0, Color(tint, glow))
		else:
			var width := 2.0 if index % 3 == 0 else 1.0
			canvas.draw_rect(Rect2(point, Vector2(width + 1.0, width)), Color(tint, glow))


static func watering(canvas: Node2D, spout: Vector2, soil: Vector2, time: float, alpha: float) -> void:
	var pour := smoothstep(0.56, 1.06, time) * (1.0 - smoothstep(3.74, 4.73, time))
	for i in range(15):
		var flight := fposmod(time * 3.3 + i * 0.128, 1.0)
		var point := spout.lerp(soil, flight) - Vector2(0, sin(flight * PI) * (6.0 + i % 4))
		point.x += (i % 5 - 2) * flight * 2.7
		var shine := alpha * pour * sin(flight * PI) * (0.63 + i % 3 * 0.13)
		canvas.draw_rect(Rect2(point.round(), Vector2(2, 2 + float(i % 3))), Color(BLUE, shine))
		if i % 3 == 0:
			canvas.draw_rect(Rect2(point.round(), Vector2.ONE), Color("#fff7d9", shine))
	for i in range(5):
		var splash := fposmod(time * 2.15 + i * 0.17, 1.0)
		var lift := sin(splash * PI) * (4.0 + i % 3)
		var direction := (i % 2 * 2.0 - 1.0) * (5.0 + i % 3 * 2.5)
		var point := (soil + Vector2(direction * splash, -lift)).round()
		canvas.draw_rect(Rect2(point, Vector2(2, 1)), Color(BLUE, pour * (1.0 - splash) * alpha))


static func flower_reveal(canvas: Node2D, seed: Vector2, tip: Vector2, time: float, index: int, alpha: float) -> void:
	var grow := clampf((time - 0.38 - index * 0.15) / 1.38, 0.0, 1.0)
	var glow := sin(grow * PI)
	if grow > 0.0 and grow < 1.0:
		for spark in range(6):
			var along := grow - spark * 0.071
			if along <= 0.0:
				continue
			var stem := seed.lerp(tip, along)
			stem.y += sin(along * PI) * (8.0 + absf(tip.x - seed.x) * 0.058)
			pixel_glint(canvas, stem.round(), 7.0 - spark * 0.82,
				Color(FLOWERS[index], alpha * glow * (0.84 - spark * 0.09)))
	var reveal := clampf((time - 1.56 - index * 0.12) / 1.65, 0.0, 1.0)
	if reveal <= 0.0 or reveal >= 1.0:
		return
	var energy := sin(reveal * PI)
	for i in range(11):
		var axis := Vector2.from_angle(i * TAU / 11.0 + 0.05 * index)
		var spark := (tip + axis * Vector2(1.0, 0.61) * (9.0 + reveal * 34.0)
			- Vector2(0, reveal * 36.0)).round()
		pixel_glint(canvas, spark, 3.0 + float(i % 3), Color(FLOWERS[index], alpha * energy * 0.86))


static func dapple(canvas: Node2D, image: Rect2, time: float, alpha: float) -> void:
	for i in range(11):
		var progress := fposmod(i * 0.193 + time * (0.12 + i % 3 * 0.023), 1.0)
		var x := image.position.x + 55.0 + fposmod(i * 95.0, image.size.x - 126.0) + progress * 37.0
		var y := image.position.y + float(i % 4) * 27.0 + progress * 122.0
		var center := Vector2(x + sin(progress * TAU + i) * 6.0, y).round()
		var color := Color(PINK if i % 2 == 0 else GOLD, sin(PI * progress) * alpha * 0.57)
		var span := 2.0 + roundf(absf(cos(progress * 14.0 + i)) * 3.0)
		canvas.draw_rect(Rect2(center - Vector2(span * 0.5, 1.0), Vector2(span, 2.0)), color)
		canvas.draw_rect(Rect2(center + Vector2(0, -2), Vector2(2, 1)), color)


static func teatime(canvas: Node2D, pot: Vector2, cup: Vector2, time: float, alpha: float) -> void:
	var strength := smoothstep(0.59, 1.07, time) * (1.0 - smoothstep(3.23, 4.26, time)) * alpha
	for i in range(7):
		var fall := fposmod(time * 2.23 + i * 0.29, 1.0)
		var point := (pot.lerp(cup, fall) + Vector2(0.0, -4.0 * sin(fall * PI))).round()
		canvas.draw_rect(Rect2(point, Vector2(1 + i % 2, 2)), Color(GOLD, strength * sin(fall * PI) * 0.81))


static func blight(canvas: Node2D, roots: PackedVector2Array, time: float, alpha: float) -> void:
	var growth := smoothstep(0.79, 4.80, time) * (roots.size() - 1)
	var dim := smoothstep(0.4, 3.1, time) * alpha
	for index in range(roots.size() - 1):
		var fraction := clampf(growth - index, 0.0, 1.0)
		if fraction <= 0.0:
			break
		var base := roots[index]
		var tip := base.lerp(roots[index + 1], fraction)
		var turn := base.direction_to(tip)
		var bend := base.lerp(tip, 0.52) + turn.orthogonal() * 7.0
		var visible := dim * lerpf(0.74, 0.93, sin(time * 3.1 - index * 0.74) * 0.5 + 0.5)
		canvas.draw_polyline(PackedVector2Array([base.round(), bend.round(), tip.round()]),
			Color("#441e3e", visible), 7.0)
		canvas.draw_polyline(PackedVector2Array([base.round(), bend.round(), tip.round()]),
			Color("#ca4d76", visible * 0.73), 2.0)
		if fraction > 0.32:
			var rise := smoothstep(0.32, 0.95, fraction)
			var claw := bend + turn * (11.0 * rise) + Vector2(3, -1) * (6.5 * rise) + Vector2(0, -12) * rise
			var thorn := PackedVector2Array([bend.round(), (bend - turn * 8.0).round(),
				(claw + Vector2(-5.0, 8.0)).round(), claw.round()])
			# During the first few growth frames pixel snapping can collapse two
			# corners; draw the thorn once it forms a valid polygon.
			if Geometry2D.triangulate_polygon(thorn).size() >= 3:
				canvas.draw_colored_polygon(thorn, Color("#5e254c", visible))
			pixel_glint(canvas, claw.round(), 3.0, Color("#ed7396", visible * 0.8))
		for i in range(2):
			var drift := fposmod(time * 0.70 + index * 0.16 + i * 0.33, 1.0)
			var ember := (tip - Vector2(0.0, drift * 24.0) + turn * (i * 10.0 + drift * 3.0)).round()
			canvas.draw_rect(Rect2(ember, Vector2(2, 2)), Color("#ffc189", visible * (1.0 - drift) * 0.63))


static func ready_weapon(canvas: Node2D, point: Vector2, index: int, time: float, alpha: float) -> void:
	var life := 0.98 if index == 1 else 0.63
	if time <= 0.0 or time >= life:
		return
	var motion := time / life
	var strength := sin(motion * PI) * alpha
	var tint: Color = FLOWERS[index]
	match index:
		1:
			for step in range(7):
				var angle := motion * 2.1 + step * TAU / 7.0
				var petal := (point + Vector2.from_angle(angle) * Vector2(1.0, 0.68) * (10.0 + motion * 16.0)).round()
				pixel_glint(canvas, petal, 3.5, Color(tint, strength * 0.87))
		2:
			for step in range(5):
				var arc := Vector2.from_angle(step * 1.23) * (6.0 + motion * 16.0)
				var spark := (point + arc).round()
				canvas.draw_rect(Rect2(spark, Vector2(3.0, 2.0)), Color(GOLD, strength * 0.92))
		3:
			var path := (point + Vector2(16.0 * motion - 5.0, 7.0 * motion)).round()
			pixel_glint(canvas, path, 8.0, Color(tint, strength * 0.92))
		_:
			var across := Vector2(7.0, -16.0) if index == 0 else Vector2(-12.0, -8.0)
			pixel_glint(canvas, (point + across * motion).round(), 10.0, Color(GOLD, strength * 0.90))
			pixel_glint(canvas, (point - across * 0.40 + across * motion).round(), 4.0, Color(tint, strength * 0.78))


static func pixel_glint(canvas: Node2D, center: Vector2, size: float, tint: Color) -> void:
	var reach := maxf(2.0, roundf(size * 0.53))
	canvas.draw_rect(Rect2(center + Vector2(-reach, 0), Vector2(2.0 * reach + 1.0, 1.0)), tint)
	canvas.draw_rect(Rect2(center + Vector2(0, -reach), Vector2(1.0, 2.0 * reach + 1.0)), tint)
	canvas.draw_rect(Rect2(center - Vector2.ONE, Vector2(3, 3)), Color(tint.lightened(0.19), tint.a * 0.92))
