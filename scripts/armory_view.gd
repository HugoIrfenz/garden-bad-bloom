extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const CodexView = preload("res://scripts/codex_view.gd")
const Catalog = preload("res://scripts/weapon_catalog.gd")
const Evolutions = preload("res://scripts/weapon_evolutions.gd")
const WeaponArt = preload("res://scripts/weapon_art.gd")
const BACK = Rect2(49, 332, 127, 42)
const INK = Color("#352737")
const DIM_INK = Color("#715461")
const PAPER = Color("#f8e8d2")
const GOLD = Color("#ac7955")

static func tab(index: int) -> Rect2:
	return Rect2(49 + index * 155, 64, 147, 38)

static func row(index: int) -> Rect2:
	return Rect2(49, 115 + index * 43, 258, 39)

static func entries(hero: int) -> Array[String]:
	var ids: Array[String] = [Catalog.starter(hero)]
	ids.append_array(Catalog.available(hero, ""))
	var evolved := Evolutions.weapon_id(hero)
	if not evolved.is_empty():
		ids.append(evolved)
	return ids

static func tap(game, point: Vector2) -> void:
	if BACK.has_point(point):
		game.screen = "codex"
		return
	for index in range(game.NAMES.size()):
		if tab(index).has_point(point):
			game.armory_hero = index
			game.armory_entry = 0
			return
	for index in range(entries(game.armory_hero).size()):
		if row(index).has_point(point):
			game.armory_entry = index
			return

static func draw(game) -> void:
	var view = game.View
	var hero: int = game.armory_hero
	var items := entries(hero)
	var selected := clampi(game.armory_entry, 0, items.size() - 1)
	game.draw_texture_rect(CodexView.BACKDROP, view.CANVAS, false)
	game.draw_rect(view.CANVAS, Color(0.09, 0.07, 0.13, 0.37))
	view.petals(game, game.visual_clock)
	view.frame(game, Rect2(305, 12, 254, 39), Color("#282032"))
	view.centered(game, Rect2(305, 12, 254, 39), "Weapon Ledger", 24, view.CREAM, true)
	for index in range(game.NAMES.size()):
		view.button(game, tab(index), game.NAMES[index], index == hero)
	for index in range(items.size()):
		draw_row(game, items[index], index, selected == index)
	draw_detail(game, items[selected])
	view.button(game, BACK, "Enemy Codex", true)

static func draw_row(game, id: String, index: int, selected: bool) -> void:
	var view = game.View
	var known: bool = game.knows_weapon(id)
	var weapon := Catalog.item(id)
	var area := row(index)
	var color: Color = Color("#fff1d5") if selected else PAPER
	view.frame(game, area, color, GOLD)
	var point := area.position + Vector2(32, 20)
	game.draw_circle(point, 16.0, Color("#e6c8aa"), true, -1.0, true)
	if known:
		WeaponArt.draw_icon(game, id, point, 29.0)
	else:
		view.centered(game, Rect2(point - Vector2(15, 14), Vector2(30, 28)), "?", 19, DIM_INK, true)
	view.text(game, area.position + Vector2(61, 18), weapon.name if known else "Undiscovered", 16, INK, true)
	if known:
		view.text(game, area.position + Vector2(62, 32), "Evolution" if weapon.get("evolved", false) else String(weapon.rarity).capitalize(), 10, DIM_INK)

static func draw_detail(game, id: String) -> void:
	var view = game.View
	var known: bool = game.knows_weapon(id)
	var item := Catalog.item(id)
	var box := Rect2(321, 115, 496, 191)
	view.frame(game, box, PAPER, GOLD)
	var point := Vector2(413, 210)
	game.draw_circle(point, 68.0, Color("#ead0af"), true, -1.0, true)
	game.draw_arc(point, 67.0, 0, TAU, 60, Color(GOLD, 0.7), 1.3, true)
	if known:
		WeaponArt.draw_icon(game, id, point, 106.0)
	else:
		view.centered(game, Rect2(point - Vector2(28, 31), Vector2(56, 62)), "?", 48, DIM_INK, true)
	var title: String = item.name if known else "Undiscovered weapon"
	view.text(game, Vector2(501, 157), title, 21, INK, true)
	var detail: String = item.detail if known else "Find this heroine’s weapons in treasure, elite and secret rooms, or at a merchant."
	if not known and item.get("evolved", false):
		detail = "Combine the listed requirements at a rest-room forge to discover this evolution."
	var baseline := 188.0
	for line in CodexView.wrap_text(detail, ThemeDB.fallback_font, 288.0, 13):
		view.text(game, Vector2(501, baseline), line, 13, DIM_INK)
		baseline += 18.0
	if known:
		var stats := "%d damage   ·   %.2fs per attack" % [item.damage, item.interval]
		view.text(game, Vector2(501, 272), stats, 14, INK)
		if Catalog.DEFINITIONS.has(id):
			view.text(game, Vector2(501, 291), "Forged in the dungeon" if item.get("evolved", false)
				else "Available in Run Preparation", 10, DIM_INK)
