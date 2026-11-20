extends RefCounted

const Catalog = preload("res://scripts/weapon_catalog.gd")
const RECIPES = {
	0: {"id": "rosewall_execution", "name": "Rosewall Execution",
		"description": "A perfected guard opens a broader thorn fan and primes a rose sweep. The forged blade replaces your current weapon.",
		"ingredients": [{"id": "relic_thornmail", "chapter": 0}, {"id": "guardians_ledger", "chapter": 2}],
		"mastery": 3},
	1: {"id": "elegy_spiral", "name": "Elegy Spiral",
		"description": "Curving shots leave ink. Two overlapping traces, from shots or spells, form a well that gathers foes and bursts. The forged grimoire replaces your current weapon.",
		"ingredients": [{"id": "rosebound_refrain", "chapter": 1}, {"id": "black_rose_ink", "chapter": 3}],
		"mastery": 0},
	2: {"id": "orchid_overclock", "name": "Orchid Overclock",
		"description": "Land punches on three adjacent beats to widen the next Security Breach. These gauntlets replace your current weapon.",
		"ingredients": [{"id": "orchid_punch_card", "chapter": 1}, {"id": "metronome_heart", "chapter": 2}], "mastery": 0},
	3: {"id": "tidy_disaster", "name": "Tidy Disaster",
		"description": "Each triggered tripwire fires one arrow sweep along the thread. The forge upgrades the equipped Snarewood Bow.",
		"ingredients": [{"id": "snarewood_bow", "chapter": 1, "kind": "weapon"},
			{"id": "sewing_thread", "chapter": 1, "kind": "talent"}], "mastery": 0},
	4: {"id": "colorstorm_path", "name": "Colorstorm Path",
		"description": "Every third landed attack paints. Dodge toward a Painted Exit with live paint to burst at the marker. These daggers replace your current weapon.",
		"ingredients": [{"id": "glitter_crime", "chapter": 1}, {"id": "painted_exit", "chapter": 2}], "mastery": 0},
}

static func recipe_for(hero: int) -> Dictionary:
	return RECIPES.get(hero, {})

static func weapon_id(hero: int) -> String:
	return str(recipe_for(hero).get("id", ""))

static func chapter_ingredient(hero: int, index: int) -> String:
	for ingredient: Dictionary in recipe_for(hero).get("ingredients", []):
		if ingredient.chapter == index and ingredient.get("kind", "relic") == "relic":
			return ingredient.id
	return ""

static func chapter_weapon(hero: int, index: int) -> String:
	for ingredient: Dictionary in recipe_for(hero).get("ingredients", []):
		if ingredient.chapter == index and ingredient.get("kind", "") == "weapon":
			return ingredient.id
	return ""

static func requirement(game, ingredient: Dictionary, current: String) -> Dictionary:
	var id: String = ingredient.id
	var biome_name: String = game.BIOMES[int(ingredient.chapter)]
	match str(ingredient.get("kind", "relic")):
		"weapon":
			return {"id": id, "name": Catalog.item(id).name, "ready": current == id,
				"detail": "Equipped" if current == id else biome_name + " treasure chest"}
		"talent":
			var learned: bool = game.talents.owns(id)
			return {"id": id, "name": game.RunTalents.definition(id).get("name", id), "ready": learned,
				"detail": "Learned" if learned else biome_name + " exit talent"}
	var item: Dictionary = game.Relics.definition(id)
	var owned: bool = game.relics.has_relic(id)
	return {"id": id, "name": item.get("name", id), "ready": owned,
		"detail": "In this run" if owned else biome_name + " boss chest"}

static func offer(game) -> Dictionary:
	var recipe := recipe_for(game.hero)
	if recipe.is_empty():
		return {}
	var requirements: Array[Dictionary] = []
	var ready := true
	var current: String = game.armory.for_hero(game.hero)
	for ingredient: Dictionary in recipe.ingredients:
		var row := requirement(game, ingredient, current)
		if current == recipe.id and ingredient.get("kind", "") == "weapon":
			row.ready = true
			row.detail = "Used to forge this weapon"
		ready = ready and row.ready
		requirements.append(row)
	var goal := int(recipe.mastery)
	if goal > 0:
		var count: int = game.relics.royal_guard_mastery
		ready = ready and count >= goal
		requirements.append({"id": "mastery", "name": "Royal Guard mastery",
			"ready": count >= goal, "detail": "%d / %d perfect guards" % [mini(count, goal), goal]})
	var reason := ""
	if current == recipe.id:
		reason = "Evolution already equipped"
	elif not ready:
		reason = "Gather the missing requirements"
	return {"id": recipe.id, "name": recipe.name, "description": recipe.description, "requirements": requirements,
		"current": Catalog.item(current).name, "can_evolve": reason.is_empty(), "reason": reason}

