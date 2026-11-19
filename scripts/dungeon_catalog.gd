extends RefCounted

## The authored room IDs are persistent save keys. Layouts share structural families,
## while the mechanic ID links each room to its own terrain or encounter feature.
const ROOMS = [
	[
		["petal_courtyard", "Petal Courtyard", ["combat", "challenge"], "courtyard", "root_grapple"],
		["broken_fountain", "Broken Fountain", ["combat", "treasure"], "centerpiece", "dry_fountain"],
		["hedge_maze", "Hedge Maze", ["combat", "elite", "secret"], "hedges", "hedge_collapse"],
		["sunken_greenhouse", "Sunken Greenhouse", ["combat", "elite"], "glass", "glass_shatter"],
		["compost_bridge", "Compost Bridge", ["combat", "challenge"], "crossing", "compost_crossing"],
		["picnic_disaster", "Picnic Disaster", ["shop", "event"], "banquet", "sliding_table"],
		["flowerbed_siege", "Flowerbed Siege", ["combat", "elite", "challenge"], "orchard", "thorn_carpet"],
		["first_gate", "The First Gate", ["transition", "rest", "curse", "boss"], "gate", "gardener_arena"],
	],
	[
		["fungal_crossroad", "Fungal Crossroad", ["combat", "transition"], "courtyard", "spore_vent"],
		["spore_nursery", "Spore Nursery", ["treasure", "combat"], "orchard", "puff_fuse"],
		["knife_orchard", "Knife Orchard", ["elite", "combat"], "hedges", "knife_ambush"],
		["glowpool", "Glowpool", ["challenge", "combat"], "crossing", "rot_pool"],
		["queens_pantry", "Queen’s Pantry", ["shop", "rest"], "banquet", "pantry_stalls"],
		["mycelium_bridge", "Mycelium Bridge", ["challenge", "secret"], "crossing", "mycelium_bridge"],
		["gilled_choir", "The Gilled Choir", ["event", "curse", "elite"], "glass", "gilled_bell"],
		["royal_audience", "Royal Audience", ["transition", "boss"], "gate", "moldy_majesty_arena"],
	],
	[
		["clockface_atrium", "Clockface Atrium", ["combat", "challenge"], "centerpiece", "clock_sector"],
		["gear_orchard", "Gear Orchard", ["combat", "elite"], "orchard", "gear_rail"],
		["brass_lift", "Brass Lift", ["combat", "transition"], "gate", "brass_lift"],
		["greenhouse_rails", "Greenhouse Rails", ["combat", "challenge"], "glass", "gear_rail"],
		["steam_pantry", "Steam Pantry", ["shop", "rest", "event"], "banquet", "steam_piston"],
		["ticking_nursery", "Ticking Nursery", ["combat", "elite"], "hedges", "seedling_hatch"],
		["lost_workshop", "Lost Workshop", ["treasure", "secret", "curse"], "courtyard", "conveyor_belt"],
		["bell_tower", "Bell Tower", ["boss"], "crossing", "bell_weight"],
	],
	[
		["redroot_corridor", "Redroot Corridor", ["combat", "elite"], "hedges", "crimson_thread"],
		["moonlit_clearing", "Moonlit Clearing", ["combat", "rest"], "orchard", "scarlet_lantern"],
		["leech_pond", "Leech Pond", ["combat", "challenge"], "crossing", "leech_slick"],
		["poppy_cathedral", "Poppy Cathedral", ["elite", "event"], "centerpiece", "drowsy_poppies"],
		["widow_crossing", "Widow Crossing", ["combat", "secret"], "glass", "severable_web"],
		["antler_path", "Antler Path", ["challenge", "transition"], "gate", "antler_lane"],
		["candle_grove", "Candle Grove", ["shop", "treasure"], "courtyard", "blood_mist"],
		["weeping_altar", "Weeping Altar", ["curse", "boss"], "banquet", "lifedrain_petal"],
	],
	[
		["broken_ballroom", "Broken Ballroom", ["combat", "elite"], "glass", "mirror_ray"],
		["royal_kitchen", "Royal Kitchen", ["combat", "shop"], "orchard", "boiling_tea"],
		["long_table", "The Long Table", ["combat", "rest"], "banquet", "table_slide"],
		["chandelier_hall", "Chandelier Hall", ["combat", "challenge"], "gate", "falling_chandelier"],
		["lost_library", "Lost Library", ["event", "secret", "treasure"], "hedges", "hidden_bookshelf"],
		["velvet_stage", "Velvet Stage", ["elite", "challenge"], "crossing", "curtain_pull"],
		["guest_rooms", "Guest Rooms", ["transition", "curse"], "courtyard", "dance_tiles"],
		["final_tea_table", "Final Tea Table", ["boss"], "centerpiece", "flying_saucer"],
	],
	[
		["starfield_patio", "Starfield Patio", ["combat", "transition"], "courtyard", "starfall"],
		["orbit_chamber", "Orbit Chamber", ["combat", "elite"], "centerpiece", "orbit_laser"],
		["glass_bridge", "Glass Bridge", ["challenge", "secret"], "crossing", "glass_fall_zones"],
		["zero_gravity_bed", "Zero Gravity Bed", ["combat", "event"], "orchard", "low_gravity"],
		["constellation_conservatory", "Constellation Conservatory", ["combat", "boss"], "glass", "constellation_lines"],
		["lunar_aquarium", "Lunar Aquarium", ["rest", "shop"], "banquet", "drifting_drops"],
		["black_flower_planetarium", "Black Flower Planetarium", ["elite", "curse", "treasure"], "hedges", "gravity_well"],
		["moon_orchard", "Moon Orchard", ["challenge", "combat"], "gate", "moonphase_floor"],
	],
	[
		["memory_of_home", "Memory of Home", ["transition", "rest"], "courtyard", "central_flower_path"],
		["five_portrait_hall", "Five Portrait Hall", ["combat", "elite"], "orchard", "echo_stations"],
		["broken_promise_bridge", "Broken Promise Bridge", ["event", "challenge"], "crossing", "promise_bridge"],
		["wish_machine_vault", "Wish Machine Vault", ["combat", "elite", "treasure"], "glass", "wish_generators"],
		["little_goodbye", "Little Goodbye", ["shop", "rest"], "banquet", "hero_dialogue"],
		["rooted_atrium", "Rooted Atrium", ["combat", "secret"], "hedges", "shifting_arches"],
		["almost_home", "Almost Home", ["curse", "transition"], "gate", "capstone_shrine"],
		["bloomheart", "The Bloomheart", ["boss"], "centerpiece", "bloomheart_core"],
	],
]

## Coordinates identify hard-cover centers on the shared landscape design canvas.
## Rendering and collisions can attach the appropriate biome props to these anchors.
const COVER_FORMS = {
	"courtyard": [Vector2(180, 158), Vector2(685, 158), Vector2(180, 268), Vector2(685, 268)],
	"centerpiece": [Vector2(432, 210), Vector2(246, 268), Vector2(618, 268)],
	"hedges": [Vector2(275, 203), Vector2(337, 214), Vector2(539, 214), Vector2(601, 203)],
	"glass": [Vector2(195, 203), Vector2(432, 181), Vector2(655, 232)],
	"crossing": [Vector2(277, 158), Vector2(277, 253), Vector2(590, 158), Vector2(590, 253)],
	"banquet": [Vector2(271, 204), Vector2(594, 204)],
	"orchard": [Vector2(199, 174), Vector2(380, 228), Vector2(652, 176)],
	"gate": [Vector2(241, 160), Vector2(623, 160)],
	"open": [],
}

static func available(biome: int, kind: String) -> Array:
	var candidates: Array = []
	for entry in ROOMS[biome]:
		if kind in entry[2]:
			candidates.append(entry)
	return candidates
