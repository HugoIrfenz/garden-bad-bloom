extends RefCounted

const Art = preload("res://scripts/evolution_art.gd")
const BACKDROP = preload("res://assets/art/menus/room_choices.png")
const PANEL = Rect2(73, 47, 718, 311)
const PREVIEW = Rect2(92, 70, 251, 220)
const BACK = Rect2(92, 305, 132, 41)
const FORGE = Rect2(577, 305, 194, 41)
const STATUS = Rect2(238, 305, 326, 41)
const READY = Color("#e8bf83")
const MUTED = Color("#a08e9e")
const INK = Color("#292036")

static func draw(game) -> void:
	var view = game.View
	var offer: Dictionary = game.evolution_offer()
	var cell := (BACKDROP.get_size() * 0.5).floor()
	game.draw_texture_rect_region(BACKDROP, view.CANVAS, Rect2(Vector2(cell.x, 0), cell))
	game.draw_rect(view.CANVAS, Color(0.10, 0.065, 0.13, 0.28))
	view.petals(game, game.visual_clock)
	view.frame(game, PANEL, Color(INK, 0.95))
	var heading := Rect2(296, 21, 272, 40)
	view.frame(game, heading, Color("#3d2b3f"), READY)
	view.centered(game, heading, "Weapon Forge", 26, view.CREAM, true)
	view.button(game, BACK, "Back")
	if offer.is_empty():
		view.centered(game, PANEL, "No evolution is available for this heroine.", 17, view.DIM)
		return
	var can_evolve: bool = offer.get("can_evolve", false)
	draw_preview(game, offer, can_evolve)
	draw_requirements(game, offer)
	if can_evolve:
		view.centered(game, STATUS, "Uses this rest stop", 13, view.DIM)
		view.button(game, FORGE, "Forge & Equip", true)
	else:
		view.centered(game, STATUS, offer.get("reason", "Requirements needed"), 13, view.DIM)
		view.frame(game, FORGE, Color("#312638"), MUTED)
		view.centered(game, FORGE, "Forge & Equip", 16, view.DIM, true)

static func draw_preview(game, offer: Dictionary, available: bool) -> void:
	var view = game.View
	var accent: Color = game.COLORS[game.hero]
	var clock: float = game.visual_clock
	view.frame(game, PREVIEW, Color("#211a32"), accent.lerp(READY, 0.55))
	view.centered(game, Rect2(99, 79, 237, 30), offer.name, 23, view.CREAM, true)
	var medallion := Vector2(217, 157)
	game.draw_circle(medallion, 44.0, Color(accent, 0.09), true, -1.0, true)
	game.draw_arc(medallion, 43.0, 0.0, TAU, 48, Color(READY, 0.48), 1.0, true)
	game.draw_arc(medallion, 48.0, clock * 0.40, clock * 0.40 + PI, 34, Color(accent, 0.48), 1.0, true)
	for index in range(4):
		var angle := clock * 0.29 + index * TAU / 4.0
		var point := (medallion + Vector2.from_angle(angle) * 48.0).round()
		view.diamond(game, point, 2.5, Color(READY, 0.69 if available else 0.42))
	Art.draw_icon(game, offer.id, medallion + Vector2(0, roundf(sin(clock * 2.0) * 2.0)), 87.0)
	var lines: Array[String] = game.CodexView.wrap_text(offer.description, ThemeDB.fallback_font, 221.0, 11)
	for index in lines.size():
		view.centered(game, Rect2(105, 210 + index * 14, 225, 14), lines[index], 11, view.DIM)

static func draw_requirements(game, offer: Dictionary) -> void:
	var view = game.View
	view.text(game, Vector2(365, 89), "Recipe Requirements", 19, view.CREAM, true)
	var requirements: Array = offer.get("requirements", [])
	var step := minf(48.0, 154.0 / maxf(1.0, requirements.size()))
	for index in requirements.size():
		var requirement: Dictionary = requirements[index]
		draw_requirement(game, Rect2(363, roundf(102 + index * step), 408, step - 5), requirement)
	var current: String = offer.get("current", "")
	if not current.is_empty():
		var equipped := Rect2(363, 264, 408, 26)
		view.frame(game, equipped, Color("#392b42"), MUTED)
		view.centered(game, equipped, "Equipped  ·  " + current, 12, view.CREAM)

static func draw_requirement(game, row: Rect2, data: Dictionary) -> void:
	var view = game.View
	var ready: bool = data.get("ready", false)
	var edge := READY if ready else MUTED
	view.frame(game, row, Color("#382d3f") if ready else Color("#302638"), edge)
	var center := Vector2(row.position.x + 26, roundf(row.get_center().y))
	var id := str(data.get("id", ""))
	var icon_size := minf(30.0, row.size.y - 5)
	if id == "mastery":
		view.ability_icon(game, game.hero, false, center, icon_size)
	else:
		Art.draw_icon(game, id, center, icon_size)
	view.text(game, row.position + Vector2(48, 15), data.get("name", ""), 15, view.CREAM, true)
	view.text(game, row.position + Vector2(48, 30), data.get("detail", ""), 11, view.DIM)
	var state := Rect2(row.end.x - 82, row.position.y + 4, 71, row.size.y - 8)
	view.centered(game, state, "Ready" if ready else "Needed", 11, edge)

static func tap(game, point: Vector2) -> void:
	if BACK.has_point(point):
		game.leave_forge()
	elif FORGE.has_point(point):
		game.forge_weapon()
