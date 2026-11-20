extends RefCounted

const Registry = preload("res://scripts/relic_effects.gd")
const RelicInfo = preload("res://scripts/relic_info_view.gd")
const RelicSources = preload("res://scripts/relic_sources.gd")
const GuestRoster = preload("res://scripts/guest_roster.gd")
const Items = preload("res://scripts/run_items.gd")
const BACKDROP = preload("res://assets/art/menus/run_preparation.png")
const GEAR = preload("res://assets/art/items/preparation_gear.png")
const BACK = Rect2(51, 335, 114, 40)
const WEAPON_NEXT = Rect2(517, 79, 53, 30)
const STARTING_POCKET = Rect2(180, 335, 291, 40)
const CLEAR = Rect2(486, 335, 141, 40)
const ENTER = Rect2(642, 334, 162, 42)
const RELIC_LEDGER = Rect2(616, 13, 176, 40)
const RELIC_IDS = RelicSources.STARTERS
const GEAR_REGIONS = [
	Rect2(127, 15, 194, 413), Rect2(507, 36, 313, 383),
	Rect2(954, 41, 333, 352), Rect2(1441, 14, 270, 415),
	Rect2(67, 469, 308, 399), Rect2(497, 510, 332, 314),
	Rect2(929, 525, 351, 277), Rect2(1395, 492, 332, 355),
]
const PAPER = Color("#f5e4cd")
const ROSEWOOD = Color("#3a2937")
const PANEL = Color("#231b2a")
const GOLD_ACTIVE = Color("#f9d19a")

static func relic_rect(index: int) -> Rect2:
	return Rect2(250 + index * 138, 155, 128, 107)

static func relic_options(hero: int) -> Array:
	var result := RELIC_IDS.filter(func(id): return RelicSources.can_offer(id, hero))
	if hero > 0 and hero < RelicSources.SIGNATURES.size():
		result.append(RelicSources.SIGNATURES[hero])
	return result

static func relic_at(point: Vector2, hero := 0) -> String:
	var options := relic_options(hero)
	for index in range(options.size()):
		if relic_rect(index).has_point(point):
			return options[index]
	return ""

static func starting_items(game) -> Array[String]:
	var options: Array[String] = [""]
	for item: String in Items.IDS:
		if game.profile.has_unlock(item):
			options.append(item)
	return options

static func next_starting_item(game) -> String:
	var options := starting_items(game)
	return options[(options.find(game.selected_starting_item) + 1) % options.size()]

static func draw(game) -> void:
	var view = game.View
	game.draw_texture_rect(BACKDROP, view.CANVAS, false)
	game.draw_rect(view.CANVAS, Color(0.09, 0.055, 0.11, 0.18))
	view.petals(game, game.visual_clock)
	var banner := Rect2(305, 13, 254, 36)
	view.frame(game, banner, PANEL)
	view.centered(game, banner, "Run Preparation", 22, view.CREAM, true)
	view.button(game, RELIC_LEDGER, "Relic Ledger")

	draw_hero_panel(game)
	draw_weapon(game)
	view.text(game, Vector2(250, 145), "Choose a Starting Relic", 20, view.CREAM, true)
	for index in range(relic_options(game.hero).size()):
		draw_relic(game, index)

	var selection := Registry.definition(game.selected_relic)
	draw_selection(game, selection)

	view.button(game, BACK, "Back")
	draw_starting_pocket(game)
	if not selection.is_empty():
		view.button(game, CLEAR, "Remove Relic")
	var primary_label := "Continue Run" if FileAccess.file_exists(game.SAVE) else "Enter Dungeon"
	view.button(game, ENTER, primary_label, true)

static func draw_selection(game, selection: Dictionary) -> void:
	var view = game.View
	var box := Rect2(250, 268, 542, 59)
	view.frame(game, box, Color(PANEL, 0.94), view.BRASS if selection.is_empty() else GOLD_ACTIVE)
	if selection.is_empty():
		view.centered(game, Rect2(262, 276, 518, 19), "No starting relic selected", 16, view.CREAM, true)
		view.centered(game, Rect2(262, 298, 518, 18), "Tap a card to inspect it. Enter Dungeon confirms your loadout.", 12, view.DIM)
		return
	var id: String = game.selected_relic
	RelicInfo.draw_icon(game, id, Vector2(278, 297), 31.0)
	view.text(game, Vector2(302, 284), "Selected  ·  " + str(selection.name), 15, GOLD_ACTIVE, true)
	var lines: Array[String] = game.CodexView.wrap_text(selection.detail, ThemeDB.fallback_font, 465.0, 11)
	for index in range(lines.size()):
		view.text(game, Vector2(302, 298 + index * 12), lines[index], 11, view.CREAM)
	var combination := RelicInfo.pairing(game, id, true)
	var tip := "A signature relic applies only to its heroine." if combination.is_empty() else combination
	view.text(game, Vector2(302, 321), tip, 10, view.DIM)

static func draw_starting_pocket(game) -> void:
	var view = game.View
	var options := starting_items(game)
	if options.size() == 1:
		view.frame(game, STARTING_POCKET, Color(PANEL, 0.93))
		view.centered(game, STARTING_POCKET, "Unlock starting items in the Seed Shop", 12, view.DIM)
		return
	var item: String = game.selected_starting_item if game.selected_starting_item in options else ""
	var option: Dictionary = Items.ITEMS.get(item, {})
	var name: String = option.get("name", "Empty")
	var motion: float = game.menu_motion.press_amount(STARTING_POCKET)
	view.frame(game, STARTING_POCKET, PANEL.lightened(motion * 0.13), GOLD_ACTIVE if not item.is_empty() else view.BRASS)
	if not item.is_empty():
		Items.draw_icon(game, item, STARTING_POCKET.position + Vector2(24, 20), 25.0, Color.WHITE)
	view.centered(game, Rect2(213, 338, 220, 18), "Starting Pocket · " + name, 15, view.CREAM, true)
	var effect: String = "Tap to choose an unlocked item" if item.is_empty() else Items.effect_for(item, game.hero)
	view.centered(game, Rect2(213, 357, 220, 13), effect, 10, view.DIM)
	view.centered(game, Rect2(435, 339, 30, 32), "›", 22, view.CREAM, true)

static func draw_hero_panel(game) -> void:
	var view = game.View
	var hero: int = game.hero
	var card := Rect2(51, 62, 177, 262)
	view.frame(game, card, Color(PANEL, 0.85))
	view.centered(game, Rect2(55, 70, 169, 35), game.NAMES[hero], 24, view.CREAM, true)
	view.heroine_stage(game, Vector2(139, 258), 149.0)
	var role: String = "The Wolfbound Gunner" if hero == GuestRoster.LUNA else view.ROLE[hero]
	view.centered(game, Rect2(57, 274, 165, 21), role, 11, view.DIM)
	view.centered(game, Rect2(57, 295, 165, 17), "%d HP  ·  %s" % [game.HEALTH[hero], game.RESOURCES[hero]], 12, view.CREAM)

static func draw_weapon(game) -> void:
	var view = game.View
	var hero: int = game.hero
	var weapon_id: String = game.prepared_weapon()
	var weapon: Dictionary = game.Weapons.item(weapon_id)
	var case_rect := Rect2(250, 62, 542, 64)
	view.frame(game, case_rect, Color(PANEL, 0.91))
	game.draw_circle(Vector2(287, 94), 24.0, Color("#573a45"), true, -1.0, true)
	game.draw_arc(Vector2(287, 94), 23.0, 0, TAU, 42, view.BRASS, 1.0, true)
	game.WeaponArt.draw_icon(game, weapon_id, Vector2(287, 94), 43.0)
	view.text(game, Vector2(325, 88), "Starting Weapon", 12, view.DIM)
	view.text(game, Vector2(325, 110), weapon.name, 19, view.CREAM, true)
	if game.starting_weapon_options().size() > 1:
		view.button(game, WEAPON_NEXT, "Swap")
	for index in range(2):
		var ultimate := index == 1
		var location := Vector2(595.0, 81.0 + index * 25.0)
		var title: String = game.HeroUltimates.NAMES[hero] if ultimate else view.CLASS_SKILLS[hero]
		view.ability_icon(game, hero, ultimate, location, 24.0)
		view.text(game, location + Vector2(17.0, 4.0), title, 12, game.COLORS[hero])

static func draw_relic(game, index: int) -> void:
	var view = game.View
	var relic_id: String = relic_options(game.hero)[index]
	var item := Registry.definition(relic_id)
	var rare: bool = item.rarity == "rare"
	var selected: bool = game.selected_relic == relic_id
	var box := relic_rect(index)
	var motion = game.get("menu_motion")
	var hover: float = motion.hover_amount(box, game.get_local_mouse_position()) if motion else 0.0
	var flare: float = motion.selection_amount(motion.relic_age) if selected and motion else 0.0
	var edge: Color = GOLD_ACTIVE if selected else view.BRASS
	var fill := Color("#fff0d9") if selected else PAPER
	if selected:
		var halo := Color(GOLD_ACTIVE, 0.43 + 0.13 * flare + 0.08 * sin(float(game.visual_clock) * 3.2))
		game.draw_rect(box.grow(2.0 + flare * 2.5), halo, false, 2.0)
	view.frame(game, box, fill.lightened(hover * 0.10), edge)
	var rarity_box := Rect2(box.position + Vector2(6, 6), Vector2(116, 18))
	var rarity_color := Color("#425b7b") if rare else Color("#496b52")
	game.draw_rect(rarity_box, rarity_color)
	var rarity_point := rarity_box.position + Vector2(12.0, 9.0)
	if rare:
		game.draw_colored_polygon(PackedVector2Array([rarity_point + Vector2.UP * 4.0,
			rarity_point + Vector2(3.5, 3.0), rarity_point + Vector2(-3.5, 3.0)]), PAPER)
	else:
		game.draw_colored_polygon(PackedVector2Array([rarity_point + Vector2(-4.0, 2.0),
			rarity_point + Vector2(-1.0, -2.0), rarity_point + Vector2(4.0, -4.0),
			rarity_point + Vector2(1.0, 2.0)]), PAPER)
	var rarity := "RARE" if rare else "UNCOMMON"
	var caption := "SELECTED · " + rarity if selected else rarity
	view.centered(game, Rect2(rarity_box.position + Vector2(10, 0), rarity_box.size - Vector2(10, 0)), caption, 10, PAPER)

	var center := box.position + Vector2(64, 44)
	game.draw_circle(center, 17.0, Color("#ead0ac"), true, -1.0, true)
	var lift := 2.0 * hover + 4.0 * flare
	RelicInfo.draw_icon(game, relic_id, center - Vector2(0.0, lift), 34.0 + 2.5 * flare)
	view.centered(game, Rect2(box.position + Vector2(2, 63), Vector2(124, 16)), item.name, 12, ROSEWOOD, true)
	view.centered(game, Rect2(box.position + Vector2(2, 79), Vector2(124, 14)), RelicInfo.highlight(relic_id, 0), 9, ROSEWOOD)
	view.centered(game, Rect2(box.position + Vector2(2, 92), Vector2(124, 12)), RelicInfo.highlight(relic_id, 1), 9, Color("#71515b"))
	if selected:
		view.diamond(game, box.position + Vector2(116, 37), 4.0, Color("#b37742"))

static func draw_gear(canvas: Node2D, center: Vector2, index: int, diameter: float) -> void:
	var source: Rect2 = GEAR_REGIONS[index]
	var size := source.size * (diameter / maxf(source.size.x, source.size.y))
	canvas.draw_texture_rect_region(GEAR, Rect2(center - size / 2.0, size), source)
