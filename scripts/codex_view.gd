extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const OptionalBosses = preload("res://scripts/optional_bosses.gd")
const BACKDROP = preload("res://assets/art/menus/enemy_archive.png")
const BACK = Rect2(49, 332, 127, 42)
const WEAPONS = Rect2(639, 332, 173, 42)
const RELICS = Rect2(451, 332, 173, 42)
const BIOME_PREV = Rect2(52, 62, 52, 38)
const BIOME_NEXT = Rect2(758, 62, 52, 38)
const GUIDE = Color("#281e2d")
const BRONZE = Color("#98704e")
const PAPER = Color("#f9eacb")
const INK = Color("#342935")
const FADED_INK = Color("#6e544d")

static func entry_rect(index: int, count := 5) -> Rect2:
	var stride := minf(43.0, floorf(215.0 / maxi(1, count)))
	return Rect2(49, 110 + index * stride, 247, stride - 3.0)

static func entry_at(point: Vector2, count := 5) -> int:
	for index in range(count):
		if entry_rect(index, count).has_point(point):
			return index
	return -1

static func draw(game) -> void:
	var view = game.View
	var biome: int = clampi(int(game.codex_biome), 0, game.BIOMES.size() - 2)
	var entries: Array = game.codex.entries(biome)
	game.draw_texture_rect(BACKDROP, view.CANVAS, false)
	game.draw_rect(view.CANVAS, Color(0.10, 0.08, 0.14, 0.25))
	view.petals(game, game.visual_clock)
	var banner := Rect2(306, 12, 252, 38)
	view.frame(game, banner, Color(GUIDE, 0.93))
	view.centered(game, banner, "Enemy Codex", 24, view.CREAM, true)

	var found := 0
	for entry in entries:
		if entry.discovered:
			found += 1
	var biome_title := Rect2(118, 59, 628, 44)
	view.frame(game, biome_title, Color(GUIDE, 0.93))
	view.centered(game, Rect2(127, 61, 610, 21), game.BIOMES[biome], 18, view.CREAM, true)
	view.centered(game, Rect2(127, 83, 610, 15), "%d / %d discovered" % [found, entries.size()], 11, view.DIM)
	if biome > 0:
		view.button(game, BIOME_PREV, "‹")
	if biome < game.BIOMES.size() - 2:
		view.button(game, BIOME_NEXT, "›")

	for index in range(entries.size()):
		entry_card(game, entries[index], index, entries.size())
	var selected: Dictionary = entries[clampi(int(game.codex_kind), 0, entries.size() - 1)] if not entries.is_empty() else {}
	detail_page(game, selected)
	view.button(game, BACK, "Back", true)
	view.button(game, RELICS, "Relic Ledger")
	view.button(game, WEAPONS, "Weapon Ledger")

static func entry_card(game, entry: Dictionary, index: int, count: int) -> void:
	var view = game.View
	var box := entry_rect(index, count)
	var selected: bool = index == game.codex_kind
	var known: bool = entry.discovered
	var fill := Color("#f8ddb1") if selected else PAPER
	view.frame(game, box, fill, Color("#eed397") if selected else BRONZE)
	var point := box.position + Vector2(28, box.size.y * 0.5)
	var radius := minf(17.0, box.size.y * 0.45)
	game.draw_circle(point, radius, Color("#e9ccaa"), true, -1.0, true)
	game.draw_arc(point, radius - 1.0, 0.0, TAU, 34, Color(BRONZE, 0.65), 1.0, true)
	if known:
		var feet := point + Vector2(0.0, radius - 3.0)
		if not entry.has("optional_boss"):
			Art.garden_enemy(game, int(entry.biome), int(entry.kind), feet, radius * 1.7, game.visual_clock, 0.0, 0.0)
		else:
			OptionalBosses.draw_pose(game, entry.optional_boss, 0, feet, 1.0, radius * 1.7)
	else:
		view.centered(game, Rect2(point - Vector2(12, 12), Vector2(24, 24)), "?", 18, FADED_INK, true)
	var name: String = entry.name if known else "Undiscovered"
	var normal_width = Art.DISPLAY_FONT.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var name_size = 13 if normal_width > box.size.x - 69.0 else 14
	view.text(game, box.position + Vector2(55, 19 if count <= 5 else box.size.y * 0.5 + 5.0), name, name_size, INK, true)
	var label := ("BOSS" if bool(entry.boss) else "ENEMY") if known else ""
	if count <= 5 and not label.is_empty():
		view.text(game, box.position + Vector2(55, 32), label, 9, FADED_INK)
	if selected:
		view.diamond(game, box.end - Vector2(11.0, 12.0), 3.8, BRONZE)

static func detail_page(game, entry: Dictionary) -> void:
	var view = game.View
	var known := bool(entry.get("discovered", false))
	var page := Rect2(311, 110, 501, 211)
	view.frame(game, page, PAPER, BRONZE)
	var portrait := Vector2(408.0, 216.0)
	game.draw_circle(portrait, 70.0, Color("#ead2ad"), true, -1.0, true)
	game.draw_arc(portrait, 69.0, 0, TAU, 60, Color(BRONZE, 0.60), 1.0, true)
	game.draw_arc(portrait, 62.0, 0, TAU, 60, Color(BRONZE, 0.35), 1.0, true)
	view.diamond(game, portrait + Vector2(0.0, -67.0), 4.0, BRONZE)
	view.diamond(game, portrait + Vector2(0.0, 67.0), 4.0, BRONZE)
	if known:
		Art.shadow(game, portrait + Vector2(0.0, 42.0), 34.0)
		if entry.has("optional_boss"):
			OptionalBosses.draw_pose(game, entry.optional_boss, 0, portrait + Vector2(0, 42), 1.0, 100.0)
		else:
			Art.garden_enemy(game, int(entry.biome), int(entry.kind),
				portrait + Vector2(0.0, 42.0), 100.0 if entry.boss else 92.0, game.visual_clock, 0.0, 0.0)
	else:
		view.centered(game, Rect2(portrait - Vector2(24, 34), Vector2(48, 68)), "?", 48, FADED_INK, true)

	var label := ("CHAPTER BOSS" if bool(entry.boss) else "ENEMY") if known else "ENTRY HIDDEN"
	if known and entry.has("optional_boss"):
		label = "OPTIONAL BOSS"
	view.text(game, Vector2(506, 143), label, 11, FADED_INK)
	var name: String = entry.name if known else "Undiscovered"
	var name_lines := wrap_text(name, Art.DISPLAY_FONT, 283.0, 22)
	var baseline := 173.0
	for line in name_lines:
		view.text(game, Vector2(506, baseline), line, 22, INK, true)
		baseline += 26.0
	game.draw_line(Vector2(506, baseline - 12.0), Vector2(786, baseline - 12.0), BRONZE, 1.0, true)
	var description: String = entry.description if known else "Meet this enemy in the dungeon to uncover its field notes."
	for line in wrap_text(description, ThemeDB.fallback_font, 278.0, 14):
		view.text(game, Vector2(506, baseline + 12.0), line, 14, INK)
		baseline += 21.0

static func wrap_text(value: String, font: Font, width: float, size: int) -> Array[String]:
	var lines: Array[String] = []
	var current := ""
	for word in value.split(" ", false):
		var expanded := word if current.is_empty() else current + " " + word
		if not current.is_empty() and font.get_string_size(expanded, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			lines.append(current)
			current = word
		else:
			current = expanded
	if not current.is_empty():
		lines.append(current)
	return lines
