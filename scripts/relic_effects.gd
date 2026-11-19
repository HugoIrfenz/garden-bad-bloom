extends RefCounted

const OrchidRhythm = preload("res://scripts/orchid_rhythm.gd")

const WEDDING_RING = "angela_wedding_ring"
const FEATHER_CROWN = "feather_crown"
const HONEST_EYES = "honest_eyes"
const TRUFFLE_SATCHEL = "truffle_satchel"
const BRASSWING_PIN = "brasswing_pin"
const SECOND_CHANCE_DIAL = "second_chance_dial"
const THORN_VEIL = "thorn_veil"
const CHOIR_ANTLER = "choir_antler"
const PRINCES_PIN = "princes_pin"
const VELVET_RIBBON = "velvet_ribbon"
const TWIN_MOON_PENDANT = "twin_moon_pendant"
const SIXTH_SEAT_TRINKET = "sixth_seat_trinket"
const NEBULA_INDEX = "nebula_index"
const MOTHERCAP_VEIL = "mothercap_veil"
const ROSE_LENS = "rose_lens"
const ORCHID_SPRING = "orchid_spring"
const CAMELLIA_RIBBON = "camellia_ribbon"
const IRIS_DICE = "iris_dice"
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
	SIXTH_SEAT_TRINKET: {"name": "Sixth Seat Trinket", "rarity": "rare", "detail": "Your first ultimate each floor restores up to 6 HP."},
	NEBULA_INDEX: {"name": "Nebula Index", "rarity": "rare", "detail": "Active skills recharge in 10% less time."},
	TWIN_MOON_PENDANT: {"name": "Twin Moon Pendant", "rarity": "rare", "detail": "Every fourth basic attack that lands adds 5 damage on its first landed hit."},
	VELVET_RIBBON: {"name": "Velvet Ribbon", "rarity": "rare", "detail": "The first damaging hit taken each hostile room grants +15% movement speed for 2 seconds."},
	PRINCES_PIN: {"name": "Prince’s Pin", "rarity": "rare", "detail": "The first landed basic hit each hostile room deals 8 extra damage."},
	CHOIR_ANTLER: {"name": "Choir Antler", "rarity": "rare", "detail": "Deal 10% more hit damage to enemies in recovery or stunned."},
	THORN_VEIL: {"name": "Thorn Veil", "rarity": "rare", "detail": "Reduces Root duration by 30%."},
	SECOND_CHANCE_DIAL: {"name": "Second Chance Dial", "rarity": "rare", "detail": "The first damaging hit each room cuts your remaining dodge cooldown by 0.6 seconds."},
	BRASSWING_PIN: {"name": "Brasswing Pin", "rarity": "rare", "detail": "Basic attacks deal 10% more damage for 2 seconds after a skill."},
	TRUFFLE_SATCHEL: {"name": "Truffle Satchel", "rarity": "rare", "detail": "Gain 2 additional Petals on each hostile room clear."},
	HONEST_EYES: {"name": "Honest Eyes", "rarity": "rare", "detail": "The first basic hit after each dodge deals +3 damage."},
	FEATHER_CROWN: {"name": "Feather Crown", "rarity": "rare", "detail": "+15% movement speed for 1 second after a dodge."},
	MOTHERCAP_VEIL: {"name": "Mothercap Veil", "rarity": "rare", "detail": "Poison duration is reduced by 30%."},
	ROSE_LENS: {"name": "Rose Lens", "rarity": "uncommon", "detail": "Vivianne's basic projectiles travel 20% farther."},
	ORCHID_SPRING: {"name": "Orchid Spring", "rarity": "uncommon", "detail": "Nixia's skill recharges 20% faster."},
	CAMELLIA_RIBBON: {"name": "Camellia Ribbon", "rarity": "uncommon", "detail": "Virelia moves 10% faster."},
	IRIS_DICE: {"name": "Iris Dice", "rarity": "uncommon", "detail": "Zaria's damaging hits have a 15% chance to deal double damage."},
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
var sixth_seat_spent_floor := -1
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

func skill_cooldown_factor() -> float:
	return 0.9 if has_relic(NEBULA_INDEX) else 1.0

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
	sixth_seat_spent_floor = -1
	pierce_armed = false
	teaspoon_spent = false
	receipt_room = ""
	rose_counter_through = -1
	royal_guard_mastery = 0
	ledger_armed = false
	rosewall_armed = false
	orchid.reset()

func spend_sixth_seat(floor: int) -> bool:
	if not has_relic(SIXTH_SEAT_TRINKET) or floor == sixth_seat_spent_floor:
		return false
	sixth_seat_spent_floor = floor
	return true

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
		"sixth_seat_spent_floor": sixth_seat_spent_floor, "pierce_armed": pierce_armed, "teaspoon_spent": teaspoon_spent, "receipt_room": receipt_room,
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
	sixth_seat_spent_floor = maxi(-1, int(snapshot_data.get("sixth_seat_spent_floor", -1)))
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
