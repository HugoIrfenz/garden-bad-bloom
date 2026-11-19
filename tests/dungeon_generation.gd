extends SceneTree

const Dungeon = preload("res://scripts/dungeon_generation.gd")
const SEED_COUNT = 1000

func _initialize() -> void:
	call_deferred("run")

func require(condition: bool, reason: String, seed_value: int, room_id: String = "") -> bool:
	if not condition:
		push_error("Dungeon generation | seed %d | room %s | %s" % [seed_value, room_id, reason])
		quit(1)
	return condition

func run() -> void:
	var rooms_checked = 0
	var biomes = {}
	var room_kinds = {}
	var templates = {}
	for value in range(SEED_COUNT):
		var seed_value = value * 30198157 - 711299
		var floor_index = posmod(value, 12)
		var floor = Dungeon.generate_floor(seed_value, floor_index)
		if not require(floor == Dungeon.generate_floor(seed_value, floor_index), "floor is not deterministic", seed_value):
			return
		if not require(graph_valid(floor), "invalid or unreachable branch", seed_value):
			return
		biomes[floor.biome] = true
		for room_id in floor.nodes:
			var room = Dungeon.generate_room(seed_value, floor, room_id)
			if not require(room_safe(room), "unsafe entry, spawn, hazard, or exit", seed_value, room_id):
				return
			room_kinds[room.kind] = true
			templates[room.template_id] = true
			rooms_checked += 1
		var entrance: String = floor.entrance_id
		var scheduled = Dungeon.generate_room(seed_value, floor, entrance)
		Dungeon.stream_seed(seed_value, floor_index, entrance, "unrelated")
		if not require(scheduled == Dungeon.generate_room(seed_value, floor, entrance), "room RNG changed across an unrelated draw", seed_value, entrance):
			return

	if not require(biomes.size() == 7 and room_kinds.size() == 11 and templates.size() == 56,
			"generation skipped a biome, room category, or authored template", 0):
		return
	var late = Dungeon.generate_floor(991, 3421008)
	if not require(late.endless and graph_valid(late), "late Endless floor failed", 991):
		return
	var legacy = Dungeon.legacy_room(44, 3, 0)
	if not require(legacy.kind == "boss" and legacy.spawns.size() == 7 and legacy.exit_positions.is_empty(),
			"legacy capstone layout failed", 44):
		return
	print("PASS: %d seeds, %d rooms, 7 biomes, 11 room kinds, and 56 templates." % [SEED_COUNT, rooms_checked])
	quit()

func graph_valid(floor: Dictionary) -> bool:
	var visited = {}
	var can_reach_boss = {floor.boss_id: true}
	var pending = [floor.entrance_id]
	var nodes: Dictionary = floor.nodes
	var safe = false
	var branch_count = 0
	while not pending.is_empty():
		var id: String = pending.pop_front()
		if visited.has(id):
			continue
		if not nodes.has(id):
			return false
		visited[id] = true
		var node: Dictionary = nodes[id]
		safe = safe or node.kind == "rest"
		if node.exits.size() > 1:
			branch_count += 1
		if (node.exits.is_empty() and id != floor.boss_id) or node.exits.size() > 2:
			return false
		for edge in node.exits:
			if not nodes.has(edge) or nodes[edge].layer <= node.layer:
				return false
			pending.append(edge)
	if not (safe and branch_count >= 1 and branch_count <= 3
			and visited.size() == nodes.size() and visited.has(floor.boss_id)):
		return false
	var ordered = nodes.values()
	ordered.sort_custom(func(a, b): return a.layer > b.layer)
	for node in ordered:
		for edge in node.exits:
			if can_reach_boss.has(edge):
				can_reach_boss[node.id] = true
				break
	return can_reach_boss.size() == nodes.size()

func room_safe(room: Dictionary) -> bool:
	var goals = room.exit_positions.values() + [room.reward] + room.spawns
	if not Dungeon.routes_reachable(room.cover + room.hazard_slots, goals) or not room.bounds.has_point(room.entry):
		return false
	if room.kind not in Dungeon.FRIENDLY_KINDS and room.spawns.size() != 7:
		return false
	var previous: Array[Vector2] = []
	for spawn: Vector2 in room.spawns:
		if not room.bounds.grow(-Dungeon.ACTOR_RADIUS).has_point(spawn) or spawn.distance_to(room.entry) < Dungeon.SAFE_ENTRY_RADIUS:
			return false
		if not Dungeon.clear_of(spawn, previous, Dungeon.SPAWN_SEPARATION) or not Dungeon.clear_of(spawn, room.hazard_slots, 44.0):
			return false
		previous.append(spawn)
	return Dungeon.clear_of(room.entry, room.hazard_slots, 56.0)
