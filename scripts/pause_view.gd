extends RefCounted

const EvolutionArt = preload("res://scripts/evolution_art.gd")
const UpgradeArt = preload("res://scripts/upgrade_art.gd")

const SHEET = Rect2(85, 20, 694, 350)
const RESUME = Rect2(547, 310, 207, 42)
const END_RUN = Rect2(106, 310, 145, 42)
const CONFIRM_CANCEL = Rect2(217, 234, 202, 45)
const CONFIRM_END = Rect2(445, 234, 202, 45)
const RELICS_TAB := Rect2(549, 85, 91, 27)
const UPGRADES_TAB := Rect2(647, 85, 95, 27)
const PLUM = Color("#272032")
const INSET = Color("#1e1928")
const ROSE = Color("#eca6aa")

static func activate(game, point: Vector2) -> void:
	if game.confirm_end_run:
		if CONFIRM_CANCEL.has_point(point):
			game.cancel_end_run()
		elif CONFIRM_END.has_point(point):
			game.end_paused_run()
	elif RESUME.has_point(point):
		game.unpause_run()
	elif END_RUN.has_point(point):
		game.request_end_run()
	elif RELICS_TAB.has_point(point):
		game.menu_motion.pause_panel = "relics"
	elif UPGRADES_TAB.has_point(point):
		game.menu_motion.pause_panel = "upgrades"
	elif game.menu_motion.pause_panel == "upgrades":
		var entries: Array[String] = game.upgrades.entries()
		for index in range(entries.size()):
			if upgrade_row(index).has_point(point):
				game.menu_motion.pause_upgrade = entries[index]
				return

static func draw(game) -> void:
	var view = game.View
	var entrance: float = game.menu_motion.entrance_amount()
	game.draw_rect(view.CANVAS, Color(0.08, 0.055, 0.125, 0.65 - entrance * 0.12))
	view.frame(game, SHEET, PLUM)
	view.centered(game, Rect2(245, 28, 374, 39), "Run paused", 27, view.CREAM, true)
	for x in [194, 670]:
		game.draw_line(Vector2(x - 47, 49), Vector2(x + 47, 49), Color(view.BRASS, 0.54))
		view.diamond(game, Vector2(x, 49), 3.7, view.BRASS)

	draw_hero(game)
	draw_stats(game)
	draw_equipment(game)
	draw_curses(game)
	view.button(game, END_RUN, "End Run")
	view.button(game, RESUME, "Resume Run", true)
	if game.confirm_end_run:
		draw_confirmation(game)

static func draw_hero(game) -> void:
	var view = game.View
	var hero: int = game.hero
	view.frame(game, Rect2(106, 73, 182, 219), INSET, Color(game.COLORS[hero], 0.65))
	view.heroine_stage(game, Vector2(194, 221), 126.0)
	view.centered(game, Rect2(108, 231, 178, 27), game.NAMES[hero], 24, view.CREAM, true)
	view.centered(game, Rect2(108, 254, 178, 20), view.ROLE[hero], 11, view.DIM)
	var weapon_id: String = game.armory.for_hero(hero)
	game.WeaponArt.draw_icon(game, weapon_id, Vector2(126, 280), 21.0)
	view.text(game, Vector2(142, 284), game.Weapons.item(weapon_id).name, 11, view.CREAM)

static func draw_stats(game) -> void:
	var view = game.View
	var hero: int = game.hero
	var max_hp: int = game.HEALTH[hero]
	var charge: int = game.HeroUltimates.CHARGE
	view.frame(game, Rect2(305, 73, 216, 219), INSET)
	view.text(game, Vector2(321, 105), "Character stats", 20, view.CREAM, true)
	stat(game, 123, "Health", "%d / %d HP" % [game.hp, max_hp])
	var life: float = clampf(float(game.hp) / max_hp, 0.0, 1.0)
	game.draw_rect(Rect2(321, 129, 184, 4), Color("#553044"))
	game.draw_rect(Rect2(321, 129, roundf(184 * life), 4), ROSE)
	stat(game, 152, game.RESOURCES[hero], "%d / %d" % [game.resource, charge])
	for index in range(charge):
		view.diamond(game, Vector2(325 + 12 * index, 160), 3.3,
			game.COLORS[hero] if index < game.resource else Color("#5a4966"))
	var weapon: Dictionary = game.Weapons.item(game.armory.for_hero(hero))
	var basic: int = game.player_hit_amount(maxi(1, int(weapon.damage) + int(game.bonus)))
	stat(game, 186, "Basic damage", str(basic))
	stat(game, 204, "Flat damage bonus", "+%d damage" % game.bonus)
	var held: String = game.pocket.held
	if held.is_empty():
		stat(game, 222, "Attack interval", "%.2fs" % game.basic_attack_interval())
	else:
		stat(game, 222, "Pocket item", game.RunItems.ITEMS[held].name)
	game.draw_line(Vector2(321, 232), Vector2(505, 232), Color(view.BRASS, 0.55))
	var seconds := int(game.run_time)
	stat(game, 250, "Room %d" % (game.depth + 1), "%d:%02d elapsed" % [int(seconds / 60.0), seconds % 60])
	var biome: String = game.BIOMES[game.active_biome]
	if game.floor_index >= game.Dungeon.BIOME_COUNT:
		biome = game.preferences.place_name(game.BIOMES.back())
	view.text(game, Vector2(321, 266), biome, 11, view.DIM)
	view.text(game, Vector2(321, 282), game.room_title, 11, view.DIM)

static func stat(game, y: float, label: String, value: String) -> void:
	var view = game.View
	view.text(game, Vector2(321, y), label, 11, view.DIM)
	view.text(game, Vector2(321, y), value, 12, view.CREAM, false, HORIZONTAL_ALIGNMENT_RIGHT, 184.0)

static func draw_curses(game) -> void:
	var ids: Array[String] = game.curses.active
	if ids.is_empty():
		return
	var view = game.View
	view.centered(game, Rect2(260, 305, 274, 18), "Bound curses", 12, view.DIM, true)
	for index in range(ids.size()):
		var id := ids[index]
		var title: String = game.RunCurses.CATALOG[id].title
		var left := 262.0 + float(index % 3) * 91.0
		var row := 331.0 + float(floori(float(index) / 3.0)) * 14.0
		game.RunCurses.draw_icon(game, id, Vector2(left + 5, row), 5.0)
		view.text(game, Vector2(left + 12, row + 3), title, 9, view.CREAM)

static func draw_equipment(game) -> void:
	var view = game.View
	view.frame(game, Rect2(537, 73, 217, 219), INSET)
	var upgrade_tab: bool = game.menu_motion.pause_panel == "upgrades"
	view.button(game, RELICS_TAB, "Relics", not upgrade_tab)
	view.button(game, UPGRADES_TAB, "Upgrades", upgrade_tab)
	if upgrade_tab:
		draw_upgrades(game)
	else:
		draw_relics(game)

static func draw_relics(game) -> void:
	var view = game.View
	var owned: Array[String] = game.relics.owned
	if owned.is_empty():
		view.text(game, Vector2(553, 130), "No relics equipped", 12, view.DIM)
		return
	var row_height := 18.0 if owned.size() > 6 else 23.0
	for index in range(owned.size()):
		var relic_id := owned[index]
		var item: Dictionary = game.Relics.definition(relic_id)
		var center := Vector2(566, 128 + index * row_height)
		view.ring(game, center, 10.0, view.BRASS, 0.58)
		draw_relic_icon(game, center, relic_id)
		view.text(game, center + Vector2(16, 4), item.get("name", relic_id), 11, view.CREAM)
	if game.relics.rose_counter_ready(game.depth) and game.armory.for_hero(game.hero) == "royal_cleaver":
		view.diamond(game, Vector2(558, 274), 3.2, ROSE)
		view.text(game, Vector2(567, 278), "Rose Receipt primed", 11, ROSE)
	elif game.relics.iron_bouquet_active():
		view.diamond(game, Vector2(558, 274), 3.2, ROSE)
		view.text(game, Vector2(567, 278), "Iron Bouquet active", 11, ROSE)

static func upgrade_row(index: int) -> Rect2:
	return Rect2(550, 115 + index * 19, 192, 19)

static func draw_upgrades(game) -> void:
	var view = game.View
	var entries: Array[String] = game.upgrades.entries()
	if entries.is_empty():
		view.text(game, Vector2(554, 133), "No run upgrades yet", 12, view.DIM)
		return
	var selected: String = game.menu_motion.pause_upgrade
	if selected not in entries:
		selected = entries[0]
	for index in range(entries.size()):
		var id := entries[index]
		var row := upgrade_row(index)
		var card: Dictionary = game.upgrades.card(id)
		if id == selected:
			game.draw_rect(row, Color("#3f3047"))
		UpgradeArt.draw_icon(game, id, row.position + Vector2(11, 10), 16.0)
		view.text(game, row.position + Vector2(23, 14), card.name, 12, view.CREAM)
		view.text(game, row.position + Vector2(138, 14), "Rank %d" % game.upgrades.rank(id),
			10, view.DIM, false, HORIZONTAL_ALIGNMENT_RIGHT, 49.0)
	var line_y := 259.0
	var details: String = game.upgrades.active_effect(selected)
	for line: String in view.Reward.split_effect(details, 182.0, 11):
		view.centered(game, Rect2(552, line_y, 187, 13), line, 11, view.DIM)
		line_y += 13.0

static func draw_relic_icon(game, center: Vector2, relic_id: String) -> void:
	if not EvolutionArt.icon(relic_id).is_empty():
		EvolutionArt.draw_icon(game, relic_id, center, 16.0)
		return
	var gear: int = game.Prep.RELIC_IDS.find(relic_id)
	if gear >= 0:
		game.Prep.draw_gear(game, center, gear + 5, 16.0)
		return
	var reward = game.View.Reward
	if relic_id == game.Relics.HONEST_RECEIPT:
		game.draw_texture_rect_region(reward.RECEIPT_ICON, Rect2(center - Vector2(8, 8), Vector2(16, 16)), reward.RECEIPT_REGION)
		return
	var texture: Texture2D = reward.THORNMAIL_ICON if relic_id == game.Relics.THORNMAIL else reward.COUNTERCLOCK_ICON
	var source := Rect2(148, 96, 932, 1064) if relic_id == game.Relics.THORNMAIL else Rect2(200, 70, 890, 1080)
	game.draw_texture_rect_region(texture, Rect2(center - Vector2(7, 8), Vector2(14, 16)), source)

static func draw_confirmation(game) -> void:
	var view = game.View
	game.draw_rect(view.CANVAS, Color(0.075, 0.045, 0.10, 0.70))
	view.frame(game, Rect2(188, 100, 488, 198), PLUM, ROSE)
	view.centered(game, Rect2(217, 115, 430, 42), "End this run?", 28, view.CREAM, true)
	view.centered(game, Rect2(213, 168, 438, 22), "Your run items and dungeon progress will be lost.", 14)
	view.centered(game, Rect2(213, 191, 438, 21), "Any Garden Seeds earned will be recorded.", 13, view.DIM)
	view.button(game, CONFIRM_CANCEL, "Back to pause", true)
	view.button(game, CONFIRM_END, "End Run")
