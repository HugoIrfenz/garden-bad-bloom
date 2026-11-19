extends RefCounted

const Dungeon = preload("res://scripts/dungeon_generation.gd")
const LILY = "cursed_lily"
const DEBT = "red_moon_debt"
const CUP = "no_second_cup"
const TITHE = "thorn_tithe"
const QUICKTHORN = "quickthorn"
const HEAVY_BLOOM = "heavy_bloom"
const WILD_ROOTS = "wild_roots"
const GOLDEN_BARGAIN = "golden_bargain"
const FRAGILE_GRACE = "fragile_grace"
const ALTAR_KEY = "curse_bargains"
const TITHE_DAMAGE = 1.25
const TITHE_HP = 4
const DEBT_DAMAGE = 1.40
const DEBT_HEALTH_CAP = 0.35
const DEBT_HEAL_PRICE = 1.50
const CUP_DISCOUNT = 0.80
const LEGACY_HP_COST = 18
const LEGACY_POWER = 3
const IDS = [LILY, DEBT, CUP, TITHE, QUICKTHORN, HEAVY_BLOOM, WILD_ROOTS, GOLDEN_BARGAIN, FRAGILE_GRACE]
const CATALOG = {
	LILY: {"title": "Cursed Lily", "detail": "Two basic strikes  ·  Conventional healing sealed", "tint": Color("#d6a2ed")},
	DEBT: {"title": "Red Moon Debt", "detail": "≤35% HP +40% hit damage  ·  Healing prices +50%", "tint": Color("#ed969e")},
	CUP: {"title": "No Second Cup", "detail": "20% off shop prices  ·  Rest rooms cannot heal", "tint": Color("#a9cddc")},
	TITHE: {"title": "Thorn Tithe", "detail": "+25% hit damage  ·  Enter fights −4 HP (min. 1)", "tint": Color("#c1c989")},
	QUICKTHORN: {"title": "Quickthorn", "detail": "Attack interval −20%  ·  Take 15% more damage", "tint": Color("#f0a387")},
	HEAVY_BLOOM: {"title": "Heavy Bloom", "detail": "+20% hit damage  ·  Move 15% slower", "tint": Color("#e9b5ce")},
	WILD_ROOTS: {"title": "Wild Roots", "detail": "Move 15% faster  ·  Dodge recharge 30% longer", "tint": Color("#a9d6a0")},
	GOLDEN_BARGAIN: {"title": "Golden Bargain", "detail": "+50% room Petals  ·  Shop prices +25%", "tint": Color("#f0cf82")},
	FRAGILE_GRACE: {"title": "Fragile Grace", "detail": "Dodge cooldown −20%  ·  Healing −25%", "tint": Color("#a7c5ed")},
}

var active: Array[String] = []

func snapshot() -> Array[String]:
	return active.duplicate()

func restore(saved: Variant = null) -> void:
	active.clear()
	if saved is Array:
		for id in saved:
			if id is String and id in IDS and id not in active:
				active.append(id)

func bind_altar(game) -> void:
	if game.room_kind != "curse":
		return
	var node: Dictionary = altar_node(game)
	if node.is_empty() or node.has(ALTAR_KEY):
		return
	var rng := Dungeon.seeded(Dungeon.stream_seed(game.run_seed, game.floor_index, game.room_id, "curse-altar:v1"))
	var options: Array[String] = []
	for id: String in IDS:
		if offer_block(id).is_empty():
			options.append(id)
	var offered: Array[String] = []
	while not options.is_empty() and offered.size() < 2:
		offered.append(options.pop_at(rng.randi_range(0, options.size() - 1)))
	node[ALTAR_KEY] = offered

static func altar_node(game) -> Dictionary:
	return game.floor_manifest.get("nodes", {}).get(game.room_id, {})

func offers(game) -> Array[Dictionary]:
	var node := altar_node(game)
	var cards: Array[Dictionary] = []
	if not node.has(ALTAR_KEY):
		cards.append({"id": "", "title": "Blood Price", "detail": "+%d damage  ·  −%d current HP" % [LEGACY_POWER, LEGACY_HP_COST],
			"tint": Color("#e9a890"), "blocked": "Requires at least %d HP" % (LEGACY_HP_COST + 1) if game.hp <= LEGACY_HP_COST else ""})
		return cards
	var bound: Variant = node[ALTAR_KEY]
	if bound is Array:
		for id in bound:
			if id is String and CATALOG.has(id) and cards.size() < 2:
				var card: Dictionary = CATALOG[id].duplicate()
				card.id = id
				card.blocked = offer_block(id)
				cards.append(card)
	return cards

func take(game, index: int) -> bool:
	if game.screen != "room_choice" or game.room_kind != "curse" or game.room_complete or game.run_paused:
		return false
	var choices := offers(game)
	if index < 0 or index >= choices.size() or not choices[index].blocked.is_empty():
		return false
	var id: String = choices[index].id
	if id.is_empty():
		game.hp -= LEGACY_HP_COST
		game.bonus += LEGACY_POWER
	else:
		active.append(id)
	return true

func has_curse(id: String) -> bool:
	return id in active

func offer_block(id: String) -> String:
	if has_curse(id):
		return "Already bound this run"
	if id == LILY and (has_curse(DEBT) or has_curse(CUP)):
		return "Conflicts with a healing bargain"
	if id in [DEBT, CUP] and has_curse(LILY):
		return "Conflicts with Cursed Lily"
	return ""

func enter_hostile_room(game) -> void:
	if has_curse(TITHE) and not game.foes.is_empty():
		game.hp = maxi(1, game.hp - TITHE_HP)

func healing_block(source: String) -> String:
	if LILY in active and source != "shrine":
		return "Cursed Lily seals conventional healing"
	if CUP in active and source == "rest":
		return "No Second Cup bars rest healing"
	return ""

func shop_price(base: int, healing_item: bool) -> int:
	if base <= 0:
		return maxi(0, base)
	var price := float(base)
	if DEBT in active and healing_item:
		price *= DEBT_HEAL_PRICE
	if CUP in active:
		price *= CUP_DISCOUNT
	if GOLDEN_BARGAIN in active:
		price *= 1.25
	return maxi(1, roundi(price))

func attack_damage(amount: int, hp: int, max_hp: int) -> int:
	if amount <= 0:
		return 0
	var multiplier := TITHE_DAMAGE if TITHE in active else 1.0
	if DEBT in active and hp > 0 and float(hp) <= DEBT_HEALTH_CAP * max_hp:
		multiplier *= DEBT_DAMAGE
	if HEAVY_BLOOM in active:
		multiplier *= 1.20
	return roundi(float(amount) * multiplier)

func attack_interval_factor() -> float:
	return 0.8 if has_curse(QUICKTHORN) else 1.0

func incoming_damage(amount: int) -> int:
	return ceili(amount * 1.15) if amount > 0 and has_curse(QUICKTHORN) else amount

func movement_factor() -> float:
	return (0.85 if has_curse(HEAVY_BLOOM) else 1.0) * (1.15 if has_curse(WILD_ROOTS) else 1.0)

func dodge_factor() -> float:
	return (1.30 if has_curse(WILD_ROOTS) else 1.0) * (0.80 if has_curse(FRAGILE_GRACE) else 1.0)

func room_reward(amount: int) -> int:
	return roundi(amount * 1.5) if amount > 0 and has_curse(GOLDEN_BARGAIN) else amount

func healing(amount: int) -> int:
	return maxi(1, roundi(amount * 0.75)) if amount > 0 and has_curse(FRAGILE_GRACE) else amount

static func draw_icon(game, id: String, center: Vector2, radius: float) -> void:
	var view = game.View
	var tint: Color = CATALOG.get(id, {}).get("tint", Color("#eda58d"))
	var glow := 0.65 + 0.20 * sin(float(game.visual_clock) * 3.8)
	view.ring(game, center, radius, Color(tint, glow), 0.74)
	match id:
		LILY:
			for angle in [-0.75, 0.0, 0.75]:
				view.diamond(game, center + Vector2(sin(angle), -cos(angle)) * radius * 0.52, radius * 0.27, tint)
			game.draw_line(center, center + Vector2.DOWN * radius * 0.58, tint, 1.2, true)
		DEBT:
			game.draw_arc(center, radius * 0.55, 0.34, TAU - 0.34, 18, tint, 2.0, true)
			view.diamond(game, center + Vector2(2, 1), radius * 0.24, tint)
		CUP:
			game.draw_arc(center - Vector2(1, 1), radius * 0.47, 0.0, PI, 16, tint, 1.4, true)
			game.draw_line(center + Vector2(-radius * 0.50, -1), center + Vector2(radius * 0.46, -1), tint, 1.1, true)
			game.draw_line(center + Vector2(-4, 4), center + Vector2(4, -5), tint, 1.5, true)
		QUICKTHORN:
			game.draw_line(center + Vector2(-5, 4), center + Vector2(4, -5), tint, 2.2, true)
			view.diamond(game, center + Vector2(3, -4), radius * 0.23, tint)
		HEAVY_BLOOM:
			for angle: float in [0.0, 1.26, 2.51, 3.77, 5.03]:
				game.draw_circle(center + Vector2.RIGHT.rotated(angle) * radius * 0.33, radius * 0.19, tint)
		WILD_ROOTS:
			game.draw_line(center + Vector2(0, -6), center + Vector2(0, 5), tint, 2.0, true)
			game.draw_line(center, center + Vector2(-5, 5), tint, 2.0, true)
			game.draw_line(center, center + Vector2(5, 5), tint, 2.0, true)
		GOLDEN_BARGAIN:
			game.draw_arc(center, radius * 0.48, 0, TAU, 20, tint, 2.0, true)
			view.diamond(game, center, radius * 0.22, tint)
		FRAGILE_GRACE:
			game.draw_line(center + Vector2(-5, -4), center + Vector2(5, 4), tint, 2.0, true)
			game.draw_line(center + Vector2(5, -4), center + Vector2(-5, 4), tint, 2.0, true)
		_:
			view.diamond(game, center, radius * 0.40, tint)
