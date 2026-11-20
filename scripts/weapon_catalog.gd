extends RefCounted

const STARTERS = ["lilyblade", "rosebound_grimoire", "orchid_gauntlets", "camellia_longbow", "iris_twin_daggers", "hammer_axe", "triune_light_focus", "luna_pistol"]
const STARTER_NAMES = ["Lilyblade", "Rosebound Grimoire", "Orchid Gauntlets", "Camellia Longbow", "Iris Twin Daggers", "Hammer-Axe", "Triune Light Focus", "Glock Pistol"]
const STARTER_DAMAGE = [13, 9, 4, 23, 11, 15, 12, 8]
const STARTER_INTERVAL = [0.38, 0.41, 0.16, 0.68, 0.28, 0.55, 0.66, 0.42]
const STARTER_REACH = [72.0, 167.0, 58.0, 284.0, 72.0, 76.0, 410.0, 180.0]
const STARTER_AIM = [91.0, 171.0, 91.0, 282.0, 91.0, 95.0, 410.0, 189.0]
const STARTER_SPEED = [0.0, 355.0, 0.0, 319.0, 0.0, 0.0, 0.0, 620.0]
const ALTERNATES = [
	["royal_cleaver", "morning_promise"],
	["black_margin", "moonquill_staff"],
	["pocket_thunder", "tiny_hammerfists"],
	["ribbon_string", "hollowglass_bow", "snarewood_bow"],
	["palette_knives", "clockface_shank"],
	[],
	[],
	["graveglass_pistol"],
]
const DEFINITIONS = {
	"rosewall_execution": {"name": "Rosewall Execution", "hero": 0, "damage": 21, "interval": 0.56,
		"reach": 91.0, "aim": 110.0, "rarity": "rare", "tags": ["guard", "thorn", "evolved"],
		"evolved": true, "accent": Color("#efbbcf"), "effect": "Perfect guards prime a rose sweep",
		"detail": "Perfect guards send out a seven-thorn fan and prime a short rose sweep for your next landed basic attack."},
	"elegy_spiral": {"name": "Elegy Spiral", "hero": 1, "damage": 12, "interval": 0.53, "reach": 200.0,
		"aim": 205.0, "speed": 320.0, "rarity": "rare", "tags": ["ink", "arcane", "evolved"],
		"evolved": true, "accent": Color("#daa4f2"), "effect": "Curving bolts leave ink traces",
		"detail": "Curving bolts leave ink traces. Overlapping two traces forms a gravity well and a capped convergence burst."},
	"orchid_overclock": {"name": "Orchid Overclock", "hero": 2, "damage": 5, "interval": 0.24,
		"reach": 61.0, "aim": 92.0, "rarity": "rare", "tags": ["rhythm", "combo", "evolved"],
		"evolved": true, "accent": Color("#e3b4f6"), "effect": "Beat punches widen Security Breach",
		"detail": "Land punches on three adjacent beats to widen the next Security Breach."},
	"snarewood_bow": {"name": "Snarewood Bow", "hero": 3, "damage": 18, "interval": 0.64, "reach": 264.0,
		"aim": 265.0, "speed": 350.0, "rarity": "uncommon", "tags": ["trap", "bow"], "accent": Color("#c2edba"),
		"effect": "Wall hits plant tripwire pins", "detail": "Miss toward two walls to lay a tripwire. It snares the first enemy to cross."},
	"tidy_disaster": {"name": "Tidy Disaster", "hero": 3, "damage": 24, "interval": 0.68, "reach": 285.0,
		"aim": 286.0, "speed": 365.0, "rarity": "rare", "tags": ["trap", "precision", "evolved"],
		"evolved": true, "accent": Color("#bde8bd"), "effect": "Tripwires send an arrow sweep",
		"detail": "Wall pins and linked trap sites lay tripwires. Each crossing triggers one arrow sweep along the thread."},
	"colorstorm_path": {"name": "Colorstorm Path", "hero": 4, "damage": 14, "interval": 0.31,
		"reach": 73.0, "aim": 94.0, "rarity": "rare", "tags": ["paint", "dodge", "evolved"],
		"evolved": true, "accent": Color("#95ecd9"), "effect": "Return through paint for a storm",
		"detail": "Every third landed attack paints. Return to a Painted Exit with live paint to release one storm."},
	"royal_cleaver": {"name": "Royal Cleaver", "hero": 0, "damage": 18, "interval": 0.62, "reach": 85.0, "aim": 99.0,
		"rarity": "rare", "tags": ["heavy", "guard"], "icon_index": 0, "accent": Color("#a6d5ef"),
		"effect": "Heavy hits crack enemy guards", "detail": "A wide, slow cleave applies Guardbreak to a foe after a damaging strike."},
	"black_margin": {"name": "Black Margin", "hero": 1, "damage": 7, "interval": 0.52, "reach": 174.0, "aim": 179.0, "speed": 320.0,
		"rarity": "uncommon", "tags": ["ink", "bleed"], "icon_index": 1, "accent": Color("#c58fd7"),
		"effect": "Ink cuts foe and nearby edges", "detail": "On impact, two short cutting edges apply Bleed to foes along the cross-stroke."},
	"pocket_thunder": {"name": "Pocket Thunder", "hero": 2, "damage": 3, "interval": 0.18, "reach": 60.0, "aim": 91.0,
		"rarity": "uncommon", "tags": ["combo", "arcane"], "icon_index": 2, "accent": Color("#ffe19e"),
		"effect": "Every third clean jab arcs", "detail": "Every third landed basic attack arcs once to a nearby target in the clear."},
	"ribbon_string": {"name": "Ribbon String", "hero": 3, "damage": 19, "interval": 0.56, "reach": 244.0, "aim": 246.0, "speed": 330.0,
		"rarity": "uncommon", "tags": ["mark", "pull"], "icon_index": 3, "accent": Color("#f5a9bd"),
		"effect": "Arrows pull marked foes", "detail": "Hit an already marked ordinary enemy to pull it toward you. Large bosses stay planted."},
	"palette_knives": {"name": "Palette Knives", "hero": 4, "damage": 10, "interval": 0.28, "reach": 68.0, "aim": 91.0,
		"rarity": "uncommon", "tags": ["burn", "chill"], "icon_index": 4, "accent": Color("#a1eddd"),
		"effect": "Hits cycle Burn and Chill", "detail": "Successful strikes alternate between a warm Burn and a slowing Chill."},
	"morning_promise": {"name": "Morning Promise", "hero": 0, "damage": 12, "interval": 0.35, "reach": 69.0, "aim": 91.0,
		"rarity": "uncommon", "tags": ["guard", "light"], "icon_index": 5, "accent": Color("#f9daa0"),
		"effect": "First hit grants a brief ward", "detail": "The first landed hit each room reduces the next incoming hit by 40% within three seconds."},
	"moonquill_staff": {"name": "Moonquill Staff", "hero": 1, "damage": 8, "interval": 0.60, "reach": 204.0, "aim": 214.0, "speed": 245.0,
		"rarity": "rare", "tags": ["arcane", "range"], "icon_index": 6, "accent": Color("#bad3f6"),
		"effect": "Clear orb blooms at full range", "detail": "An unobstructed orb bursts at full range. Direct hits deal damage but stop the orb."},
	"tiny_hammerfists": {"name": "Tiny Hammerfists", "hero": 2, "damage": 7, "interval": 0.34, "reach": 50.0, "aim": 75.0,
		"rarity": "rare", "tags": ["heavy", "collision"], "icon_index": 7, "accent": Color("#edb888"),
		"effect": "Launched foes hit bystanders", "detail": "A heavy punch knocks ordinary foes farther. The first foe in their path takes collateral damage."},
	"hollowglass_bow": {"name": "Hollowglass Bow", "hero": 3, "damage": 19, "interval": 0.72, "reach": 272.0, "aim": 276.0, "speed": 355.0,
		"rarity": "rare", "tags": ["pierce", "glass"], "icon_index": 8, "accent": Color("#cdbaf7"),
		"effect": "Pierces once, then shatters", "detail": "Arrows pass through one foe and shatter on the next. The second hit deals reduced damage."},
	"clockface_shank": {"name": "Clockface Shank", "hero": 4, "damage": 10, "interval": 0.30, "reach": 69.0, "aim": 91.0,
		"rarity": "rare", "tags": ["echo", "rhythm"], "icon_index": 9, "accent": Color("#f9d7a1"),
		"effect": "Every fourth slash echoes", "detail": "Every fourth input leaves an echo that repeats a weaker strike at the original position."},
	"graveglass_pistol": {"name": "Graveglass Pistol", "hero": 7, "damage": 12, "interval": 0.64,
		"reach": 200.0, "aim": 210.0, "speed": 570.0, "rarity": "uncommon", "tags": ["pistol", "wolfbound", "pierce"],
		"accent": Color("#d4b1f3"), "effect": "Second target takes half damage",
		"detail": "Heavier, slower shots pierce once. The second target takes half damage. Each shot adds at most one Frenzy charge."},
}

static func starter(hero: int) -> String:
	return STARTERS[clampi(hero, 0, STARTERS.size() - 1)]

static func usable_by(id: String, hero: int) -> bool:
	return id == starter(hero) or int(DEFINITIONS.get(id, {}).get("hero", -1)) == hero

static func item(id: String) -> Dictionary:
	var hero := STARTERS.find(id)
	if hero >= 0:
		var luna := id == "luna_pistol"
		return {"name": STARTER_NAMES[hero], "hero": hero, "damage": STARTER_DAMAGE[hero], "interval": STARTER_INTERVAL[hero],
			"reach": STARTER_REACH[hero], "aim": STARTER_AIM[hero], "speed": STARTER_SPEED[hero], "rarity": "common",
			"effect": "Pistol hits fill the Frenzy gauge" if luna else "Signature starting weapon",
			"detail": "A quick pistol. Land damaging hits to charge Frenzy Shift." if luna else "The heroine’s signature basic attack."}
	return DEFINITIONS.get(id, {})

static func available(hero: int, equipped: String) -> Array[String]:
	var ids: Array[String] = []
	ids.assign(ALTERNATES[hero])
	ids.erase(equipped)
	return ids
