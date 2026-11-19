extends RefCounted

const CodexView = preload("res://scripts/codex_view.gd")
const Icons = preload("res://scripts/relic_info_view.gd")
const Relics = preload("res://scripts/relic_effects.gd")
const Sources = preload("res://scripts/relic_sources.gd")

const BACK = Rect2(49, 331, 126, 43)
const PREV = Rect2(181, 331, 65, 43)
const NEXT = Rect2(252, 331, 65, 43)
const ROWS = 5
const TAB_NAMES = ["Find Relic", "Effect", "Forge & Pairs"]
const PAGE = Rect2(329, 62, 484, 261)
const PAPER = Color("#f8e8cc")
const BRONZE = Color("#9e7254")
const INK = Color("#382839")
const MUTED = Color("#74554e")
const PLUM = Color("#2d2133")

static func entry_rect(row: int) -> Rect2:
	return Rect2(49, 102 + row * 44, 268, 41)

static func tab_rect(index: int) -> Rect2:
	return Rect2(346 + index * 150, 142, 142, 33)

static func page_count() -> int:
	return ceili(float(Sources.LEDGER_IDS.size()) / ROWS)

static func tap(game, point: Vector2) -> void:
	if BACK.has_point(point):
		game.screen = game.relic_ledger_return
		return
	var page: int = game.relic_ledger_page
	if PREV.has_point(point) or NEXT.has_point(point):
		var next_page := clampi(page + (-1 if PREV.has_point(point) else 1), 0, page_count() - 1)
		if page != next_page:
			game.relic_ledger_page = next_page
			game.relic_ledger_entry = next_page * ROWS
			game.sound.play("ui")
		return
	for row in ROWS:
		var entry := page * ROWS + row
		if entry < Sources.LEDGER_IDS.size() and entry_rect(row).has_point(point):
			if game.relic_ledger_entry != entry:
				game.relic_ledger_entry = entry
				game.sound.play("ui")
			return
	for index in TAB_NAMES.size():
		if tab_rect(index).has_point(point):
			if game.relic_ledger_tab != index:
				game.relic_ledger_tab = index
				game.sound.play("ui")
			return

static func draw(game) -> void:
	var view = game.View
	game.draw_texture_rect(CodexView.BACKDROP, view.CANVAS, false)
	game.draw_rect(view.CANVAS, Color(0.10, 0.075, 0.15, 0.33))
	view.petals(game, game.visual_clock)

	var title := Rect2(305, 12, 254, 39)
	view.frame(game, title, Color(PLUM, 0.94))
	view.centered(game, title, "Relic Ledger", 25, view.CREAM, true)
	var found := 0
	for id: String in Sources.LEDGER_IDS:
		if game.codex.knows_relic(id) or id in game.relic_ledger_carried:
			found += 1
	var ledger_page: int = game.relic_ledger_page
	view.frame(game, Rect2(49, 62, 268, 36), Color(PLUM, 0.94))
	view.text(game, Vector2(60, 85), "%d / %d discovered" % [found, Sources.LEDGER_IDS.size()], 14, view.CREAM, true)
	view.text(game, Vector2(245, 85), "Page %d / %d" % [ledger_page + 1, page_count()], 10, view.DIM)

	for row in ROWS:
		var entry := ledger_page * ROWS + row
		if entry < Sources.LEDGER_IDS.size():
			draw_entry(game, Sources.LEDGER_IDS[entry], row, entry == game.relic_ledger_entry)
	draw_details(game, Sources.LEDGER_IDS[game.relic_ledger_entry])

	view.button(game, BACK, "Back", true)
	draw_page_button(game, PREV, "‹", ledger_page > 0)
	draw_page_button(game, NEXT, "›", ledger_page < page_count() - 1)
	var note := Rect2(329, 331, 484, 43)
	view.frame(game, note, Color(PLUM, 0.94))
	view.centered(game, Rect2(345, 337, 452, 15), "Equip a relic to record its discovery.", 12, view.CREAM)
	view.centered(game, Rect2(345, 353, 452, 16), "Take one reward per chest and carry multiple relics in a run.", 12, view.DIM)

static func state_label(game, id: String) -> String:
	if id in game.relic_ledger_carried:
		return "Carried"
	return "Discovered" if game.codex.knows_relic(id) else "Undiscovered"

static func draw_page_button(game, box: Rect2, title: String, enabled: bool) -> void:
	var view = game.View
	if enabled:
		view.button(game, box, title)
	else:
		view.frame(game, box, Color(PLUM, 0.94))
		view.centered(game, box, title, 19, view.DIM.darkened(0.38), true)

static func draw_entry(game, id: String, row: int, selected: bool) -> void:
	var view = game.View
	var box := entry_rect(row)
	var hover: float = game.menu_motion.hover_amount(box, game.get_local_mouse_position())
	var press: float = game.menu_motion.press_amount(box)
	var fill := Color("#f7dcb1") if selected else PAPER
	view.frame(game, box, fill.lightened(hover * 0.1 + press * 0.16), Color("#ffdb99") if selected else BRONZE)
	var center := box.position + Vector2(28, 20)
	game.draw_circle(center, 16.0, Color("#e6c8a2"), true, -1.0, true)
	game.draw_arc(center, 15.5, 0.0, TAU, 28, Color(BRONZE, 0.78), 1.0, true)
	Icons.draw_icon(game, id, center, 29.0)
	var item := Relics.definition(id)
	view.text(game, box.position + Vector2(51, 19), item.name, 15, INK, true)
	var label := state_label(game, id)
	var tag := str(item.rarity).capitalize() + "  ·  " + label
	view.text(game, box.position + Vector2(52, 33), tag, 10, Color("#3a624a") if label == "Carried" else MUTED)
	if selected:
		view.diamond(game, box.end - Vector2(13, 19), 4.0, BRONZE)

static func draw_details(game, id: String) -> void:
	var view = game.View
	var item := Relics.definition(id)
	view.frame(game, PAGE, PAPER, BRONZE)
	var center := Vector2(377, 101)
	game.draw_circle(center, 29.0, Color("#ebc9a2"), true, -1.0, true)
	game.draw_arc(center, 28.0, 0.0, TAU, 36, BRONZE, 1.0, true)
	var lift := roundf(sin(float(game.visual_clock) * 2.7) * 1.5)
	Icons.draw_icon(game, id, center - Vector2(0.0, lift), 53.0)
	view.text(game, Vector2(422, 99), item.name, 25, INK, true)
	var hero := Sources.hero_for(id)
	var compatible: String = "Any heroine" if hero < 0 else game.NAMES[hero] + " only"
	view.text(game, Vector2(423, 122), "%s  ·  %s  ·  %s" % [str(item.rarity).capitalize(), compatible, state_label(game, id)], 13, MUTED)

	for index in TAB_NAMES.size():
		var box := tab_rect(index)
		var hover: float = game.menu_motion.hover_amount(box, game.get_local_mouse_position())
		var press: float = game.menu_motion.press_amount(box)
		if index == game.relic_ledger_tab:
			view.frame(game, box, PLUM.lightened(press * 0.23), BRONZE)
			view.centered(game, box, TAB_NAMES[index], 14, view.CREAM, true)
		else:
			view.frame(game, box, Color("#f1dbc0").lightened(hover * 0.25), BRONZE)
			view.centered(game, box, TAB_NAMES[index], 14, INK, true)

	match game.relic_ledger_tab:
		0:
			var baseline := 214.0
			view.text(game, Vector2(353, 195), "Where to find it", 16, INK, true)
			for line: String in Sources.source_lines(id, game.BIOMES):
				view.diamond(game, Vector2(356, baseline - 4.0), 2.6, BRONZE)
				baseline = draw_paragraph(game, line, 366.0, baseline, 420.0) + 2.0
		1:
			view.text(game, Vector2(353, 195), "Effect", 16, INK, true)
			var baseline := draw_paragraph(game, item.detail, 353.0, 215.0, 434.0) + 11.0
			view.text(game, Vector2(353, baseline), "Trigger and limit", 16, INK, true)
			draw_paragraph(game, Icons.TRIGGER_NOTES[id], 353.0, baseline + 20.0, 434.0)
		_:
			var baseline := 214.0
			view.text(game, Vector2(353, 195), "Combinations", 16, INK, true)
			var combinations := Sources.combinations(id)
			if combinations.is_empty():
				combinations.append("The perfect-dodge charge works with any basic weapon attack.")
			for line: String in combinations:
				baseline = draw_paragraph(game, line, 353.0, baseline, 434.0) + 10.0

static func draw_paragraph(game, paragraph: String, x: float, y: float, width: float) -> float:
	for line: String in CodexView.wrap_text(paragraph, ThemeDB.fallback_font, width, 13):
		game.View.text(game, Vector2(x, y), line, 13, INK)
		y += 15.0
	return y
