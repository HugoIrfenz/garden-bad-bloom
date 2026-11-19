extends RefCounted

const ORIGINAL = preload("res://assets/art/items/room_rewards.png")
const ORIGINAL_EDGE := Rect2(998, 17, 744, 842)
const ATLAS = preload("res://assets/art/items/run_upgrades.png")
const REGIONS := {
	"quickstep": Rect2(50, 41, 366, 375), "quickhands": Rect2(488, 36, 358, 380),
	"wildstride": Rect2(924, 35, 364, 381), "petal_aegis": Rect2(1383, 36, 337, 383),
	"first_bloom": Rect2(62, 481, 319, 366), "steady_spell": Rect2(497, 466, 346, 394),
	"velvet_purse": Rect2(923, 468, 366, 393),
}
const AEGIS_LIGHT := Color("#ffd8ba")
const AEGIS_SHADE := Color("#b46b8d")


static func icon(id: String) -> Dictionary:
	if id == "thorn_edge":
		return {"texture": ORIGINAL, "icon": ORIGINAL_EDGE}
	if not REGIONS.has(id):
		return {}
	return {"texture": ATLAS, "icon": REGIONS[id]}


static func draw_icon(canvas: Node2D, id: String, point: Vector2, width: float, alpha := 1.0) -> void:
	var art := icon(id)
	if art.is_empty():
		return
	var source: Rect2 = art.icon
	var extent := (source.size * (width / maxf(source.size.x, source.size.y))).round()
	canvas.draw_texture_rect_region(art.texture, Rect2((point - extent * 0.5).round(), extent),
		source, Color(1.0, 1.0, 1.0, alpha))


static func draw_guard(canvas: Node2D, point: Vector2, time: float) -> void:
	if time <= 0.0:
		return
	var remaining := clampf(time / 0.28, 0.0, 1.0)
	var travel := 1.0 - remaining
	var center := (point - Vector2(0, 12.0)).round()
	for i in range(6):
		var angle := i * TAU / 6.0 + travel * 0.8
		var axis := Vector2.from_angle(angle)
		var side := axis.orthogonal()
		var foot := (center + axis * Vector2(1.0, 0.74) * (20.0 + travel * 18.0)).round()
		var tip := (foot + axis * (6.0 + travel * 6.0)).round()
		var petal := PackedVector2Array([foot, (foot + side * 4.0 + axis * 3.0).round(), tip,
			(foot - side * 3.5 + axis * 5.0).round()])
		canvas.draw_colored_polygon(petal, Color(AEGIS_SHADE, remaining * 0.85))
		canvas.draw_polyline(PackedVector2Array([petal[1], tip, petal[3]]), Color(AEGIS_LIGHT, remaining), 1.0)
