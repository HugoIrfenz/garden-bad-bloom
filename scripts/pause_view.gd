extends RefCounted

const RelicInfo = preload("res://scripts/relic_info_view.gd")
const UpgradeArt = preload("res://scripts/upgrade_art.gd")
const GuestRoster = preload("res://scripts/guest_roster.gd")

const SHEET = Rect2(85, 20, 694, 350)
const HERO_CARD := Rect2(106, 73, 182, 219)
const STATS_CARD := Rect2(305, 73, 216, 219)
const RESUME = Rect2(547, 310, 207, 42)
const END_RUN = Rect2(106, 310, 145, 42)
const CONFIRM_CANCEL = Rect2(217, 234, 202, 45)
const CONFIRM_END = Rect2(445, 234, 202, 45)
const RELICS_TAB := Rect2(549, 85, 56, 27)
const UPGRADES_TAB := Rect2(610, 85, 63, 27)
const ABILITIES_TAB := Rect2(678, 85, 64, 27)
const RELICS_PREV := Rect2(549, 249, 47, 23)
const RELICS_NEXT := Rect2(695, 249, 47, 23)
const RELIC_ROWS := 7
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
	elif ABILITIES_TAB.has_point(point):
		game.menu_motion.pause_panel = "abilities"
	elif game.menu_motion.pause_panel == "upgrades":
		var entries: Array[String] = game.upgrades.entries()
		for index in range(entries.size()):
			if upgrade_row(index).has_point(point):
				game.menu_motion.pause_upgrade = entries[index]
				return
	elif game.menu_motion.pause_panel == "relics" and (RELICS_PREV.has_point(point) or RELICS_NEXT.has_point(point)):
		var last := relic_last_page(game)
		var page := clampi(game.menu_motion.pause_relic_page, 0, last)
		var next := clampi(page + (-1 if RELICS_PREV.has_point(point) else 1), 0, last)
		if next != page:
			game.menu_motion.pause_relic_page = next
			game.sound.play("ui")

static func draw(game) -> void:
	var view = game.View
	var entrance: float = game.menu_motion.entrance_amount()
	game.draw_rect(view.CANVAS, Color(0.08, 0.055, 0.125, 0.65 - entrance * 0.12))
	view.frame(game, SHEET, PLUM)
	game.draw_rect(Rect2(104, 29, 652, 36), Color("#322638"))
	view.centered(game, Rect2(245, 28, 374, 39), "Run paused", 27, view.CREAM, true)
	for x in [194, 670]:
		game.draw_line(Vector2(x - 47, 49), Vector2(x + 47, 49), Color(view.BRASS, 0.54))
		view.diamond(game, Vector2(x, 49), 3.7, view.BRASS)
	view.sprig(game, Vector2(250, 49), Vector2(1, 0), Color(view.BRASS, 0.72))
	view.sprig(game, Vector2(614, 49), Vector2(-1, 0), Color(view.BRASS, 0.72))
	game.draw_line(Vector2(106, 300), Vector2(754, 300), Color(view.BRASS, 0.38), 1.0)

	draw_hero(game)
	draw_stats(game)
	draw_equipment(game)
	draw_curses(game)
	view.button(game, END_RUN, "End Run")
	view.button(game, RESUME, "Resume Run", true)
	if game.confirm_end_run:
		draw_confirmation(game)
	else:
		var inspected: int = game.inspected_ability()
		if inspected >= 0:
			view.draw_ability_inspection(game, game.hero, inspected, Vector2(237, 58))

static func draw_hero(game) -> void:
	var view = game.View
	var hero: int = game.hero
	var tint: Color = game.COLORS[hero]
	var luna := hero == GuestRoster.LUNA
	var wolf: bool = luna and game.luna_combat.in_wolf()
	view.frame(game, HERO_CARD, INSET, Color(tint, 0.69))
	var portrait := Rect2(113, 80, 168, 147)
	game.draw_polygon(PackedVector2Array([portrait.position, Vector2(portrait.end.x, portrait.position.y),
		portrait.end, Vector2(portrait.position.x, portrait.end.y)]),
		PackedColorArray([Color("#242032"), Color("#242032"), tint.darkened(0.78), tint.darkened(0.78)]))
	if wolf:
		var paws := Vector2(196, 214)
		game.Art.shadow(game, paws, 52.0)
		game.draw_arc(Vector2(196, 156), 49.0, 0.0, TAU, 44, Color(tint, 0.48), 1.2, true)
		game.LunaArt.walk(game, paws, 111.0, 0.0, Vector2.RIGHT, false, Color.WHITE, true)
	else:
		view.heroine_stage(game, Vector2(194, 221), 126.0)
		if luna:
			game.draw_arc(Vector2(196, 155), 67.0, -PI * 0.93, -PI * 0.12, 36, Color(tint, 0.45), 1.0, true)
	game.draw_line(Vector2(118, 227), Vector2(276, 227), Color(view.BRASS, 0.6))
	view.diamond(game, Vector2(196, 227), 3.4, view.BRASS)
	view.centered(game, Rect2(109, 230, 176, 25), game.NAMES[hero], 23, view.CREAM, true)
	var role: String = "Wolf form" if wolf else ("The Wolfbound Gunner" if luna else view.ROLE[hero])
	view.centered(game, Rect2(109, 253, 176, 15), role, 10, tint)
	var loadout := Rect2(117, 270, 160, 17)
	game.draw_rect(loadout, Color("#302637"))
	if wolf:
		game.LunaArt.icon(game, 14, Vector2(128, 278), 15.0)
		view.text(game, Vector2(142, 282), "Claws & Rend", 11, view.CREAM)
		return
	var weapon_id: String = game.armory.for_hero(hero)
	game.WeaponArt.draw_icon(game, weapon_id, Vector2(128, 278), 17.0)
	view.text(game, Vector2(142, 282), game.Weapons.item(weapon_id).name, 11, view.CREAM)

static func draw_stats(game) -> void:
	var view = game.View
	var hero: int = game.hero
	var max_hp: int = game.HEALTH[hero]
	view.frame(game, STATS_CARD, INSET)
	game.draw_rect(Rect2(313, 81, 200, 26), Color("#302637"))
	view.text(game, Vector2(321, 101), "Character stats", 18, view.CREAM, true)
	stat(game, 123, "Health", "%d / %d HP" % [game.hp, max_hp])
	var life: float = clampf(float(game.hp) / max_hp, 0.0, 1.0)
	game.draw_rect(Rect2(321, 129, 184, 4), Color("#553044"))
	game.draw_rect(Rect2(321, 129, roundf(184 * life), 4), ROSE)
	draw_resource(game, hero)
	var weapon: Dictionary = game.Weapons.item(game.armory.for_hero(hero))
	var wolf: bool = hero == GuestRoster.LUNA and game.luna_combat.in_wolf()
	var power: int = game.LunaCombat.CLAW_DAMAGE if wolf else int(weapon.damage)
	var basic: int = game.player_hit_amount(maxi(1, power + game.basic_damage_bonus(int(game.bonus))))
	stat(game, 186, "Claw damage" if wolf else "Basic damage", str(basic))
	stat(game, 204, "Flat damage bonus", "+%d damage" % game.bonus)
	var held: String = game.pocket.held
	if held.is_empty():
		stat(game, 222, "Attack interval", "%.2fs" % game.basic_attack_interval())
	else:
		stat(game, 222, "Pocket item", game.RunItems.ITEMS[held].name)
	game.draw_line(Vector2(321, 173), Vector2(505, 173), Color(view.BRASS, 0.32))
	game.draw_line(Vector2(321, 232), Vector2(505, 232), Color(view.BRASS, 0.55))
	var seconds := int(game.run_time)
	stat(game, 250, "Room %d" % (game.depth + 1), "%d:%02d elapsed" % [int(seconds / 60.0), seconds % 60])
	var biome: String = game.BIOMES[game.active_biome]
	if game.floor_index >= game.Dungeon.BIOME_COUNT:
		biome = game.preferences.place_name(game.BIOMES.back())
	view.text(game, Vector2(321, 266), biome, 11, view.DIM)
	view.text(game, Vector2(321, 282), game.room_title, 11, view.DIM)

static func draw_resource(game, hero: int) -> void:
	var view = game.View
	var luna := hero == GuestRoster.LUNA
	if luna and game.luna_combat.in_wolf():
		var left: float = game.luna_combat.wolf_left
		var fraction := clampf(left / game.luna_combat.duration(game), 0.0, 1.0)
		stat(game, 152, "Wolf form", "%.1fs" % left)
		game.draw_rect(Rect2(321, 159, 184, 4), Color("#553044"))
		game.draw_rect(Rect2(321, 159, roundf(184 * fraction), 4), ROSE)
		return
	var charge: int = game.LunaCombat.SHOTS_REQUIRED if luna else game.HeroUltimates.CHARGE
	var filled: int = game.luna_combat.gauge if luna else game.resource
	stat(game, 152, "Transformation" if luna else game.RESOURCES[hero], "%d / %d" % [filled, charge])
	for index in range(charge):
		view.diamond(game, Vector2(325 + 12 * index, 160), 3.3,
			game.COLORS[hero] if index < filled else Color("#5a4966"))

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
	var active: String = game.menu_motion.pause_panel
	draw_tab(game, RELICS_TAB, "Relics", active == "relics")
	draw_tab(game, UPGRADES_TAB, "Upgrades", active == "upgrades")
	draw_tab(game, ABILITIES_TAB, "Abilities", active == "abilities")
	match active:
		"upgrades": draw_upgrades(game)
		"abilities": draw_abilities(game)
		_: draw_relics(game)

static func draw_tab(game, area: Rect2, label: String, selected: bool) -> void:
	var view = game.View
	view.frame(game, area, view.CREAM if selected else Color("#392c46"))
	view.centered(game, area, label, 13, view.INK if selected else view.CREAM, true)

static func ability_rect(game, ability: int) -> Rect2:
	var abilities: Array[int] = game.View.inspectable_abilities(game.hero)
	return Rect2(549, 122 + abilities.find(ability) * 39, 193, 33)

static func draw_abilities(game) -> void:
	var view = game.View
	for ability: int in view.inspectable_abilities(game.hero):
		view.draw_ability_row(game, ability_rect(game, ability), game.hero, ability)
	view.centered(game, Rect2(549, 251, 193, 23), "Hold an ability for details", 11, view.DIM)

static func relic_last_page(game) -> int:
	return maxi(0, ceili(float(game.relics.owned.size()) / RELIC_ROWS) - 1)

static func draw_relics(game) -> void:
	var view = game.View
	var owned: Array[String] = game.relics.owned
	if owned.is_empty():
		view.text(game, Vector2(553, 130), "No relics equipped", 12, view.DIM)
		return
	var last := relic_last_page(game)
	var page := clampi(game.menu_motion.pause_relic_page, 0, last)
	var first := page * RELIC_ROWS
	for index in range(first, mini(first + RELIC_ROWS, owned.size())):
		var relic_id := owned[index]
		var item: Dictionary = game.Relics.definition(relic_id)
		var center := Vector2(566, 128 + (index - first) * 18.0)
		view.ring(game, center, 10.0, view.BRASS, 0.58)
		RelicInfo.draw_icon(game, relic_id, center, 17.0)
		view.text(game, center + Vector2(16, 4), item.get("name", relic_id), 11, view.CREAM)
	if last > 0:
		if page > 0:
			view.button(game, RELICS_PREV, "‹")
		if page < last:
			view.button(game, RELICS_NEXT, "›")
		view.centered(game, Rect2(599, 249, 93, 23), "Page %d / %d" % [page + 1, last + 1], 11, view.DIM)
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

static func draw_confirmation(game) -> void:
	var view = game.View
	game.draw_rect(view.CANVAS, Color(0.075, 0.045, 0.10, 0.70))
	view.frame(game, Rect2(188, 100, 488, 198), PLUM, ROSE)
	view.centered(game, Rect2(217, 115, 430, 42), "End this run?", 28, view.CREAM, true)
	view.centered(game, Rect2(213, 168, 438, 22), "Your run items and dungeon progress will be lost.", 14)
	view.centered(game, Rect2(213, 191, 438, 21), "Any Garden Seeds earned will be recorded.", 13, view.DIM)
	view.button(game, CONFIRM_CANCEL, "Back to pause", true)
	view.button(game, CONFIRM_END, "End Run")
