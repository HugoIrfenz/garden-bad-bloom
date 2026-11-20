extends RefCounted

const Roster = preload("res://scripts/guest_roster.gd")
const ATLAS = [
	preload("res://assets/art/heroines/mina_sprite_atlas.png"),
	preload("res://assets/art/heroines/whi_sprite_atlas.png"),
]
const DEFEAT = preload("res://assets/art/heroines/guest_defeat.png")
const REGIONS = [
	[
		Rect2(43, 14, 237, 281), Rect2(357, 14, 237, 283), Rect2(669, 14, 238, 283), Rect2(981, 14, 236, 282),
		Rect2(41, 327, 235, 280), Rect2(354, 328, 236, 279), Rect2(684, 329, 218, 279), Rect2(998, 329, 218, 279),
		Rect2(60, 644, 215, 278), Rect2(326, 665, 290, 241), Rect2(656, 663, 267, 244), Rect2(966, 649, 256, 253),
		Rect2(22, 951, 280, 281), Rect2(349, 949, 246, 280), Rect2(695, 963, 202, 262), Rect2(997, 979, 192, 231),
	],
	[
		Rect2(70, 26, 179, 271), Rect2(385, 28, 179, 269), Rect2(698, 26, 178, 271), Rect2(1023, 28, 144, 269),
		Rect2(65, 342, 176, 265), Rect2(378, 342, 169, 265), Rect2(707, 340, 156, 270), Rect2(1020, 339, 164, 271),
		Rect2(84, 654, 150, 266), Rect2(353, 646, 233, 269), Rect2(682, 660, 158, 255), Rect2(964, 658, 256, 254),
		Rect2(27, 952, 282, 277), Rect2(364, 965, 209, 264), Rect2(691, 966, 187, 258), Rect2(1025, 970, 144, 245),
	],
]
const ACTION_CENTERS := [[-28, -25, 0], [-27, 0, -32]]
const DEFEAT_REGIONS := [Rect2(42, 21, 842, 851), Rect2(978, 169, 742, 701)]
const PORTRAIT_EYES := [1060.0, 1075.0]

static func source(hero: int, frame: int) -> Dictionary:
	var index := hero - Roster.MINA
	return {"texture": ATLAS[index], "icon": REGIONS[index][frame]}

static func actor(canvas: Node2D, hero: int, frame: int, feet: Vector2, height: float,
		flip: bool, lean: float, tint: Color, offset := 0.0) -> void:
	var art := source(hero, frame)
	var region: Rect2 = art.icon
	var factor := height / region.size.y
	var width := roundf(region.size.x * factor)
	canvas.draw_set_transform(feet.round(), lean, Vector2(-1.0 if flip else 1.0, 1.0))
	canvas.draw_texture_rect_region(art.texture, Rect2(-roundf(width * 0.5 + offset * factor), -roundf(height), width, roundf(height)), region, tint)
	canvas.draw_set_transform(Vector2.ZERO)

static func walk(canvas: Node2D, hero: int, feet: Vector2, height: float, distance: float,
		direction: Vector2, moving: bool, tint: Color) -> void:
	var base := 0
	if absf(direction.x) > absf(direction.y):
		base = 3
	elif direction.y < 0.0:
		base = 6
	var frames := [0, 1, 0, 2]
	var step := int(distance / 10.5) % frames.size() if moving else 0
	var pose: int = base + frames[step]
	var rise := 1.0 if moving and step % 2 == 1 else 0.0
	actor(canvas, hero, pose, feet - Vector2(0, rise), height, base == 3 and direction.x < 0.0,
		0.0, tint)

static func action(canvas: Node2D, hero: int, feet: Vector2, height: float, direction: Vector2,
		variant: int, left: float, tint: Color) -> void:
	variant = clampi(variant, 0, 2)
	var swing := sin(clampf(left / 0.29, 0.0, 1.0) * PI)
	var tilt := (0.07 if hero == Roster.MINA else 0.03) * swing
	var flip := direction.x < 0.0
	var shift := direction * swing * (6.0 if hero == Roster.MINA else 3.0)
	var center := float(ACTION_CENTERS[hero - Roster.MINA][variant])
	var spin := hero == Roster.MINA and variant == 2
	var frame := 9 + variant
	if spin:
		var beat := floori(left * 36.0) % 4
		frame = [11, 3, 6, 11][beat]
		flip = beat >= 2
		center = 0.0
	actor(canvas, hero, frame, feet + shift - Vector2(0, roundf(swing * 3.0)),
		height * (0.94 if hero == Roster.MINA and variant < 2 else 1.0),
		flip, -tilt if flip else tilt, tint, center)

static func icon(canvas: Node2D, hero: int, frame: int, center: Vector2, size: float, tint := Color.WHITE) -> void:
	var art := source(hero, frame)
	var region: Rect2 = art.icon
	var extent := (region.size * size / maxf(region.size.x, region.size.y)).round()
	canvas.draw_texture_rect_region(art.texture, Rect2((center - extent * 0.5).round(), extent), region, tint)

static func defeat_source(hero: int) -> Dictionary:
	return {"texture": DEFEAT, "icon": DEFEAT_REGIONS[hero - Roster.MINA]}

static func eyes(canvas: Node2D, hero: int, area: Rect2, tint: Color) -> void:
	var art := source(hero, 12)
	var region: Rect2 = art.icon
	var width := region.size.x - 10.0
	var height := width * area.size.y / area.size.x
	var crop := Rect2(region.position.x + 5.0, PORTRAIT_EYES[hero - Roster.MINA] - height * 0.50,
		width, height)
	canvas.draw_texture_rect_region(art.texture, area, crop, tint)
