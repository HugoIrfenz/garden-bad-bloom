extends RefCounted

const Economy = preload("res://scripts/run_economy.gd")
const Items = preload("res://scripts/run_items.gd")
const Weapons = preload("res://scripts/weapon_catalog.gd")
const GuestRoster = preload("res://scripts/guest_roster.gd")
const STOCK_COUNT = 5
const WEAPON_SLOT = 4
const REROLL_LIMIT = 1
const REVIVE_ITEM = "revive_blossom"
const REVIVE_SLOT = 3
const REVIVE_PRICE = 55
const PRICES = {"royal_teacup": 17, "clockwise_tonic": 20, "petal_bomb": 23}

var rerolls := 0
var sold: Array[String] = []
var comparing_weapon := false

func reset() -> void:
	rerolls = 0
	sold.clear()
	comparing_weapon = false

func snapshot() -> Dictionary:
	return {"rerolls": rerolls, "sold": sold.duplicate()}

func restore(saved: Variant) -> void:
	reset()
	if not saved is Dictionary:
		return
	rerolls = clampi(int(saved.get("rerolls", 0)), 0, REROLL_LIMIT)
	var stock: Variant = saved.get("sold", [])
	if stock is Array:
		for id in stock:
			if id is String and (id in ["dew_tea", "thorn_edge", REVIVE_ITEM] or Items.ITEMS.has(id) or Weapons.DEFINITIONS.has(id)) and id not in sold:
				sold.append(id)

func stock(game) -> Array[Dictionary]:
	var heal: int = game.healing_amount(Economy.SHOP_HEAL, "shop")
	var heal_block: String = game.curses.healing_block("shop")
	if heal <= 0 and heal_block.is_empty():
		heal_block = "Cannot heal right now"
	var offers: Array[Dictionary] = [
		{"id": "dew_tea", "name": "Dew Tea", "price": Economy.SHOP_TEA_PRICE, "effect": "Restore %d HP" % heal,
			"blocked": heal_block},
		{"id": "thorn_edge", "name": "Thorn Edge", "price": 22, "effect": "+2 damage for this run", "blocked": ""},
	]
	var seed_value := int(game.current_room().reward_seed)
	var base := posmod(posmod(seed_value, Items.IDS.size()) + rerolls, Items.IDS.size())
	var markup := mini(4, int(game.floor_index / 2.0))
	for index in range(WEAPON_SLOT - offers.size()):
		var id: String = Items.IDS[(base + index) % Items.IDS.size()]
		var item: Dictionary = Items.ITEMS[id]
		offers.append({"id": id, "name": item.name, "price": int(PRICES[id]) + markup, "effect": Items.effect_for(id, game.hero),
			"blocked": "Pocket already occupied" if not game.pocket.held.is_empty() else ""})
	var options := Weapons.available(game.hero, "")
	if options.is_empty():
		var item_id: String = Items.IDS[(base + 2) % Items.IDS.size()]
		var supply: Dictionary = Items.ITEMS[item_id]
		offers.append({"id": item_id, "name": supply.name, "price": int(PRICES[item_id]) + markup,
			"effect": Items.effect_for(item_id, game.hero), "blocked": "Pocket already occupied" if not game.pocket.held.is_empty() else ""})
	else:
		var id: String = options[posmod(posmod(seed_value, options.size()) + rerolls, options.size())]
		var weapon := Weapons.item(id)
		offers.append({"id": id, "name": weapon.name, "price": (33 if weapon.rarity == "rare" else 26) + markup,
			"effect": "Compare weapon", "blocked": "Already equipped" if game.armory.for_hero(game.hero) == id else ""})
	# A rare, personal single-use rescue item. The room seed is shared so the
	# authority and each client always show the same stock.
	if (game.network_simulation or is_instance_valid(game.online_peer)) and posmod(seed_value, 5) == 0:
		offers[REVIVE_SLOT] = {"id": REVIVE_ITEM, "name": "Revive Blossom", "price": REVIVE_PRICE,
			"effect": "Revive a friend once", "blocked": ""}
	for offer in offers:
		var adjusted: int = game.shop_price(offer.price, offer.id == "dew_tea")
		offer.price = maxi(1, adjusted - game.relics.receipt_credit(game.room_id))
		if offer.id in sold:
			offer.blocked = "Sold"
		elif offer.blocked.is_empty() and game.petals < offer.price:
			offer.blocked = "Need %d more Petals" % (offer.price - game.petals)
	if not game.profile.has_unlock(GuestRoster.LUNA_UNLOCK):
		var price := GuestRoster.LUNA_PRICE
		var missing := price - int(game.petals)
		offers.append({"id": GuestRoster.LUNA_UNLOCK, "name": "Unlock Luna", "price": price,
			"effect": "Joins future runs", "blocked": "Need %d more Petals" % missing if missing > 0 else ""})
	return offers

func buy(game, index: int) -> bool:
	if game.screen != "room_choice" or game.room_kind != "shop" or game.run_paused or index < 0:
		return false
	var offers := stock(game)
	if index >= offers.size():
		return false
	var offer: Dictionary = offers[index]
	if not offer.blocked.is_empty():
		return false
	if offer.id == GuestRoster.LUNA_UNLOCK:
		return game.buy_luna_with_petals()
	if offer.id == REVIVE_ITEM:
		# Multiplayer authority handles inventory and payment together.
		return false
	match offer.id:
		"dew_tea":
			game.hp += game.healing_amount(Economy.SHOP_HEAL, "shop")
		"thorn_edge":
			game.bonus += 2
		_:
			if Weapons.DEFINITIONS.has(offer.id):
				if not game.equip_weapon(offer.id):
					return false
			elif not game.pocket.take(offer.id):
				return false
	game.petals -= offer.price
	sold.append(offer.id)
	game.relics.record_sale(game.room_id, game.depth, game.armory.for_hero(game.hero) == "royal_cleaver")
	game.sound.play("reward")
	game.checkpoint()
	return true

func reroll_price(game) -> int:
	return game.shop_price(8 + mini(5, int(game.floor_index / 2.0)))

func reroll_block(game) -> String:
	if rerolls >= REROLL_LIMIT:
		return "Stock refreshed"
	var missing: int = reroll_price(game) - game.petals
	return "Need %d more Petals" % missing if missing > 0 else ""

func refresh(game) -> bool:
	if game.screen != "room_choice" or game.room_kind != "shop" or game.run_paused or not reroll_block(game).is_empty():
		return false
	game.petals -= reroll_price(game)
	rerolls += 1
	game.sound.play("confirm")
	game.checkpoint()
	return true
