extends RefCounted

const PANEL = Rect2(155, 55, 554, 280)
const REFRESH = Rect2(241, 281, 179, 34)
const LEAVE = Rect2(444, 281, 179, 34)
const COMPARE_BACK = Rect2(259, 267, 143, 38)
const COMPARE_BUY = Rect2(462, 267, 143, 38)

static func stock_rect(index: int) -> Rect2:
	return Rect2(171 + (index % 3) * 176, 137 + floori(index / 3.0) * 67, 170, 60)

static func draw(game) -> void:
	var view = game.View
	view.frame(game, PANEL, Color("#241c2f"), Color("#b88c68"))
	view.centered(game, Rect2(236, 69, 392, 31), game.room_title, 25, view.CREAM, true)
	var credit: int = game.relics.receipt_credit(game.room_id)
	var purse := "%d Petals" % game.petals
	if credit > 0:
		purse += "  ·  %d receipt credit" % credit
	view.centered(game, Rect2(300, 103, 264, 22), purse, 14, Color("#f4ceaa"))
	view.sprig(game, Vector2(274, 114), Vector2(1, 0), view.BRASS)
	view.sprig(game, Vector2(590, 114), Vector2(-1, 0), view.BRASS)
	var offers: Array[Dictionary] = game.merchant.stock(game)
	if game.merchant.comparing_weapon:
		draw_comparison(game, offers[game.merchant.WEAPON_SLOT])
		return
	for index in range(offers.size()):
		draw_offer(game, stock_rect(index), offers[index])
	var blocked: String = game.merchant.reroll_block(game)
	if blocked.is_empty():
		view.button(game, REFRESH, "Refresh Stock · %d" % game.merchant.reroll_price(game))
	else:
		view.frame(game, REFRESH, Color("#2b2633"), Color("#75666c"))
		view.centered(game, REFRESH, blocked, 12, view.DIM)
	view.button(game, LEAVE, "Continue onward", true)

static func draw_offer(game, area: Rect2, offer: Dictionary) -> void:
	var view = game.View
	var available: bool = offer.blocked.is_empty()
	var focus: bool = available and area.has_point(game.get_local_mouse_position())
	var fill := Color("#f6e4ca") if available else Color("#3b2d40")
	if focus:
		fill = fill.lightened(0.16)
	var ink: Color = Color("#322535") if available else view.CREAM
	var muted: Color = Color("#5f4650") if available else view.DIM
	view.frame(game, area, fill, Color("#b38563") if available else Color("#785f70"))
	var icon_center := area.position + Vector2(24, 29)
	game.draw_circle(icon_center, 17.0, Color("#e7c9a6") if available else Color("#584053"), true, -1.0, true)
	var tint := Color.WHITE if available else Color(0.68, 0.58, 0.62)
	draw_icon(game, offer.id, icon_center, tint)
	view.text(game, area.position + Vector2(46, 20), offer.name, 14, ink, true)
	var detail: String = offer.effect if available else offer.blocked
	var detail_size := 8 if detail.length() > 24 else 10
	view.text(game, area.position + Vector2(46, 36), detail, detail_size, muted)
	view.diamond(game, area.position + Vector2(50, 48), 2.4, muted)
	view.text(game, area.position + Vector2(57, 52), "%d Petals" % offer.price, 10, muted)

static func draw_icon(game, id: String, point: Vector2, tint: Color) -> void:
	if id == game.merchant.REVIVE_ITEM:
		var color := Color("#f2cfad") * tint
		game.draw_circle(point, 12.0, Color("#885a73") * tint)
		game.draw_rect(Rect2(point + Vector2(-2, -8), Vector2(4, 16)), color)
		game.draw_rect(Rect2(point + Vector2(-8, -2), Vector2(16, 4)), color)
		return
	if id == game.GuestRoster.LUNA_UNLOCK:
		game.LunaArt.icon(game, 0, point, 33.0, tint)
		return
	if game.Weapons.DEFINITIONS.has(id):
		game.WeaponArt.draw_icon(game, id, point, 29.0)
		return
	if game.RunItems.ITEMS.has(id):
		game.RunItems.draw_icon(game, id, point, 29.0, tint)
		return
	var reward = game.View.Reward
	var source: Rect2 = reward.TEA_ICON if id == "dew_tea" else reward.THORN_ICON
	var size := (source.size * (29.0 / maxf(source.size.x, source.size.y))).round()
	game.draw_texture_rect_region(reward.ICONS, Rect2((point - size / 2.0).round(), size), source, tint)

static func draw_comparison(game, offer: Dictionary) -> void:
	var view = game.View
	var equipped: String = game.armory.for_hero(game.hero)
	var left: Dictionary = game.Weapons.item(equipped)
	var right: Dictionary = game.Weapons.item(offer.id)
	var center := Vector2(432, 170)
	for index in range(2):
		var id: String = equipped if index == 0 else offer.id
		var item: Dictionary = left if index == 0 else right
		var point := center + Vector2(-124.0 if index == 0 else 124.0, 0)
		game.WeaponArt.draw_icon(game, id, point, 58.0)
		view.centered(game, Rect2(point + Vector2(-109, 31), Vector2(218, 24)),
			"Equipped · " + item.name if index == 0 else item.name, 15, view.CREAM, true)
		view.centered(game, Rect2(point + Vector2(-108, 55), Vector2(216, 18)),
			"%d damage · %.2fs" % [item.damage, item.interval], 12, view.DIM)
	view.centered(game, Rect2(240, 244, 384, 18), right.effect, 12, view.CREAM)
	view.button(game, COMPARE_BACK, "Back to stock")
	if offer.blocked.is_empty():
		view.button(game, COMPARE_BUY, "Equip · %d Petals" % offer.price, true)
	else:
		view.frame(game, COMPARE_BUY, Color("#3b2d40"), Color("#785f70"))
		view.centered(game, COMPARE_BUY, offer.blocked, 12, view.DIM)

static func tap(game, point: Vector2) -> void:
	if game.merchant.comparing_weapon:
		if COMPARE_BACK.has_point(point):
			game.merchant.comparing_weapon = false
		elif COMPARE_BUY.has_point(point) and game.merchant.buy(game, game.merchant.WEAPON_SLOT):
			game.merchant.comparing_weapon = false
		return
	if LEAVE.has_point(point):
		game.complete_room()
	elif REFRESH.has_point(point):
		game.merchant.refresh(game)
	else:
		var offers: Array[Dictionary] = game.merchant.stock(game)
		for index in range(offers.size()):
			if stock_rect(index).has_point(point):
				if index == game.merchant.WEAPON_SLOT and game.Weapons.DEFINITIONS.has(offers[index].id):
					game.merchant.comparing_weapon = true
				else:
					game.merchant.buy(game, index)
				return
