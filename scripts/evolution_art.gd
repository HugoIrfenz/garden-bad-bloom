extends RefCounted

const ATLAS = preload("res://assets/art/items/forge_evolutions.png")
const SECOND_ATLAS = preload("res://assets/art/items/forge_evolutions_second.png")
const THORNMAIL = preload("res://assets/art/items/thornmail.png")
const REGIONS := {
	"rosewall_execution": Rect2(100, 172, 258, 379),
	"elegy_spiral": Rect2(504, 209, 301, 298),
	"guardians_ledger": Rect2(960, 225, 260, 285),
	"rosebound_refrain": Rect2(1351, 225, 283, 275),
	"black_rose_ink": Rect2(1818, 206, 241, 298),
}
const SECOND_REGIONS := {
	"orchid_overclock": Rect2(116, 79, 255, 300),
	"orchid_punch_card": Rect2(480, 112, 282, 247),
	"metronome_heart": Rect2(871, 78, 246, 291),
	"snarewood_bow": Rect2(164, 445, 154, 378),
	"sewing_thread": Rect2(491, 515, 229, 244),
	"tidy_disaster": Rect2(905, 438, 193, 390),
	"colorstorm_path": Rect2(130, 897, 216, 288),
	"glitter_crime": Rect2(500, 880, 229, 296),
	"painted_exit": Rect2(859, 892, 259, 283),
}

static func icon(id: String) -> Dictionary:
	if id == "relic_thornmail":
		return {"texture": THORNMAIL, "icon": Rect2(148, 96, 932, 1064)}
	if SECOND_REGIONS.has(id):
		return {"texture": SECOND_ATLAS, "icon": SECOND_REGIONS[id]}
	if not REGIONS.has(id):
		return {}
	return {"texture": ATLAS, "icon": REGIONS[id]}

static func draw_icon(canvas: Node2D, id: String, center: Vector2, diameter: float, tint := Color.WHITE) -> void:
	var card := icon(id)
	if card.is_empty():
		return
	var source: Rect2 = card.icon
	var size := (source.size * (diameter / maxf(source.size.x, source.size.y))).round()
	var target := Rect2((center - size * 0.5).round(), size)
	canvas.draw_texture_rect_region(card.texture, target, source, tint)
