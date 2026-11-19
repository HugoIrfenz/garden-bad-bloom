extends RefCounted

const THORN_EDGE = "thorn_edge"
const QUICKSTEP = "quickstep"
const QUICKHANDS = "quickhands"
const WILDSTRIDE = "wildstride"
const PETAL_AEGIS = "petal_aegis"
const FIRST_BLOOM = "first_bloom"
const STEADY_SPELL = "steady_spell"
const VELVET_PURSE = "velvet_purse"
const AEGIS_FLASH_TIME = 0.28
const PETAL_PAYOUT = 12
const BASE_POOL = [THORN_EDGE, QUICKSTEP, QUICKHANDS, WILDSTRIDE, PETAL_AEGIS, FIRST_BLOOM, STEADY_SPELL]
const CATALOG = {
	THORN_EDGE: {"name": "Thorn Edge", "rarity": "uncommon", "kind": "Upgrade",
		"effect": "+2 damage for this run", "cap": 4, "weight": 3},
	QUICKSTEP: {"name": "Quickstep", "rarity": "uncommon", "kind": "Upgrade",
		"effect": "−6% dodge recovery", "cap": 3, "weight": 3},
	QUICKHANDS: {"name": "Quickhands", "rarity": "uncommon", "kind": "Upgrade",
		"effect": "−7% basic attack recovery", "cap": 3, "weight": 3},
	WILDSTRIDE: {"name": "Wildstride", "rarity": "common", "kind": "Upgrade",
		"effect": "+5% walking speed", "cap": 3, "weight": 4},
	PETAL_AEGIS: {"name": "Petal Aegis", "rarity": "rare", "kind": "Upgrade",
		"effect": "First hit each fight: −5 damage", "cap": 2, "weight": 2},
	FIRST_BLOOM: {"name": "First Bloom", "rarity": "rare", "kind": "Upgrade",
		"effect": "Enter each fight with +1 charge", "cap": 2, "weight": 2},
	STEADY_SPELL: {"name": "Steady Spell", "rarity": "uncommon", "kind": "Upgrade",
		"effect": "−6% skill recovery", "cap": 3, "weight": 3},
	VELVET_PURSE: {"name": "Velvet Purse", "rarity": "rare", "kind": "Utility",
		"effect": "Gain 12 Petals now", "cap": 0, "weight": 1},
}

var _ranks: Dictionary = {}
var _order: Array[String] = []
var _offered: Array[String] = []
var _hostile_room := false
var _aegis_spent := false
var aegis_flash := 0.0


func reset() -> void:
	_ranks.clear()
	_order.clear()
	_offered.clear()
	_hostile_room = false
	_aegis_spent = false
	aegis_flash = 0.0


func enter_room(hostile: bool) -> int:
	_hostile_room = hostile
	_aegis_spent = false
	aegis_flash = 0.0
	_offered.clear()
	return rank(FIRST_BLOOM) if hostile else 0


func snapshot() -> Dictionary:
	return {"ranks": _ranks.duplicate(), "order": _order.duplicate(), "offered": _offered.duplicate(),
		"hostile_room": _hostile_room, "aegis_spent": _aegis_spent, "aegis_flash": aegis_flash}


func restore(raw: Variant, hero: int) -> void:
	reset()
	if not raw is Dictionary:
		return
	var ranks: Variant = raw.get("ranks")
	if ranks is Dictionary:
		for id: String in BASE_POOL:
			if not compatible(id, hero):
				continue
			var count := clampi(int(ranks.get(id, 0)), 0, int(CATALOG[id].cap))
			if count > 0:
				_ranks[id] = count
	append_saved_ids(_order, raw.get("order"), _ranks.keys(), BASE_POOL.size())
	for id: String in BASE_POOL:
		if _ranks.has(id) and id not in _order:
			_order.append(id)
	var eligible := []
	for id: String in CATALOG.keys():
		if can_take(id, hero):
			eligible.append(id)
	append_saved_ids(_offered, raw.get("offered"), eligible, 2)
	_hostile_room = bool(raw.get("hostile_room", false))
	_aegis_spent = bool(raw.get("aegis_spent", false))
	aegis_flash = clampf(float(raw.get("aegis_flash", 0.0)), 0.0, AEGIS_FLASH_TIME)


static func append_saved_ids(target: Array[String], raw: Variant, allowed: Array, limit: int) -> void:
	if not raw is Array:
		return
	for id: Variant in raw:
		if id is String and id in allowed and id not in target:
			target.append(id)
			if target.size() >= limit:
				return


func card(id: String) -> Dictionary:
	var data: Dictionary = CATALOG.get(id, {})
	if data.is_empty():
		return {}
	var result := data.duplicate()
	result.id = id
	result.rank = rank(id)
	result.action = "Pack Petals" if id == VELVET_PURSE else "Take upgrade"
	return result


func entries() -> Array[String]:
	return _order.duplicate()


func rank(id: String) -> int:
	return int(_ranks.get(id, 0))


func active_effect(id: String) -> String:
	var quantity := rank(id)
	match id:
		THORN_EDGE: return "+%d damage" % (2 * quantity)
		QUICKSTEP: return "−%d%% dodge recovery" % (6 * quantity)
		QUICKHANDS: return "−%d%% basic attack recovery" % (7 * quantity)
		WILDSTRIDE: return "+%d%% walking speed" % (5 * quantity)
		PETAL_AEGIS: return "First hit each fight: −%d damage" % (5 * quantity)
		FIRST_BLOOM: return "+%d charge entering each fight" % quantity
		STEADY_SPELL: return "−%d%% skill recovery" % (6 * quantity)
	return ""


static func compatible(id: String, hero: int) -> bool:
	return id != STEADY_SPELL or hero != 0


func can_take(id: String, hero: int) -> bool:
	if not CATALOG.has(id) or not compatible(id, hero):
		return false
	return id == VELVET_PURSE or rank(id) < int(CATALOG[id].cap)


func offers() -> Array[String]:
	return _offered.duplicate()


func clear_offers() -> void:
	_offered.clear()


func prepare_offers(seed_value: int, hero: int, slots: int, depth: int,
		legacy := false, old_open_chest := false) -> void:
	if not _offered.is_empty():
		return
	if (legacy or old_open_chest) and can_take(THORN_EDGE, hero):
		_offered.append(THORN_EDGE)
	if old_open_chest and not _offered.is_empty():
		return
	var pool: Array[String] = []
	for id: String in BASE_POOL:
		if id not in _offered and can_take(id, hero):
			pool.append(id)
	if depth >= 4 or pool.size() + _offered.size() < slots:
		pool.append(VELVET_PURSE)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	while _offered.size() < clampi(slots, 1, 2) and not pool.is_empty():
		var picked := draw_weighted(pool, rng)
		_offered.append(picked)
		pool.erase(picked)
	if _offered.is_empty():
		_offered.append(VELVET_PURSE)


static func draw_weighted(pool: Array[String], rng: RandomNumberGenerator) -> String:
	var total := 0
	for id: String in pool:
		total += int(CATALOG[id].weight)
	var roll := rng.randi_range(1, total)
	for id: String in pool:
		roll -= int(CATALOG[id].weight)
		if roll <= 0:
			return id
	return pool[0]


func take(id: String, hero: int) -> bool:
	if id not in _offered or not can_take(id, hero):
		return false
	if id != VELVET_PURSE:
		if rank(id) == 0:
			_order.append(id)
		_ranks[id] = rank(id) + 1
	_offered.clear()
	return true


func dodge_factor() -> float:
	return 1.0 - 0.06 * rank(QUICKSTEP)


func attack_factor() -> float:
	return 1.0 - 0.07 * rank(QUICKHANDS)


func movement_factor() -> float:
	return 1.0 + 0.05 * rank(WILDSTRIDE)


func skill_factor(hero: int) -> float:
	return 1.0 if hero == 0 else 1.0 - 0.06 * rank(STEADY_SPELL)


func aegis_ready() -> bool:
	return _hostile_room and not _aegis_spent and rank(PETAL_AEGIS) > 0


func absorb_first_hit(amount: int) -> int:
	if not aegis_ready() or amount <= 1:
		return amount
	_aegis_spent = true
	aegis_flash = AEGIS_FLASH_TIME
	return maxi(1, amount - 5 * rank(PETAL_AEGIS))


func tick(delta: float) -> void:
	aegis_flash = maxf(0.0, aegis_flash - delta)
