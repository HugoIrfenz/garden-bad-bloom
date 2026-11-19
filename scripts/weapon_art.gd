extends RefCounted

const Catalog = preload("res://scripts/weapon_catalog.gd")
const Prep = preload("res://scripts/run_preparation_view.gd")
const EvolutionArt = preload("res://scripts/evolution_art.gd")
const FIELD = preload("res://assets/art/items/field_weapons.png")
const REGIONS = [
	Rect2(7, 7, 384, 366), Rect2(413, 7, 354, 385), Rect2(810, 10, 393, 367),
	Rect2(1203, 5, 401, 374), Rect2(1604, 17, 390, 361),
	Rect2(15, 392, 376, 383), Rect2(410, 392, 376, 384), Rect2(802, 429, 401, 347),
	Rect2(1203, 392, 391, 386), Rect2(1617, 395, 368, 374),
]

static func draw_icon(canvas: Node2D, id: String, center: Vector2, size: float) -> void:
	var definition := Catalog.item(id)
	if definition.is_empty():
		return
	if not EvolutionArt.icon(id).is_empty():
		EvolutionArt.draw_icon(canvas, id, center, size)
		return
	if not definition.has("icon_index"):
		Prep.draw_gear(canvas, center.round(), int(definition.hero), size)
		return
	var region: Rect2 = REGIONS[definition.icon_index]
	var extent := (region.size * (size / maxf(region.size.x, region.size.y))).round()
	canvas.draw_texture_rect_region(FIELD, Rect2((center - extent * 0.5).round(), extent), region)

static func reward_card(id: String) -> Dictionary:
	var data := Catalog.item(id).duplicate()
	if data.is_empty():
		return data
	data.kind = "Weapon"
	data.action = "Equip weapon"
	if not EvolutionArt.icon(id).is_empty():
		data.merge(EvolutionArt.icon(id), true)
	elif data.has("icon_index"):
		data.texture = FIELD
		data.icon = REGIONS[data.icon_index]
	else:
		data.gear_index = int(data.hero)
	return data

static func draw_swing(canvas: Node2D, id: String, player: Vector2, facing: Vector2, phase: float) -> void:
	var weapon := Catalog.item(id)
	if (not weapon.has("icon_index") and not weapon.get("evolved", false)) or float(weapon.get("speed", 0.0)) > 0.0:
		return
	var reach := lerpf(13.0, 33.0, sin(phase * PI))
	var direction := facing.rotated(lerpf(-0.86, 0.81, phase))
	var point := player + direction * reach - Vector2(0, 6)
	var color: Color = weapon.accent
	canvas.draw_arc(player - Vector2(0, 5), reach + 4.0, direction.angle() - 0.64,
		direction.angle() + 0.27, 16, Color(color, 0.8 * (1.0 - phase)), 2.0, true)
	draw_icon(canvas, id, point, 22.0 if weapon.hero != 2 else 18.0)

static func draw_projectile(canvas: Node2D, id: String, point: Vector2, direction: Vector2, clock: float) -> bool:
	var weapon := Catalog.item(id)
	if not weapon.has("icon_index") and id not in ["snarewood_bow", "tidy_disaster"]:
		return false
	var tint: Color = weapon.accent
	var side := direction.orthogonal()
	var n := point.round()
	match id:
		"moonquill_staff":
			canvas.draw_circle(n, 7.0, Color(tint, 0.22), true, -1.0, true)
			canvas.draw_arc(n, 6.0, clock * 7.0, clock * 7.0 + TAU * 0.71, 20, tint, 2.0, true)
			canvas.draw_circle(n + direction * 2, 3.0, Color("#eef4ff"), true, -1.0, true)
		"black_margin":
			canvas.draw_colored_polygon(PackedVector2Array([n + direction * 7, n + side * 4,
				n - direction * 8, n - side * 4]), Color("#39253d"))
			canvas.draw_line(n - direction * 4, n + direction * 7, tint, 1.7, true)
		_:
			canvas.draw_line(n - direction * 15, n + direction * 6, tint, 2.1, true)
			canvas.draw_colored_polygon(PackedVector2Array([n + direction * 9, n - direction * 2 + side * 3,
				n, n - direction * 2 - side * 3]), tint.lightened(0.32))
			if id in ["ribbon_string", "snarewood_bow", "tidy_disaster"]:
				canvas.draw_polyline(PackedVector2Array([n, n - direction * 10 + side * 4.0 * sin(clock * 16.0),
					n - direction * 19 - side * 3]), Color(tint, 0.65), 1.5, true)
	return true
