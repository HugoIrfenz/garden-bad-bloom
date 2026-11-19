extends RefCounted

const OrchidRhythm = preload("res://scripts/orchid_rhythm.gd")

const WEDDING_RING = "angela_wedding_ring"
const GLASS_EYELASH = "glass_eyelash"
const LAST_TEASPOON = "last_teaspoon"
const THORNMAIL = "relic_thornmail"
const GUARDIANS_LEDGER = "guardians_ledger"
const ROSEWALL_EXECUTION = "rosewall_execution"
const GUARD_MASTERY_REQUIRED = 3
const COUNTERCLOCK_LOCKET = "counterclock_locket"
const HONEST_RECEIPT = "honest_receipt"
const GLITTER_CRIME = "glitter_crime"
const PAINTED_EXIT = "painted_exit"
const ROSEBOUND_REFRAIN = "rosebound_refrain"
const BLACK_ROSE_INK = "black_rose_ink"
const ORCHID_PUNCH_CARD = OrchidRhythm.PUNCH_CARD
const METRONOME_HEART = OrchidRhythm.METRONOME
const RECEIPT_CREDIT = 5
const ROSE_COUNTER_BONUS = 8
const STATE_VERSION = 1
const RING_GRACE = 0.72
const UNIVERSAL_BOSS_RELICS = [WEDDING_RING, GLASS_EYELASH, LAST_TEASPOON, HONEST_RECEIPT]
const ANGELA_BOSS_RELICS = [THORNMAIL, COUNTERCLOCK_LOCKET]
const DEFINITIONS = {
	GLITTER_CRIME: {
		"name": "Glitter Crime", "rarity": "uncommon",
		"detail": "Zaria’s flank hits deal 30% more damage and leave paint. Step into a patch for one small slash.",
	},
	PAINTED_EXIT: {
		"name": "Painted Exit", "rarity": "rare",
		"detail": "Graffiti Cut leaves a return mark. Dodge toward the mark once to return along a clear path.",
	},
	ORCHID_PUNCH_CARD: {
		"name": "Orchid Punch Card", "rarity": "uncommon",
		"detail": "Every eighth basic attack that lands releases a small orchid burst around the target.",
	},
	METRONOME_HEART: {
		"name": "Metronome Heart", "rarity": "rare",
		"detail": "Land a punch as the ring flashes to refund one Momentum on your next skill that spends Momentum.",
	},
	ROSEBOUND_REFRAIN: {
		"name": "Rosebound Refrain", "rarity": "rare",
		"detail": "Vivianne’s Midnight Verse repeats at half power after 0.54 seconds. Skill recharge takes 0.8 seconds longer.",
	},
	BLACK_ROSE_INK: {
		"name": "Black Rose Ink", "rarity": "rare",
		"detail": "Vivianne’s spells leave ink traces. Two overlapping traces form a short gravity well that draws ordinary enemies inward.",
	},
	HONEST_RECEIPT: {
		"name": "Honest Receipt", "rarity": "uncommon",
		"detail": "Purchases leave a 5-Petal credit for a future merchant. Royal Cleaver unlocks Rose Receipt.",
	},
	COUNTERCLOCK_LOCKET: {
		"name": "Counterclock Locket", "rarity": "rare",
		"detail": "Angela’s perfect guard reflects one projectile per cast at reduced damage.",
	},
	THORNMAIL: {
		"name": "Thornmail", "rarity": "rare",
		"detail": "Angela’s first perfect guard in each cast launches five thorns.",
	},
	GUARDIANS_LEDGER: {
		"name": "Guardian’s Ledger", "rarity": "uncommon",
		"detail": "A block primes Angela’s next landed basic slash to hit one extra adjacent foe.",
	},

	WEDDING_RING: {
		"name": "Angela’s Wedding Ring", "rarity": "rare",
		"detail": "Once per floor, survive a lethal hit at 1 HP and briefly become invulnerable.",
	},
	GLASS_EYELASH: {
		"name": "Glass Eyelash", "rarity": "uncommon",
		"detail": "A perfect dodge lets your next basic shot or slash pierce its target.",
	},
	LAST_TEASPOON: {
		"name": "Last Teaspoon", "rarity": "uncommon",
		"detail": "Once per run at 1 HP, your next basic attack reaches a wider cone.",
	},
}

var owned: Array[String] = []
var ring_spent_floor = -1
var pierce_armed = false
var teaspoon_spent = false
var receipt_room := ""
var rose_counter_through := -1
var royal_guard_mastery := 0
var ledger_armed := false
var rosewall_armed := false
var orchid := OrchidRhythm.new()

static func definition(relic_id: String) -> Dictionary:
	return DEFINITIONS.get(relic_id, {}).duplicate()

static func boss_rotates(relic_id: String, hero: int) -> bool:
	return relic_id in UNIVERSAL_BOSS_RELICS or (hero == 0 and relic_id in ANGELA_BOSS_RELICS)

func boss_offer(seed_value: int, hero: int = -1) -> String:
	var available: Array = UNIVERSAL_BOSS_RELICS.duplicate()
	if hero == 0:
		available.append_array(ANGELA_BOSS_RELICS)
	var candidates: Array[String] = []
	for relic_id in available:
		if not has_relic(relic_id):
			candidates.append(relic_id)
	if candidates.is_empty():
		return ""

	var weight_sum = 0
	for relic_id in candidates:
		weight_sum += offer_weight(relic_id)
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var roll = rng.randi_range(1, weight_sum)
	for relic_id in candidates:
		roll -= offer_weight(relic_id)
		if roll <= 0:
			return relic_id
	return ""

static func offer_weight(relic_id: String) -> int:
	return 1 if DEFINITIONS[relic_id].rarity == "rare" else 3

func equip(relic_id: String) -> bool:
	if not DEFINITIONS.has(relic_id) or has_relic(relic_id):
		return false
	owned.append(relic_id)
	return true

func has_relic(relic_id: String) -> bool:
	return relic_id in owned

func iron_bouquet_active() -> bool:
	return has_relic(THORNMAIL) and has_relic(COUNTERCLOCK_LOCKET)

func receipt_credit(room_id: String) -> int:
	return RECEIPT_CREDIT if has_relic(HONEST_RECEIPT) and not receipt_room.is_empty() and receipt_room != room_id else 0

func record_sale(room_id: String, depth: int, has_cleaver: bool) -> void:
	if not has_relic(HONEST_RECEIPT) or room_id == receipt_room:
		return
	receipt_room = room_id
	if has_cleaver:
		rose_counter_through = depth + 2

func rose_counter_ready(depth: int) -> bool:
	return has_relic(HONEST_RECEIPT) and rose_counter_through >= depth

func spend_rose_counter() -> void:
	rose_counter_through = -1

func reset() -> void:
	owned.clear()
	ring_spent_floor = -1
	pierce_armed = false
	teaspoon_spent = false
	receipt_room = ""
	rose_counter_through = -1
	royal_guard_mastery = 0
	ledger_armed = false
	rosewall_armed = false
	orchid.reset()

func ring_available(floor_index: int) -> bool:
	return has_relic(WEDDING_RING) and floor_index > ring_spent_floor

## Call only after applying guard and existing invulnerability. The grace is
## additional seconds of invulnerability, measured by the combat controller.
func resolve_damage(hp: int, amount: int, floor_index: int) -> Dictionary:
	var remaining = hp - maxi(0, amount)
	if hp > 0 and remaining <= 0 and ring_available(floor_index):
		ring_spent_floor = floor_index
		return {"hp": 1, "grace": RING_GRACE, "prevented": true}
	return {"hp": remaining, "grace": 0.0, "prevented": false}

## Call when a dash evades a damaging attack. Repeated evasions refresh one
## charge; they cannot stack extra piercing on the next strike.
func on_perfect_dodge() -> void:
	if has_relic(GLASS_EYELASH):
		pierce_armed = true

func on_royal_guard(perfect: bool, evolved := false) -> bool:
	var changed := false
	if has_relic(GUARDIANS_LEDGER) and not ledger_armed:
		ledger_armed = true
		changed = true
	if perfect and royal_guard_mastery < GUARD_MASTERY_REQUIRED:
		royal_guard_mastery += 1
		changed = true
	if perfect and evolved and not rosewall_armed:
		rosewall_armed = true
		changed = true
	return changed

## Consume modifiers only when an attack actually fires. Projectiles should
## retain the returned pierce flag and keep their own set of already-hit foes.
func on_basic_attack(hp: int, rosewall_equipped := false) -> Dictionary:
	var wide_cone = hp == 1 and has_relic(LAST_TEASPOON) and not teaspoon_spent
	var pierce = pierce_armed
	pierce_armed = false
	if wide_cone:
		teaspoon_spent = true
	return {"pierce": pierce, "wide_cone": wide_cone,
		"ledger": ledger_armed, "rosewall": rosewall_armed and rosewall_equipped}

func spend_guard_followthrough(rosewall: bool) -> void:
	ledger_armed = false
	if rosewall:
		rosewall_armed = false

func snapshot() -> Dictionary:
	return {"version": STATE_VERSION, "owned": owned.duplicate(), "ring_spent_floor": ring_spent_floor,
		"pierce_armed": pierce_armed, "teaspoon_spent": teaspoon_spent, "receipt_room": receipt_room,
		"rose_counter_through": rose_counter_through, "royal_guard_mastery": royal_guard_mastery,
		"ledger_armed": ledger_armed, "rosewall_armed": rosewall_armed, "orchid": orchid.snapshot()}

func restore(snapshot_data: Variant) -> bool:
	if not snapshot_data is Dictionary or int(snapshot_data.get("version", 0)) > STATE_VERSION:
		return false
	var relic_ids: Variant = snapshot_data.get("owned", [])
	if not relic_ids is Array:
		return false
	reset()
	for entry in relic_ids:
		if entry is String:
			equip(entry)
	if has_relic(WEDDING_RING):
		ring_spent_floor = maxi(-1, int(snapshot_data.get("ring_spent_floor", -1)))
	pierce_armed = has_relic(GLASS_EYELASH) and bool(snapshot_data.get("pierce_armed", false))
	teaspoon_spent = has_relic(LAST_TEASPOON) and bool(snapshot_data.get("teaspoon_spent", false))
	if has_relic(HONEST_RECEIPT):
		receipt_room = str(snapshot_data.get("receipt_room", ""))
		rose_counter_through = maxi(-1, int(snapshot_data.get("rose_counter_through", -1)))
	royal_guard_mastery = clampi(int(snapshot_data.get("royal_guard_mastery", 0)), 0, GUARD_MASTERY_REQUIRED)
	ledger_armed = has_relic(GUARDIANS_LEDGER) and bool(snapshot_data.get("ledger_armed", false))
	rosewall_armed = bool(snapshot_data.get("rosewall_armed", false))
	orchid.restore(snapshot_data.get("orchid"))
	return true
