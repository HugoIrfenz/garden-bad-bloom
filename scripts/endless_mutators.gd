extends RefCounted

const Dungeon = preload("res://scripts/dungeon_generation.gd")
const Codex = preload("res://scripts/codex.gd")

const VOLATILE = "volatile_corpses"
const CLOCK = "fast_clock"
const HUNT = "big_game_hunting"
const TEA = "tea_time"
const BOUNTY = "bounty_board"
const RULES = [VOLATILE, CLOCK, HUNT, TEA, BOUNTY]
const TITLES = {
	VOLATILE: "Volatile Corpses", CLOCK: "Fast Clock", HUNT: "Big Game Hunting",
	TEA: "Tea Time", BOUNTY: "Bounty Board",
}
const DESCRIPTIONS = {
	VOLATILE: "Fallen enemies fuse before a short-range blast.",
	CLOCK: "Clockwork enemies approach faster. Their attack tells keep their timing.",
	HUNT: "Fewer enemies, stronger gold-marked elites. Each elite pays 9 extra Petals.",
	TEA: "Temporary tea circles shelter anyone inside from damage.",
	BOUNTY: "Each %s defeated pays 5 extra Petals.",
}
const CONFLICTS = {VOLATILE: [HUNT, TEA]}
const MAX_FUSES = 3
const BLAST_RADIUS = 37.0
const TEA_RADIUS = 46.0
const TEA_ACTIVE_SECONDS = 2.55
const TEA_PERIOD = 7.6

var rules: Array[String] = []
var bounty_kind = -1
var bounty_name = ""
var room_seed = 0
var elapsed = 0.0
var tea: Dictionary = {}
var fuses: Array[Dictionary] = []

static func configure_floor(manifest: Dictionary, seed_value: int) -> void:
	if not manifest.get("endless", false) or manifest.has("mutators"):
		return
	var floor = int(manifest.floor_index)
	var biome = int(manifest.biome)
	var rng = Dungeon.seeded(Dungeon.stream_seed(seed_value, floor, "", "endless-mutators"))
	var available: Array[String] = []
	for rule in RULES:
		if rule != CLOCK or biome == 2:
			available.append(rule)
	var selected: Array[String] = []
	var maximum = mini(3, 1 + maxi(0, floor - Dungeon.BIOME_COUNT) / 3)
	var wanted = rng.randi_range(1, maximum)
	while not available.is_empty() and selected.size() < wanted:
		var rule: String = available.pop_at(rng.randi_range(0, available.size() - 1))
		if selected.all(func(previous): return compatible(previous, rule)):
			selected.append(rule)
	manifest.mutators = selected
	manifest.bounty_kind = rng.randi_range(0, 2) if BOUNTY in selected else -1

static func compatible(first: String, second: String) -> bool:
	return first != second and second not in CONFLICTS.get(first, []) and first not in CONFLICTS.get(second, [])

func begin_room(manifest: Dictionary, encounter_seed: int) -> void:
	rules.clear()
	for candidate in manifest.get("mutators", []):
		if candidate in RULES:
			rules.append(candidate)
	bounty_kind = int(manifest.get("bounty_kind", -1))
	bounty_name = ""
	if bounty_kind in [0, 1, 2] and manifest.has("biome"):
		bounty_name = str(Codex.BESTIARY[int(manifest.biome)][bounty_kind][0])
	room_seed = encounter_seed
	elapsed = 0.0
	tea.clear()
	fuses.clear()

func snapshot() -> Dictionary:
	if rules.is_empty():
		return {}
	return {"elapsed": elapsed, "tea": tea, "fuses": fuses}

func restore(data: Variant) -> void:
	if rules.is_empty() or not data is Dictionary:
		return
	elapsed = maxf(0.0, float(data.get("elapsed", 0.0)))
	var saved_tea = data.get("tea", {})
	if saved_tea is Dictionary:
		tea = saved_tea.duplicate()
	var saved_fuses = data.get("fuses", [])
	if saved_fuses is Array:
		fuses.clear()
		for fuse in saved_fuses:
			if fuse is Dictionary and fuse.has("x") and fuse.has("y") and fuse.has("remaining"):
				fuses.append(fuse.duplicate())
				if fuses.size() == MAX_FUSES:
					break

func encounter_count(count: int, kind: String) -> int:
	if HUNT not in rules or count < 2 or kind not in ["combat", "elite", "secret", "challenge"]:
		return count
	return maxi(2 if kind == "elite" else 1, count - 1)

func mark_foe(foe: Dictionary, index: int, kind: String) -> void:
	if bool(foe.boss):
		return
	if HUNT in rules and kind in ["combat", "elite", "secret", "challenge"] and index < (2 if kind == "elite" else 1):
		var health = roundi(float(foe.max) * 1.34)
		foe.hp = health
		foe.max = health
		foe.hunt_elite = true

func is_bounty(foe: Dictionary) -> bool:
	return BOUNTY in rules and int(foe.get("kind", -1)) == bounty_kind

func move_delta(foe: Dictionary, delta: float) -> float:
	# The caller advances the telegraph clock with unscaled time.
	if CLOCK in rules and int(foe.get("phase", -1)) == 0 and int(foe.get("biome", -1)) == 2:
		return delta * 1.24
	return delta

func defeat(game, foe: Dictionary) -> void:
	if rules.is_empty() or foe.get("flower_node", false):
		return
	if foe.get("hunt_elite", false):
		game.petals += 9
	if is_bounty(foe):
		game.petals += 5
	if VOLATILE not in rules or fuses.size() >= MAX_FUSES or bool(foe.boss):
		return
	var point: Vector2 = game.target(foe)
	for existing in fuses:
		if point.distance_squared_to(position(existing)) < 23.0 * 23.0:
			return
	var delay = 1.0 + 0.14 * fuses.size()
	fuses.append({"x": point.x, "y": point.y, "remaining": delay, "duration": delay})

func holds_room() -> bool:
	return not fuses.is_empty()

func tick(game, delta: float) -> void:
	if rules.is_empty():
		return
	for i in range(fuses.size() - 1, -1, -1):
		var fuse: Dictionary = fuses[i]
		fuse.remaining = float(fuse.remaining) - delta
		if float(fuse.remaining) <= 0.0:
			if game.player.distance_squared_to(position(fuse)) <= BLAST_RADIUS * BLAST_RADIUS:
				game.damage_hero(11)
			fuses.remove_at(i)
	if TEA not in rules or game.foes.is_empty():
		tea.clear()
		return
	elapsed += delta
	if elapsed < 2.25:
		return
	var cycle = floori((elapsed - 2.25) / TEA_PERIOD)
	if int(tea.get("cycle", -1)) != cycle:
		place_tea(game, cycle)

func place_tea(game, cycle: int) -> void:
	var arena: Rect2 = game.ARENA
	var area := arena.grow(-TEA_RADIUS - 9.0)
	var rng = Dungeon.seeded(Dungeon.stream_seed(room_seed, cycle, "", "tea-circles"))
	var place := area.get_center()
	for attempt in range(12):
		var candidate = Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		if game.barrels.all(func(barrel): return candidate.distance_squared_to(barrel) > 65.0 * 65.0):
			place = candidate
			break
	tea = {"cycle": cycle, "x": place.x, "y": place.y}

func tea_remaining() -> float:
	if tea.is_empty():
		return 0.0
	return maxf(0.0, TEA_ACTIVE_SECONDS - (elapsed - (2.25 + int(tea.cycle) * TEA_PERIOD)))

func protected_at(point: Vector2) -> bool:
	return tea_remaining() > 0.0 and point.distance_squared_to(position(tea)) <= TEA_RADIUS * TEA_RADIUS

static func position(item: Dictionary) -> Vector2:
	return Vector2(item.x, item.y)

func detail(rule: String) -> String:
	var description = str(DESCRIPTIONS[rule])
	return description % bounty_name if rule == BOUNTY else description

func draw_hud(game) -> void:
	if rules.is_empty() or game.screen != "fight":
		return
	var view = game.View
	if game.room_kind == "transition":
		var preferences = game.preferences
		var floor_number := int(game.floor_index) - Dungeon.BIOME_COUNT + 1
		var mode_name: String = preferences.place_name(game.BIOMES.back())
		var title: String = preferences.text("endless.floor", {"garden": mode_name, "floor": floor_number})
		var biome_name: String = preferences.place_name(game.BIOMES[int(game.active_biome)])
		var panel = Rect2(230, 93, 404, 50 + 41 * rules.size())
		view.frame(game, panel, Color(0.15, 0.11, 0.19, 0.95))
		view.centered(game, Rect2(246, 101, 372, 24), title, 17, view.CREAM, true)
		view.centered(game, Rect2(246, 123, 372, 15), biome_name, 11, view.DIM)
		for index in range(rules.size()):
			var row = float(index) * 41.0 + 150.0
			var rule: String = rules[index]
			view.diamond(game, Vector2(251, row - 5.0), 4.0, Color("#e1b383"))
			view.text(game, Vector2(264, row), TITLES[rule], 13, view.CREAM)
			view.text(game, Vector2(264, row + 16.0), detail(rule), 10, view.DIM)
	elif not game.room_complete:
		var titles = PackedStringArray()
		for rule in rules:
			titles.append(TITLES[rule])
		var strip = Rect2(37, 44, 219, 21) if game.room_kind == "boss" else Rect2(227, 44, 410, 21)
		view.frame(game, strip, Color(0.15, 0.11, 0.19, 0.84))
		view.centered(game, strip, "  ·  ".join(titles), 11, view.CREAM)

func draw_field(game) -> void:
	var canvas: Node2D = game.world_canvas
	for fuse in fuses:
		var center = position(fuse)
		var progress = clampf(1.0 - float(fuse.remaining) / float(fuse.duration), 0.0, 1.0)
		canvas.draw_circle(center, BLAST_RADIUS, Color(0.89, 0.29, 0.19, 0.23), true, -1.0, true)
		canvas.draw_arc(center, BLAST_RADIUS, 0, TAU, 37, Color("#ffab78"), 1.8, true)
		canvas.draw_arc(center, BLAST_RADIUS - 5.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 37,
			Color("#ffe0a2"), 2.8, true)
		canvas.draw_circle(center, 4.0 + 3.0 * progress, Color("#ffbb7b"), true, -1.0, true)
	var remaining = tea_remaining()
	if remaining <= 0.0:
		return
	var center = position(tea)
	var tint = Color(0.73, 0.96, 0.79, 0.84)
	canvas.draw_circle(center, TEA_RADIUS, Color(0.33, 0.67, 0.48, 0.25), true, -1.0, true)
	canvas.draw_arc(center, TEA_RADIUS, 0, TAU, 50, tint, 2.0, true)
	canvas.draw_arc(center, TEA_RADIUS - 5.0, 0.0, TAU * remaining / TEA_ACTIVE_SECONDS, 40, tint, 1.8, true)
	canvas.draw_arc(center, 9.0, 0, PI, 18, tint, 2.0, true)
	canvas.draw_arc(center + Vector2(10, 3), 4.0, -1.0, 1.3, 15, tint, 1.7, true)
	canvas.draw_line(center + Vector2(-9, 0), center + Vector2(9, 0), tint, 1.7, true)

func draw_foe_badge(canvas: Node2D, foe: Dictionary, location: Vector2) -> void:
	if foe.get("hunt_elite", false):
		canvas.draw_colored_polygon(PackedVector2Array([location + Vector2(-7, 5), location + Vector2(-10, -5),
			location + Vector2(-3, -1), location + Vector2(0, -8), location + Vector2(4, -1),
			location + Vector2(10, -5), location + Vector2(7, 5)]), Color("#f0c279"))
	if is_bounty(foe):
		canvas.draw_arc(location + Vector2(0, 10), 3, 0, TAU, 15, Color("#e1a1c6"), 1.4, true)
