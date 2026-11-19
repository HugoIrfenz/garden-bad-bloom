extends RefCounted

const CAMP_HEAL = 18
const LOOT_HEAL = 14
const SHOP_HEAL = 10
const SHOP_TEA_PRICE = 18
const LOOT_RESOURCE = 2

static func room_petals(kind: String, floor_index: int, timed_hunt: bool) -> int:
	var amount := 4 + clampi(floor_index >> 1, 0, 3)
	match kind:
		"boss":
			amount += 8
		"elite", "secret":
			amount += 4
		"challenge":
			if timed_hunt:
				amount += 5
	return amount

static func event_petals(amount: int) -> int:
	return ceili(amount * 0.55) if amount > 0 else amount

static func event_heal(amount: int) -> int:
	return ceili(amount * 0.65)

static func chest_has_tea(kind: String, reward_seed: int) -> bool:
	return kind in ["treasure", "boss"] or posmod(reward_seed, 5) == 0
