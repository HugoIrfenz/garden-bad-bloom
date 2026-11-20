extends RefCounted

const Relics = preload("res://scripts/relic_effects.gd")
const GuestArt = preload("res://scripts/guest_hero_art.gd")
const GuestRoster = preload("res://scripts/guest_roster.gd")
const EvolutionArt = preload("res://scripts/evolution_art.gd")
const STARTING_GEAR = preload("res://assets/art/items/preparation_gear.png")
const COUNTERCLOCK_ICON = preload("res://assets/art/items/counterclock_locket.png")
const RECEIPT_ICON = preload("res://assets/art/items/honest_receipt.png")
const RECEIPT_REGION = Rect2(169, 157, 882, 891)
const BOSS_RELICS = preload("res://assets/art/items/optional_boss_relics.png")
const LUNA_RELICS = preload("res://assets/art/items/luna_relics.png")
const LUNA_RELIC_REGIONS := {
	Relics.MOONLIT_CARTRIDGE: Rect2(0, 0, 40, 40),
	Relics.WOLFBOUND_CHOKER: Rect2(40, 0, 40, 40),
}
const BOSS_RELIC_REGIONS := {
	Relics.FEATHER_CROWN: Rect2(33, 42, 254, 239),
	Relics.HONEST_EYES: Rect2(329, 21, 282, 272),
	Relics.MOTHERCAP_VEIL: Rect2(653, 47, 271, 248),
	Relics.TRUFFLE_SATCHEL: Rect2(970, 32, 256, 257),
	Relics.BRASSWING_PIN: Rect2(20, 359, 278, 231),
	Relics.SECOND_CHANCE_DIAL: Rect2(342, 326, 219, 279),
	Relics.THORN_VEIL: Rect2(643, 340, 282, 270),
	Relics.CHOIR_ANTLER: Rect2(954, 330, 275, 277),
	Relics.PRINCES_PIN: Rect2(43, 645, 234, 275),
	Relics.VELVET_RIBBON: Rect2(328, 672, 284, 241),
	Relics.TWIN_MOON_PENDANT: Rect2(661, 644, 244, 274),
	Relics.NEBULA_INDEX: Rect2(954, 663, 272, 249),
	Relics.SIXTH_SEAT_TRINKET: Rect2(51, 958, 228, 278),
}
const STARTING_ICONS := {
	Relics.ROSE_LENS: Rect2(929, 525, 351, 277),
	Relics.ORCHID_SPRING: Rect2(497, 510, 332, 314),
	Relics.CAMELLIA_RIBBON: Rect2(1395, 492, 332, 355),
	Relics.IRIS_DICE: Rect2(929, 525, 351, 277),
	Relics.WEDDING_RING: Rect2(497, 510, 332, 314),
	Relics.GLASS_EYELASH: Rect2(929, 525, 351, 277),
	Relics.LAST_TEASPOON: Rect2(1395, 492, 332, 355),
}
const HIGHLIGHTS := {
	Relics.ROSE_LENS: ["Longer projectile range", "Vivianne only"],
	Relics.ORCHID_SPRING: ["20% shorter miss cooldown", "Nixia only"],
	Relics.CAMELLIA_RIBBON: ["Faster movement", "Virelia only"],
	Relics.IRIS_DICE: ["Chance for double damage", "Zaria only"],
	Relics.TEMPER_BELL: ["Build Temper faster", "Mina only"],
	Relics.THREEFOLD_PRISM: ["+2 per Judgment hit", "Whi only"],
	Relics.MOONLIT_CARTRIDGE: ["+2 damage on distant shots", "Luna only"],
	Relics.WOLFBOUND_CHOKER: ["+0.8s in wolf form", "Luna only"],
	Relics.WEDDING_RING: ["Survive a lethal hit", "Once per floor"],
	Relics.GLASS_EYELASH: ["Piercing basic attack", "After a perfect dodge"],
	Relics.LAST_TEASPOON: ["Wider basic attack", "At 1 HP · once per run"],
	Relics.THORNMAIL: ["Launch five thorns", "First perfect guard per cast"],
	Relics.COUNTERCLOCK_LOCKET: ["Reflect a projectile", "One per perfect guard cast"],
	Relics.HONEST_RECEIPT: ["Earn 5 Petals of credit", "Spend it at a later merchant"],
	Relics.GUARDIANS_LEDGER: ["Slash an extra adjacent foe", "After a Royal Guard block"],
	Relics.ROSEBOUND_REFRAIN: ["Verse echoes at half power", "+0.8s skill recovery"],
	Relics.BLACK_ROSE_INK: ["Ink forms a gravity well", "Overlap two spell traces"],
	Relics.ORCHID_PUNCH_CARD: ["Punches release a burst", "Every eighth landed attack"],
	Relics.METRONOME_HEART: ["Prime a Momentum refund", "Land a punch on the beat"],
	Relics.GLITTER_CRIME: ["Flank hits leave paint", "Step in paint for a second slash"],
	Relics.PAINTED_EXIT: ["Dodge back to a return mark", "After Graffiti Cut"],
}
const TRIGGER_NOTES := {
	Relics.WEDDING_RING: "The protection refreshes on the next floor. Another lethal hit on the same floor can end the run.",
	Relics.GLASS_EYELASH: "Dodge through an incoming hit to charge it. Your next basic attack spends the charge even if it misses.",
	Relics.LAST_TEASPOON: "Use a basic attack while still at 1 HP. Healing first delays the trigger. A miss still spends the charge.",
	Relics.THORNMAIL: "Catch a hit while Royal Guard flashes gold. Thorns fire toward the hit.",
	Relics.COUNTERCLOCK_LOCKET: "Requires a projectile. A melee perfect guard cannot reflect an attack.",
	Relics.HONEST_RECEIPT: "The credit is for another merchant. Multiple purchases in one room do not increase it.",
	Relics.GUARDIANS_LEDGER: "A regular or perfect Royal Guard block counts. The extra strike needs a nearby second target.",
	Relics.ROSEBOUND_REFRAIN: "The echo repeats at the spell’s target. The extra recovery applies even if it misses.",
	Relics.BLACK_ROSE_INK: "The well pulls ordinary enemies only. A single trace cannot create a well.",
	Relics.ORCHID_PUNCH_CARD: "Skills and misses do not advance the count. Land eight separate punches to fire the burst.",
	Relics.METRONOME_HEART: "Follow Nixia’s flashing beat ring. Only the next skill that spends Momentum uses the refund.",
	Relics.GLITTER_CRIME: "Strike behind a foe relative to its movement direction. Each paint patch grants one extra slash.",
	Relics.PAINTED_EXIT: "Aim your dodge back toward the temporary mark before it fades. Cover can block the return.",
	Relics.MOONLIT_CARTRIDGE: "Distance is measured from the shot’s starting point to the enemy.",
}
const PANEL = Rect2(113, 50, 638, 299)
const BACK = Rect2(130, 296, 178, 41)
const EQUIP = Rect2(545, 296, 185, 41)
const BRASS = Color("#ecbb84")
const PLUM = Color("#2f2339")

static func icon(id: String) -> Dictionary:
	if LUNA_RELIC_REGIONS.has(id):
		return {"texture": LUNA_RELICS, "icon": LUNA_RELIC_REGIONS[id]}
	var guest_index := GuestRoster.RELICS.find(id)
	if guest_index >= 0:
		return GuestArt.source(GuestRoster.MINA + guest_index, 15)
	if BOSS_RELIC_REGIONS.has(id):
		return {"texture": BOSS_RELICS, "icon": BOSS_RELIC_REGIONS[id]}
	if STARTING_ICONS.has(id):
		return {"texture": STARTING_GEAR, "icon": STARTING_ICONS[id]}
	if id == Relics.COUNTERCLOCK_LOCKET:
		return {"texture": COUNTERCLOCK_ICON, "icon": Rect2(200, 70, 890, 1080)}
	if id == Relics.HONEST_RECEIPT:
		return {"texture": RECEIPT_ICON, "icon": RECEIPT_REGION}
	return EvolutionArt.icon(id)

static func draw_icon(canvas: Node2D, id: String, center: Vector2, diameter: float) -> void:
	var art := icon(id)
	if art.is_empty():
		return
	var source: Rect2 = art.icon
	var size := (source.size * (diameter / maxf(source.size.x, source.size.y))).round()
	canvas.draw_texture_rect_region(art.texture, Rect2((center - size * 0.5).round(), size), source)

static func highlight(id: String, line: int) -> String:
	return HIGHLIGHTS.get(id, ["", ""])[line]

static func pairing(game, id: String, starting := false) -> String:
	match id:
		Relics.WEDDING_RING:
			return "Pair with %s to follow a lethal-hit save with a wider attack." % partner(game, Relics.LAST_TEASPOON, starting)
		Relics.LAST_TEASPOON:
			return "Pair with %s to reach 1 HP by surviving a lethal hit." % partner(game, Relics.WEDDING_RING, starting)
		Relics.THORNMAIL, Relics.COUNTERCLOCK_LOCKET:
			var other := Relics.COUNTERCLOCK_LOCKET if id == Relics.THORNMAIL else Relics.THORNMAIL
			var label := "Iron Bouquet with %s makes reflected bolts plant thorns." % partner(game, other, starting)
			if id == Relics.THORNMAIL:
				label += " Forge Rosewall Execution with %s and 3 perfect guards." % partner(game, Relics.GUARDIANS_LEDGER, starting)
			return label
		Relics.HONEST_RECEIPT:
			var cleaver: bool = game.armory.for_hero(game.hero) == "royal_cleaver"
			var pairing_name := "Royal Cleaver (equipped)" if cleaver else "Royal Cleaver"
			return "With %s, a purchase primes +%d damage for a landed guard counter within two rooms." % [pairing_name, Relics.ROSE_COUNTER_BONUS]
	var recipe: Dictionary = game.WeaponEvolutions.recipe_for(game.hero)
	var ingredient_ids: Array[String] = []
	for ingredient: Dictionary in recipe.get("ingredients", []):
		if ingredient.get("kind", "relic") == "relic":
			ingredient_ids.append(ingredient.id)
	if id in ingredient_ids and ingredient_ids.size() == 2:
		var other: String = ingredient_ids[1] if id == ingredient_ids[0] else ingredient_ids[0]
		var mastery := ", plus three perfect guards" if int(recipe.get("mastery", 0)) > 0 else ""
		return "%s%s, unlocks %s at a rest-room Forge." % [partner(game, other, starting), mastery, recipe.name]
	return ""

static func partner(game, id: String, starting: bool) -> String:
	var item := Relics.definition(id)
	var name: String = item.get("name", id)
	if not starting and game.relics.has_relic(id):
		name += " (carried)"
	return name

static func draw_inspection(game, id: String) -> void:
	var view = game.View
	var item := Relics.definition(id)
	var carried: Array[String] = game.relics.owned
	var owned := id in carried
	game.draw_rect(view.CANVAS, Color(0.11, 0.065, 0.14, 0.67))
	view.frame(game, PANEL, PLUM, BRASS)
	var illustration := Rect2(131, 69, 176, 210)
	view.frame(game, illustration, Color("#f4e2c8"))
	view.centered(game, Rect2(142, 79, 154, 21), "Carried Relic" if owned else "Offered Relic", 16, view.INK, true)
	view.centered(game, Rect2(144, 103, 150, 17), str(item.rarity).capitalize(), 12, view.INK)
	var center := Vector2(219, 165)
	game.draw_circle(center, 39.0, Color("#e6c89c"), true, -1.0, true)
	game.draw_arc(center, 38.0, 0.0, TAU, 42, Color("#bb8b62"), 1.0, true)
	draw_icon(game, id, center, 68.0)
	game.draw_line(Vector2(149, 210), Vector2(289, 210), Color("#be936a"), 1.0)
	var count := carried.size()
	view.centered(game, Rect2(146, 218, 146, 18), "Carrying %d %s" % [count, "relic" if count == 1 else "relics"], 12, view.INK, true)
	for index in mini(count, 4):
		draw_icon(game, carried[index], Vector2(219 + (index - (mini(count, 4) - 1) * 0.5) * 32, 253), 27.0)
	view.text(game, Vector2(329, 101), item.name, 28, view.CREAM, true)
	game.draw_line(Vector2(329, 111), Vector2(725, 111), Color(BRASS, 0.63), 1.0)
	var next_y := draw_section(game, 129.0, "Effect", item.detail)
	var condition: String = TRIGGER_NOTES.get(id, "")
	if not condition.is_empty():
		next_y = draw_section(game, next_y, "Trigger and limit", condition)
	var combination := pairing(game, id)
	if not combination.is_empty():
		draw_section(game, next_y, "Synergy", combination)
	view.button(game, BACK, "Back to Rewards")
	if owned:
		view.frame(game, EQUIP, Color("#382a3e"), view.BRASS)
		view.centered(game, EQUIP, "Already Carried", 16, view.DIM, true)
	else:
		view.centered(game, Rect2(318, 300, 217, 33), "Uses this chest’s reward choice", 12, view.DIM)
		view.button(game, EQUIP, "Equip Relic", true)

static func draw_section(game, y: float, heading: String, description: String) -> float:
	var view = game.View
	view.text(game, Vector2(330, y), heading, 13, BRASS, true)
	y += 16.0
	var lines: Array[String] = game.CodexView.wrap_text(description, ThemeDB.fallback_font, 390.0, 12)
	for line: String in lines:
		view.text(game, Vector2(330, y), line, 12, view.CREAM)
		y += 15.0
	return y + 7.0
