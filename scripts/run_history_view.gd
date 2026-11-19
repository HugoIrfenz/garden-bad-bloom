extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const BACKDROP = preload("res://assets/art/menus/moonlit_pond.png")
const PAGE_SIZE = 5
const BACK = Rect2(43, 332, 144, 40)
const PREVIOUS = Rect2(254, 332, 107, 40)
const NEXT = Rect2(503, 332, 107, 40)
const DETAILS = Rect2(435, 78, 386, 239)
const INK = Color("#242033")
const SEED_GOLD = Color("#f4d091")

static func draw(game) -> void:
	var view = game.View
	var preferences = game.preferences
	game.draw_texture_rect(BACKDROP, view.CANVAS, false)
	game.draw_rect(view.CANVAS, Color(0.09, 0.07, 0.15, 0.36))
	view.petals(game, game.visual_clock)
	var heading := Rect2(285, 18, 294, 45)
	view.frame(game, heading, Color(INK, 0.92))
	view.centered(game, heading, preferences.text("hub.run_history"), 28, view.CREAM, true)
	view.button(game, BACK, preferences.text("common.back_to_garden"))
	var records: Array = game.run_history
	if records.is_empty():
		var empty := Rect2(245, 144, 374, 80)
		view.frame(game, empty, Color(INK, 0.94))
		view.centered(game, empty, preferences.text("history.empty"), 16, view.CREAM)
		return
	var page: int = game.history_page
	var first := page * PAGE_SIZE
	var last := mini(first + PAGE_SIZE, records.size())
	for index in range(first, last):
		draw_row(game, row_rect(index - first), records[index], index == game.history_selected)
	var selected: int = clampi(game.history_selected, first, last - 1)
	draw_details(game, records[selected])
	var page_label := Rect2(374, 332, 116, 40)
	view.frame(game, page_label, Color(INK, 0.92))
	view.centered(game, page_label, "%d / %d" % [page + 1, page_count(records.size())], 15, view.CREAM)
	if page > 0:
		view.button(game, PREVIOUS, preferences.text("history.previous"))
	if last < records.size():
		view.button(game, NEXT, preferences.text("history.next"))

static func page_count(count: int) -> int:
	return maxi(1, ceili(float(count) / PAGE_SIZE))

static func row_rect(index: int) -> Rect2:
	return Rect2(43, 78 + index * 48, 377, 43)

static func activate(game, point: Vector2) -> bool:
	if BACK.has_point(point):
		return true
	var count: int = game.run_history.size()
	var page: int = game.history_page
	var next_page := page
	if PREVIOUS.has_point(point) and page > 0:
		next_page -= 1
	elif NEXT.has_point(point) and page + 1 < page_count(count):
		next_page += 1
	if next_page != page:
		game.history_page = next_page
		game.history_selected = next_page * PAGE_SIZE
		game.sound.play("ui")
		return false
	var first := page * PAGE_SIZE
	for index in range(first, mini(first + PAGE_SIZE, count)):
		if row_rect(index - first).has_point(point) and index != game.history_selected:
			game.history_selected = index
			game.sound.play("ui")
			return false
	return false

static func draw_row(game, box: Rect2, record: Dictionary, selected: bool) -> void:
	var view = game.View
	var edge := SEED_GOLD if selected else Color("#9d8893")
	var fill := Color("#433246") if selected else Color(INK, 0.92)
	var motion: float = game.menu_motion.press_amount(box)
	view.frame(game, box, fill.lightened(motion * 0.14), edge)
	view.text(game, box.position + Vector2(14, 18), heroine_name(game, record), 16, view.CREAM, true)
	view.text(game, box.position + Vector2(14, 34), progress(game, record), 11, view.DIM)
	var stamp := Rect2(box.position + Vector2(238, 7), Vector2(125, 29))
	view.centered(game, stamp, game.preferences.text(outcome_key(record)), 13, outcome_tint(record), true)

static func draw_details(game, record: Dictionary) -> void:
	var view = game.View
	var preferences = game.preferences
	var border := outcome_tint(record)
	view.frame(game, DETAILS, Color(INK, 0.95), border)
	view.text(game, Vector2(456, 112), heroine_name(game, record), 26, view.CREAM, true)
	view.text(game, Vector2(456, 135), preferences.text(outcome_key(record)), 16, border, true)
	var room := str(record.get("room_title", ""))
	var biome := int(record.get("biome", -1))
	if biome >= 0 and biome < game.BIOMES.size():
		view.text(game, Vector2(456, 159), preferences.place_name(game.BIOMES[biome]), 13, view.CREAM)
	if not room.is_empty():
		view.text(game, Vector2(456, 179), preferences.place_name(room), 12, view.DIM)
	view.text(game, Vector2(456, 201), progress(game, record), 12, view.CREAM)
	var time := int(record.get("finished_at", 0))
	if time > 0:
		view.text(game, Vector2(456, 222), Time.get_date_string_from_unix_time(time), 12, view.DIM)
	var hero := int(record.get("hero", -1))
	if hero >= 0 and hero < game.NAMES.size():
		var feet := Vector2(740, 229)
		Art.shadow(game, feet, 34.0)
		Art.heroine(game, hero, feet, 106.0, game.visual_clock)
	game.draw_line(Vector2(458, 242), Vector2(798, 242), Color(border, 0.45), 1.0)
	var seeds := int(record.get("seeds_earned", 0))
	var bank_key := "history.bank.one" if seeds == 1 else "history.bank.other"
	view.text(game, Vector2(456, 266), preferences.text(bank_key, {"amount": seeds}), 16, SEED_GOLD, true)
	var relics: Variant = record.get("relics", [])
	var count: int = relics.size() if relics is Array else 0
	var petals := int(record.get("petals", 0))
	var carried_key := "history.carried.one" if count == 1 else "history.carried.other"
	var carried: String = preferences.text(carried_key, {"petals": petals, "relics": count})
	view.text(game, Vector2(456, 285), carried, 12, view.DIM)
	if record.get("reached_endless", false):
		var mode_name: String = preferences.place_name(game.BIOMES.back())
		view.text(game, Vector2(456, 303), preferences.text("history.endless", {"garden": mode_name}), 11, view.CREAM)

static func heroine_name(game, record: Dictionary) -> String:
	var hero := int(record.get("hero", -1))
	var fallback: String = game.NAMES[hero] if hero >= 0 and hero < game.NAMES.size() else game.preferences.text("history.unknown_heroine")
	return str(record.get("hero_name", fallback))

static func outcome_key(record: Dictionary) -> String:
	match record.get("result", ""):
		"clear": return "history.clear"
		"defeat": return "history.defeat"
		_: return "history.ended"

static func outcome_tint(record: Dictionary) -> Color:
	match record.get("result", ""):
		"clear": return SEED_GOLD
		"defeat": return Color("#d7a6bc")
		_: return Color("#c4b8da")

static func progress(game, record: Dictionary) -> String:
	var depth := int(record.get("depth", -1))
	var elapsed := maxi(0, int(record.get("elapsed_seconds", 0)))
	var duration := "%d:%02d" % [floori(elapsed / 60.0), elapsed % 60]
	return game.preferences.text("history.progress", {"room": depth + 1, "duration": duration}) if depth >= 0 else duration
