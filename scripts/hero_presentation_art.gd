extends RefCounted

const HERO_PORTRAITS = preload("res://assets/art/heroines/hero_portraits.png")
const DEFEAT_PORTRAITS = preload("res://assets/art/heroines/defeat_portraits.png")
const VICTORY_PORTRAITS = preload("res://assets/art/heroines/victory_portraits.png")
const ABILITY_ATLAS = preload("res://assets/art/items/hero_abilities.png")

const HERO_REGIONS = [
	Rect2(0, 9, 433, 715), Rect2(435, 12, 430, 712),
	Rect2(866, 9, 440, 715), Rect2(1308, 7, 429, 717), Rect2(1740, 7, 431, 717),
]
const DEFEAT_REGIONS = [
	Rect2(0, 104, 437, 555), Rect2(438, 110, 426, 547),
	Rect2(865, 116, 443, 542), Rect2(1309, 121, 428, 542), Rect2(1740, 118, 431, 538),
]
const VICTORY_REGIONS = [
	Rect2(0, 4, 440, 720), Rect2(442, 5, 434, 719),
	Rect2(876, 4, 426, 720), Rect2(1304, 7, 433, 717), Rect2(1738, 4, 434, 720),
]

static func portrait(canvas: Node2D, index: int, area: Rect2, defeated := false,
		close := false, tint := Color.WHITE) -> void:
	var region: Rect2 = DEFEAT_REGIONS[index] if defeated else HERO_REGIONS[index]
	if close:
		region.size.y = roundf(region.size.y * 0.56)
	var texture: Texture2D = DEFEAT_PORTRAITS if defeated else HERO_PORTRAITS
	draw_portrait_region(canvas, texture, area, region, tint)

static func victory(canvas: Node2D, index: int, area: Rect2, tint: Color) -> void:
	draw_portrait_region(canvas, VICTORY_PORTRAITS, area, VICTORY_REGIONS[index], tint)

static func draw_portrait_region(canvas: Node2D, texture: Texture2D, area: Rect2, region: Rect2,
		tint: Color) -> void:
	var zoom := minf(area.size.x / region.size.x, area.size.y / region.size.y)
	var target_size := region.size * zoom
	var base := Vector2(area.get_center().x - target_size.x * 0.5, area.end.y - target_size.y)
	canvas.draw_texture_rect_region(texture, pixel_rect(Rect2(base, target_size)), region, tint)

static func eyes(canvas: Node2D, index: int, area: Rect2, tint: Color) -> void:
	var region: Rect2 = HERO_REGIONS[index]
	var eye_heights := [179.0, 182.0, 182.0, 186.0, 194.0]
	var crop_width := region.size.x - 16.0
	var crop_height := crop_width * area.size.y / area.size.x
	var crop := Rect2(region.position.x + 8.0, eye_heights[index] - crop_height * 0.50,
		crop_width, crop_height)
	canvas.draw_texture_rect_region(HERO_PORTRAITS, pixel_rect(area), pixel_rect(crop), tint)

static func ability(canvas: Node2D, index: int, ultimate: bool, center: Vector2,
		diameter: float, tint := Color.WHITE) -> void:
	var cell := ABILITY_ATLAS.get_size() / Vector2(5.0, 2.0)
	var cell_index := Vector2(index, 1.0 if ultimate else 0.0)
	var first := (cell_index * cell).round() + Vector2(3.0, 3.0)
	var last := ((cell_index + Vector2.ONE) * cell).round() - Vector2(3.0, 3.0)
	var source := Rect2(first, last - first)
	var size := source.size * (diameter / maxf(source.size.x, source.size.y))
	canvas.draw_texture_rect_region(ABILITY_ATLAS, pixel_rect(Rect2(center - size * 0.5, size)), source, tint)

static func pixel_rect(area: Rect2) -> Rect2:
	var origin := area.position.round()
	return Rect2(origin, area.end.round() - origin)
