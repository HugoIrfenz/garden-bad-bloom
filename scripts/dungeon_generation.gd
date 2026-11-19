extends RefCounted

const Catalog = preload("res://scripts/dungeon_catalog.gd")
const ArcadeCatalog = preload("res://scripts/arcade_catalog.gd")
const CONTENT_VERSION = 1
const BIOME_COUNT = 7
const BOUNDS = Rect2(31, 78, 802, 286)
const ENTRY = Vector2(432, 305)
const REWARD = Vector2(553, 247)
const ACTOR_RADIUS = 16.0
const COVER_CLEARANCE = 28.0
const SAFE_ENTRY_RADIUS = 88.0
const SPAWN_SEPARATION = 40.0
const EXIT_Y = 106.0
const OPTIONAL_BOSS_PAIRS = [
	["queen_of_dandelions", "first_scarecrow"],
	["mother_of_spores", "truffle_bandit"],
	["baroness_brasswing", "unfinished_hour"],
	["bride_of_thorns", "antlered_choir"],
	["crownless_prince", "madam_black_velvet"],
	["queen_of_two_moons", "nebula_librarian"],
	["empty_sixth_chair"],
]
const FRIENDLY_KINDS = ["transition", "rest", "shop", "treasure", "event", "curse"]
const ROOM_KINDS = ["transition", "combat", "elite", "treasure", "shop", "event",
	"rest", "curse", "challenge", "secret", "boss"]

## Split random streams by floor and room ID. Calling or adding one stream has no
## effect on the others. Use versioned IDs and ASCII stream names in save files.
static func stream_seed(run_seed: int, floor_index: int, room_id: String, stream: String) -> int:
	var key = "%d|%d|%d|%s|%s" % [CONTENT_VERSION, run_seed, floor_index, room_id, stream]
	var digest = key.sha256_buffer()
	return digest.decode_u32(0) | (int(digest.decode_u32(4) & 0x7fffffff) << 32)

static func generate_floor(run_seed: int, floor_index: int, biome: int = -1) -> Dictionary:
	var endless = biome >= BIOME_COUNT or (biome < 0 and floor_index >= BIOME_COUNT)
	if endless:
		biome = int(stream_seed(run_seed, floor_index, "", "biome") % BIOME_COUNT)
	elif biome < 0:
		biome = clampi(floor_index, 0, BIOME_COUNT - 1)

	var rng = seeded(stream_seed(run_seed, floor_index, "", "graph"))
	var spine_length = rng.randi_range(6, 10)
	var prefix = "floor_%d" % floor_index
	var nodes: Dictionary = {}
	for layer in range(spine_length):
		var id = "%s_r%d" % [prefix, layer]
		var kind = "combat"
		if layer == 0:
			kind = "transition"
		elif layer == spine_length - 1:
			kind = "boss"
		elif layer == spine_length - 2:
			kind = "rest"
		elif layer == 2:
			kind = "treasure"
		elif layer > 2:
			kind = ["combat", "combat", "combat", "elite", "event"][rng.randi_range(0, 4)]
		nodes[id] = make_node(id, kind, layer, 0)
		if layer > 0:
			var previous = "%s_r%d" % [prefix, layer - 1]
			nodes[previous].exits.append(id)

	var main_arcade := place_arcade_event(nodes, prefix, spine_length, biome, endless,
		stream_seed(run_seed, floor_index, "", "main-arcade:v1"))
	var branch_candidates = range(1, spine_length - 2)
	var branch_count = rng.randi_range(1, mini(3, branch_candidates.size()))
	var merchant_generated := false
	for branch_index in range(branch_count):
		var selected = rng.randi_range(0, branch_candidates.size() - 1)
		var layer: int = branch_candidates.pop_at(selected)
		var branch_id = "%s_r%d_b" % [prefix, layer]
		var kind = ["elite", "event", "curse", "secret", "challenge", "shop"][rng.randi_range(0, 5)]
		if branch_index == 0:
			if floor_index == 0 or floor_index >= 2 and floor_index % 3 == 2:
				kind = "curse"
			elif floor_index >= 0 and floor_index % 2 == 1:
				kind = "shop"
		if kind == "shop":
			if merchant_generated:
				kind = "event"
			else:
				merchant_generated = true
		nodes[branch_id] = make_node(branch_id, kind, layer, 1)
		nodes[branch_id].exits.append("%s_r%d" % [prefix, layer + 1])
		nodes["%s_r%d" % [prefix, layer - 1]].exits.append(branch_id)

	return {"version": CONTENT_VERSION, "floor_index": floor_index, "biome": biome,
		"endless": endless, "boss_cover": true, "entrance_id": "%s_r0" % prefix, "boss_id": "%s_r%d" % [prefix, spine_length - 1],
		"nodes": nodes, "main_arcade": main_arcade}

static func add_optional_boss_route(floor: Dictionary, run_seed: int, available: Array = []) -> void:
	if floor.endless or floor.has("optional_boss_route"):
		return
	var boss_node: Dictionary = floor.nodes[floor.boss_id]
	var start_layer := int(boss_node.layer) - 3
	var prefix := "floor_%d" % int(floor.floor_index)
	while start_layer >= 0 and floor.nodes["%s_r%d" % [prefix, start_layer]].exits.size() > 1:
		start_layer -= 1
	if start_layer < 0:
		start_layer = int(boss_node.layer) - 2
	var start := "%s_r%d" % [prefix, start_layer]
	var rejoin := "%s_r%d" % [prefix, start_layer + 1]
	var roster: Array = OPTIONAL_BOSS_PAIRS[int(floor.biome)]
	if not available.is_empty():
		roster = roster.filter(func(id): return id in available)
	if roster.is_empty():
		return
	var selection := stream_seed(run_seed, int(floor.floor_index), start, "optional-boss:v1")
	var boss: String = roster[posmod(selection, roster.size())]
	var rooms: Array[String] = []
	for index in range(3):
		var id := "%s_optional_%d" % [prefix, index]
		rooms.append(id)
		var node := make_node(id, "challenge", start_layer, 1)
		node.layer = float(start_layer) + float(index + 1) * 0.25
		node.optional_boss = boss
		node.optional_stage = index
		floor.nodes[id] = node
		if index > 0:
			floor.nodes[rooms[index - 1]].exits.append(id)
	floor.nodes[rooms.back()].exits.append(rejoin)
	floor.nodes[start].exits.append(rooms.front())
	floor.optional_boss_route = {"boss": boss, "rooms": rooms, "entry": start, "rejoin": rejoin}

static func place_arcade_event(nodes: Dictionary, prefix: String, length: int,
		biome: int, endless: bool, seed_value: int) -> String:
	var event_id := ArcadeCatalog.event_for_floor(biome)
	if event_id.is_empty() or (endless and posmod(seed_value, 3) != 0):
		return ""
	var ordinary_events: Array[String] = []
	for layer in range(3, length - 2):
		var node_id := "%s_r%d" % [prefix, layer]
		if nodes[node_id].kind == "event":
			ordinary_events.append(node_id)
	if endless and ordinary_events.is_empty():
		return ""
	var selected := "%s_r3" % prefix if ordinary_events.is_empty() \
		else ordinary_events[posmod(seed_value, ordinary_events.size())]
	nodes[selected].kind = "event"
	nodes[selected].event_override = event_id
	return selected

static func make_node(id: String, kind: String, layer: int, branch: int) -> Dictionary:
	return {"id": id, "kind": kind, "layer": layer, "branch": branch, "exits": []}

## A compatibility entry point for the current linear save format. Switch to
## generate_floor + generate_room when the run director stores node IDs.
static func legacy_room(run_seed: int, depth: int, route: int) -> Dictionary:
	var floor_index = depth >> 2
	var layer = posmod(depth, 4)
	var floor = generate_floor(run_seed, floor_index)
	var id = "legacy_%d_%d" % [depth, route]
	var node = make_node(id, "boss" if layer == 3 else "combat", layer, route)
	if layer < 3:
		node.exits.append("legacy_%d_0" % (depth + 1))
		node.exits.append("legacy_%d_1" % (depth + 1))
	floor.nodes[id] = node
	return generate_room(run_seed, floor, id)

static func generate_room(run_seed: int, floor: Dictionary, room_id: String) -> Dictionary:
	if not floor.nodes.has(room_id):
		push_error("Unknown dungeon room %s on floor %d" % [room_id, floor.floor_index])
		return {}
	var node: Dictionary = floor.nodes[room_id]
	var floor_index: int = floor.floor_index
	var biome: int = floor.biome
	var kind: String = node.kind
	var rng = seeded(stream_seed(run_seed, floor_index, room_id, "layout"))
	var templates = Catalog.available(biome, kind)
	var template: Array = templates[rng.randi_range(0, templates.size() - 1)]

	var exits: Dictionary = {}
	for i in range(node.exits.size()):
		var x = 432.0 if node.exits.size() == 1 else 336.0 + 192.0 * i
		exits[node.exits[i]] = Vector2(x, EXIT_Y)

	var cover: Array[Vector2] = []
	var hazard_slots: Array[Vector2] = []
	var spawns: Array[Vector2] = []
	var valid = false
	for attempt in range(3):
		cover = place_cover(template[3], kind, rng)
		hazard_slots = place_hazards(kind, cover, exits.values())
		spawns = place_spawns(kind, rng, cover, hazard_slots, exits.values())
		var goals = exits.values() + [REWARD] + spawns
		var blocked = cover + hazard_slots
		if (kind in FRIENDLY_KINDS or spawns.size() == 7) and routes_reachable(blocked, goals):
			valid = true
			break
	if not valid:
		push_warning("Dungeon layout fallback for seed %d floor %d room %s template %s" % [run_seed, floor_index, room_id, template[0]])
		cover = []
		hazard_slots = []
		spawns = place_spawns(kind, rng, cover, hazard_slots, exits.values())
	if kind == "boss" and floor.get("boss_cover", false):
		add_boss_cover(cover, hazard_slots, spawns, [Vector2(432, EXIT_Y)])

	return {"version": CONTENT_VERSION, "id": room_id, "kind": kind, "biome": biome, "endless": floor.endless,
		"template_id": template[0], "display_name": template[1], "mechanic_id": template[4],
		"bounds": BOUNDS, "entry": ENTRY, "exit_positions": exits, "reward": REWARD,
		"cover": cover, "hazard_slots": hazard_slots, "spawns": spawns, "fallback": not valid,
		"encounter_seed": stream_seed(run_seed, floor_index, room_id, "encounter"),
		"reward_seed": stream_seed(run_seed, floor_index, room_id, "reward")}

static func seeded(value: int) -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	rng.seed = value
	return rng

static func add_boss_cover(cover: Array[Vector2], hazards: Array[Vector2],
		spawns: Array[Vector2], exits: Array) -> void:
	var reserved := cover + hazards + exits + spawns + [REWARD, ENTRY]
	for point: Vector2 in [Vector2(696, 156), Vector2(168, 156), Vector2(335, 267), Vector2(624, 269)]:
		if clear_of(point, reserved, 54.0) and routes_reachable(cover + hazards + [point], exits + [REWARD] + spawns):
			cover.append(point)
			return

static func place_cover(form: String, kind: String, rng: RandomNumberGenerator) -> Array[Vector2]:
	var cover: Array[Vector2] = []
	var reflected = rng.randi_range(0, 1) == 1
	for anchor: Vector2 in Catalog.COVER_FORMS[form]:
		var x = 864.0 - anchor.x if reflected else anchor.x
		var point = Vector2(x + rng.randi_range(-12, 12), anchor.y + rng.randi_range(-7, 7))
		if point.distance_to(REWARD) > 45.0 and point.distance_to(ENTRY) > 62.0:
			cover.append(point)
		if kind == "boss" and cover.size() == 2:
			break
	return cover

static func place_hazards(kind: String, cover: Array[Vector2], exits: Array) -> Array[Vector2]:
	var hazards: Array[Vector2] = []
	if kind in FRIENDLY_KINDS:
		return hazards
	for candidate in [Vector2(150, 239), Vector2(718, 218), Vector2(432, 154)]:
		if clear_of(candidate, cover, 46.0) and clear_of(candidate, exits, 58.0):
			hazards.append(candidate)
	return hazards

static func place_spawns(kind: String, rng: RandomNumberGenerator, cover: Array[Vector2],
		hazards: Array[Vector2], exits: Array) -> Array[Vector2]:
	var anchors: Array[Vector2] = []
	if kind in FRIENDLY_KINDS:
		return anchors
	var candidates: Array[Vector2] = []
	for x in range(179, 715, 48):
		for y in range(126, 260, 36):
			var point = Vector2(x + rng.randi_range(-5, 5), y + rng.randi_range(-3, 3))
			if point.distance_to(ENTRY) >= SAFE_ENTRY_RADIUS and point.distance_to(REWARD) >= 37.0 					and clear_of(point, cover, COVER_CLEARANCE + 8.0) and clear_of(point, hazards, 44.0) 					and clear_of(point, exits, 56.0):
				candidates.append(point)
	while not candidates.is_empty() and anchors.size() < 7:
		var point: Vector2 = candidates.pop_at(rng.randi_range(0, candidates.size() - 1))
		if clear_of(point, anchors, SPAWN_SEPARATION):
			anchors.append(point)
	return anchors

static func clear_of(point: Vector2, anchors: Array, clearance: float) -> bool:
	for anchor: Vector2 in anchors:
		if point.distance_squared_to(anchor) < clearance * clearance:
			return false
	return true

## Continuous collision-radius clearance with a sampled graph. Use connected
## line segments, so a circle cannot slip through cover between two free cells.
static func routes_reachable(cover: Array, goals: Array) -> bool:
	var candidates: Array[Vector2] = [ENTRY]
	for goal: Vector2 in goals:
		if not clear_of(goal, cover, COVER_CLEARANCE):
			return false
		if not segment_clear(ENTRY, goal, cover):
			candidates.append(goal)
	var remaining_goals = candidates.size() - 1
	if remaining_goals == 0:
		return true
	for x in range(57, 811, 42):
		for y in range(102, 345, 38):
			var point = Vector2(x, y)
			if clear_of(point, cover, COVER_CLEARANCE):
				candidates.append(point)
	var visited = {0: true}
	var pending = [0]
	var reached_goals = 0
	while not pending.is_empty():
		var current: int = pending.pop_front()
		for index in range(1, candidates.size()):
			if visited.has(index) or candidates[current].distance_squared_to(candidates[index]) > 62.0 * 62.0:
				continue
			if not segment_clear(candidates[current], candidates[index], cover):
				continue
			visited[index] = true
			pending.append(index)
			if index <= remaining_goals:
				reached_goals += 1
				if reached_goals == remaining_goals:
					return true
	return reached_goals == remaining_goals

static func segment_clear(start: Vector2, end: Vector2, cover: Array) -> bool:
	for center: Vector2 in cover:
		var nearest = Geometry2D.get_closest_point_to_segment(center, start, end)
		if nearest.distance_squared_to(center) < COVER_CLEARANCE * COVER_CLEARANCE:
			return false
	return true
