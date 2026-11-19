extends RefCounted

const Weapons = preload("res://scripts/weapon_catalog.gd")
const Relics = preload("res://scripts/relic_effects.gd")

const SAVE = "user://codex.json"
const BESTIARY = [
	[
		["Grumble Tulip", "Watch for the straight warning lane. Sidestep its lunge and strike while it is uprooted."],
		["Thorn Slug", "Its slime sprouts lingering thorns. When it curls into its shell, attack from behind."],
		["Pea-Shooter Bud", "A fan of three lanes warns of the volley. Weave between them or take cover behind a barrel."],
		["The Gardener That Forgot", "Dodge the shear sweep, step out of the watering marks, and leave yourself space when root lanes multiply."],
		["Hedge Knight", "Its shield protects the front. Bait its lance into cover or blooming thorns, then strike during recovery."],
	],
	[
		["Knife Shroom", "It lifts its blade before committing to a dash. Move off the lane and punish its dizzy recovery."],
		["Puffball Bomber", "Its swelling fuse marks the blast. Get away early or let the explosion catch another enemy."],
		["Spore Butler", "Glowing links mark protected allies. Go around its umbrella and cut off the ward at the source."],
		["His Moldy Majesty", "Read the gaps in his cross-cut and crown toss. Two Knife Shrooms join when his cyclone begins."],
		["Mycelium Leaper", "Watch the landing circle as it crouches. Move toward the takeoff point and punish the landing recovery."],
	],
	[
		["Tin Bee", "It traces a straight course before buzzing through it. Change lanes after it locks on."],
		["Pendulum Mouse", "The tail marks two swings on a steady beat. Wait for the second swing before closing in."],
		["Clockwork Rose", "Its six petals fire in marked directions. Use the spaces between spokes."],
		["The Late Bell", "Watch the clock hand, make room for the bell ring, and mind the change in tempo at half health."],
	],
	[
		["Siphon Moth", "Its wings flare before the dive. Break the attack line to keep it from stealing health."],
		["Hemlock Doe", "Step out of the antler lane. Cover can stop a charge and leave it open to a counter."],
		["Bloom Leech", "Its body stretches before a short leap. If it latches on, use your dodge to break free."],
		["The Weeping Orchard", "Leave the marked lifedrain ground. After the trunk cracks, track the moving red heart."],
		["Thorn Widow", "Destroy her anchors to cut the strands. Each living anchor keeps one crossing dangerous."],
	],
	[
		["Teacup Duelist", "Its saucer curves back to the cup. Stay clear of the returning path before moving in."],
		["Wailing Curtain", "The cloth draws in around the edges. Stay in the center or strike while it is winding up."],
		["Hollow Knight", "Its shield resists frontal blows. Dodge the two-part duel and strike its open side."],
		["Duchess of the Last Tea", "Read the tea fan and steam ring. Watch the returning saucers after her porcelain cracks."],
		["Porcelain Hound", "Its paw scratches the start of a zigzag. Strike the turquoise-marked flank to stop its rush, or let it stumble into cover."],
	],
	[
		["Starseed Wisp", "A slow mote follows you. Lead it into cover and move closer during the pause."],
		["Orbiting Bloom", "Danger spokes rotate around the flower. Move along with the gap."],
		["Mirror Moth", "The first reflection is a feint. Track the marked lane from the real moth."],
		["The Starbound Florist", "Trace the safe space between constellation rays and watch the landing circles of the falling stars."],
	],
	[
		["Wish Husk", "A glowing wish bubble announces its charge. Step sideways when the lane locks in."],
		["Glitch Rose", "Its projectiles switch paths as they travel. Read the marked return angles."],
		["Fractured Root", "The floor splits into a marked grid. Move to a stable tile before the pattern settles."],
		["The Bloomheart, Unraveled", "Destroy all five flower nodes to open the shield. Space out your dodges as the wish machine changes patterns."],
	],
]

var discovered: Dictionary = {}
const OPTIONAL_ENTRIES = {
	5: [["queen_of_two_moons", "Queen of Two Moons", "The center seam protects you from the dark altar’s gravity. At half health the altars swap roles."], ["nebula_librarian", "The Nebula Librarian", "Each shelf sweeps a different angle. Watch the gaps and leave marked pages before they burst."]],
	6: [["empty_sixth_chair", "The Empty Sixth Chair", "Step clear of invitations. When the puppet rises, break both glowing string posts to expose it."]],
	4: [
		["crownless_prince", "The Crownless Prince", "Follow the real shadow. Lure the chandelier onto either mirror to stop its reflections."],
		["madam_black_velvet", "Madam Black Velvet", "Leave the spotlight before it strikes. Once it reveals a puppet, interact beside the string to cut it."],
	],
	3: [
		["bride_of_thorns", "Bride of Thorns", "Tap the ribbon knot while nearby to break it, or step beyond it before it closes. Wait out both thorn lanes after her veil tears, then strike during her recovery."],
		["antlered_choir", "The Antlered Choir", "Interact beside the bells to silence them. Each muted bell shortens the charge after the Choir's chest flower lights up."],
	],
	2: [
		["baroness_brasswing", "Baroness Brasswing", "Step aside from the needle dive and make space for the rotor gust. Destroy both detached drones to expose the core."],
		["unfinished_hour", "The Unfinished Hour", "Leave your previous position behind. A beam can fire twice, and after the clock cracks its mirrored echoes strike in sequence."],
	],
	0: [
		["queen_of_dandelions", "Queen of Dandelions", "Step outside the gust cone and dodge the seed landing circles. After the crown lifts, seeds fly inward."],
		["first_scarecrow", "The First Scarecrow", "Bait the lunge into cover and step away from the marked needle lines. The moving shadow identifies the real Scarecrow."],
	],
	1: [
		["mother_of_spores", "Mother of Spores", "Reach a glowing mushroom before the poison bloom. Check which platforms glow when the wind reverses."],
		["truffle_bandit", "The Truffle Bandit", "Keep clear of the zigzag rush. When the gold magnet ring appears, step outside it before the truffle rolls."],
	],
}
var weapon_discoveries: Dictionary = {}
var relic_discoveries: Dictionary = {}
var dirty = false

func load_local() -> void:
	var file = FileAccess.open(SAVE, FileAccess.READ)
	if file == null:
		return
	var saved = JSON.parse_string(file.get_as_text())
	if saved is Dictionary and saved.get("discovered") is Dictionary:
		discovered = saved.discovered
		var weapons: Variant = saved.get("weapons", {})
		if weapons is Dictionary:
			weapon_discoveries = weapons
		var relics: Variant = saved.get("relics", {})
		if relics is Dictionary:
			relic_discoveries = relics

func knows_weapon(id: String) -> bool:
	return id in Weapons.STARTERS or bool(weapon_discoveries.get(id, false))

func observe_weapon(id: String) -> void:
	if Weapons.DEFINITIONS.has(id) and not knows_weapon(id):
		weapon_discoveries[id] = true
		dirty = true
	if dirty:
		save_local()

func knows_relic(id: String) -> bool:
	return bool(relic_discoveries.get(id, false))

func observe_relics(ids: Array) -> void:
	for value: Variant in ids:
		if value is String and Relics.DEFINITIONS.has(value) and not knows_relic(value):
			relic_discoveries[value] = true
			dirty = true
	if dirty:
		save_local()

func observe(foes: Array) -> void:
	for foe: Dictionary in foes:
		if foe.has("optional_boss") and not foe.has("optional_lesson"):
			var optional_id := str(foe.optional_boss)
			if not discovered.has(optional_id):
				discovered[optional_id] = true
				dirty = true
			continue
		var biome = int(foe.get("biome", -1))
		var kind = int(foe.get("kind", -1))
		if biome < 0 or biome >= BESTIARY.size() or kind < 0 or kind >= BESTIARY[biome].size():
			continue
		var id = entry_id(biome, kind)
		if not discovered.has(id):
			discovered[id] = true
			dirty = true
	if dirty:
		save_local()

func save_local() -> void:
	var file = FileAccess.open(SAVE + ".tmp", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"version": 3, "discovered": discovered,
		"weapons": weapon_discoveries, "relics": relic_discoveries}))
	file.close()
	dirty = DirAccess.rename_absolute(SAVE + ".tmp", SAVE) != OK

func entries(biome: int) -> Array:
	var result: Array = []
	if biome < 0 or biome >= BESTIARY.size():
		return result
	for kind in range(BESTIARY[biome].size()):
		var data: Array = BESTIARY[biome][kind]
		result.append({"biome": biome, "kind": kind, "name": data[0], "description": data[1],
			"boss": kind == 3, "discovered": discovered.get(entry_id(biome, kind), false)})
	for data: Array in OPTIONAL_ENTRIES.get(biome, []):
		result.append({"biome": biome, "kind": -1, "optional_boss": data[0], "name": data[1],
			"description": data[2], "boss": true, "discovered": discovered.get(data[0], false)})
	return result

static func entry_id(biome: int, kind: int) -> String:
	return "%d_%d" % [biome, kind]
