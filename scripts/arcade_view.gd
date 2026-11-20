extends RefCounted

const Catalog = preload("res://scripts/arcade_catalog.gd")
const Media = preload("res://scripts/garden_media.gd")
const PAVILION = preload("res://assets/art/menus/arcade_pavilion.png")
const ICONS = preload("res://assets/art/items/arcade_icons.png")
const GROUNDS := {
	Catalog.PRIX: preload("res://assets/art/forgotten_garden.png"),
	Catalog.ENCORE: preload("res://assets/art/clockwork_conservatory.png"),
	Catalog.SNAKE: preload("res://assets/art/bloodbloom_forest.png"),
	Catalog.CATCH: preload("res://assets/art/hollow_palace.png"),
}
const GALLERY_BACK := Rect2(38, 23, 104, 39)
const EXIT := Rect2(609, 330, 180, 41)
const REPLAY := Rect2(470, 330, 122, 41)
const CARD_Y := 117.0
const CARD_X := 38.0
const CARD_STEP := 159.0
const CARD_SIZE := Vector2(152, 198)
const ICON_REGIONS := {
	Catalog.PRIX: Rect2(20, 132, 456, 440), Catalog.BOARD: Rect2(477, 160, 363, 386),
	Catalog.ENCORE: Rect2(851, 119, 450, 451), Catalog.SNAKE: Rect2(1300, 121, 346, 446),
	Catalog.CATCH: Rect2(1658, 144, 507, 398),
}


static func gallery(game) -> void:
	var view = game.View
	var preferences = game.preferences
	game.draw_texture_rect(PAVILION, view.CANVAS, false)
	game.draw_rect(view.CANVAS, Color("#291c36", 0.23))
	view.petals(game, game.visual_clock)
	view.button(game, GALLERY_BACK, preferences.text("common.back"))
	var header := Rect2(270, 23, 324, 62)
	view.frame(game, header, Color("#251d34", 0.95), Color("#d7b387"))
	view.centered(game, Rect2(277, 24, 310, 36), preferences.text("arcade.title"), 30, view.CREAM, true)
	var powered: bool = game.profile.has_unlock(Media.CONSOLE)
	view.centered(game, Rect2(277, 60, 310, 20),
		preferences.text("media.play_owned" if powered else "media.arcade_locked"), 12, view.DIM)
	var entrance: float = game.menu_motion.entrance_amount()
	for index in range(Catalog.GAMES.size()):
		var id: String = Catalog.GAMES[index]
		var area := card_rect(index)
		var lift := render_lift(game, area, index, entrance)
		area.position.y += lift
		draw_card(game, id, area, index)


static func card_rect(index: int) -> Rect2:
	return Rect2(Vector2(CARD_X + index * CARD_STEP, CARD_Y), CARD_SIZE)


static func render_lift(game, area: Rect2, index: int, entrance: float) -> float:
	var hover: float = game.menu_motion.hover_amount(area, game.get_local_mouse_position())
	var press: float = game.menu_motion.press_amount(area)
	return roundf(12.0 * entrance * (0.6 + 0.15 * index) - hover * 4.0 + press * 3.0)


static func draw_card(game, id: String, area: Rect2, index: int) -> void:
	var view = game.View
	var preferences = game.preferences
	var color: Color = Catalog.DATA[id].color
	var owned := Media.can_replay(game.profile, id)
	if not owned:
		color = color.lerp(Color("#aba0b3"), 0.57)
	var box_ink := Color("#2f2238").lerp(color.darkened(0.65), 0.34)
	view.frame(game, area, box_ink, color)
	var center := (area.position + Vector2(CARD_SIZE.x * 0.5, 62.0)).round()
	var light := 0.11 + 0.065 * sin(float(game.visual_clock) * 3.0 + index * 1.2)
	game.draw_circle(center, 40.0, Color(color, light))
	game.draw_arc(center, 40.0, 0, TAU, 40, Color(color, 0.38), 1.0)
	var float_y := roundf(sin(float(game.visual_clock) * (1.8 + index * 0.14) + index) * 2.0)
	draw_icon(game, id, center + Vector2(0, float_y), 77.0)
	for side: float in [-1.0, 1.0]:
		view.diamond(game, center + Vector2(side * 38.0, -24.0 * side), 2.4, Color(color, light * 4.0))
	var title := Catalog.label(id, "short", preferences.language)
	view.centered(game, Rect2(area.position + Vector2(6, 112), Vector2(140, 29)), title, 16, view.CREAM, true)
	view.centered(game, Rect2(area.position + Vector2(6, 143), Vector2(140, 15)),
		Catalog.label(id, "tag", preferences.language), 10, color)
	view.frame(game, Rect2(area.position + Vector2(17, 169), Vector2(118, 20)), Color("#201a2a"), Color(color, 0.72))
	var needed := Media.cartridge(id) if game.profile.has_unlock(Media.CONSOLE) else Media.CONSOLE
	var action: String = preferences.text("arcade.play") if owned \
		else preferences.text("media.shop_price", {"amount": Media.PRICES[needed]})
	view.centered(game, Rect2(area.position + Vector2(17, 169), Vector2(118, 20)),
		action, 12, view.CREAM, true)


static func select(game, point: Vector2) -> void:
	if GALLERY_BACK.has_point(point):
		game.screen = "garden_hub"
		return
	for index in range(Catalog.GAMES.size()):
		if card_rect(index).grow(3).has_point(point):
			game.practice_arcade_round(Catalog.GAMES[index])
			return


static func draw_icon(canvas: Node2D, id: String, point: Vector2, width: float) -> void:
	var region := icon_region(id)
	var extent := (region.size * width / maxf(region.size.x, region.size.y)).round()
	canvas.draw_texture_rect_region(ICONS, Rect2((point - extent * 0.5).round(), extent), region)


static func icon_region(id: String) -> Rect2:
	return ICON_REGIONS[id]


static func round(game) -> void:
	if game.arcade.round == null:
		return
	var id: String = game.arcade.id
	var view = game.View
	if id == Catalog.BOARD:
		if game.arcade.practice:
			game.draw_texture_rect(PAVILION, view.CANVAS, false)
		game.arcade.round.draw(game)
		return
	var color: Color = Catalog.DATA[id].color
	game.draw_texture_rect(GROUNDS[id], view.CANVAS, false)
	game.draw_rect(view.CANVAS, Color("#1c1629", 0.73))
	draw_header(game, id, color)
	game.arcade.round.draw(game)
	draw_footer(game, id, color)


static func draw_header(game, id: String, color: Color) -> void:
	var view = game.View
	var box := Rect2(74, 23, 716, 51)
	view.frame(game, box, Color("#2b2034"), color)
	draw_icon(game, id, Vector2(107, 49), 37.0)
	var language: String = game.preferences.language
	view.text(game, Vector2(138, 58), Catalog.label(id, "title", language), 27, view.CREAM, true)
	var subtext: String = Catalog.label(id, "tag", language)
	view.text(game, Vector2(491, 54), subtext, 13, color, false, HORIZONTAL_ALIGNMENT_RIGHT, 276.0)


static func draw_footer(game, id: String, color: Color) -> void:
	var view = game.View
	var prefs = game.preferences
	var mode := str(game.arcade.round.state)
	var practice: bool = game.arcade.practice
	var ended := mode != "playing"
	var line: String
	if practice:
		line = prefs.text("arcade.free_practice") if not ended else prefs.text(result_key(mode))
		if ended:
			view.button(game, REPLAY, prefs.text("arcade.again"), true)
	else:
		var stake: int = Catalog.DATA[id].stake
		match mode:
			"win":
				line = prefs.text("arcade.win_prize", {"prize": winning_prize(game, id)})
			"loss":
				line = prefs.text("arcade.stake_lost")
			"draw":
				line = prefs.text("arcade.refund", {"amount": stake})
			_:
				line = prefs.text("arcade.win_prize", {"prize": Catalog.prize(game, id)})
	var label := "common.back" if practice else ("three_caps.claim" if ended else "three_caps.forfeit")
	view.button(game, EXIT, prefs.text(label), ended and not practice)
	var info := Rect2(74, 330, 458 if not practice or not ended else 376, 41)
	view.frame(game, info, Color("#2a2036"), Color(color, 0.67))
	view.centered(game, Rect2(info.position + Vector2(7, 0), info.size - Vector2(14, 0)),
		line, 13, view.CREAM)


static func winning_prize(game, id: String) -> String:
	if id == Catalog.SNAKE:
		return game.preferences.text("item.petal_bomb.name") if game.pocket.held.is_empty() \
			else game.preferences.text("arcade.petals", {"amount": 8})
	if id == Catalog.CATCH:
		return game.preferences.text("item.clockwise_tonic.name") if game.pocket.held.is_empty() \
			else game.preferences.text("arcade.petals", {"amount": 9})
	return Catalog.prize(game, id)


static func result_key(mode: String) -> String:
	match mode:
		"win": return "three_caps.won"
		"loss": return "arcade.round_lost"
		_: return "three_caps.draw"


static func tap_round(game, point: Vector2) -> void:
	if game.arcade.round == null:
		return
	var id: String = game.arcade.id
	if id != Catalog.BOARD and game.arcade.outcome != "playing" and EXIT.has_point(point):
		game.arcade.settle(game)
	elif id != Catalog.BOARD and game.arcade.practice and game.arcade.outcome != "playing" and REPLAY.has_point(point):
		game.practice_arcade_round(id)
	else:
		game.arcade.tap(game, point)
