extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const Heroines = preload("res://scripts/garden_hub_heroines.gd")
const Decorations = preload("res://scripts/garden_decorations.gd")
const Profile = preload("res://scripts/run_profile.gd")
const COURTYARD = preload("res://assets/art/menus/garden_hub.png")
const TEA_TABLE = preload("res://assets/art/menus/encounter_props.png")
const TEA_REGION = Rect2(918, 235, 296, 244)
const TITLE = Rect2(83, 329, 118, 43)
const ROSTER = Rect2(213, 329, 163, 43)
const CODEX = Rect2(388, 329, 105, 43)
const SEEDS = Rect2(505, 329, 124, 43)
const HISTORY = Rect2(641, 329, 140, 43)
const GAMES = Rect2(352, 24, 160, 45)
const JUKEBOX = Rect2(524, 24, 114, 45)
const LANTERNS = [Vector2(270, 153), Vector2(314, 175), Vector2(550, 175), Vector2(594, 153)]

static func action_at(point: Vector2) -> String:
	if GAMES.has_point(point):
		return "games"
	if JUKEBOX.has_point(point):
		return "jukebox"
	if TITLE.has_point(point):
		return "title"
	if ROSTER.has_point(point):
		return "roster"
	if CODEX.has_point(point):
		return "codex"
	if SEEDS.has_point(point):
		return "seeds"
	if HISTORY.has_point(point):
		return "history"
	return ""

static func react_at(game, point: Vector2) -> void:
	Heroines.react_at(game, point)

static func draw(game) -> void:
	draw_courtyard(game)
	var view = game.View
	var preferences = game.preferences
	var title_box := Rect2(35, 25, 200, 47)
	view.frame(game, title_box, Color(0.14, 0.11, 0.21, 0.86))
	view.centered(game, title_box, preferences.text("common.garden"), 28, view.CREAM, true)
	draw_balance(game, Rect2(655, 25, 173, 38))
	view.button(game, GAMES, preferences.text("arcade.title"), true)
	view.button(game, JUKEBOX, preferences.text("media.jukebox_short"))
	view.button(game, TITLE, preferences.text("hub.title_screen"))
	var roster_key := "hub.continue" if FileAccess.file_exists(game.SAVE) else "hub.roster"
	view.button(game, ROSTER, preferences.text(roster_key), true)
	view.button(game, CODEX, preferences.text("hub.codex"))
	view.button(game, SEEDS, preferences.text("hub.seed_shop"))
	view.button(game, HISTORY, preferences.text("hub.run_history"))

static func draw_balance(game, box: Rect2) -> void:
	var view = game.View
	var seeds: int = game.garden_seeds
	var key := "currency.seeds.one" if seeds == 1 else "currency.seeds.other"
	view.frame(game, box, Color(0.14, 0.11, 0.21, 0.92))
	view.centered(game, box, game.preferences.text(key, {"amount": seeds}), 16, view.CREAM, true)

static func draw_courtyard(game) -> void:
	var view = game.View
	var clock: float = game.visual_clock
	game.draw_texture_rect(COURTYARD, view.CANVAS, false)
	_draw_fountain(game, clock)
	draw_furnishings(game, clock)
	view.petals(game, clock)
	Heroines.draw(game)

static func draw_furnishings(game, clock: float) -> void:
	Decorations.draw(game, clock)
	if game.profile.has_unlock(Profile.FOUNTAIN_LANTERNS):
		for index in range(LANTERNS.size()):
			draw_lantern(game, LANTERNS[index], 1.0, clock + index * 1.6)
	if game.profile.has_unlock(Profile.PORCELAIN_PLANTERS):
		draw_planter(game, Vector2(120, 205), 49.0)
		draw_planter(game, Vector2(760, 192), 47.0)
	if game.profile.has_unlock(Profile.ROSE_TEA_CORNER):
		draw_tea_corner(game, Vector2(796, 264), 75.0, clock)
	if game.profile.has_unlock(Profile.FIREFLY_GROVE):
		for index in range(13):
			var pulse := clock * (1.1 + (index % 3) * 0.2) + index * 1.4
			var point := Vector2(116.0 + fposmod(index * 91.0 + clock * 5.0, 622.0),
				90.0 + fposmod(index * 61.0, 191.0))
			draw_firefly(game, point + Vector2(sin(pulse * 0.62) * 13.0, cos(pulse * 0.74) * 9.0), pulse, 1.0)

static func draw_planter(canvas: Node2D, feet: Vector2, height: float) -> void:
	Art.shadow(canvas, feet, height * 0.31)
	Art.paint_actor(canvas, Art.COVER, Art.COVER_REGIONS[4], feet, height, 0.0, Vector2.ONE, Color.WHITE)

static func draw_tea_corner(canvas: Node2D, feet: Vector2, height: float, clock: float) -> void:
	Art.shadow(canvas, feet, height * 0.59)
	Art.paint_actor(canvas, TEA_TABLE, TEA_REGION, feet, height, 0.0, Vector2.ONE, Color.WHITE)
	for index in range(3):
		var rise := fposmod(clock * 0.61 + index / 3.0, 1.0)
		var point := feet + Vector2(height * 0.27 + sin(clock * 1.5 + index) * 3.0, -height * 0.75 - rise * height * 0.22)
		canvas.draw_circle(point.round(), 1.2 + rise, Color(1.0, 0.89, 0.81, sin(PI * rise) * 0.68))

static func draw_firefly(canvas: Node2D, point: Vector2, phase: float, scale: float) -> void:
	var glow := 0.40 + 0.55 * pow(maxf(0.0, sin(phase)), 2.0)
	var center := point.round()
	canvas.draw_circle(center, 4.6 * scale, Color(0.98, 0.78, 0.37, glow * 0.21), true, -1.0, true)
	canvas.draw_circle(center, 1.7 * scale, Color(1.0, 0.86, 0.49, glow), true, -1.0, true)
	canvas.draw_rect(Rect2(center, Vector2.ONE), Color(1.0, 0.97, 0.74, glow))

static func draw_lantern(canvas: Node2D, feet: Vector2, size: float, clock: float) -> void:
	var glow := 0.78 + 0.12 * sin(clock * 2.7) + 0.08 * sin(clock * 5.1)
	canvas.draw_set_transform(feet.round(), 0.0, Vector2.ONE * size)
	canvas.draw_circle(Vector2(0, -10), 12.0, Color(1.0, 0.62, 0.22, 0.19 * glow), true, -1.0, true)
	canvas.draw_rect(Rect2(-4, -2, 8, 2), Color("#663f3c"))
	canvas.draw_rect(Rect2(-1, -7, 2, 6), Color("#806145"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, -8), Vector2(-5, -12),
		Vector2(-4, -17), Vector2(0, -20), Vector2(4, -17), Vector2(5, -12)]), Color("#924e43"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, -9), Vector2(-4, -13),
		Vector2(0, -18), Vector2(4, -13)]), Color("#e7ac52").lerp(Color("#fff2b1"), glow))
	canvas.draw_rect(Rect2(0, -16, 1, 5), Color("#fffbe4"))
	canvas.draw_set_transform(Vector2.ZERO)

static func _draw_fountain(canvas: Node2D, clock: float) -> void:
	const WATER = Color(0.86, 0.99, 1.0, 0.70)
	for column in [376.0, 389.0, 471.0, 484.0]:
		for index in range(4):
			var progress := fposmod(clock * 1.4 + index * 0.24 + column * 0.047, 1.0)
			var point := Vector2(column + sin(PI * progress) * 1.8, lerpf(72.0, 118.0, progress * progress))
			canvas.draw_line(point, point + Vector2(0.0, 2.5), Color(WATER, 0.61 - 0.39 * progress), 0.9, true)
	for index in range(3):
		var progress := fposmod(clock * 0.83 + index * 0.33, 1.0)
		var point := Vector2(382.0 + index * 48.0, 119.0 - (index % 2) * 6.0)
		canvas.draw_set_transform(point, 0.0, Vector2(1.0, 0.28))
		canvas.draw_arc(Vector2.ZERO, 2.0 + progress * 15.0, 0.0, TAU, 20,
			Color(WATER, (1.0 - progress) * 0.40), 1.3, true)
	canvas.draw_set_transform(Vector2.ZERO)
