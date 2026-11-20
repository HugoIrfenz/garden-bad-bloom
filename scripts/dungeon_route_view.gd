extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const ShopView = preload("res://scripts/merchant_view.gd")
const ArcadeCatalog = preload("res://scripts/arcade_catalog.gd")
const CHOICE_BACKDROPS = preload("res://assets/art/menus/room_choices.png")
const ENCOUNTER_PROPS = preload("res://assets/art/menus/encounter_props.png")
const FORGOTTEN_EVENT_ART = preload("res://assets/art/menus/forgotten_events.png")
const FUNGAL_EVENT_ART = preload("res://assets/art/items/fungal_event_icons.png")
const FUNGAL_PROP_REGIONS = {
	"cap_inspection": Rect2(120, 205, 645, 505),
	"moldy_crown": Rect2(1010, 212, 630, 455),
}
const CLOCKWORK_EVENT_ART = preload("res://assets/art/menus/clockwork_events.png")
const BLOODBLOOM_EVENT_ART = preload("res://assets/art/menus/bloodbloom_events.png")
const FORGOTTEN_PROP_REGIONS = {
	"empty_watering_can": Rect2(60, 78, 605, 553),
	"sleeping_root": Rect2(762, 134, 621, 504),
	"fountain_should_have_known": Rect2(1501, 24, 613, 649),
}
const CLOCKWORK_PROP_REGIONS = {
	"clock_repair": Rect2(61, 53, 629, 618),
	"wrong_bell": Rect2(798, 36, 574, 633),
	"copper_choir_audition": Rect2(1493, 81, 619, 602),
}
const BLOODBLOOM_PROP_REGIONS = {
	"weeping_flower": Rect2(61, 32, 419, 431),
	"quiet_fox": Rect2(524, 112, 461, 328),
	"leech_doctor": Rect2(1024, 60, 465, 408),
	"mourning_picnic": Rect2(59, 531, 448, 434),
	"ashen_lantern": Rect2(634, 515, 283, 456),
	"widows_thread": Rect2(1030, 540, 481, 441),
}
const PROP_REGIONS = [
	Rect2(260, 7, 267, 222), Rect2(950, 51, 271, 162), Rect2(1701, 8, 200, 220),
	Rect2(179, 270, 361, 202), Rect2(918, 235, 296, 244), Rect2(1646, 239, 302, 232),
	Rect2(189, 487, 392, 232), Rect2(886, 485, 377, 228), Rect2(1618, 485, 361, 226),
]
const ROOM_PROPS = {"rest": 6, "shop": 7, "curse": 8}
const BACKDROP_CELLS = {
	"shop": Vector2(0, 0),
	"rest": Vector2(1, 0),
	"event": Vector2(0, 1),
	"curse": Vector2(1, 1),
}

const OPTIONS_PANEL = Rect2(245, 72, 374, 250)
const FIRST_ACTION = Rect2(279, 179, 306, 35)
const SECOND_ACTION = Rect2(279, 224, 306, 35)
const LEAVE_ACTION = Rect2(279, 269, 306, 35)
const FORGE_ACTION = Rect2(279, 314, 306, 35)
const INTERACTION_RANGE = 66.0
const EXIT_COLORS = [Color("#f6d59d"), Color("#a6dce0")]
const BOARD_INK = Color("#2b2032")
const BOARD_GOLD = Color("#f2c88e")
const KIND_LABELS = {
	"transition": "Passage", "combat": "Combat", "elite": "Elite", "treasure": "Treasure",
	"shop": "Merchant", "event": "Encounter", "rest": "Rest", "curse": "Curse altar",
	"challenge": "Timed hunt", "secret": "Unmarked passage", "boss": "Chapter boss",
}

static func draw_world_ui(game) -> void:
	if game.floor_index < 0:
		return

	var view = game.View
	if game.room_complete:
		var exit_ids: Array = game.room_exits.keys()
		for index in range(exit_ids.size()):
			var exit_id: String = exit_ids[index]
			var point: Vector2 = game.room_exits[exit_id]
			var area := exit_label(point)
			var label = "Next chapter"
			var mode_name := ""
			var arcade_gate := ""
			if game.floor_manifest.nodes.has(exit_id):
				var node: Dictionary = game.floor_manifest.nodes[exit_id]
				label = KIND_LABELS[node.kind]
				match int(node.get("optional_stage", -1)):
					0: label = "Optional boss route"
					1: label = "Continue detour"
					2: label = "Enter hidden arena"
				if int(game.floor_manifest.nodes[game.room_id].branch) == 1 and int(node.branch) == 0:
					label = "Rejoin main route"
				arcade_gate = ArcadeCatalog.id_for_node(node)
			elif game.floor_manifest.endless:
				label = game.preferences.text("endless.next_floor")
				mode_name = game.preferences.place_name(game.BIOMES.back())
			var near: bool = game.player.distance_to(point) < INTERACTION_RANGE
			var tint: Color = EXIT_COLORS[index]
			var gate := PackedVector2Array([point + Vector2(-23, 1), point + Vector2(-23, -10),
				point + Vector2(-15, -19), point + Vector2(15, -19), point + Vector2(23, -10), point + Vector2(23, 1)])
			game.draw_colored_polygon(gate, Color(0.13, 0.10, 0.18, 0.82))
			game.draw_polyline(gate, tint, 1.5, true)
			game.draw_line(point + Vector2(-23, 1), point + Vector2(23, 1), Color(tint, 0.5), 1.0, true)
			var arrow := point + Vector2(0, roundf(-6.0 + sin(game.visual_clock * 5.8) * 2.0))
			game.draw_colored_polygon(PackedVector2Array([arrow + Vector2(0, -9),
				arrow + Vector2(7, -2), arrow + Vector2(3, -2), arrow + Vector2(3, 4),
				arrow + Vector2(-3, 4), arrow + Vector2(-3, -2), arrow + Vector2(-7, -2)]), tint)
			view.frame(game, area, Color("#362a3d") if near else Color("#211c2e"), tint)
			if not arcade_gate.is_empty():
				var hint := "three_caps.board_game" if arcade_gate == ArcadeCatalog.BOARD else "arcade.map_hint"
				draw_arcade_label(game, area, arcade_gate, hint)
				continue
			view.diamond(game, area.position + Vector2(11, 12), 3.0, tint)
			var label_area := Rect2(area.position + Vector2(10, 0), area.size - Vector2(10, 0))
			if mode_name.is_empty():
				view.centered(game, label_area, label, 11, tint)
			else:
				label_area.size.y = 12.0
				view.centered(game, label_area, mode_name, 11, tint, true)
				label_area.position.y += 11.0
				view.centered(game, label_area, label, 9, tint)
		return

	if game.uses_room_choice() and game.screen == "fight":
		var point: Vector2 = game.chest_position
		var near: bool = game.player.distance_to(point) < INTERACTION_RANGE
		var arcade_id := ""
		if game.room_kind == "event":
			arcade_id = ArcadeCatalog.id_for_event(game.RoomEvents.card_for(game).id)
		if not arcade_id.is_empty():
			var marker := Rect2(point + Vector2(-67, -68), Vector2(134, 24))
			view.frame(game, marker, Color("#392b43") if near else BOARD_INK, BOARD_GOLD)
			var hint := "arcade.approach"
			if near:
				hint = "arcade.tap" if OS.has_feature("mobile") else "arcade.open"
			draw_arcade_label(game, marker, arcade_id, hint)
		elif near:
			var marker := Rect2(point + Vector2(-53, -68), Vector2(106, 20))
			view.frame(game, marker, Color("#211c2e"))
			view.centered(game, marker, KIND_LABELS[game.room_kind], 11)
		if near:
			view.diamond(game, point + Vector2(0, roundf(-41 + sin(game.visual_clock * 5.0) * 2)), 3.0, view.CREAM)
	if game.room_kind == "challenge" and not game.foes.is_empty():
		var elapsed_text = "%.1fs" % maxf(0.0, game.HUNT_TIME - game.room_clock)
		var hunt = Rect2(38, 58, 136, 26)
		view.frame(game, hunt, Color(0.16, 0.12, 0.20, 0.92))
		view.centered(game, hunt, "Timed bonus  " + elapsed_text, 12)

static func exit_label(point: Vector2) -> Rect2:
	return Rect2(point + Vector2(-66, -45), Vector2(132, 24))

static func draw_arcade_label(game, area: Rect2, arcade_id: String, hint_key: String) -> void:
	draw_arcade_icon(game, arcade_id, area.position + Vector2(13, 12), 12, BOARD_GOLD)
	var line := Rect2(area.position + Vector2(22, 0), Vector2(area.size.x - 26, 12))
	var title := ArcadeCatalog.label(arcade_id, "short", game.preferences.language)
	game.View.centered(game, line, title, 11, game.View.CREAM, true)
	line.position.y += 11.0
	game.View.centered(game, line, game.preferences.text(hint_key), 9, BOARD_GOLD)

static func draw_arcade_icon(game, arcade_id: String, point: Vector2, size: int, tint: Color) -> void:
	if arcade_id == ArcadeCatalog.BOARD:
		draw_board_icon(game, point, size, tint)
		return
	var frame := Rect2(point - Vector2.ONE * size * 0.5, Vector2.ONE * size)
	game.draw_rect(frame.grow(1), BOARD_INK)
	game.draw_rect(frame.grow(1), tint, false, 1.0)
	game.ArcadeView.draw_icon(game, arcade_id, point, size)

static func draw_board_icon(canvas: Node2D, point: Vector2, size: int, tint: Color) -> void:
	var side := float(size)
	var origin := (point - Vector2.ONE * (side * 0.5)).round()
	var box := Rect2(origin, Vector2.ONE * side)
	canvas.draw_rect(box.grow(1), BOARD_INK)
	canvas.draw_rect(box, tint, false, 1.0)
	var cell := side / 3.0
	for index in range(1, 3):
		var offset := cell * index
		canvas.draw_line(origin + Vector2(offset, 0), origin + Vector2(offset, side), tint, 1.0)
		canvas.draw_line(origin + Vector2(0, offset), origin + Vector2(side, offset), tint, 1.0)
	var mark_size := 1.0 if size == 9 else 2.0
	for index in range(3):
		var mark := origin + Vector2.ONE * floorf(cell * (index + 0.5) - mark_size * 0.5)
		canvas.draw_rect(Rect2(mark, Vector2.ONE * mark_size), tint)

static func map_layout(manifest: Dictionary) -> Dictionary:
	var positions := {}
	var extent := maxi(1, int(manifest.nodes[manifest.boss_id].layer))
	for node: Dictionary in manifest.nodes.values():
		positions[node.id] = Vector2(635.0 + roundf(float(node.layer) * 124.0 / extent),
			31.0 if node.branch == 0 else 19.0)
	return positions

static func draw_minimap(game) -> void:
	var view = game.View
	view.text(game, Vector2(576, 16), "Room %d" % (game.depth + 1), 11)
	if game.floor_index < 0 or not game.floor_manifest.nodes.has(game.room_id):
		return
	var manifest: Dictionary = game.floor_manifest
	var points := map_layout(manifest)
	var visited: Array[String] = game.route_history
	var edges: Array = game.room_exits.keys()
	for node: Dictionary in manifest.nodes.values():
		for dest: String in node.exits:
			var available: bool = node.id == game.room_id and game.room_complete and edges.has(dest)
			var used: bool = node.id in visited and dest in visited and visited.find(dest) == visited.find(node.id) + 1
			var tint := Color("#66576e")
			if available:
				tint = EXIT_COLORS[edges.find(dest)]
			elif used:
				tint = Color("#9dac92")
			game.draw_line(points[node.id], points[dest], tint, 2.0 if available else 1.0, true)
	for node: Dictionary in manifest.nodes.values():
		var selected: bool = node.id == game.room_id
		var next := edges.find(node.id)
		var tint := Color("#8d7891")
		if selected:
			tint = view.CREAM
		elif next >= 0 and game.room_complete:
			tint = EXIT_COLORS[next]
		elif node.id in visited:
			tint = Color("#aabd9f")
		var point: Vector2 = points[node.id]
		var arcade_id := ArcadeCatalog.id_for_node(node)
		if not arcade_id.is_empty():
			draw_arcade_icon(game, arcade_id, point, 9, view.CREAM if selected else BOARD_GOLD)
			continue
		view.diamond(game, point, 6.5 if selected else 4.0, view.INK)
		view.diamond(game, point, 4.6 if selected else (3.6 if node.kind == "boss" else 2.6), tint)

static func prop_for(game) -> Dictionary:
	var index := mini(int(game.active_biome), 5) if game.room_kind == "event" else int(ROOM_PROPS[game.room_kind])
	var region: Rect2 = PROP_REGIONS[index]
	var atlas: Texture2D = ENCOUNTER_PROPS
	if game.room_kind == "event":
		var card_id: String = game.RoomEvents.card_for(game).id
		var arcade_id := ArcadeCatalog.id_for_event(card_id)
		if not arcade_id.is_empty():
			return {"atlas": game.ArcadeView.ICONS, "region": game.ArcadeView.icon_region(arcade_id)}
		if FORGOTTEN_PROP_REGIONS.has(card_id):
			region = FORGOTTEN_PROP_REGIONS[card_id]
			atlas = FORGOTTEN_EVENT_ART
		elif FUNGAL_PROP_REGIONS.has(card_id):
			region = FUNGAL_PROP_REGIONS[card_id]
			atlas = FUNGAL_EVENT_ART
		elif CLOCKWORK_PROP_REGIONS.has(card_id):
			region = CLOCKWORK_PROP_REGIONS[card_id]
			atlas = CLOCKWORK_EVENT_ART
		elif BLOODBLOOM_PROP_REGIONS.has(card_id):
			region = BLOODBLOOM_PROP_REGIONS[card_id]
			atlas = BLOODBLOOM_EVENT_ART
	return {"atlas": atlas, "region": region}

static func draw_interaction_prop(game) -> void:
	var prop := prop_for(game)
	var feet: Vector2 = game.chest_position + Vector2(0, 10)
	var region: Rect2 = prop.region
	var height := minf(53.0, 65.0 * region.size.y / region.size.x)
	var canvas: Node2D = game.world_canvas
	var tint := Color("#e3abf3") if game.room_kind == "curse" else Color("#eddab0")
	Art.shadow(canvas, feet, 27.0)
	Art.paint_actor(canvas, prop.atlas, region, feet, height, 0.0, Vector2.ONE, Color.WHITE)
	for index in range(3):
		var age := fposmod(game.visual_clock * 0.62 + index * 0.33, 1.0)
		var point := feet + Vector2(roundf(sin(game.visual_clock * 1.6 + index * 2.0) * 16.0),
			roundf(-height * 0.65 - age * 21.0))
		game.View.diamond(canvas, point, 1.4, Color(tint, sin(PI * age) * 0.78))

static func draw_choice(game) -> void:
	if game.screen != "room_choice":
		return
	var view = game.View
	var cell_size = (CHOICE_BACKDROPS.get_size() * 0.5).floor()
	var cell_origin = BACKDROP_CELLS.get(game.room_kind, Vector2.ZERO) * cell_size
	game.draw_texture_rect_region(CHOICE_BACKDROPS, view.CANVAS, Rect2(cell_origin, cell_size))
	view.petals(game, game.visual_clock)
	game.draw_rect(view.CANVAS, Color(0.09, 0.06, 0.12, 0.18))
	draw_choice_vignette(game)
	if game.room_kind == "shop":
		ShopView.draw(game)
		return
	var can_inspect_forge: bool = game.room_kind == "rest" and not game.WeaponEvolutions.recipe_for(game.hero).is_empty()
	var panel := OPTIONS_PANEL
	if can_inspect_forge:
		panel.size.y += 44.0
	view.frame(game, panel, Color(0.17, 0.12, 0.20, 0.94))
	if game.room_kind == "event":
		draw_event(game)
		return
	view.centered(game, Rect2(258, 85, 348, 42), game.room_title, 23, view.CREAM, true)
	var header = Rect2(265, 131, 334, 34)
	match game.room_kind:
		"rest":
			view.centered(game, header, "Rest by the roots or hone your weapon.", 14, view.DIM)
			var heal: int = game.healing_amount(game.RunEconomy.CAMP_HEAL, "rest")
			var unavailable: String = game.curses.healing_block("rest")
			if unavailable.is_empty():
				unavailable = "Health is full" if game.hp >= game.HEALTH[game.hero] else "Cannot heal right now"
			draw_action(game, FIRST_ACTION, "Rest here  ·  Restore %d HP" % heal if heal > 0 else unavailable, heal > 0)
			draw_action(game, SECOND_ACTION, "Hone weapon  ·  +1 damage for this run", true)
		"curse":
			draw_curse_bargains(game, header)
	view.button(game, LEAVE_ACTION, "Continue onward")
	if can_inspect_forge:
		view.button(game, FORGE_ACTION, "Inspect weapon evolution")

static func draw_curse_bargains(game, header: Rect2) -> void:
	var view = game.View
	var offers: Array[Dictionary] = game.curses.offers(game)
	var caption := "Every vow lasts for this run." if not offers.is_empty() else "No unbound bargains remain."
	view.centered(game, header, caption, 14, view.DIM)
	for index in range(offers.size()):
		var offer := offers[index]
		var area := FIRST_ACTION if index == 0 else SECOND_ACTION
		var filled: bool = offer.blocked.is_empty()
		var ink: Color = view.CREAM if filled else view.DIM
		var accent: Color = offer.tint if filled else Color("#786a7b")
		var fill := Color("#3d294b") if area.has_point(game.get_local_mouse_position()) and filled else Color("#2b2134")
		view.frame(game, area, fill, accent)
		game.RunCurses.draw_icon(game, offer.id, area.position + Vector2(19, 17), 11.0)
		var row := Rect2(area.position + Vector2(35, 0), area.size - Vector2(41, 0))
		view.centered(game, Rect2(row.position, Vector2(row.size.x, 18)), offer.title, 14, ink, true)
		view.centered(game, Rect2(row.position + Vector2(0, 17), Vector2(row.size.x, 15)),
			offer.detail if filled else offer.blocked, 10, accent)

static func draw_choice_vignette(game) -> void:
	var pace = clampf(game.menu_motion.screen_age / 0.46, 0.0, 1.0)
	var arrive = 1.0 - pow(1.0 - pace, 3.0)
	var hero_feet = Vector2(roundf(lerpf(98, 150, arrive)), 315)
	var prop_feet = Vector2(roundf(lerpf(764, 724, arrive)), 305)
	var prop := prop_for(game)
	var region: Rect2 = prop.region
	var prop_art: Texture2D = prop.atlas
	var prop_height = minf(129.0, 169.0 * region.size.y / region.size.x)
	var prop_tint = Color(1, 1, 1, minf(1.0, arrive * 1.25))
	var idle = sin(game.visual_clock * 2.4) * 0.016
	Art.shadow(game, hero_feet, 47.0)
	Art.heroine(game, game.hero, hero_feet, 160.0, game.visual_clock,
		Vector2.RIGHT * (1.0 - arrive) * 38.0, 0.0, prop_tint)
	Art.shadow(game, prop_feet, 56)
	Art.paint_actor(game, prop_art, region, prop_feet, prop_height, 0.0,
		Vector2(1.0, 1.0 + idle), prop_tint)
	for mote in range(5):
		var ages = fposmod(game.visual_clock * 0.48 + float(mote) / 5.0, 1.0)
		var point = prop_feet + Vector2(sin(game.visual_clock + mote * 1.7) * 64, -22 - ages * 125)
		game.View.diamond(game, point.round(), 2.0, Color(1.0, 0.83, 0.6, sin(ages * PI) * arrive * 0.62))

static func event_choice_at(point: Vector2) -> int:
	if FIRST_ACTION.has_point(point):
		return 0
	if SECOND_ACTION.has_point(point):
		return 1
	return -1

static func draw_event(game) -> void:
	var view = game.View
	var card: Dictionary = game.RoomEvents.card_for(game)
	var arcade_id := ArcadeCatalog.id_for_event(card.id)
	var is_game := not arcade_id.is_empty()
	var three_caps := arcade_id == ArcadeCatalog.BOARD
	var text = game.preferences
	var title: String = ArcadeCatalog.label(arcade_id, "title", text.language) if is_game else card.title
	var prompt: String = ArcadeCatalog.label(arcade_id, "prompt", text.language) if is_game else card.prompt
	view.centered(game, Rect2(258, 85, 348, 42), title, 23, view.CREAM, true)
	var row_y = 132.0
	for line in wrap_event_prompt(prompt, 310.0):
		view.centered(game, Rect2(273, row_y, 318, 16), line, 13, view.DIM)
		row_y += 17.0
	for index in range(card.actions.size()):
		var area = FIRST_ACTION if index == 0 else SECOND_ACTION
		var effect: Dictionary = game.RoomEvents.preview(game, index)
		var available = bool(effect.available)
		var ink = view.INK if available else Color("#d4bdbf")
		if available:
			var focus: bool = area.has_point(game.get_local_mouse_position())
			var paper = Color("#fff4db") if focus else view.CREAM
			view.frame(game, area, paper)
		else:
			view.frame(game, area, Color("#282230"), Color("#786b73"))
		var action: String = text.text("three_caps.play") if three_caps else effect.title
		var detail: String = effect.summary if available else effect.reason
		if is_game:
			var stake: int = int(game.petals) - int(effect.petals)
			if three_caps:
				detail = text.text("three_caps.stake" if available else "three_caps.requires_stake", {"amount": stake})
			else:
				action = text.text("arcade.play")
				detail = text.text("arcade.stake" if available else "three_caps.requires_stake", {"amount": stake})
		view.centered(game, Rect2(area.position + Vector2(2, 1), Vector2(area.size.x - 4, 17)),
			action, 14, ink, true)
		view.centered(game, Rect2(area.position + Vector2(2, 18), Vector2(area.size.x - 4, 14)),
			detail, 11, ink)
	if is_game and not three_caps:
		var prize: String = ArcadeCatalog.prize(game, arcade_id)
		view.centered(game, Rect2(265, 224, 334, 32), text.text("arcade.win_prize", {"prize": prize}), 13, view.CREAM)
	var leave: String = card.leave
	if is_game:
		leave = text.text("three_caps.pass" if three_caps else "common.back")
	view.button(game, LEAVE_ACTION, leave)

static func wrap_event_prompt(prompt: String, width: float) -> Array[String]:
	var lines: Array[String] = []
	var line := ""
	for word in prompt.split(" ", false):
		var candidate := word if line.is_empty() else line + " " + word
		if not line.is_empty() and ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x > width:
			lines.append(line)
			line = word
		else:
			line = candidate
	if not line.is_empty():
		lines.append(line)
	return lines

static func draw_action(game, area: Rect2, label: String, available: bool) -> void:
	if available:
		game.View.frame(game, area, game.View.CREAM)
		game.View.centered(game, area, label, 14, game.View.INK, true)
	else:
		game.View.frame(game, area, Color("#282230"), Color("#786b73"))
		game.View.centered(game, area, label, 14, Color("#b1a0a4"))
