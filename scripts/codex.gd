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
	return result

static func entry_id(biome: int, kind: int) -> String:
	return "%d_%d" % [biome, kind]
