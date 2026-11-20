extends RefCounted

const GuestArt = preload("res://scripts/guest_hero_art.gd")
const GuestRoster = preload("res://scripts/guest_roster.gd")
const LunaArt = preload("res://scripts/luna_art.gd")

const DISPLAY_FONT = preload("res://assets/fonts/Alegreya.ttf")
const TITLE_FONT = preload("res://assets/fonts/AlegreyaTitle.tres")
const ITALIC_FONT = preload("res://assets/fonts/AlegreyaItalic.ttf")
const WALK_ATLASES = [
	preload("res://assets/art/angela_walk.png"),
	preload("res://assets/art/vivianne_walk.png"),
	preload("res://assets/art/nixia_walk.png"),
	preload("res://assets/art/virelia_walk.png"),
	preload("res://assets/art/zaria_walk.png"),
]
const HEROES = preload("res://assets/art/heroines.png")
const PROPS = preload("res://assets/art/garden_props.png")
const COVER = preload("res://assets/art/room_cover.png")
const COVER_REGIONS = [
	Rect2(93, 113, 356, 287), Rect2(647, 78, 245, 319), Rect2(1110, 88, 315, 320),
	Rect2(90, 594, 358, 330), Rect2(614, 552, 309, 390), Rect2(1116, 553, 307, 382),
]
const BIOME_COVER = [[0, 1, -1], [1, 0, -1], [2, -1, 0], [3, 0, 1], [4, 1, -1], [5, 4, 0], [5, 3, 4]]
const ENEMY_ATLASES = [
	preload("res://assets/art/forgotten_garden_enemies.png"),
	preload("res://assets/art/mushroom_enemies.png"),
	preload("res://assets/art/clockwork_enemies.png"),
	preload("res://assets/art/bloodbloom_enemies.png"),
	preload("res://assets/art/palace_enemies.png"),
	preload("res://assets/art/astral_enemies.png"),
	preload("res://assets/art/core_enemies.png"),
]
const HEDGE_KNIGHT = preload("res://assets/art/hedge_knight.png")
const MYCELIUM_LEAPER = preload("res://assets/art/mycelium_leaper.png")
const ENEMY_ADDENDUM = preload("res://assets/art/enemy_addendum.png")
const PORCELAIN_HOUND = preload("res://assets/art/porcelain_hound.png")
const HOUND_POSES = [
	Rect2(61, 173, 493, 463), Rect2(694, 164, 565, 466), Rect2(1405, 137, 654, 464),
]

const HERO_REGIONS = [
	Rect2(22, 134, 402, 506),
	Rect2(469, 136, 389, 504),
	Rect2(901, 156, 361, 485),
	Rect2(1313, 140, 391, 498),
	Rect2(1736, 138, 413, 502),
]
const ENEMY_REGIONS = [
	[Rect2(44, 201, 456, 379), Rect2(586, 312, 415, 268),
		Rect2(1147, 195, 359, 387), Rect2(1588, 57, 554, 570)],
	[Rect2(40, 376, 321, 278), Rect2(491, 333, 293, 328),
		Rect2(939, 325, 332, 346), Rect2(1407, 34, 750, 632)],
	[Rect2(104, 390, 240, 235), Rect2(508, 392, 338, 268),
		Rect2(955, 368, 360, 297), Rect2(1467, 4, 641, 661)],
	[Rect2(41, 380, 403, 252), Rect2(501, 199, 335, 440),
		Rect2(247, 146, 686, 521), Rect2(1341, 9, 803, 637)],
	[Rect2(64, 310, 391, 338), Rect2(502, 208, 480, 438),
		Rect2(1262, 22, 657, 633), Rect2(1469, 16, 652, 649)],
	[Rect2(107, 346, 315, 278), Rect2(469, 241, 438, 389),
		Rect2(942, 236, 451, 378), Rect2(1412, 15, 747, 634)],
	[Rect2(40, 378, 303, 297), Rect2(435, 303, 318, 365),
		Rect2(798, 301, 411, 372), Rect2(1265, 13, 879, 678)],
]

const WALK_BASELINES = [
	[[296, 294, 296, 289], [294, 293, 294, 293],
		[292, 292, 292, 292], [298, 291, 299, 291]],
	[[294, 295, 295, 295], [291, 290, 291, 290],
		[288, 288, 290, 288], [284, 281, 284, 275]],
	[[293, 289, 292, 287], [288, 283, 291, 288],
		[289, 282, 290, 287], [294, 272, 290, 287]],
	[[297, 296, 296, 296], [296, 296, 295, 290],
		[292, 290, 294, 289], [295, 294, 288, 279]],
	[[297, 294, 297, 296], [294, 288, 295, 293],
		[288, 285, 288, 288], [287, 275, 287, 278]],
]

const ZARIA_CENTER_X = [[173, 164, 157, 146], [167, 164, 154, 142],
	[172, 162, 164, 151], [170, 168, 166, 148]]

static func walk(canvas: Node2D, index: int, feet: Vector2, height: float, distance: float,
		direction: Vector2, moving: bool, tint: Color) -> void:
	if index == GuestRoster.LUNA:
		LunaArt.walk(canvas, feet, height, distance, direction, moving, tint)
		return
	if GuestRoster.is_guest(index):
		GuestArt.walk(canvas, index, feet, height, distance, direction, moving, tint)
		return
	var row: int
	if absf(direction.x) >= absf(direction.y):
		row = 1 if direction.x < 0 else 2
	else:
		row = 0 if direction.y >= 0 else 3
	var frame = int(distance / 16.0) % 4 if moving else 0
	var atlas: Texture2D = WALK_ATLASES[index]
	var cell = atlas.get_size() * 0.25
	var start = Vector2(floorf(frame * cell.x), floorf(row * cell.y))
	var end = Vector2(floorf((frame + 1) * cell.x), floorf((row + 1) * cell.y))
	var region = Rect2(start, end - start)
	var art_scale = height / 286.0
	var center_x = float(ZARIA_CENTER_X[row][frame]) if index == 4 else cell.x * 0.5
	var anchor = Vector2(center_x, WALK_BASELINES[index][row][frame]) * art_scale
	var target = Rect2((feet - anchor).round(), (region.size * art_scale).round())
	canvas.draw_texture_rect_region(atlas, target, region, tint)

const PROP_REGIONS = [
	Rect2(328, 204, 247, 333),
	Rect2(885, 227, 358, 308),
	Rect2(1518, 125, 369, 410),
]

static func prop(canvas: Node2D, index: int, feet: Vector2, height: float) -> void:
	shadow(canvas, feet, 16.0)
	paint_actor(canvas, PROPS, PROP_REGIONS[index], feet, height, 0.0, Vector2.ONE, Color.WHITE)

static func room_cover(canvas: Node2D, biome: int, depth: int, index: int, feet: Vector2, boss: bool) -> void:
	var choices: Array = BIOME_COVER[clampi(biome, 0, BIOME_COVER.size() - 1)]
	var pick: int = choices[0 if boss and index == 0 else posmod(depth + index, choices.size())]
	if pick < 0:
		prop(canvas, 0, feet, 38.0)
		return
	var region: Rect2 = COVER_REGIONS[pick]
	var height := minf(49.0, 44.0 * region.size.y / region.size.x)
	shadow(canvas, feet, 19.0)
	paint_actor(canvas, COVER, region, feet, height, 0.0, Vector2.ONE, Color.WHITE)

static func heroine(canvas: Node2D, index: int, feet: Vector2, height: float,
		clock: float, velocity := Vector2.ZERO, action := 0.0, tint := Color.WHITE) -> void:
	var pace = clampf(velocity.length() / 150.0, 0.0, 1.0)
	var step = sin(clock * 15.0)
	var idle = sin(clock * 3.4 + index * 0.7)
	var lift = absf(step) * pace * height * 0.065
	var stretch = 1.0 + idle * 0.022 + step * pace * 0.04 - action * 0.07
	var lean = clampf(velocity.x / 880.0, -0.2, 0.2) + step * pace * 0.045
	if index == GuestRoster.LUNA:
		var moving: bool = pace > 0.08
		LunaArt.walk(canvas, feet - Vector2(0, lift - roundf(idle * 1.4)), height,
			clock * velocity.length(), velocity if moving else Vector2.DOWN, moving, tint)
		return
	if GuestRoster.is_guest(index):
		GuestArt.actor(canvas, index, 0, feet - Vector2(0, lift) + Vector2(0, roundf(idle * 1.4)), height,
			false, lean, tint)
		return
	paint_actor(canvas, HEROES, HERO_REGIONS[index], feet - Vector2(0, lift), height,
		lean, Vector2(1.0 + action * 0.11, stretch), tint)

static func garden_enemy(canvas: Node2D, biome: int, index: int, feet: Vector2, height: float,
		clock: float, windup: float, hit: float, visibility := 1.0) -> void:
	var bounce = absf(sin(clock * (7.0 - index))) * height * 0.075 * (1.0 - windup)
	var jitter = sin(clock * 53.0) * windup * 2.7
	var squash = 1.0 - windup * 0.18 + sin(clock * 4.1) * 0.04
	var tint = Color.WHITE.lerp(Color(1.0, 0.56, 0.54), windup * 0.55)
	tint = tint.lerp(Color(2.3, 1.9, 1.8), hit)
	tint.a = visibility
	paint_enemy(canvas, biome, index, feet + Vector2(jitter, -bounce), height, jitter * 0.035,
		Vector2(1.0 + windup * 0.14, squash), tint)

static func paint_enemy(canvas: Node2D, biome: int, index: int, feet: Vector2, height: float,
		lean: float, stretch: Vector2, tint: Color) -> void:
	if biome == 0 and index == 4:
		paint_actor(canvas, HEDGE_KNIGHT, Rect2(175, 37, 819, 1049), feet, height, lean, stretch, tint)
		return
	if biome == 1 and index == 4:
		paint_actor(canvas, MYCELIUM_LEAPER, Rect2(248, 212, 798, 726), feet, height, lean, stretch, tint)
		return
	if biome == 3 and index == 4:
		paint_actor(canvas, ENEMY_ATLASES[3], Rect2(894, 346, 381, 295), feet, height, lean, stretch, tint)
		return
	if biome == 4 and index == 4:
		paint_hound(canvas, 0, feet, height, lean, stretch, tint)
		return
	var atlas = ENEMY_ADDENDUM if biome in [3, 4] and index == 2 else ENEMY_ATLASES[biome]
	paint_actor(canvas, atlas, ENEMY_REGIONS[biome][index], feet, height, lean, stretch, tint)

static func paint_hound(canvas: Node2D, pose: int, feet: Vector2, height: float,
		lean: float, stretch: Vector2, tint: Color) -> void:
	paint_actor(canvas, PORCELAIN_HOUND, HOUND_POSES[pose], feet, height, lean, stretch, tint)

static func paint_actor(canvas: Node2D, atlas: Texture2D, region: Rect2, feet: Vector2,
		height: float, angle: float, scale: Vector2, tint: Color) -> void:
	var painted_height := roundf(height)
	var width := roundf(painted_height * region.size.x / region.size.y)
	canvas.draw_set_transform(feet.round(), angle, scale)
	canvas.draw_texture_rect_region(atlas, Rect2(-floorf(width * 0.5), -painted_height, width, painted_height), region, tint)
	canvas.draw_set_transform(Vector2.ZERO)

static func shadow(canvas: Node2D, position: Vector2, radius: float) -> void:
	canvas.draw_set_transform(position, 0.0, Vector2(1.0, 0.38))
	canvas.draw_circle(Vector2.ZERO, radius, Color(0.09, 0.07, 0.15, 0.55), true, -1.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
