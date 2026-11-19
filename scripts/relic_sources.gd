extends RefCounted

const Relics = preload("res://scripts/relic_effects.gd")
const Evolutions = preload("res://scripts/weapon_evolutions.gd")

const STARTERS = [Relics.WEDDING_RING, Relics.GLASS_EYELASH, Relics.LAST_TEASPOON]
const SIGNATURES = ["", Relics.ROSE_LENS, Relics.ORCHID_SPRING, Relics.CAMELLIA_RIBBON, Relics.IRIS_DICE]
const LEDGER_IDS = [
	Relics.SIXTH_SEAT_TRINKET,
	Relics.NEBULA_INDEX,
	Relics.TWIN_MOON_PENDANT,
	Relics.VELVET_RIBBON,
	Relics.PRINCES_PIN,
	Relics.THORN_VEIL,
	Relics.CHOIR_ANTLER,
	Relics.FEATHER_CROWN, Relics.HONEST_EYES, Relics.MOTHERCAP_VEIL, Relics.TRUFFLE_SATCHEL, Relics.BRASSWING_PIN, Relics.SECOND_CHANCE_DIAL,
	Relics.ROSE_LENS, Relics.ORCHID_SPRING, Relics.CAMELLIA_RIBBON, Relics.IRIS_DICE,
	Relics.WEDDING_RING, Relics.GLASS_EYELASH, Relics.LAST_TEASPOON, Relics.HONEST_RECEIPT,
	Relics.THORNMAIL, Relics.COUNTERCLOCK_LOCKET, Relics.GUARDIANS_LEDGER,
	Relics.ROSEBOUND_REFRAIN, Relics.BLACK_ROSE_INK, Relics.ORCHID_PUNCH_CARD, Relics.METRONOME_HEART,
	Relics.GLITTER_CRIME, Relics.PAINTED_EXIT,
]
const TREASURE_RELICS = {
	0: Relics.HONEST_RECEIPT,
	1: Relics.COUNTERCLOCK_LOCKET,
	2: Relics.GLASS_EYELASH,
	3: Relics.LAST_TEASPOON,
}
const BOSS_RELICS = {4: Relics.WEDDING_RING}
const EVENT_SOURCES = {
	Relics.WEDDING_RING: [[3, "Leech Doctor", "donate 16 HP"]],
	Relics.GLASS_EYELASH: [[1, "Cap Inspection", "12 Petals"], [2, "Mechanical Rose", "14 Petals"]],
	Relics.LAST_TEASPOON: [[2, "Copper Choir Audition", "2 class resource"],
		[3, "Crimson Bargain", "24 Petals"]],
}

static func hero_for(id: String) -> int:
	if not id.is_empty() and id in SIGNATURES:
		return SIGNATURES.find(id)
	if id == Relics.COUNTERCLOCK_LOCKET:
		return 0
	for hero_index: int in Evolutions.RECIPES:
		for ingredient: Dictionary in Evolutions.RECIPES[hero_index].ingredients:
			if ingredient.id == id and ingredient.get("kind", "relic") == "relic":
				return hero_index
	return -1

static func can_offer(id: String, hero: int) -> bool:
	if not Relics.DEFINITIONS.has(id):
		return false
	var required_hero := hero_for(id)
	return required_hero == -1 or required_hero == hero

static func treasure_offer(floor_index: int, hero: int, carried: Array[String]) -> String:
	var id: String = TREASURE_RELICS.get(floor_index, "")
	if not can_offer(id, hero) or id in carried or not Evolutions.chapter_weapon(hero, floor_index).is_empty():
		return ""
	return id

static func boss_preference(floor_index: int, hero: int, carried: Array[String]) -> String:
	var milestone := Evolutions.chapter_ingredient(hero, floor_index)
	if can_offer(milestone, hero) and milestone not in carried:
		return milestone
	var id: String = BOSS_RELICS.get(floor_index, "")
	return id if can_offer(id, hero) and id not in carried else ""

static func source_lines(id: String, biomes: Array) -> Array[String]:
	var sources: Array[String] = []
	if id == Relics.SIXTH_SEAT_TRINKET:
		sources.append("Bloomheart Core · The Empty Sixth Chair.")
	elif id == Relics.NEBULA_INDEX:
		sources.append("Astral Greenhouse · The Nebula Librarian.")
	elif id == Relics.TWIN_MOON_PENDANT:
		sources.append("Astral Greenhouse · Queen of Two Moons.")
	elif id == Relics.FEATHER_CROWN:
		sources.append("Forgotten Garden · Queen of Dandelions.")
	elif id == Relics.HONEST_EYES:
		sources.append("Forgotten Garden · The First Scarecrow.")
	elif id == Relics.MOTHERCAP_VEIL:
		sources.append("Mushroom Kingdom · Mother of Spores.")
	elif id == Relics.TRUFFLE_SATCHEL:
		sources.append("Mushroom Kingdom · The Truffle Bandit.")
	elif id == Relics.BRASSWING_PIN:
		sources.append("Clockwork Conservatory · Baroness Brasswing.")
	elif id == Relics.SECOND_CHANCE_DIAL:
		sources.append("Clockwork Conservatory · The Unfinished Hour.")
	elif id == Relics.THORN_VEIL:
		sources.append("Bloodbloom Forest · Bride of Thorns.")
	elif id == Relics.VELVET_RIBBON:
		sources.append("Hollow Palace · Madam Black Velvet.")
	elif id == Relics.PRINCES_PIN:
		sources.append("Hollow Palace · The Crownless Prince.")
	elif id == Relics.CHOIR_ANTLER:
		sources.append("Bloodbloom Forest · The Antlered Choir.")
	if id in STARTERS or id in SIGNATURES:
		sources.append("Choose in Run Preparation.")
	for floor_index: int in TREASURE_RELICS:
		if TREASURE_RELICS[floor_index] == id:
			sources.append("%s · Treasure path chest." % biomes[floor_index])
	for floor_index: int in BOSS_RELICS:
		if BOSS_RELICS[floor_index] == id:
			sources.append("%s · boss chest." % biomes[floor_index])
	var required_hero := hero_for(id)
	for ingredient: Dictionary in Evolutions.recipe_for(required_hero).get("ingredients", []):
		if ingredient.id == id:
			sources.append("%s · boss chest." % biomes[int(ingredient.chapter)])
	for event: Array in EVENT_SOURCES.get(id, []):
		sources.append("%s · %s (%s)." % [biomes[event[0]], event[1], event[2]])
	if Relics.boss_rotates(id, required_hero):
		sources.append("Also a possible drop in boss chests with no fixed relic.")
	return sources

static func combinations(id: String) -> Array[String]:
	var notes: Array[String] = []
	match id:
		Relics.WEDDING_RING:
			notes.append("Last Teaspoon can use the 1 HP left by a lethal-hit save.")
		Relics.LAST_TEASPOON:
			notes.append("Angela’s Wedding Ring can leave you at 1 HP to prime the wider attack.")
		Relics.THORNMAIL, Relics.COUNTERCLOCK_LOCKET:
			var other := Relics.COUNTERCLOCK_LOCKET if id == Relics.THORNMAIL else Relics.THORNMAIL
			notes.append("Iron Bouquet with %s makes reflected bolts plant thorns." % Relics.definition(other).name)
		Relics.HONEST_RECEIPT:
			notes.append("With Royal Cleaver, a purchase primes Rose Receipt for +%d damage on one landed guard counter within two rooms." % Relics.ROSE_COUNTER_BONUS)
	var recipe := Evolutions.recipe_for(hero_for(id))
	var ingredients: Array = recipe.get("ingredients", [])
	if ingredients.size() == 2 and (ingredients[0].id == id or ingredients[1].id == id):
		for ingredient: Dictionary in ingredients:
			if ingredient.id == id:
				continue
			var mastery := int(recipe.get("mastery", 0))
			var forge := "Pair with %s to forge %s at a rest-room Forge." % [Relics.definition(ingredient.id).name, recipe.name]
			if mastery > 0:
				forge += " Land %d perfect guards before forging." % mastery
			notes.append(forge)
	return notes
