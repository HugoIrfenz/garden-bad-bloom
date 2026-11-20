extends RefCounted

const Economy = preload("res://scripts/run_economy.gd")
const CapBoard = preload("res://scripts/cap_board.gd")
const ArcadeCatalog = preload("res://scripts/arcade_catalog.gd")
const Relics = preload("res://scripts/relic_effects.gd")
const Ultimates = preload("res://scripts/hero_ultimates.gd")
const Dungeon = preload("res://scripts/dungeon_generation.gd")
const RunItems = preload("res://scripts/run_items.gd")
const GuestRoster = preload("res://scripts/guest_roster.gd")
const GARDEN_EVENT_KEY = "forgotten_event_id"
const MUSHROOM_EVENT_KEY = "mushroom_event_id"
const CLOCKWORK_EVENT_KEY = "clockwork_event_id"
const BLOODBLOOM_EVENT_KEY = "bloodbloom_event_id"
const ENCOUNTER_PREVIEWS = {
	"challenge": "Timed hunt + loot chest",
	"secret": "Hidden fight + loot chest",
	"elite": "Elite fight + loot chest",
}

const CARDS = [
	{
		"id": "sulking_statue", "title": "The Sulking Statue",
		"prompt": "A carved knight waits for a compliment. Its stone purse is open.",
		"leave": "Ignore the statue",
		"actions": [{"title": "Compliment the statue", "petals": -10, "resource": 2}],
	},
	{
		"id": "suspicious_omelet", "title": "The Suspicious Omelet",
		"prompt": "The omelet smells of butter and wild spores. A vendor makes an offer.",
		"leave": "Leave the omelet",
		"actions": [{"title": "Eat the omelet", "hp": 20, "petals": 4},
			{"title": "Sell it to the vendor", "petals": 18}],
	},
	{
		"id": "mechanical_rose", "title": "Mechanical Rose",
		"prompt": "A brass rose ticks softly. A glass eyelash gleams between its gears.",
		"leave": "Leave the rose",
		"actions": [{"title": "Water the rose", "petals": -14, "relic": Relics.GLASS_EYELASH},
			{"title": "Overwind the mechanism", "hp": -10, "bonus": 2}],
	},
	{
		"id": "crimson_bargain", "title": "Crimson Bargain",
		"prompt": "A merchant displays a silver spoon and a blade-shaped thorn.",
		"leave": "Decline the bargain",
		"actions": [{"title": "Pay the blood price", "hp": -14, "bonus": 2},
			{"title": "Buy the silver spoon", "petals": -24, "relic": Relics.LAST_TEASPOON}],
	},
	{
		"id": "empty_seat", "title": "The Empty Seat",
		"prompt": "One place at the table is set for you. The palace still hums.",
		"leave": "Pass the table",
		"actions": [{"title": "Take the offered seat", "hp": 16},
			{"title": "Stand guard", "resource": 2}],
	},
	{
		"id": "moon_fountain", "title": "Moon Fountain",
		"prompt": "Liquid starlight fills the basin. It pricks the skin like frost.",
		"leave": "Leave the fountain",
		"actions": [{"title": "Drink the starlight", "hp": -8, "resource": 5},
			{"title": "Bottle it for trade", "petals": 14}],
	},
	{
		"id": "familiar_bench", "title": "The Familiar Bench",
		"prompt": "You know the worn wood and the smell of the flowers beside it.",
		"leave": "Pass the bench",
		"actions": [{"title": "Sit and remember", "hp": 23},
			{"title": "Keep walking", "resource": 2}],
	},
]

const GARDEN_ALTERNATIVES = [
	{
		"id": "empty_watering_can", "title": "Empty Watering Can",
		"prompt": "A seed rattles in the old can. Its spout holds a few dry Petals.",
		"leave": "Leave the can alone",
		"actions": [{"title": "Feed the seed a drop of blood", "hp": -11, "bonus": 2},
			{"title": "Shake out the dry Petals", "petals": 8}],
	},
	{
		"id": "sleeping_root", "title": "Sleeping Root",
		"prompt": "A sleeping root curls around a purse. Its bark twitches at every step.",
		"leave": "Let it sleep",
		"actions": [{"title": "Step over and grab the purse", "hp": -9, "petals": 19},
			{"title": "Water the root with Petals", "petals": -9, "resource": 3}],
	},
	{
		"id": "fountain_should_have_known", "title": "Fountain of Should-Have-Known",
		"prompt": "The basin mends scrapes, but its water eats the edge off steel.",
		"leave": "Pass the fountain",
		"actions": [{"title": "Drink from the fountain", "hp": 26, "bonus": -1},
			{"title": "Sell a sealed bottle", "petals": 14}],
	},
]

const MUSHROOM_ALTERNATIVES = [
	{
		"id": "three_caps", "title": "Three Caps in a Row",
		"prompt": "A capkeeper sets out a board. Win a Petal Bomb or +1 damage. Draws refund your stake.",
		"leave": "Pass the capkeeper",
		"actions": [{"title": "Play the capkeeper", "petals": -CapBoard.STAKE, "minigame": CapBoard.EVENT_ID}],
	},
	{
		"id": "cap_inspection", "title": "Cap Inspection",
		"prompt": "A cap blinks. Its handler offers a glass charm, but the spores are free to taste.",
		"leave": "Leave the cap alone",
		"actions": [{"title": "Inspect and buy the charm", "petals": -12, "relic": Relics.GLASS_EYELASH},
			{"title": "Taste a pinch of spores", "hp": -7, "bonus": 2}],
	},
	{
		"id": "spore_poet", "title": "Spore Poet",
		"prompt": "A puffball taps its quill, waiting for a rhyme to finish its poem.",
		"leave": "Keep your rhymes",
		"actions": [{"title": "Recite a stanza", "resource": 3},
			{"title": "Copy the verse for a bookseller", "petals": 13}],
	},
	{
		"id": "moldy_crown", "title": "The Moldy Crown",
		"prompt": "The crown lends strength, but the little teeth inside the band are sharp.",
		"leave": "Leave the crown",
		"actions": [{"title": "Try on the crown", "hp": -15, "bonus": 3},
			{"title": "Polish it for the vendor", "petals": 20}],
	},
]

const CLOCKWORK_ALTERNATIVES = [
	{
		"id": "clock_repair", "title": "Clock Repair",
		"prompt": "The cracked clock's repair kit holds a tonic. A loose gear still spins inside the case.",
		"leave": "Leave the clock ticking",
		"actions": [{"title": "Pay to repair the clock", "petals": -13, "item": "clockwise_tonic"},
			{"title": "Pry out the spinning gear", "hp": -6, "petals": 19}],
	},
	{
		"id": "wrong_bell", "title": "The Wrong Bell",
		"prompt": "The red cord opens a guarded service bay. A little brass seed lies below the bell.",
		"leave": "Leave the bell alone",
		"actions": [{"title": "Ring and enter the service bay", "encounter": "challenge"},
			{"title": "Pocket the brass seed", "petals": 10}],
	},
	{
		"id": "copper_choir_audition", "title": "Copper Choir Audition",
		"prompt": "Three copper songbirds warm up. The singer who powers the chorus wins their silver tuning spoon.",
		"leave": "Let the birds rehearse",
		"actions": [{"title": "Power the chorus", "resource": -2, "relic": Relics.LAST_TEASPOON},
			{"title": "Listen to their warm-up", "resource": 3}],
	},
]

const BLOODBLOOM_ALTERNATIVES = [
	{
		"id": "weeping_flower", "title": "Weeping Flower",
		"prompt": "The blossom takes offerings for its healing sap. Its thorns pulse with stored strength.",
		"leave": "Leave the flower weeping",
		"actions": [{"title": "Offer a pocket item for sap", "hp": 24, "spend_item": true},
			{"title": "Catch a thorn in your palm", "hp": -8, "resource": 4}],
	},
	{
		"id": "quiet_fox", "title": "The Quiet Fox",
		"prompt": "A white fox nudges a wrapped cup toward you, then noses a trail through the briars.",
		"leave": "Watch the fox disappear",
		"actions": [{"title": "Follow its hidden trail", "encounter": "secret"},
			{"title": "Accept the wrapped cup", "item": "royal_teacup"}],
	},
	{
		"id": "leech_doctor", "title": "Leech Doctor",
		"prompt": "The doctor offers a protective ring to donors and keeps clean dressings in reserve.",
		"leave": "Decline treatment",
		"actions": [{"title": "Donate blood for the ring", "hp": -16, "relic": Relics.WEDDING_RING},
			{"title": "Take a clean dressing", "hp": 10}],
	},
	{
		"id": "mourning_picnic", "title": "Mourning Picnic",
		"prompt": "The cake looks delicious and terribly heavy. The host will buy an untouched slice.",
		"leave": "Pass the picnic",
		"actions": [{"title": "Eat a heavy slice", "hp": 29, "resource": -1},
			{"title": "Box a slice for trade", "petals": 16}],
	},
	{
		"id": "ashen_lantern", "title": "Ashen Lantern",
		"prompt": "Cold embers give a gentle warmth. Raising a flame would draw the forest's collector.",
		"leave": "Leave it unlit",
		"actions": [{"title": "Light the lantern", "encounter": "elite"},
			{"title": "Rest beside the embers", "hp": 9, "resource": 2}],
	},
	{
		"id": "widows_thread", "title": "Widow’s Thread",
		"prompt": "Silver silk holds a twitching seedpod. The hunter has strung her web across the trail.",
		"leave": "Leave the silk intact",
		"actions": [{"title": "Cut through and face the hunter", "encounter": "challenge"},
			{"title": "Weave a seedpod bomb", "item": "petal_bomb"}],
	},
]

const EVENT_POOLS = {
	0: {"key": GARDEN_EVENT_KEY, "stream": "forgotten-garden-event:v1", "alternatives": GARDEN_ALTERNATIVES},
	1: {"key": MUSHROOM_EVENT_KEY, "stream": "mushroom-kingdom-event:v1", "alternatives": MUSHROOM_ALTERNATIVES},
	2: {"key": CLOCKWORK_EVENT_KEY, "stream": "clockwork-conservatory-event:v1", "alternatives": CLOCKWORK_ALTERNATIVES},
	3: {"key": BLOODBLOOM_EVENT_KEY, "stream": "bloodbloom-forest-event:v1", "alternatives": BLOODBLOOM_ALTERNATIVES},
}

static func card(biome: int) -> Dictionary:
	return CARDS[clampi(biome, 0, CARDS.size() - 1)]

## Bind on room entry, never on resume. Older open events without a binding
## still show their biome's original card.
static func bind_card(game) -> void:
	if game.room_kind != "event" or not EVENT_POOLS.has(game.active_biome):
		return
	var pool: Dictionary = EVENT_POOLS[game.active_biome]
	var node: Dictionary = game.floor_manifest.get("nodes", {}).get(game.room_id, {})
	if node.is_empty() or node.has(pool.key):
		return
	var scripted_event := str(node.get("event_override", ""))
	if ArcadeCatalog.DATA.has(scripted_event) and scripted_event != ArcadeCatalog.BOARD:
		return
	for alternative: Dictionary in pool.alternatives:
		if alternative.id == scripted_event:
			node[pool.key] = scripted_event
			return
	var seed_value = Dungeon.stream_seed(game.run_seed, game.floor_index, game.room_id, pool.stream)
	var options: Array = pool.alternatives
	if game.active_biome == 1 and not str(game.floor_manifest.get("main_arcade", "")).is_empty():
		options = pool.alternatives.filter(func(option): return option.id != "three_caps")
	var index = posmod(seed_value, options.size() + 1)
	node[pool.key] = CARDS[game.active_biome].id if index == 0 else options[index - 1].id

static func card_for(game) -> Dictionary:
	var node: Dictionary = game.floor_manifest.get("nodes", {}).get(game.room_id, {})
	var arcade_id := ArcadeCatalog.id_for_node(node)
	if arcade_id == ArcadeCatalog.BOARD:
		return MUSHROOM_ALTERNATIVES[0]
	if not arcade_id.is_empty():
		return ArcadeCatalog.card(arcade_id)
	if EVENT_POOLS.has(game.active_biome):
		var pool: Dictionary = EVENT_POOLS[game.active_biome]
		var selected: String = node.get(pool.key, "")
		for option in pool.alternatives:
			if option.id == selected:
				return option
	return card(game.active_biome)

static func preview(game, index: int) -> Dictionary:
	var actions: Array = card_for(game).actions
	if index < 0 or index >= actions.size():
		return {}
	var action: Dictionary = actions[index]
	var hp = int(game.hp)
	var petals = int(game.petals)
	var resource := int(game.resource)
	var bonus = int(game.bonus)
	var hp_delta := int(action.get("hp", 0))
	var heal: int = game.healing_amount(Economy.event_heal(hp_delta), "event") if hp_delta > 0 else hp_delta
	var next_hp := int(hp) + heal
	var next_petals = petals + Economy.event_petals(int(action.get("petals", 0)))
	var resource_delta := int(action.get("resource", 0))
	var luna: bool = game.hero == GuestRoster.LUNA
	var next_resource := resource if luna else mini(resource + resource_delta, Ultimates.CHARGE)
	var next_bonus = bonus + int(action.get("bonus", 0))
	var relic_id = str(action.get("relic", ""))
	var relic = Relics.definition(relic_id)
	var item_id := str(action.get("item", ""))
	var item: Dictionary = RunItems.ITEMS.get(item_id, {})
	var spends_item := bool(action.get("spend_item", false))
	var spent_item := str(game.pocket.held) if spends_item else ""
	var encounter := str(action.get("encounter", ""))
	var starts_encounter := ENCOUNTER_PREVIEWS.has(encounter)
	var minigame := str(action.get("minigame", ""))
	var starts_game := ArcadeCatalog.DATA.has(minigame)
	var starts_hunt := encounter == "challenge"
	var blocked := ""
	if next_hp <= 0:
		blocked = "Requires at least %d HP" % (1 - int(action.get("hp", 0)))
	elif next_petals < 0:
		blocked = "Requires %d Petals" % -int(action.petals)
	elif luna and resource_delta < 0:
		blocked = "Needs class charge"
	elif next_resource < 0:
		blocked = "Requires %d %s" % [-resource_delta, game.RESOURCES[game.hero]]
	elif spends_item and spent_item.is_empty():
		blocked = "Requires an item in your pocket"
	elif not relic.is_empty() and game.relics.has_relic(relic_id):
		blocked = "%s already equipped" % relic.name
	elif not item.is_empty() and not game.pocket.held.is_empty():
		blocked = "Pocket already holds %s" % RunItems.ITEMS[game.pocket.held].name
	elif not starts_encounter and not starts_game and next_hp <= hp and next_petals <= petals and next_resource <= resource \
			and next_bonus <= bonus and relic.is_empty() and item.is_empty():
		if hp_delta > 0:
			blocked = game.curses.healing_block("event")
		elif luna and resource_delta > 0:
			blocked = "Frenzy charges from pistol hits"
		else:
			blocked = "Resource already full"
		if blocked.is_empty():
			blocked = "Already at full HP"

	var terms := PackedStringArray()
	append_delta(terms, next_hp - hp, "HP")
	append_delta(terms, next_petals - petals, "Petals")
	append_delta(terms, next_resource - resource, game.RESOURCES[game.hero])
	append_delta(terms, next_bonus - bonus, "damage")
	if not relic.is_empty():
		terms.append(str(relic.name))
	if not item.is_empty():
		terms.append(str(item.name))
	if not spent_item.is_empty():
		terms.append("Give up %s" % RunItems.ITEMS[spent_item].name)
	if starts_encounter:
		terms.append(ENCOUNTER_PREVIEWS[encounter])
	if starts_game:
		terms.append(str(ArcadeCatalog.DATA[minigame].tag[0]))
	if starts_hunt:
		terms.append("%ds for bonus Petals" % int(game.HUNT_TIME))
	return {"title": action.title, "summary": "  ·  ".join(terms), "reason": blocked,
		"available": blocked.is_empty(), "hp": next_hp, "petals": next_petals,
		"resource": next_resource, "bonus": next_bonus, "relic": relic_id,
		"item": item_id, "spent_item": spent_item, "hunt": starts_hunt,
		"encounter": encounter if starts_encounter else "", "minigame": minigame if starts_game else ""}

static func append_delta(terms: PackedStringArray, delta: int, label: String) -> void:
	if delta != 0:
		var sign = "+" if delta > 0 else "−"
		terms.append("%s%d %s" % [sign, absi(delta), label])

static func apply(game, index: int) -> bool:
	if game.screen != "room_choice" or game.room_kind != "event" or game.room_complete:
		return false
	var result = preview(game, index)
	if result.is_empty() or not result.available:
		return false
	if not result.relic.is_empty() and not game.relics.equip(result.relic):
		return false
	if not result.item.is_empty() and not game.pocket.take(result.item):
		return false
	if not result.spent_item.is_empty():
		game.pocket.held = ""
	game.hp = result.hp
	game.petals = result.petals
	game.resource = result.resource
	game.bonus = result.bonus
	if not result.encounter.is_empty():
		start_encounter(game, result.encounter)
	elif not result.minigame.is_empty():
		game.open_arcade_round(result.minigame)
	return true

static func start_encounter(game, kind: String) -> void:
	game.floor_manifest.nodes[game.room_id].kind = kind
	# Rebuild this node as a combat room without recording a second visit.
	if not game.route_history.is_empty() and game.route_history.back() == game.room_id:
		game.route_history.pop_back()
	game.enter_room()
