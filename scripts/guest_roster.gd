extends RefCounted

const MINA := 5
const WHI := 6
const LUNA := 7
const PRICE := 200
const LUNA_PRICE := 300
const LUNA_UNLOCK := "hero_luna"
const OFFERS := {"hero_mina": MINA, "hero_whi": WHI, "hero_luna": LUNA}
const KEYS := ["hero_mina", "hero_whi", "hero_luna"]
const NAMES := ["Angela", "Vivianne", "Nixia", "Virelia", "Zaria", "Mina", "Whi", "Luna"]
const ROLES := ["Knight / Counterguard", "Witch / Roseweaver", "Brawler / Security Gremlin",
	"Ranger / Camellia Warden", "Rogue / Chaos Painter", "Ramp-up Bruiser", "Stance-Switching Light Caster",
	"Transforming Gunner / Feral Berserker"]
const COLORS := [Color.SKY_BLUE, Color.LAVENDER, Color.MEDIUM_PURPLE, Color.LIGHT_PINK, Color.TURQUOISE,
	Color("#f5a0ab"), Color("#d5b7ff"), Color("#ee9dbd")]
const RELICS := ["temper_bell", "threefold_prism"]
const BIOS := ["Inspired by Uwais", "Inspired by Wahyu", "The Wolfbound Gunner"]
const MODES := ["Holy", "Mercy", "Ray"]
const MODE_COLORS := [Color("#fff0b8"), Color("#c5edab"), Color("#e0c9ff")]
const SEED_HOLD_SECONDS := 10.0
const SEED_GRANT := 500

static func is_guest(hero: int) -> bool:
	return hero >= MINA and hero < NAMES.size()

static func unlock_price(hero: int) -> int:
	return LUNA_PRICE if hero == LUNA else PRICE

static func has_dodge(hero: int) -> bool:
	return hero in [0, 2, 3, 4, LUNA]

static func is_unlocked(profile, hero: int) -> bool:
	return not is_guest(hero) or profile.has_unlock(KEYS[hero - MINA])
