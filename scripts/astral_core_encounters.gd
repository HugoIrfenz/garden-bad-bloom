extends RefCounted

const AttackArt = preload("res://scripts/enemy_attack_art.gd")

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const ASTRAL = 5
const CORE = 6
const STAR_CUE = Color("#e3edff")
const CORE_CUE = Color("#ffd5ba")
const MAX_ORBIT_RADIUS = 162.0
const FRACTURE_GRID = Vector2i(7, 3)
const FINALE := ["petal_gates", "echo", "gravity", "petal_gates", "sequence"]
const GATE_MOVE_TIME := 1.45
const GATE_SECOND_START := 1.94
const GATE_ACTIVE_TIME := GATE_SECOND_START + GATE_MOVE_TIME
const GATE_HALF_OPENING := 52.0
const GATE_HALF_WIDTH := 17.0
const GATE_SAFE := Color("#b9ffe5")
const GATE_BLADE := Color("#ff9cbd")
const NODE_NAMES = ["Lily", "Rose", "Orchid", "Camellia", "Iris"]
const NODE_TINTS = [Color("#a0d1ff"), Color("#d09afe"), Color("#f79ad4"), Color("#ffa98b"), Color("#8fe5d7")]
const MOVES = {
	"mote": [239.0, 0.87, 1.03, 1.72],
	"spokes": [172.0, 0.84, 1.06, 1.35],
	"reflection": [164.0, 0.82, 1.01, 0.38],
	"constellation": [395.0, 1.04, 1.28, 0.94],
	"falling_stars": [640.0, 0.96, 1.18, 0.82],
	"planets": [263.0, 0.95, 1.18, 1.75],
	"wish_dash": [158.0, 0.82, 0.96, 0.45],
	"glitch": [287.0, 0.94, 1.12, 1.82],
	"fracture": [640.0, 1.16, 1.13, 0.90],
	"sequence": [640.0, 1.05, 1.1, 1.47],
	"echo": [350.0, 0.97, 1.08, 1.10],
	"gravity": [640.0, 1.08, 1.17, 1.38],
	"petal_gates": [900.0, 1.33, 1.16, GATE_ACTIVE_TIME],
}

static func advance(game, foe: Dictionary, delta: float) -> void:
	if foe.get("flower_node", false):
		return
	if fracture_active(foe) and not is_same(fracture_owner(game, foe), foe):
		foe.phase = Geometry.APPROACH
		foe.clock = 0.24
		return
	if core_boss(foe):
		spawn_flower_nodes(game, foe)
	if foe.phase == Geometry.WINDUP and not foe.has("move"):
		foe.phase = Geometry.APPROACH
		foe.clock = 0.0
	match int(foe.phase):
		Geometry.APPROACH:
			approach(game, foe, delta)
		Geometry.WINDUP:
			if foe.clock <= 0.0:
				begin_attack(foe)
		Geometry.LUNGE:
			active(game, foe, delta)
			if foe.clock <= 0.0:
				foe.phase = Geometry.RECOVERY
				foe.clock = float(MOVES[str(foe.move)][2])
				foe.cycle = int(foe.get("cycle", 0)) + 1
		Geometry.RECOVERY:
			if foe.clock <= 0.0:
				foe.phase = Geometry.APPROACH

static func core_boss(foe: Dictionary) -> bool:
	return int(foe.get("biome", -1)) == CORE and foe.boss

static func spawn_flower_nodes(game, foe: Dictionary) -> void:
	if foe.get("nodes_spawned", false):
		return
	foe.nodes_spawned = true
	var arena: Rect2 = game.ARENA
	var bounds = arena.grow(-58.0)
	var positions = [Vector2(0.12, 0.29), Vector2(0.28, 0.74), Vector2(0.52, 0.24), Vector2(0.71, 0.74), Vector2(0.88, 0.29)]
	for index in range(positions.size()):
		var mark: Vector2 = bounds.position + bounds.size * positions[index]
		for offset in [Vector2.ZERO, Vector2(0, 44), Vector2(0, -44), Vector2(32, 0), Vector2(-32, 0)]:
			var candidate: Vector2 = game.clamp_position(mark + offset)
			if not Geometry.blocked(game, candidate, candidate, game.BARREL_CLEARANCE):
				mark = candidate
				break
		game.foes.append({"biome": CORE, "kind": 4, "boss": false, "flower_node": true, "flower_index": index,
			"x": mark.x, "y": mark.y, "tx": mark.x, "ty": mark.y,
			"hp": 26, "max": 26, "phase": Geometry.APPROACH, "clock": 1000.0})

static func shield_lives(game) -> int:
	var count = 0
	for foe in game.foes:
		if foe.get("flower_node", false) and foe.hp > 0:
			count += 1
	return count

static func defend(game, foe: Dictionary, amount: int) -> int:
	if core_boss(foe) and (not foe.get("nodes_spawned", false) or shield_lives(game) > 0):
		return 0
	return amount

static func stage(foe: Dictionary) -> int:
	if not foe.boss:
		return 0
	var ratio = float(foe.hp) / maxf(1.0, float(foe.max))
	if int(foe.biome) == ASTRAL:
		return 1 if ratio <= 0.5 else 0
	if ratio <= 0.35:
		return 2
	return 1 if ratio <= 0.7 else 0

static func choose(foe: Dictionary) -> String:
	var kind = int(foe.kind)
	var cycle = int(foe.get("cycle", 0))
	var wave = stage(foe)
	if int(foe.biome) == ASTRAL:
		var sequence = ["constellation", "planets", "falling_stars"] if wave > 0 else ["constellation", "falling_stars", "planets"]
		return ["mote", "spokes", "reflection"][kind] if kind < 3 else sequence[cycle % sequence.size()]
	if kind < 3:
		return ["wish_dash", "glitch", "fracture"][kind]
	if wave == 2:
		return FINALE[int(foe.get("finale_step", 0)) % FINALE.size()]
	var sequence := ["sequence", "echo", "gravity"] if wave == 0 else ["echo", "sequence", "gravity"]
	return sequence[cycle % sequence.size()]

static func approach(game, foe: Dictionary, delta: float) -> void:
	var origin: Vector2 = game.target(foe)
	var gap: Vector2 = game.player - origin
	var move = choose(foe)
	if gap.length() > float(MOVES[move][0]):
		var stride = gap.normalized() * float([67.0, 57.0, 78.0, 58.0][int(foe.kind)]) * delta
		if move == "reflection":
			stride = stride.rotated(0.32 if gap.y > 0 else -0.32)
		var moved: Vector2 = game.slide_with_cover(origin, stride)
		if moved.distance_to(origin) < stride.length() * 0.4:
			moved = game.slide_with_cover(origin, stride.rotated(PI * 0.5))
		foe.x = moved.x
		foe.y = moved.y
	elif foe.clock <= 0.0 and (move != "fracture" or fracture_owner(game, foe).is_empty()):
		arm(game, foe, move)

static func fracture_active(foe: Dictionary) -> bool:
	return foe.get("move", "") == "fracture" and foe.hp > 0 \
		and int(foe.phase) in [Geometry.WINDUP, Geometry.LUNGE]

static func fracture_owner(game, fallback: Dictionary) -> Dictionary:
	for candidate: Dictionary in game.foes:
		if fracture_active(candidate):
			return candidate
	return fallback if fracture_active(fallback) else {}

static func arm(game, foe: Dictionary, move: String) -> void:
	var origin: Vector2 = game.target(foe)
	var direction: Vector2 = origin.direction_to(game.player)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var duration = float(MOVES[move][1])
	var wave = stage(foe)
	foe.merge({"move": move, "phase": Geometry.WINDUP, "clock": duration, "duration": duration,
		"ox": origin.x, "oy": origin.y, "dx": direction.x, "dy": direction.y,
		"tx": game.player.x, "ty": game.player.y, "attack_stage": wave, "hits": 0}, true)
	if core_boss(foe) and wave == 2:
		foe.finale_step = int(foe.get("finale_step", 0)) + 1
	if move in ["reflection", "wish_dash"]:
		var aim = direction
		var range_limit = 195.0
		if move == "reflection":
			var turn = -0.25 if int(foe.get("cycle", 0)) % 2 == 0 else 0.25
			aim = direction.rotated(turn)
			var mirror = Geometry.clear_endpoint(game, origin, direction.rotated(-turn), 188.0, game.BARREL_CLEARANCE)
			foe.mirror = [mirror.x, mirror.y]
			range_limit = 188.0
		var end = Geometry.clear_endpoint(game, origin, aim, range_limit, game.BARREL_CLEARANCE)
		foe.tx = end.x
		foe.ty = end.y
	elif move == "fracture":
		var tile = tile_for(game, game.player)
		foe.fracture_parity = (tile.x + tile.y + 1) % 2
	elif move == "glitch":
		foe.paths = []
		for index in [-1, 1]:
			foe.paths.append(clear_glitch_distance(game, origin, direction, index))
	elif move == "petal_gates":
		var center: Vector2 = game.ARENA.get_center()
		var side := 1.0 if float(game.player.y) <= center.y else -1.0
		foe.gate_openings = [center.y + side * 58.0, center.y - side * 4.0]
		# Give the player time to reach the first opening by starting across the room.
		foe.gate_from_left = float(game.player.x) > center.x
		foe.gate_second_cue = false

static func begin_attack(foe: Dictionary) -> void:
	foe.phase = Geometry.LUNGE
	var duration = float(MOVES[str(foe.move)][3])
	foe.clock = duration
	foe.duration = duration
	if foe.move == "mote":
		foe.orb = [foe.ox, foe.oy, Geometry.direction(foe).angle()]

static func active(game, foe: Dictionary, delta: float) -> void:
	var progress = Geometry.progress(foe)
	var origin = Geometry.origin(foe)
	match str(foe.move):
		"mote":
			move_mote(game, foe, delta)
		"spokes":
			for endpoint in spoke_ends(game, foe, progress):
				if Geometry.segment_gap(game.player, origin, endpoint) <= 11.0:
					once(game, foe, 0, 11, origin)
					break
		"reflection", "wish_dash":
			var past: Vector2 = game.target(foe)
			var now = origin.lerp(Geometry.aim(foe), progress)
			foe.x = now.x
			foe.y = now.y
			if Geometry.segment_gap(game.player, past, now) <= 20.0:
				once(game, foe, 0, 13, past)
		"constellation", "echo":
			var lines = paths(game, foe)
			for i in range(lines.size()):
				var start_time = sweep_time(i)
				if progress >= start_time and progress <= start_time + 0.21:
					if Geometry.segment_gap(game.player, lines[i][0], lines[i][1]) <= 18.0:
						once(game, foe, i, 17, lines[i][0])
		"falling_stars", "sequence":
			var points = impact_points(game, foe)
			for i in range(points.size()):
				var start_time = impact_time(i, points.size())
				if absf(progress - start_time) < 0.10 and game.player.distance_squared_to(points[i]) < 34.0 * 34.0:
					once(game, foe, i, 16)
		"planets":
			for i in range(3):
				if game.player.distance_to(planet(foe, i, progress)) <= 19.0:
					once(game, foe, i, 15, orbit_source(foe, i, progress))
		"glitch":
			for i in range(2):
				var sign_value = -1 if i == 0 else 1
				var distance = float(foe.paths[i]) * glitch_travel(progress)
				var point = glitch_curve(origin, Geometry.direction(foe), sign_value, distance)
				if point.distance_to(game.player) <= 16.0:
					var last = float(foe.paths[i]) * glitch_travel(maxf(progress - 0.035, 0.0))
					once(game, foe, i, 14, glitch_curve(origin, Geometry.direction(foe), sign_value, last))
		"fracture":
			var cell = tile_for(game, game.player)
			if (cell.x + cell.y) % 2 != int(foe.fracture_parity):
				once(game, foe, 1 if progress > 0.64 else 0, 13)
		"gravity":
			var focus = Geometry.aim(foe)
			var gap: Vector2 = focus - game.player
			if gap.length() < 110.0 and game.dash_remaining <= 0.0:
				game.player = game.slide_with_cover(game.player, gap.normalized() * delta * (35.0 + 10 * int(foe.attack_stage)))
			var radius = gravity_radius(progress)
			if absf(gap.length() - radius) <= 14.0:
				once(game, foe, 0, 19)
		"petal_gates":
			sweep_gate(game, foe, delta)

static func gate_from_left(foe: Dictionary, wave: int) -> bool:
	return bool(foe.gate_from_left) == (wave == 0)

static func gate_wave(elapsed: float) -> int:
	if elapsed < GATE_MOVE_TIME:
		return 0
	return 1 if elapsed >= GATE_SECOND_START else -1

static func gate_progress(elapsed: float, wave: int) -> float:
	var start := 0.0 if wave == 0 else GATE_SECOND_START
	return clampf((elapsed - start) / GATE_MOVE_TIME, 0.0, 1.0)

static func gate_x(arena: Rect2, foe: Dictionary, wave: int, progress: float) -> float:
	if not gate_from_left(foe, wave):
		progress = 1.0 - progress
	return lerpf(arena.position.x - GATE_HALF_WIDTH, arena.end.x + GATE_HALF_WIDTH, progress)

static func sweep_gate(game, foe: Dictionary, delta: float) -> void:
	var elapsed := GATE_ACTIVE_TIME - float(foe.clock)
	if elapsed >= GATE_MOVE_TIME + 0.12 and not foe.gate_second_cue:
		foe.gate_second_cue = true
		game.sound.play("enemy_gear", 0.87)
	var wave := gate_wave(elapsed)
	if wave < 0 or absf(float(game.player.y) - float(foe.gate_openings[wave])) <= GATE_HALF_OPENING:
		return
	var arena: Rect2 = game.ARENA
	var current_x := gate_x(arena, foe, wave, gate_progress(elapsed, wave))
	var previous_x := gate_x(arena, foe, wave, gate_progress(elapsed - delta, wave))
	var player_x: float = game.player.x
	if player_x >= minf(current_x, previous_x) - GATE_HALF_WIDTH and player_x <= maxf(current_x, previous_x) + GATE_HALF_WIDTH:
		var side := -1.0 if gate_from_left(foe, wave) else 1.0
		once(game, foe, wave, 22, game.player + Vector2(side * 48.0, 0.0))

static func move_mote(game, foe: Dictionary, delta: float) -> void:
	var old = Vector2(foe.orb[0], foe.orb[1])
	var heading = float(foe.orb[2])
	var preferred = old.direction_to(game.player).angle()
	var shift = clampf(angle_difference(heading, preferred), -1.15 * delta, 1.15 * delta)
	heading += shift
	var point = old + Vector2.from_angle(heading) * delta * 157.0
	foe.orb = [point.x, point.y, heading]
	if not game.ARENA.has_point(point) or Geometry.blocked(game, old, point, 15.0):
		foe.clock = 0.0
	elif Geometry.segment_gap(game.player, old, point) <= 15.0:
		once(game, foe, 0, 13, old)
		foe.clock = 0.0

static func once(game, foe: Dictionary, index: int, damage: int, source: Vector2 = Vector2.INF) -> void:
	var bit = 1 << index
	if int(foe.hits) & bit == 0:
		foe.hits = int(foe.hits) | bit
		game.damage_hero(damage, source)

static func spoke_ends(game, foe: Dictionary, ratio: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var base = Geometry.direction(foe).angle() + ratio * 0.94
	for offset in [-2.6, -1.4, 1.4, 2.6]:
		var vector = Vector2.from_angle(base + offset)
		result.append(Geometry.line_endpoint(game, Geometry.origin(foe), vector, MAX_ORBIT_RADIUS))
	return result

static func paths(game, foe: Dictionary) -> Array:
	var origin = Geometry.origin(foe)
	var direction = Geometry.direction(foe)
	var mirrored = bool(int(foe.attack_stage) % 2)
	var offsets = [0.0, 85.0] if foe.move == "constellation" else [-65.0, 0.0, 65.0]
	if int(foe.attack_stage) > 0 and foe.move == "constellation":
		offsets = [-74.0, 0.0, 74.0]
	if mirrored:
		offsets.reverse()
	var extent = 423.0 if foe.move == "constellation" else 335.0
	var result = []
	for shift in offsets:
		var start: Vector2 = game.clamp_position(origin + direction.orthogonal() * shift)
		var end = Geometry.line_endpoint(game, start, direction, extent)
		result.append([start, end])
	return result

static func impact_points(game, foe: Dictionary) -> Array[Vector2]:
	var aim = Geometry.aim(foe)
	var side = Geometry.direction(foe).orthogonal()
	var result: Array[Vector2] = []
	var offsets = [0.0, 66.0, -66.0]
	if foe.move == "sequence" or int(foe.attack_stage) > 0:
		offsets.append_array([129.0, -129.0])
	if foe.move == "sequence" and int(foe.attack_stage) == 2:
		offsets.reverse()
	for offset in offsets:
		var point: Vector2 = game.clamp_position(aim + side * offset)
		if result.all(func(old): return old.distance_squared_to(point) > 300.0):
			result.append(point)
	return result

static func impact_time(index: int, count: int) -> float:
	return 0.18 + float(index) * 0.64 / maxi(1, count - 1)

static func sweep_time(index: int) -> float:
	return 0.11 + float(index) * 0.29

static func planet(foe: Dictionary, index: int, ratio: float) -> Vector2:
	var velocity = 3.6 if int(foe.attack_stage) > 0 else 2.75
	var angle = Geometry.direction(foe).angle() + index * TAU / 3.0 + ratio * velocity
	return Geometry.origin(foe) + Vector2.from_angle(angle) * (64.0 + ratio * 98.0)

static func orbit_source(foe: Dictionary, index: int, ratio: float) -> Vector2:
	return planet(foe, index, maxf(0.0, ratio - 0.05))

static func glitch_travel(ratio: float) -> float:
	return clampf(ratio, 0.0, 1.0)

static func glitch_curve(origin: Vector2, vector: Vector2, sign_value: int, distance: float) -> Vector2:
	var shift = 46.0 * (1.0 - 2.0 * smoothstep(92.0, 164.0, distance))
	return origin + vector * distance + vector.orthogonal() * shift * sign_value

static func clear_glitch_distance(game, origin: Vector2, vector: Vector2, sign_value: int) -> float:
	var saved = 0.0
	for i in range(1, 58):
		var distance = i * 6.0
		var point = glitch_curve(origin, vector, sign_value, distance)
		if not game.ARENA.grow(-9.0).has_point(point) or Geometry.blocked(game, point, point, 16.0):
			break
		saved = distance
	return saved

static func tile_for(game, point: Vector2) -> Vector2i:
	var arena: Rect2 = game.ARENA
	var scale = (point - arena.position) / arena.size * Vector2(FRACTURE_GRID)
	var cell = Vector2i(scale.floor())
	return cell.clamp(Vector2i.ZERO, FRACTURE_GRID - Vector2i.ONE)

static func gravity_radius(ratio: float) -> float:
	return lerpf(20.0, 138.0, ratio)

static func warning(game, foe: Dictionary) -> void:
	if not foe.has("move"):
		return
	var canvas: Node2D = game.world_canvas
	var origin = Geometry.origin(foe)
	var direction = Geometry.direction(foe)
	var ratio = Geometry.progress(foe)
	match str(foe.move):
		"mote":
			var endpoint = Geometry.clear_endpoint(game, origin, direction, 108.0, 14.0)
			Geometry.paint_lane(canvas, origin, endpoint, 14.0, ratio)
			var orb = origin + Vector2.from_angle(game.visual_clock * 6.0) * 21.0
			spark(canvas, orb, 6.0 + ratio * 3.0, STAR_CUE)
		"spokes":
			for point in spoke_ends(game, foe, 0.0):
				light_line(canvas, origin, point, 11.0, ratio)
		"reflection":
			var false_point = Vector2(foe.mirror[0], foe.mirror[1])
			canvas.draw_line(origin, false_point, Color(0.70, 0.71, 0.94, 0.32), 1.4, true)
			canvas.draw_arc(false_point, 11.0, 0, TAU, 23, Color(0.70, 0.71, 0.94, 0.44), 1.6, true)
			light_line(canvas, origin, Geometry.aim(foe), 20.0, ratio)
			spark(canvas, Geometry.aim(foe), 8.0 + ratio, STAR_CUE)
		"wish_dash":
			Geometry.paint_lane(canvas, origin, Geometry.aim(foe), 20.0, ratio)
			canvas.draw_arc(origin, 12.0 + ratio * 14.0, 0, TAU, 39, CORE_CUE, 2.2, true)
		"constellation", "echo":
			for lane in paths(game, foe):
				light_line(canvas, lane[0], lane[1], 18.0, ratio)
		"falling_stars", "sequence":
			var points = impact_points(game, foe)
			for i in range(points.size()):
				Geometry.paint_circle(canvas, points[i], 34.0, maxf(0.12, ratio - i * 0.1))
				spark(canvas, points[i], 5.0, STAR_CUE if foe.move == "falling_stars" else NODE_TINTS[i])
		"planets":
			canvas.draw_arc(origin, 64.0, 0, TAU, 46, STAR_CUE, 1.5, true)
			canvas.draw_arc(origin, 162.0, 0, TAU, 54, Color(0.68, 0.72, 0.93, 0.50), 1.3, true)
			for i in range(3):
				spark(canvas, planet(foe, i, 0.0), 11.0 + ratio * 5.0, STAR_CUE)
		"glitch":
			for i in range(2):
				var trace = glitch_trace(foe, i, 1.0)
				canvas.draw_polyline(trace, Color(0.94, 0.49, 0.79, 0.24), 16, true)
				canvas.draw_polyline(trace, CORE_CUE, 1.4, true)
				canvas.draw_polyline(glitch_trace(foe, i, ratio), NODE_TINTS[i + 1], 2.6, true)
			var crossing = origin + direction * 129.0
			spark(canvas, crossing, 8.0 + sin(ratio * 19.0) * 2.0, CORE_CUE)
		"fracture":
			draw_tiles(game, foe, false)
		"gravity":
			var focus = Geometry.aim(foe)
			canvas.draw_arc(focus, 108.0, 0, TAU, 51, CORE_CUE, 1.6, true)
			canvas.draw_arc(focus, 21.0 + ratio * 77.0, 0, TAU, 46, CORE_CUE, 2.3, true)
			spark(canvas, focus, 7.0 + ratio * 6.0, CORE_CUE)
		"petal_gates":
			draw_gate_opening(game, foe, 0, 0.7 + ratio * 0.3, true)

static func attack_effect(game, foe: Dictionary) -> void:
	var canvas: Node2D = game.world_canvas
	if core_boss(foe) and (not foe.get("nodes_spawned", false) or shield_lives(game) > 0):
		var position: Vector2 = game.target(foe)
		canvas.draw_arc(position, 41.0, game.visual_clock * 1.8, game.visual_clock * 1.8 + 5.3,
			45, Color(1.0, 0.77, 0.67, 0.8), 2.1, true)
	if foe.phase != Geometry.LUNGE or not foe.has("move"):
		return
	var ratio = Geometry.progress(foe)
	var origin = Geometry.origin(foe)
	match str(foe.move):
		"mote":
			var point = Vector2(foe.orb[0], foe.orb[1])
			var trail = Vector2.from_angle(float(foe.orb[2])) * 17.0
			canvas.draw_line(point - trail, point, Color(0.67, 0.73, 1.0, 0.68), 6.0, true)
			spark(canvas, point, 9.0, STAR_CUE)
		"spokes":
			for point in spoke_ends(game, foe, ratio):
				ray(canvas, origin, point, STAR_CUE)
		"reflection", "wish_dash":
			var position: Vector2 = game.target(foe)
			var back = position.move_toward(origin, 28.0)
			canvas.draw_line(back, position, Color(0.74, 0.69, 0.96, 0.64), 9.0, true)
		"constellation", "echo":
			var lanes = paths(game, foe)
			for i in range(lanes.size()):
				var start_time = sweep_time(i)
				if ratio >= start_time and ratio <= start_time + 0.21:
					ray(canvas, lanes[i][0], lanes[i][1], STAR_CUE if foe.move == "constellation" else NODE_TINTS[i])
		"falling_stars", "sequence":
			var points = impact_points(game, foe)
			for i in range(points.size()):
				var time = impact_time(i, points.size())
				if ratio < time:
					Geometry.paint_circle(canvas, points[i], 34.0, ratio / time)
					var descent := clampf((time - ratio) / 0.14, 0.0, 1.0)
					if descent < 1.0:
						AttackArt.meteor(canvas, points[i], descent * 77.0, ratio + i * 0.4, STAR_CUE)
				elif ratio < time + 0.20:
					var fade = 1.0 - (ratio - time) * 5.0
					canvas.draw_arc(points[i], 34.0 - fade * 13.0, 0, TAU, 33, Color(STAR_CUE, fade), 4.0, true)
					AttackArt.shatter(canvas, points[i], fade, STAR_CUE)
		"planets":
			for i in range(3):
				var point = planet(foe, i, ratio)
				canvas.draw_line(orbit_source(foe, i, ratio), point, Color(0.70, 0.71, 0.95, 0.61), 9.0, true)
				spark(canvas, point, 13.0, NODE_TINTS[i])
		"glitch":
			for i in range(2):
				var sign_value = -1 if i == 0 else 1
				var distance = float(foe.paths[i]) * glitch_travel(ratio)
				var position = glitch_curve(origin, Geometry.direction(foe), sign_value, distance)
				spark(canvas, position, 10.0, NODE_TINTS[i + 1])
		"fracture":
			draw_tiles(game, foe, true)
		"gravity":
			var focus = Geometry.aim(foe)
			var radius = gravity_radius(ratio)
			canvas.draw_circle(focus, 106.0, Color(0.58, 0.23, 0.45, 0.24), true, -1.0, true)
			canvas.draw_arc(focus, radius, 0, TAU, 53, CORE_CUE, 3.3, true)
			for i in range(9):
				var particle_position = focus + Vector2.from_angle(ratio * 3.0 + i * 0.7) * fposmod(100.0 - ratio * 56 + i * 31, 105)
				spark(canvas, particle_position, 4.0, NODE_TINTS[i % 5])
		"petal_gates":
			var elapsed := GATE_ACTIVE_TIME - float(foe.clock)
			var wave := gate_wave(elapsed)
			if wave < 0:
				draw_gate_opening(game, foe, 1, 0.7 + 0.3 * inverse_lerp(GATE_MOVE_TIME, GATE_SECOND_START, elapsed), true)
			else:
				draw_gate_opening(game, foe, wave, 0.58, false)
				var arena: Rect2 = game.ARENA
				var travel := gate_progress(elapsed, wave)
				draw_gate_wall(canvas, arena, gate_x(arena, foe, wave, travel),
					float(foe.gate_openings[wave]), elapsed)

static func draw_gate_opening(game, foe: Dictionary, wave: int, intensity: float, preview: bool) -> void:
	var canvas: Node2D = game.world_canvas
	var arena: Rect2 = game.ARENA
	var opening: float = foe.gate_openings[wave]
	var top := opening - GATE_HALF_OPENING
	var bottom := opening + GATE_HALF_OPENING
	canvas.draw_rect(Rect2(arena.position.x, top, arena.size.x, bottom - top), Color(GATE_SAFE, intensity * 0.12))
	for edge in [top, bottom]:
		canvas.draw_dashed_line(Vector2(arena.position.x + 8.0, edge), Vector2(arena.end.x - 8.0, edge),
			Color(GATE_SAFE, intensity * 0.64), 1.7, 13.0, true, true)
	if not preview:
		return
	var sign_value := 1.0 if gate_from_left(foe, wave) else -1.0
	var edge_x := arena.position.x + 14.0 if sign_value > 0.0 else arena.end.x - 14.0
	for index in range(3):
		var x := edge_x + sign_value * (14.0 + 16.0 * index)
		var start := Vector2(x - sign_value * 8.0, opening)
		var point := Vector2(x + sign_value * 5.0, opening)
		canvas.draw_polyline(PackedVector2Array([start + Vector2(0.0, -12.0), point,
			start + Vector2(0.0, 12.0)]), Color(GATE_SAFE, intensity), 2.7, true)
	var wave_x := edge_x + sign_value * 4.0
	canvas.draw_line(Vector2(wave_x, arena.position.y), Vector2(wave_x, top), Color(GATE_BLADE, intensity), 4.0, true)
	canvas.draw_line(Vector2(wave_x, bottom), Vector2(wave_x, arena.end.y), Color(GATE_BLADE, intensity), 4.0, true)

static func draw_gate_wall(canvas: Node2D, arena: Rect2, x: float, opening: float, elapsed: float) -> void:
	var left := maxf(arena.position.x, x - GATE_HALF_WIDTH)
	var right := minf(arena.end.x, x + GATE_HALF_WIDTH)
	if right <= left:
		return
	var top := opening - GATE_HALF_OPENING
	var bottom := opening + GATE_HALF_OPENING
	for segment in [Vector2(arena.position.y, top), Vector2(bottom, arena.end.y)]:
		var band := Rect2(left, segment.x, right - left, segment.y - segment.x)
		canvas.draw_rect(band, Color("#cb426e", 0.51))
		canvas.draw_rect(band, Color(GATE_BLADE, 0.92), false, 1.8)
		canvas.draw_line(Vector2(band.get_center().x, segment.x), Vector2(band.get_center().x, segment.y),
			Color(CORE_CUE, 0.75), 2.0, true)
		if band.size.x < 14.0:
			continue
		var step_count := floori((segment.y - segment.x - 12.0) / 19.0)
		for index in range(step_count):
			var offset := 10.0 + index * 19.0 + 3.0 * sin(elapsed * 11.0 + index)
			var petal := Vector2(band.get_center().x, segment.x + offset)
			var angle := elapsed * 6.0 - index * 0.72
			var long_axis := Vector2.from_angle(angle) * 6.5
			var short_axis := long_axis.orthogonal() * 0.48
			canvas.draw_colored_polygon(PackedVector2Array([petal - long_axis, petal + short_axis,
				petal + long_axis, petal - short_axis]), Color(CORE_CUE, 0.89))

static func glitch_trace(foe: Dictionary, index: int, ratio: float) -> PackedVector2Array:
	var result = PackedVector2Array()
	for i in range(22):
		result.append(glitch_curve(Geometry.origin(foe), Geometry.direction(foe), -1 if index == 0 else 1,
			float(foe.paths[index]) * float(i) / 21.0 * ratio))
	return result

static func draw_tiles(game, foe: Dictionary, active_now: bool) -> void:
	var canvas: Node2D = game.world_canvas
	var room: Rect2 = game.ARENA
	var cell_size = room.size / Vector2(FRACTURE_GRID)
	for x in range(FRACTURE_GRID.x):
		for y in range(FRACTURE_GRID.y):
			var cell = Rect2(room.position + Vector2(x, y) * cell_size, cell_size).grow(-2.0)
			if (x + y) % 2 == int(foe.fracture_parity):
				canvas.draw_rect(cell, Color(0.53, 0.88, 0.71, 0.20 if active_now else 0.12))
				canvas.draw_rect(cell, Color(0.66, 0.95, 0.78, 0.51), false, 1.0)
			else:
				canvas.draw_rect(cell, Color(0.48, 0.21, 0.36, 0.40 if active_now else 0.16))
				canvas.draw_polyline(PackedVector2Array([cell.position + Vector2(16, 12), cell.get_center(),
					cell.get_center() + Vector2(-7, 13), cell.end - Vector2(19, 10)]), Color(0.95, 0.53, 0.62, 0.68), 2.0, true)

static func draw_node(game, foe: Dictionary) -> void:
	var canvas: Node2D = game.world_canvas
	var center: Vector2 = game.target(foe)
	var tint: Color = NODE_TINTS[int(foe.flower_index)]
	var glow = 0.7 + sin(game.visual_clock * 3.7 + float(foe.flower_index)) * 0.22
	canvas.draw_circle(center, 19.0, Color(0.17, 0.13, 0.27, 0.83), true, -1.0, true)
	canvas.draw_arc(center, 20.0, 0, TAU, 32, Color(tint, 0.82), 2.0, true)
	for i in range(6):
		var point = center + Vector2.from_angle(float(i) * TAU / 6.0) * (8.0 + glow * 2.0)
		canvas.draw_circle(point, 5.0, Color(tint, glow), true, -1.0, true)
	spark(canvas, center, 7.0, Color.WHITE)
	var health = float(foe.hp) / maxf(1.0, float(foe.max))
	var bar = center + Vector2(-13, -28)
	canvas.draw_line(bar, bar + Vector2(26, 0), Color("#503b55"), 3.0, true)
	canvas.draw_line(bar, bar + Vector2(26 * health, 0), tint, 2.0, true)
	if game.player.distance_squared_to(center) < 92.0 * 92.0:
		canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-30, -35), NODE_NAMES[int(foe.flower_index)],
			HORIZONTAL_ALIGNMENT_CENTER, 60.0, 11, Color("#f6ead8"))

static func light_line(canvas: Node2D, a: Vector2, b: Vector2, half: float, ratio: float) -> void:
	canvas.draw_line(a, b, Color(0.69, 0.73, 0.95, 0.24), half * 2.0, true)
	canvas.draw_line(a, b, Color(0.85, 0.88, 0.97, 0.70), 1.25, true)
	canvas.draw_line(a, a.lerp(b, ratio), STAR_CUE, 2.9, true)
	spark(canvas, b, 4.0, STAR_CUE)

static func ray(canvas: Node2D, a: Vector2, b: Vector2, color: Color) -> void:
	canvas.draw_line(a, b, Color(color, 0.44), 21.0, true)
	canvas.draw_line(a, b, color, 3.7, true)
	spark(canvas, b, 7.0, color)

static func spark(canvas: Node2D, point: Vector2, size: float, color: Color) -> void:
	var vertices = PackedVector2Array()
	for i in range(8):
		var radius = size if i % 2 == 0 else size * 0.24
		vertices.append(point + Vector2.from_angle(i * TAU / 8.0) * radius)
	canvas.draw_colored_polygon(vertices, color)
