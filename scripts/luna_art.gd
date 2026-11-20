extends RefCounted

const ATLAS = preload("res://assets/art/heroines/luna_sprite_atlas.png")
const MENU_PORTRAIT = preload("res://assets/art/heroines/luna_menu_chibi.png")
const PORTRAITS = preload("res://assets/art/heroines/luna_portraits.png")
const ICONS = preload("res://assets/art/heroines/luna_icons.png")

const HUMAN := [
	Rect2(112, 18, 149, 300), Rect2(409, 17, 151, 301), Rect2(704, 18, 150, 300), Rect2(999, 12, 148, 306),
	Rect2(110, 337, 152, 293), Rect2(409, 334, 147, 296), Rect2(703, 343, 145, 287), Rect2(1001, 343, 148, 289),
	Rect2(114, 659, 149, 291), Rect2(375, 654, 200, 296), Rect2(674, 654, 213, 296), Rect2(969, 659, 195, 291),
]
const WOLF := [
	Rect2(23, 1031, 261, 172), Rect2(327, 1045, 275, 150),
	Rect2(636, 1037, 252, 165), Rect2(926, 1047, 302, 153),
]
const MENU_REGION := Rect2(238, 3, 763, 1249)
const VICTORY := Rect2(679, 0, 484, 802)
const DEFEAT := Rect2(1308, 272, 590, 530)
const WOLF_ICON := Rect2(39, 64, 821, 791)
const PISTOL_ICON := Rect2(1102, 157, 552, 603)

static func source(frame: int) -> Dictionary:
	match frame:
		12: return {"texture": MENU_PORTRAIT, "icon": MENU_REGION}
		13: return {"texture": PORTRAITS, "icon": VICTORY}
		14: return {"texture": ICONS, "icon": WOLF_ICON}
		15: return {"texture": ICONS, "icon": PISTOL_ICON}
	return {"texture": ATLAS, "icon": HUMAN[clampi(frame, 0, HUMAN.size() - 1)]}

static func defeat_source() -> Dictionary:
	return {"texture": PORTRAITS, "icon": DEFEAT}

static func eyes(canvas: Node2D, area: Rect2, tint: Color) -> void:
	var height := 239.0 * area.size.y / area.size.x
	var crop := Rect2(246.0, 113.0 - height * 0.48, 239.0, height)
	canvas.draw_texture_rect_region(PORTRAITS, area, crop, tint)

static func icon(canvas: Node2D, frame: int, center: Vector2, size: float, tint := Color.WHITE) -> void:
	var art := source(frame)
	var region: Rect2 = art.icon
	var extent := (region.size * size / maxf(region.size.x, region.size.y)).round()
	canvas.draw_texture_rect_region(art.texture, Rect2((center - extent * 0.5).round(), extent), region, tint)

static func walk(canvas: Node2D, feet: Vector2, height: float, distance: float,
		direction: Vector2, moving: bool, tint: Color, wolf := false) -> void:
	var step := floori(distance / (8.0 if wolf else 10.0)) % 4 if moving else 0
	var stride := 1.0 if moving and step % 2 != 0 else 0.0
	if wolf:
		var pose: int = [0, 1, 2, 1][step] if moving else 0
		draw_actor(canvas, WOLF[pose], feet - Vector2(0, stride), height * 0.58,
			direction.x < -0.03, (direction.y * 0.04 if moving else 0.0), tint)
		return
	var base := 0
	if absf(direction.x) > absf(direction.y):
		base = 3
	elif direction.y < 0.0:
		base = 6
	var frame: int = base + [0, 1, 0, 2][step]
	draw_actor(canvas, HUMAN[frame], feet - Vector2(0, stride), height, base == 3 and direction.x < 0.0, 0.0, tint)

static func action(canvas: Node2D, feet: Vector2, height: float, direction: Vector2,
		left: float, tint: Color, wolf := false, dashing := false) -> void:
	var side := -1.0 if direction.x < -0.03 else 1.0
	if wolf:
		var region: Rect2 = WOLF[2] if left > 0.17 and not dashing else WOLF[3]
		if dashing and floori(left * 32.0) % 2 == 0:
			region = WOLF[1]
		var lunge := 3.0 if dashing else 7.0 * sin(PI * clampf(left / 0.23, 0.0, 1.0))
		draw_actor(canvas, region, feet + direction * lunge, height * 0.56, side < 0.0,
			direction.y * 0.065, tint)
		return
	var frame := 10 if left > 0.12 else (11 if left > 0.055 else 9)
	var recoil := 3.0 if frame == 11 else 0.0
	var anchor_x := 0.42 if frame != 10 else 0.46
	draw_actor(canvas, HUMAN[frame], feet - direction * recoil, height, side < 0.0,
		-recoil * side * 0.018, tint, anchor_x)

static func draw_actor(canvas: Node2D, region: Rect2, feet: Vector2, height: float,
		flipped: bool, tilt: float, tint: Color, anchor_x := 0.5) -> void:
	var width := roundf(region.size.x * height / region.size.y)
	canvas.draw_set_transform(feet.round(), tilt, Vector2(-1.0 if flipped else 1.0, 1.0))
	canvas.draw_texture_rect_region(ATLAS,
		Rect2(-roundf(width * anchor_x), -roundf(height), width, roundf(height)), region, tint)
	canvas.draw_set_transform(Vector2.ZERO)
