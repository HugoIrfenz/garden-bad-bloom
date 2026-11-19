extends RefCounted

const Profile = preload("res://scripts/run_profile.gd")
const Media = preload("res://scripts/garden_media.gd")
const Decorations = preload("res://scripts/garden_decorations.gd")
const Hub = preload("res://scripts/garden_hub.gd")
const Items = preload("res://scripts/run_items.gd")
const Catalog = preload("res://scripts/weapon_catalog.gd")
const WeaponArt = preload("res://scripts/weapon_art.gd")
const MARKET = preload("res://assets/art/menus/room_choices.png")
const BACK = Rect2(45, 329, 155, 43)
const PREV = Rect2(626, 329, 48, 43)
const NEXT = Rect2(771, 329, 48, 43)
const PAGE_BADGE = Rect2(683, 329, 79, 43)
const PAGE_SIZE = 4
enum Shelf { ITEMS, WEAPONS, DECORATIONS, MEDIA }
const TABS = [Rect2(45, 69, 182, 34), Rect2(242, 69, 182, 34), Rect2(439, 69, 182, 34), Rect2(636, 69, 182, 34)]
const TAB_LABELS = ["seed_shop.loadouts", "seed_shop.weapons", "seed_shop.decorations", "seed_shop.media"]
const HINTS = ["seed_shop.hint", "seed_shop.weapon_hint", "seed_shop.decoration_hint", "seed_shop.media_hint"]
static var MEDIA_STOCK: Array = [Media.CONSOLE, Media.JUKEBOX] + Media.CARTRIDGES + Media.TAPES
static var STOCK: Array = [Profile.STARTING_ITEMS, Profile.STARTING_WEAPONS, Profile.GARDEN_DECORATIONS, MEDIA_STOCK]
const INK = Color("#241c2e")
const GOLD = Color("#f2c88a")

static func draw(game) -> void:
	var view = game.View
	var preferences = game.preferences
	var cell := (MARKET.get_size() * 0.5).floor()
	game.draw_texture_rect_region(MARKET, view.CANVAS, Rect2(Vector2.ZERO, cell))
	game.draw_rect(view.CANVAS, Color(0.11, 0.07, 0.12, 0.29))
	view.petals(game, game.visual_clock)
	var header := Rect2(284, 17, 296, 43)
	view.frame(game, header, INK)
	view.centered(game, header, preferences.text("hub.seed_shop"), 28, view.CREAM, true)
	Hub.draw_balance(game, Rect2(646, 19, 173, 38))
	var shelf: int = game.seed_shop_shelf
	var page: int = game.seed_shop_page
	for index in TABS.size():
		view.button(game, TABS[index], preferences.text(TAB_LABELS[index]), shelf == index)
	var offers := page_offers(shelf, page)
	for index in offers.size():
		draw_offer(game, card_rect(index, offers.size()), offers[index])
	var back_key := "common.back_to_garden" if game.seed_shop_return_screen == "garden_hub" else "common.back"
	view.button(game, BACK, preferences.text(back_key))
	var pages := page_count(shelf)
	var notice := Rect2(216, 329, 397 if pages > 1 else 603, 43)
	var hint: String = HINTS[shelf]
	var message_key: String = hint if game.seed_shop_feedback.is_empty() else game.seed_shop_feedback
	view.frame(game, notice, Color(INK, 0.94))
	var lines: Array[String] = game.CodexView.wrap_text(preferences.text(message_key), ThemeDB.fallback_font, notice.size.x - 26.0, 12)
	for index in mini(lines.size(), 2):
		var center_y := notice.get_center().y + (index - (mini(lines.size(), 2) - 1) * 0.5) * 15.0
		view.centered(game, Rect2(notice.position.x, center_y - 7.0, notice.size.x, 14), lines[index], 12, view.CREAM)
	if pages > 1:
		view.frame(game, PAGE_BADGE, INK)
		view.centered(game, PAGE_BADGE, "%d / %d" % [page + 1, pages], 15, view.CREAM, true)
		if page > 0:
			view.button(game, PREV, "‹")
		if page + 1 < pages:
			view.button(game, NEXT, "›")

static func page_count(shelf: int) -> int:
	return maxi(1, ceili(float(STOCK[shelf].size()) / PAGE_SIZE))

static func page_of(shelf: int, offer_id: String) -> int:
	var index: int = STOCK[shelf].find(offer_id)
	return floori(float(maxi(0, index)) / PAGE_SIZE)

static func page_offers(shelf: int, page: int) -> Array:
	return STOCK[shelf].slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE)

static func card_rect(index: int, count: int) -> Rect2:
	var gap := 14.0
	var width := minf(244.0, floorf((774.0 - gap * (count - 1)) / count))
	var strip := count * width + (count - 1) * gap
	return Rect2(roundf((864.0 - strip) * 0.5 + index * (width + gap)), 115, width, 199)

static func purchase_rect(card: Rect2) -> Rect2:
	return Rect2(card.position + Vector2(11, 145), Vector2(card.size.x - 22, 42))

static func draw_offer(game, card: Rect2, unlock_id: String) -> void:
	var view = game.View
	var preferences = game.preferences
	var decorative := unlock_id in Profile.GARDEN_DECORATIONS
	var is_weapon := unlock_id in Profile.STARTING_WEAPONS
	var is_media := Media.PRICES.has(unlock_id)
	var item := offer_detail(unlock_id)
	var owned: bool = game.knows_weapon(unlock_id) if is_weapon else game.profile.has_unlock(unlock_id)
	var cost: int = Profile.SEED_OFFERS[unlock_id]
	var can_buy: bool = game.garden_seeds >= cost
	var accent: Color = item.get("accent", Color("#b9b9f0") if unlock_id in Media.TAPES else GOLD)
	var focused: bool = game.seed_shop_focus == unlock_id
	if focused:
		game.draw_rect(card.grow(4), Color(GOLD, 0.24 + sin(float(game.visual_clock) * 3.1) * 0.07), false, 2.0)
	view.frame(game, card, Color(INK, 0.95), GOLD if focused else (accent if owned else view.BRASS))
	var origin := card.position
	var icon_center := Vector2(card.get_center().x, origin.y + 44).round()
	var ring := 29.0
	game.draw_circle(icon_center, ring, Color(accent, 0.10), true, -1.0, true)
	game.draw_arc(icon_center, ring, 0.0, TAU, 42, Color(accent, 0.62), 1.0, true)
	if is_media:
		Media.draw_icon(game, unlock_id, icon_center, 57.0)
	elif decorative:
		draw_decoration(game, unlock_id, icon_center)
	elif is_weapon:
		WeaponArt.draw_icon(game, unlock_id, icon_center, 52.0)
	else:
		Items.draw_icon(game, unlock_id, icon_center, 52.0, Color.WHITE)
	var item_key := "item." + unlock_id
	var inner_width := card.size.x - 16.0
	var category: String = preferences.text("seed_shop.decoration" if decorative else "seed_shop.starting_item")
	if is_weapon:
		category = preferences.text("seed_shop.weapon_for", {"hero": game.NAMES[int(item.hero)]})
	elif is_media:
		category = preferences.text(media_kind(unlock_id))
	var name: String = preferences.text(item_key + ".name", {}, item.get("name", ""))
	var title_size := 17 if name.length() <= 20 else 14
	view.centered(game, Rect2(origin + Vector2(8, 78), Vector2(inner_width, 22)),
		name, title_size, view.CREAM, true)
	view.centered(game, Rect2(origin + Vector2(8, 102), Vector2(inner_width, 16)), category, 11, accent)
	var effect: String = preferences.text(item_key + ".effect", {}, item.get("effect", ""))
	var lines: Array[String] = game.CodexView.wrap_text(effect, ThemeDB.fallback_font, inner_width, 10)
	for index in mini(lines.size(), 2):
		view.centered(game, Rect2(origin + Vector2(8, 119 + index * 12), Vector2(inner_width, 13)), lines[index], 10, view.DIM)
	var action := purchase_rect(card)
	if owned:
		view.frame(game, action, Color("#313638"), accent)
		var label := "seed_shop.placed" if decorative else "seed_shop.owned"
		if is_weapon:
			label = "seed_shop.weapon_ready"
		elif is_media:
			label = "seed_shop.media_owned"
		view.centered(game, action, preferences.text(label), 14, view.CREAM, true)
	elif can_buy:
		var pointer: Vector2 = game.get_local_mouse_position()
		var response: float = game.menu_motion.hover_amount(action, pointer) + game.menu_motion.press_amount(action)
		view.frame(game, action, view.CREAM.lightened(response * 0.10), accent)
		view.centered(game, Rect2(action.position + Vector2(0, 3), Vector2(action.size.x, 18)),
			preferences.text("seed_shop.unlock_button"), 15, view.INK, true)
		view.centered(game, Rect2(action.position + Vector2(0, 22), Vector2(action.size.x, 15)),
			preferences.text("seed_shop.cost", {"amount": cost}), 11, view.INK)
	else:
		view.frame(game, action, Color("#302637"), Color("#806d79"))
		view.centered(game, Rect2(action.position + Vector2(0, 3), Vector2(action.size.x, 18)),
			preferences.text("seed_shop.cost", {"amount": cost}), 14, view.CREAM, true)
		view.centered(game, Rect2(action.position + Vector2(0, 23), Vector2(action.size.x, 14)),
			preferences.text("seed_shop.shortfall", {"amount": cost - game.garden_seeds}), 10, view.DIM)

static func offer_detail(id: String) -> Dictionary:
	if Media.PRICES.has(id):
		return Media.item(id)
	if Decorations.PRICES.has(id):
		return Decorations.item(id)
	if id in Profile.STARTING_WEAPONS:
		return Catalog.item(id)
	return Items.ITEMS.get(id, {})

static func media_kind(id: String) -> String:
	if id in Media.CARTRIDGES:
		return "seed_shop.cartridge"
	if id in Media.TAPES:
		return "seed_shop.vhs"
	return "seed_shop.machine"

static func draw_decoration(game, unlock_id: String, center: Vector2) -> void:
	var clock: float = game.visual_clock
	match unlock_id:
		Profile.FOUNTAIN_LANTERNS:
			Hub.draw_lantern(game, center + Vector2(0, 22), 2.25, clock)
		Profile.PORCELAIN_PLANTERS:
			Hub.draw_planter(game, center + Vector2(0, 23), 46.0)
		Profile.ROSE_TEA_CORNER:
			Hub.draw_tea_corner(game, center + Vector2(0, 20), 42.0, clock)
		Profile.FIREFLY_GROVE:
			for index in range(6):
				var phase := clock * (1.25 + index * 0.12) + index * TAU / 6.0
				var point := center + Vector2.from_angle(phase) * Vector2(15.0 + index % 3 * 4.0, 16.0)
				Hub.draw_firefly(game, point, phase * 3.0, 1.7)
		_:
			Decorations.draw_icon(game, unlock_id, center, 52.0)

static func activate(game, point: Vector2) -> bool:
	if BACK.has_point(point):
		return true
	for index in TABS.size():
		if not TABS[index].has_point(point):
			continue
		if index != game.seed_shop_shelf:
			game.seed_shop_shelf = index
			game.seed_shop_page = 0
			game.seed_shop_focus = ""
			game.seed_shop_feedback = ""
			game.sound.play("ui")
		return false
	var page: int = game.seed_shop_page
	var next_page := page
	if PREV.has_point(point) and page > 0:
		next_page -= 1
	elif NEXT.has_point(point) and page + 1 < page_count(game.seed_shop_shelf):
		next_page += 1
	if page != next_page:
		game.seed_shop_page = next_page
		game.seed_shop_focus = ""
		game.seed_shop_feedback = ""
		game.sound.play("ui")
		return false
	game.purchase_seed_offer(purchase_at(game, point))
	return false

static func purchase_at(game, point: Vector2) -> String:
	var offers := page_offers(game.seed_shop_shelf, game.seed_shop_page)
	for index in offers.size():
		if not purchase_rect(card_rect(index, offers.size())).has_point(point):
			continue
		var unlock_id: String = offers[index]
		var is_weapon := unlock_id in Profile.STARTING_WEAPONS
		var owned: bool = game.knows_weapon(unlock_id) if is_weapon else game.profile.has_unlock(unlock_id)
		if not owned and game.garden_seeds >= Profile.SEED_OFFERS[unlock_id]:
			return unlock_id
	return ""
