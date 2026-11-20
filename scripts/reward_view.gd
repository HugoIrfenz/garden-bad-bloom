extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const Prep = preload("res://scripts/run_preparation_view.gd")
const Relics = preload("res://scripts/relic_effects.gd")
const RelicInfo = preload("res://scripts/relic_info_view.gd")
const UpgradeArt = preload("res://scripts/upgrade_art.gd")
const ICONS = preload("res://assets/art/items/room_rewards.png")
const DEW_TEA_RECT = Rect2(209, 112, 210, 224)
const THORN_EDGE_RECT = Rect2(445, 112, 210, 224)
const BOSS_TEA_RECT = Rect2(121, 112, 210, 224)
const BOSS_THORN_RECT = Rect2(344, 112, 210, 224)
const RELIC_RECT = Rect2(567, 112, 210, 224)
const RELIC_BACK = RelicInfo.BACK
const RELIC_EQUIP = RelicInfo.EQUIP
const TEA_ICON = Rect2(40, 141, 819, 680)
const THORN_ICON = Rect2(998, 17, 744, 842)
const INK = Color("#2f2534")
const NAVY = Color("#252334")
const BRASS = Color("#a7754e")
const CREAM = Color("#f7e7ce")
const PAPER = Color("#fff2de")
const SAGE = Color("#425940")

static func tea_rect(has_relic: bool) -> Rect2:
	return BOSS_TEA_RECT if has_relic else DEW_TEA_RECT

static func thorn_rect(has_relic: bool) -> Rect2:
	return BOSS_THORN_RECT if has_relic else THORN_EDGE_RECT

static func upgrade_rect(index: int, has_third: bool) -> Rect2:
	return thorn_rect(has_third) if index == 0 else RELIC_RECT

static func relic_preview_open(game) -> bool:
	var offered := str(game.reward_relic_id)
	return not offered.is_empty() and game.menu_motion.reward_relic_preview == offered

static func draw(game) -> void:
	if relic_preview_open(game):
		RelicInfo.draw_inspection(game, game.reward_relic_id)
		return
	var reveal := float(game.menu_motion.screen_age)
	var clock := float(game.visual_clock)
	var header := enter_progress(reveal, 0.0, 0.24)
	var purse := enter_progress(reveal, 0.07, 0.23)
	var offered := str(game.reward_relic_id)
	var weapon_id := str(game.reward_weapon_id)
	var has_relic := not offered.is_empty()
	var consumable: String = game.pocket.offer(game)
	var upgrade_ids: Array[String] = game.reward_upgrade_offers()
	var has_third := has_relic or not weapon_id.is_empty() or not consumable.is_empty() or upgrade_ids.size() > 1
	game.draw_rect(Rect2(0, 0, 864, 390), Color(0.12, 0.08, 0.14, 0.29 * header))
	draw_hero_reaction(game, has_third, reveal, clock)
	if header > 0.0:
		var banner := Rect2(277, 24 - roundf(10.0 * (1.0 - header)), 310, 47)
		framed_panel(game, banner, Color(NAVY, header), Color("#c29b73", header), 13.0)
		draw_banner_leaves(game, banner, header)
		centered(game, banner, "Choose your reward", 24, Color(CREAM, header), true)
	if purse > 0.0:
		var currency := Rect2(367, 77 + roundf(6.0 * (1.0 - purse)), 130, 24)
		framed_panel(game, currency, Color("#382b3d", purse), Color("#9a795e", purse), 6.0)
		diamond(game, currency.position + Vector2(17, 12), 3.5, Color("#e7a6b6", purse))
		centered(game, currency, "%d Petals" % game.petals, 12, Color(CREAM, purse))

	var first: Dictionary
	if game.reward_has_tea():
		var healing: int = game.reward_healing()
		var sealed: bool = not game.curses.healing_block("reward").is_empty()
		var effect := "Cursed Lily seals healing" if sealed else ("Restore %d HP" % healing if healing > 0 else "Health is full")
		first = {"icon": TEA_ICON, "name": "Dew Tea", "kind": "Consumable", "rarity": "common",
			"effect": effect, "action": "Drink tea" if healing > 0 else "Unavailable", "blocked": healing <= 0}
	else:
		var boost: int = game.reward_resource_gain()
		first = game.RunItems.card("royal_teacup")
		first.name = "Second Wind"
		first.kind = "Charge"
		first.rarity = "common"
		first.effect = "Restore %d %s" % [boost, game.RESOURCES[game.hero]] if boost > 0 else "Class meter is full"
		first.action = "Take a breath" if boost > 0 else "Unavailable"
		first.blocked = boost <= 0
	draw_card(game, tea_rect(has_third), first, reveal, 0.09, clock)
	if not upgrade_ids.is_empty():
		draw_card(game, upgrade_rect(0, has_third), upgrade_card(game, upgrade_ids[0]), reveal, 0.16, clock)
	if has_relic:
		var item := Relics.definition(offered)
		if not item.is_empty():
			item.merge(RelicInfo.icon(offered), true)
			item.kind = "Offered Relic"
			item.action = "Inspect Relic"
			item.effect = RelicInfo.highlight(offered, 0)
			if item.effect.is_empty():
				item.effect = item.detail
			draw_card(game, RELIC_RECT, item, reveal, 0.23, clock)
	elif not weapon_id.is_empty():
		var current: Dictionary = game.Weapons.item(game.armory.for_hero(game.hero))
		var new_weapon: Dictionary = game.WeaponArt.reward_card(weapon_id)
		draw_card(game, RELIC_RECT, new_weapon, reveal, 0.23, clock)
		var compare := Rect2(262, 344, 515, 29)
		framed_panel(game, compare, Color(NAVY, header), Color(BRASS, header), 7.0)
		centered(game, compare, "%s   ·   %d → %d base damage   ·   %.2fs → %.2fs" %
			[current.name, current.damage, new_weapon.damage, current.interval, new_weapon.interval],
			12, Color(CREAM, header))
	elif not consumable.is_empty():
		draw_card(game, RELIC_RECT, game.RunItems.card(consumable, game.hero), reveal, 0.23, clock)
	elif upgrade_ids.size() > 1:
		draw_card(game, upgrade_rect(1, has_third), upgrade_card(game, upgrade_ids[1]), reveal, 0.23, clock)

static func upgrade_card(game, id: String) -> Dictionary:
	var item: Dictionary = game.upgrades.card(id)
	item.merge(UpgradeArt.icon(id), true)
	var current: int = int(item.get("rank", 0))
	if current > 0:
		item.action = "Raise to Rank %d" % (current + 1)
	return item

static func draw_confirmation(game) -> void:
	var motion = game.menu_motion
	if motion.previous_screen != "reward" or motion.press_screen != "reward":
		return
	var duration := 0.34
	var age := float(motion.screen_age)
	var acquired: String = game.acquired_upgrade_id
	if not acquired.is_empty():
		draw_upgrade_confirmation(game, acquired, age)
	if age >= duration:
		return
	var progress := age / duration
	var fade := 1.0 - smoothstep(0.28, 1.0, progress)
	var center: Vector2 = game.player - Vector2(0, 14)
	for index in range(7):
		var angle := TAU * float(index) / 7.0 + 0.35
		var travel := Vector2.from_angle(angle) * (12.0 + 27.0 * progress)
		var point := (center + travel - Vector2(0, progress * 14.0)).round()
		var tint := Color("#f8d599") if index % 2 == 0 else Color("#eaaeaf")
		diamond(game, point, (2.1 + (index % 3) * 0.4) * fade, Color(tint, fade))

static func draw_upgrade_confirmation(game, id: String, age: float) -> void:
	const HOLD := 1.04
	if age >= HOLD:
		return
	var visible := smoothstep(0.0, 0.16, age) * (1.0 - smoothstep(0.74, HOLD, age))
	var rise := roundf(8.0 * (1.0 - smoothstep(0.0, 0.23, age)))
	var box := Rect2(321, 82 + rise, 222, 41)
	var accent := Color("#edc396", visible)
	var view = game.View
	view.frame(game, box, Color("#342638", visible * 0.96), accent)
	UpgradeArt.draw_icon(game, id, box.position + Vector2(27, 21), 31.0, visible)
	var item: Dictionary = game.upgrades.card(id)
	var name := str(item.name)
	var current: int = game.upgrades.rank(id)
	if current > 1:
		name += "  ·  Rank %d" % current
	centered(game, Rect2(box.position + Vector2(50, 2), Vector2(159, 36)),
		name, 16, Color(CREAM, visible), true)
	diamond(game, box.position + Vector2(49, 21), 2.0, accent)

static func enter_progress(age: float, start: float, duration: float) -> float:
	var t := clampf((age - start) / duration, 0.0, 1.0)
	return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t)

static func draw_hero_reaction(game, has_relic: bool, reveal: float, clock: float) -> void:
	var arrival := enter_progress(reveal, 0.05, 0.33)
	if arrival <= 0.0:
		return
	var height := 102.0 if has_relic else 128.0
	var x := 63.0 if has_relic else 104.0
	var settle := maxf(0.0, sin(arrival * PI) * 9.0)
	var feet := Vector2(roundf(x - 18.0 * (1.0 - arrival)), roundf(332.0 - settle))
	game.draw_circle(Vector2(feet.x, 332.0), 15.0, Color(0.11, 0.07, 0.11, 0.24 * arrival), true, -1.0, true)
	Art.heroine(game, int(game.hero), feet, height, clock, Vector2.RIGHT * (1.0 - arrival) * 36.0,
		0.0, Color(1.0, 1.0, 1.0, arrival))
	var sparkle := sin(PI * clampf((reveal - 0.18) / 0.48, 0.0, 1.0))
	if sparkle > 0.0:
		var above := feet - Vector2(0, height + 14.0)
		diamond(game, above + Vector2(13, 1), 5.0 * sparkle, Color("#ffe2aa", sparkle))
		diamond(game, above + Vector2(-8, -7), 3.0 * sparkle, Color("#f4b7bb", sparkle))

static func draw_banner_leaves(canvas: Node2D, banner: Rect2, alpha: float) -> void:
	for direction: float in [-1.0, 1.0]:
		var edge := banner.get_center() + Vector2(direction * 133.0, 0.0)
		var tip := edge + Vector2(direction * 13.0, 0.0)
		canvas.draw_line(edge - Vector2(direction * 14.0, 0.0), tip, Color("#bc926c", alpha), 1.0, true)
		draw_leaves(canvas, edge, direction, alpha)

static func draw_leaves(canvas: Node2D, center: Vector2, direction: float, alpha: float) -> void:
	var color := Color("#c19b72", alpha)
	canvas.draw_colored_polygon(PackedVector2Array([center, center + Vector2(direction * 10.0, -4.0),
		center + Vector2(direction * 15.0, -8.0), center + Vector2(direction * 3.0, -6.0)]), color)
	canvas.draw_colored_polygon(PackedVector2Array([center, center + Vector2(direction * 10.0, 4.0),
		center + Vector2(direction * 15.0, 8.0), center + Vector2(direction * 3.0, 6.0)]), color)

static func draw_card(canvas, hit_box: Rect2, item: Dictionary, reveal: float, delay: float, clock: float) -> void:
	var visible := enter_progress(reveal, delay, 0.31)
	if visible <= 0.0:
		return
	var blocked := bool(item.get("blocked", false))
	var hover := 0.0 if blocked else float(canvas.menu_motion.hover_amount(hit_box, canvas.get_local_mouse_position()))
	var pressed := 0.0 if blocked else float(canvas.menu_motion.press_amount(hit_box))
	var hovered := hover > 0.0
	var box := hit_box
	box.position.y += roundf(15.0 * (1.0 - visible) - 2.0 * hover + 2.0 * pressed)
	var rarity: String = item.rarity
	var accent: Color = {"common": Color("#8d6b53"), "uncommon": Color("#60734b"), "rare": Color("#465b7a")}[rarity]
	var border := BRASS.lerp(Color("#c59357"), hover)
	var fill := Color("#cbbdc9") if blocked else PAPER.lerp(Color("#fff7e8"), hover)
	framed_panel(canvas, box, Color(fill, visible), Color(border, visible), 12.0)
	canvas.draw_polyline(closed_border(box.grow(-5), 7.0), Color("#d5b794", 0.65 * visible), 1.0, true)
	if hovered:
		canvas.draw_polyline(closed_border(box.grow(3), 14.0), Color("#edba71", visible * hover * (0.68 + 0.22 * sin(clock * 7.0))), 1.5, true)

	var origin := box.position
	var rarity_bar := Rect2(origin + Vector2(21, 11), Vector2(168, 23))
	framed_panel(canvas, rarity_bar, Color(accent, visible), Color("#c8ab8a", visible), 5.0)
	draw_rarity_shape(canvas, rarity_bar.position + Vector2(12, 12), rarity, visible)
	var caption := "%s · %s" % [rarity.to_upper(), str(item.kind).to_upper()]
	var caption_size := 10 if caption.length() > 19 else 11
	centered(canvas, Rect2(rarity_bar.position + Vector2(22, 0), rarity_bar.size - Vector2(25, 0)), caption,
		caption_size, Color(PAPER, visible))

	var art_center := origin + Vector2(105, 87)
	canvas.draw_circle(art_center, 44.0, Color(CREAM, visible), true, -1.0, true)
	canvas.draw_arc(art_center, 43.0, 0.0, TAU, 48, Color("#a7754e", 0.59 * visible), 1.0, true)
	var lift := roundf(5.0 * (1.0 - visible)) + (roundf(1.2 * sin(clock * 5.0)) if hovered else 0.0)
	draw_item_icon(canvas, art_center + Vector2(0, lift), item, visible)
	var glint := visible * (0.55 + sin(clock * 4.9 + delay) * 0.27)
	if hovered or rarity == "rare":
		diamond(canvas, art_center + Vector2(35, -29), 3.0, Color("#d49f61", glint))
		diamond(canvas, art_center + Vector2(-35, 27), 2.3, Color("#dfb181", glint))

	var title_size := 17 if str(item.name).length() > 17 else 23
	centered(canvas, Rect2(origin + Vector2(9, 134), Vector2(192, 29)), item.name, title_size, Color(INK, visible), true)
	var line_y := origin.y + 165.0
	canvas.draw_line(Vector2(box.position.x + 37.0, line_y), Vector2(box.end.x - 37.0, line_y), Color(BRASS, visible), 1.0)
	diamond(canvas, Vector2(box.get_center().x, line_y), 2.6, Color(BRASS, visible))
	var detail_size := 12 if item.has("gear_index") or item.has("texture") else 14
	var details := split_effect(str(item.effect), 193.0, detail_size)
	var row := Rect2(origin + Vector2(7.0, 181.0 - details.size() * 6.0), Vector2(196.0, 12.0))
	for detail: String in details:
		centered(canvas, row, detail, detail_size, Color(INK, visible))
		row.position.y += row.size.y

	var action_box := Rect2(origin + Vector2(26, 193), Vector2(158, 24))
	var action_fill := SAGE if rarity == "uncommon" else NAVY
	if hovered:
		action_fill = action_fill.lightened(0.12)
	framed_panel(canvas, action_box, Color(action_fill, visible), Color("#b89468", visible), 5.0)
	centered(canvas, action_box, item.action, 13, Color(CREAM, visible), true)

static func draw_item_icon(canvas: Node2D, center: Vector2, item: Dictionary, alpha: float) -> void:
	var texture: Texture2D = item.get("texture", ICONS)
	var source: Rect2
	if item.has("gear_index"):
		texture = Prep.GEAR
		source = Prep.GEAR_REGIONS[int(item.gear_index)]
	elif item.has("icon"):
		source = item.icon
	else:
		return
	var icon_size := (source.size * (78.0 / maxf(source.size.x, source.size.y))).round()
	var area := Rect2((center - icon_size * 0.5).round(), icon_size)
	canvas.draw_texture_rect_region(texture, area, source, Color(1.0, 1.0, 1.0, alpha))

static func split_effect(detail: String, width: float, font_size: int) -> PackedStringArray:
	var words := detail.split(" ", false)
	var face := ThemeDB.fallback_font
	if words.size() < 2 or face.get_string_size(detail, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return PackedStringArray([detail])
	var best := PackedStringArray([detail])
	var best_width := INF
	for index in range(1, words.size()):
		var left := " ".join(words.slice(0, index))
		var right := " ".join(words.slice(index))
		var measured := maxf(face.get_string_size(left, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x,
			face.get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		if measured < best_width:
			best_width = measured
			best = PackedStringArray([left, right])
	return best

static func closed_border(area: Rect2, corner: float) -> PackedVector2Array:
	var points := cut_corners(area, corner)
	points.append(points[0])
	return points

static func draw_rarity_shape(canvas: Node2D, point: Vector2, rarity: String, alpha: float) -> void:
	if rarity == "rare":
		canvas.draw_colored_polygon(PackedVector2Array([
			point + Vector2(0, -4), point + Vector2(4, 3), point + Vector2(-4, 3),
		]), Color(PAPER, alpha))
	elif rarity == "uncommon":
		canvas.draw_colored_polygon(PackedVector2Array([
			point + Vector2(-4, 3), point + Vector2(-2, -3), point + Vector2(5, -5),
			point + Vector2(3, 1), point + Vector2(0, 4),
		]), Color(PAPER, alpha))
	else:
		canvas.draw_circle(point, 3.0, Color(PAPER, alpha), true, -1.0, true)

static func framed_panel(canvas: Node2D, area: Rect2, color: Color, border: Color, corner: float) -> void:
	var shadow = area.grow(2)
	shadow.position.y += 2
	canvas.draw_colored_polygon(cut_corners(shadow, corner), Color(0.06, 0.04, 0.08, 0.6 * color.a))
	canvas.draw_colored_polygon(cut_corners(area, corner), border)
	canvas.draw_colored_polygon(cut_corners(area.grow(-1), maxf(0.0, corner - 1.0)), color)

static func cut_corners(area: Rect2, corner: float) -> PackedVector2Array:
	var x = area.position.x
	var y = area.position.y
	var right = area.end.x
	var bottom = area.end.y
	return PackedVector2Array([
		Vector2(x + corner, y), Vector2(right - corner, y), Vector2(right, y + corner),
		Vector2(right, bottom - corner), Vector2(right - corner, bottom),
		Vector2(x + corner, bottom), Vector2(x, bottom - corner), Vector2(x, y + corner),
	])

static func diamond(canvas: Node2D, point: Vector2, width: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([point + Vector2.UP * width, point + Vector2.RIGHT * width,
		point + Vector2.DOWN * width, point + Vector2.LEFT * width]), color)

static func centered(canvas: Node2D, area: Rect2, line: String, size: int, color: Color, serif := false) -> void:
	var face = Art.DISPLAY_FONT if serif else ThemeDB.fallback_font
	var baseline = area.position + Vector2(0, (area.size.y + size * 0.72) * 0.5)
	canvas.draw_string(face, baseline, line, HORIZONTAL_ALIGNMENT_CENTER, area.size.x, size, color)
