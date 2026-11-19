extends RefCounted

const AttackArt = preload("res://scripts/enemy_attack_art.gd")

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Cue = preload("res://scripts/biome_encounters.gd")
const Hound = preload("res://scripts/porcelain_hound.gd")
const Statuses = preload("res://scripts/combat_statuses.gd")
const BLOODBLOOM = 3
const PALACE = 4
const THORN_WIDOW = 4
const PORCELAIN_HOUND = Hound.KIND
const ROOM_RIM = 59.0
const STEAM_RADIUS = 49.0
const ROOT_HALF_WIDTH = 20.0
const ROOT_REACH = 338.0
const HEART_RADIUS = 29.0
const WEB_REACH = 104.0
const WEB_HALF_WIDTH = 12.0

# Approach distance, windup, recovery.
const MOVES = {
	"siphon": [136.0, 0.74, 0.89],
	"antlers": [173.0, 0.88, 1.03],
	"latch": [54.0, 0.76, 1.0],
	"thorn_web": [161.0, 0.95, 1.24],
	"lash": [349.0, 0.89, 1.02],
	"petal_rain": [640.0, 0.91, 1.16],
	"drain": [640.0, 1.0, 1.2],
	"saucer": [229.0, 0.77, 0.97],
	"curtain": [640.0, 0.81, 1.04],
	"duel": [84.0, 0.74, 1.1],
	"hot_tea": [280.0, 0.84, 1.08],
	"clone_cups": [640.0, 0.86, 1.10],
	"steam": [640.0, 0.94, 1.2],
	"saucer_ring": [266.0, 0.93, 1.19],
}
const DASH_LENGTH = {"siphon": 166.0, "antlers": 232.0, "latch": 75.0}
const DASH_SPEED = {"siphon": 488.0, "antlers": 536.0, "latch": 414.0}
const HIT_RADIUS = {"siphon": 17.0, "antlers": 27.0, "latch": 15.0}
const ACTIVE = {
	"duel": 0.58, "drain": 0.86, "saucer": 1.31, "saucer_ring": 1.54,
	"steam": 0.82, "clone_cups": 0.76, "thorn_web": 2.45,
}

static func advance(game, foe: Dictionary, delta: float) -> void:
	if foe.get("web_anchor", false):
		maintain_web_anchor(game, foe)
		return
	if int(foe.biome) == PALACE and int(foe.kind) == PORCELAIN_HOUND:
		Hound.advance(game, foe, delta)
		return
	foe.impact = maxf(0.0, float(foe.get("impact", 0.0)) - delta)
	if orchard(foe):
		foe.heart_angle = fposmod(float(foe.get("heart_angle", 0.0)) + delta * 1.25, TAU)
	if foe.phase == Geometry.WINDUP and not foe.has("move"):
		foe.phase = Geometry.APPROACH
		foe.clock = 0.0
	match int(foe.phase):
		Geometry.APPROACH:
			approach(game, foe, delta)
		Geometry.WINDUP:
			if foe.move == "curtain" and float(foe.get("flash", 0.0)) > 0.0:
				recover(foe, false)
			elif foe.clock <= 0.0:
				activate(game, foe)
		Geometry.LUNGE:
			tick_active(game, foe)
		Geometry.RECOVERY:
			if foe.clock <= 0.0:
				foe.phase = Geometry.APPROACH

static func orchard(foe: Dictionary) -> bool:
	return int(foe.get("biome", BLOODBLOOM)) == BLOODBLOOM and bool(foe.boss)

static func phase_two(foe: Dictionary) -> bool:
	var ratio = 0.55 if orchard(foe) else 0.5
	return bool(foe.boss) and float(foe.hp) <= float(foe.max) * ratio

static func next_move(foe: Dictionary) -> String:
	var kind = int(foe.kind)
	var cycle = int(foe.get("cycle", 0))
	if int(foe.biome) == BLOODBLOOM:
		if kind == THORN_WIDOW:
			return "thorn_web"
		var order = ["lash", "petal_rain", "drain"]
		return ["siphon", "antlers", "latch"][kind] if kind < 3 else order[cycle % order.size()]
	if kind < 3:
		return ["saucer", "curtain", "duel"][kind]
	var order = ["hot_tea", "clone_cups", "steam", "saucer_ring"] if phase_two(foe) else ["hot_tea", "clone_cups", "steam"]
	return order[cycle % order.size()]

static func approach(game, foe: Dictionary, delta: float) -> void:
	var pos: Vector2 = game.target(foe)
	var gap: Vector2 = game.player - pos
	var move = next_move(foe)
	if gap.length() > float(MOVES[move][0]):
		var speed = float([83.0, 61.0, 76.0, 55.0, 65.0][int(foe.kind)])
		var direction = gap.normalized()
		if move == "siphon":
			direction = direction.rotated(0.53 if pos.y < game.player.y else -0.53)
		var stride = direction * speed * delta
		var moved: Vector2 = game.slide_with_cover(pos, stride)
		if moved.distance_to(pos) < stride.length() * 0.45:
			moved = game.slide_with_cover(pos, stride.rotated(PI * 0.5))
		foe.x = moved.x
		foe.y = moved.y
	elif foe.clock <= 0.0:
		arm(game, foe, move)

static func arm(game, foe: Dictionary, move: String) -> void:
	var origin: Vector2 = game.target(foe)
	var facing: Vector2 = origin.direction_to(game.player)
	if facing == Vector2.ZERO:
		facing = Vector2.LEFT
	var time = float(MOVES[move][1])
	foe.merge({"move": move, "phase": Geometry.WINDUP, "clock": time, "duration": time,
		"ox": origin.x, "oy": origin.y, "dx": facing.x, "dy": facing.y,
		"tx": game.player.x, "ty": game.player.y, "hit_bits": 0,
		"phase_two_move": phase_two(foe), "latched": false}, true)
	if DASH_LENGTH.has(move):
		var end = Geometry.clear_endpoint(game, origin, facing, DASH_LENGTH[move], game.BARREL_CLEARANCE)
		foe.tx = end.x
		foe.ty = end.y
	elif move in ["saucer", "saucer_ring"]:
		var maximum = 267.0 if move == "saucer" else 299.0
		var extents: Array[float] = []
		for angle in flight_angles(foe):
			extents.append(flight_extent(game, foe, Vector2.from_angle(angle), maximum))
		foe.flight_ranges = extents
	elif move == "thorn_web":
		weave_web(game, foe)
	if move == "antlers":
		foe.collided = origin.distance_to(Geometry.aim(foe)) + 6.0 < float(DASH_LENGTH[move])

static func activate(game, foe: Dictionary) -> void:
	var move = str(foe.move)
	if DASH_LENGTH.has(move) or ACTIVE.has(move):
		var time = float(ACTIVE.get(move, 0.25))
		if DASH_LENGTH.has(move):
			time = maxf(0.15, Geometry.origin(foe).distance_to(Geometry.aim(foe)) / float(DASH_SPEED[move]))
		foe.merge({"phase": Geometry.LUNGE, "clock": time, "duration": time}, true)
		return
	match move:
		"lash":
			for lane in roots(game, foe):
				if Geometry.segment_gap(game.player, lane[0], lane[1]) <= ROOT_HALF_WIDTH:
					game.damage_hero(17, lane[0])
					break
		"petal_rain":
			for point in ground_marks(game, foe):
				if game.player.distance_squared_to(point) <= 31.0 * 31.0:
					game.damage_hero(15)
					break
		"curtain":
			if not shadow_center(game).has_point(game.player):
				game.damage_hero(11)
		"hot_tea":
			var facing = Geometry.direction(foe)
			for index in range(-2, 3):
				spawn_bolt(game, Geometry.origin(foe), facing.rotated(index * 0.15), 187.0, 12)
	recover(foe)

static func tick_active(game, foe: Dictionary) -> void:
	var move = str(foe.move)
	var ratio = Geometry.progress(foe)
	if DASH_LENGTH.has(move) and not bool(foe.latched):
		var before: Vector2 = game.target(foe)
		var position = Geometry.origin(foe).lerp(Geometry.aim(foe), ratio)
		foe.x = position.x
		foe.y = position.y
		if Geometry.segment_gap(game.player, before, position) <= float(HIT_RADIUS[move]):
			var damage = int({"siphon": 9, "antlers": 14, "latch": 6}[move])
			var hit = once(game, foe, 0, damage, before)
			if hit and move == "siphon":
				heal(foe, 6)
			elif hit and move == "latch":
				foe.merge({"latched": true, "clock": 0.96, "duration": 0.96}, true)
				return
	elif bool(foe.latched):
		if game.dash_remaining > 0.0 or float(foe.get("flash", 0.0)) > 0.0:
			recover(foe)
			return
		var point: Vector2 = game.clamp_position(game.player - Geometry.direction(foe) * 18.0)
		foe.x = point.x
		foe.y = point.y
		if ratio >= 0.56:
			once(game, foe, 1, 7)
	else:
		match move:
			"thorn_web":
				pulse_web(game, foe, ratio)
			"duel":
				if ratio < 0.3:
					slash(game, foe, -0.39, 0, 12)
				elif ratio > 0.59:
					slash(game, foe, 0.42, 1, 13)
			"drain":
				for point in ground_marks(game, foe):
					if game.player.distance_squared_to(point) <= 49.0 * 49.0:
						var beat = 1 if ratio > 0.64 else 0
						if once(game, foe, beat, 8):
							heal(foe, 7)
						break
			"saucer", "saucer_ring":
				for index in range(flight_angles(foe).size()):
					var flight = flight_position(foe, index, ratio)
					if game.player.distance_to(flight) <= 16.0:
						var returning = 1 if ratio > 0.5 else 0
						var prior = flight_position(foe, index, maxf(0.0, ratio - 0.035))
						once(game, foe, index * 2 + returning, 12, prior)
			"clone_cups":
				var points = ground_marks(game, foe)
				for i in range(points.size()):
					if ratio > 0.38 + i * 0.20 and claim(foe, i):
						var facing = points[i].direction_to(Geometry.aim(foe))
						for offset in [-0.19, 0.19]:
							spawn_bolt(game, points[i], facing.rotated(offset), 142.0, 10, "ghost_tea")
			"steam":
				for point in ground_marks(game, foe):
					if game.player.distance_squared_to(point) <= STEAM_RADIUS * STEAM_RADIUS:
						once(game, foe, 1 if ratio > 0.62 else 0, 12)
						break
	if foe.clock <= 0.0:
		recover(foe)

static func heal(foe: Dictionary, amount: int) -> void:
	foe.hp = mini(int(foe.max), int(foe.hp) + Statuses.foe_healing(foe, amount))

static func claim(foe: Dictionary, index: int) -> bool:
	var bit = 1 << index
	if int(foe.hit_bits) & bit != 0:
		return false
	foe.hit_bits = int(foe.hit_bits) | bit
	return true

static func once(game, foe: Dictionary, index: int, damage: int, source: Vector2 = Vector2.INF) -> bool:
	if not claim(foe, index):
		return false
	var old = int(game.hp)
	game.damage_hero(damage, source)
	return int(game.hp) < old

static func slash(game, foe: Dictionary, shift: float, index: int, damage: int) -> void:
	var offset: Vector2 = game.player - Geometry.origin(foe)
	var facing = Geometry.direction(foe).rotated(shift)
	if offset.length_squared() <= 93.0 * 93.0 and (offset.is_zero_approx() or absf(facing.angle_to(offset)) <= 0.57):
		once(game, foe, index, damage, Geometry.origin(foe))

static func spawn_bolt(game, point: Vector2, direction: Vector2, speed: float, damage: int, art := "tea") -> void:
	point += direction * 7.0
	game.bolts.append({"x": point.x, "y": point.y, "dx": direction.x, "dy": direction.y,
		"life": 2.5, "speed": speed, "damage": damage, "art": art})

static func recover(foe: Dictionary, effect := true) -> void:
	var move = str(foe.move)
	foe.phase = Geometry.RECOVERY
	foe.clock = float(MOVES[move][2])
	foe.cycle = int(foe.get("cycle", 0)) + 1
	foe.impact = 0.25 if effect else 0.0
	if move == "antlers" and bool(foe.get("collided", false)):
		foe.clock += 0.45

static func defend(game, foe: Dictionary, amount: int) -> int:
	var biome = int(foe.get("biome", game.active_biome))
	if biome == PALACE and int(foe.kind) == PORCELAIN_HOUND:
		return Hound.defend(game, foe, amount)
	if biome == PALACE and int(foe.kind) == 2 and foe.phase == Geometry.WINDUP and foe.has("move"):
		var incoming: Vector2 = game.target(foe).direction_to(game.player)
		if Geometry.direction(foe).dot(incoming) > 0.30:
			return maxi(1, ceili(amount * 0.47))
	if biome == BLOODBLOOM and orchard(foe) and phase_two(foe):
		var incoming: Vector2 = game.target(foe).direction_to(game.player)
		return maxi(1, ceili(amount * (1.4 if heart_direction(foe).dot(incoming) >= 0.46 else 0.78)))
	return amount

static func heart_direction(foe: Dictionary) -> Vector2:
	return Vector2.from_angle(float(foe.get("heart_angle", 0.0)))

static func roots(game, foe: Dictionary) -> Array:
	var start = Geometry.origin(foe)
	var direction = Geometry.direction(foe)
	var lanes = []
	var angles = [-0.34, 0.0, 0.34] if bool(foe.phase_two_move) else [-0.26, 0.26]
	for angle in angles:
		lanes.append([start, Geometry.line_endpoint(game, start, direction.rotated(angle), ROOT_REACH)])
	return lanes

static func weave_web(game, foe: Dictionary) -> void:
	# When several Widows weave at once, each pair of anchors belongs to its own attack.
	var serial = 1
	for existing: Dictionary in game.foes:
		serial = maxi(serial, int(existing.get("web_id", 0)) + 1)
	foe.web_id = serial
	var center = Geometry.aim(foe)
	var direction = Geometry.direction(foe)
	var lanes: Array = []
	for index in range(2):
		var axis = direction.rotated(PI / 4.0 if index == 0 else -PI / 4.0)
		var corner: Vector2 = game.clamp_position(center - axis * WEB_REACH)
		var far: Vector2 = game.clamp_position(center + axis * WEB_REACH)
		if Geometry.blocked(game, corner, corner, game.BARREL_CLEARANCE):
			# Route the first knot to the opposite corner when a barrel hides it.
			var old_corner = corner
			corner = far
			far = old_corner
		lanes.append([corner.x, corner.y, far.x, far.y])
		game.foes.append({"biome": BLOODBLOOM, "kind": -1, "boss": false,
			"web_anchor": true, "web_id": serial, "web_lane": index,
			"x": corner.x, "y": corner.y, "tx": corner.x, "ty": corner.y,
			"hp": 13, "max": 13, "phase": Geometry.APPROACH, "clock": 1000.0})
	foe.web_lanes = lanes

static func maintain_web_anchor(game, anchor: Dictionary) -> void:
	for owner: Dictionary in game.foes:
		if owner.get("web_anchor", false) or int(owner.get("web_id", 0)) != int(anchor.web_id):
			continue
		if int(owner.hp) > 0 and int(owner.phase) in [Geometry.WINDUP, Geometry.LUNGE]:
			return
	anchor.hp = 0

static func intact_lanes(game, foe: Dictionary) -> Array:
	var available: Array = []
	for anchor: Dictionary in game.foes:
		if not anchor.get("web_anchor", false) or int(anchor.web_id) != int(foe.web_id) or int(anchor.hp) <= 0:
			continue
		var lane = foe.web_lanes[int(anchor.web_lane)]
		available.append([Vector2(lane[0], lane[1]), Vector2(lane[2], lane[3])])
	return available

static func pulse_web(game, foe: Dictionary, ratio: float) -> void:
	var first = ratio >= 0.13 and ratio <= 0.38
	var second = ratio >= 0.60 and ratio <= 0.84
	if not first and not second:
		return
	for lane in intact_lanes(game, foe):
		if Geometry.segment_gap(game.player, lane[0], lane[1]) <= WEB_HALF_WIDTH:
			once(game, foe, 0 if first else 1, 11)
			return

static func ground_marks(game, foe: Dictionary) -> Array[Vector2]:
	var aim = Geometry.aim(foe)
	var side = Geometry.direction(foe).orthogonal()
	var distance = float({"petal_rain": 62.0, "drain": 83.0, "steam": 97.0, "clone_cups": 100.0}[str(foe.move)])
	var points: Array[Vector2] = []
	for raw_position in [aim, aim + side * distance, aim - side * distance]:
		var point: Vector2 = game.clamp_position(raw_position)
		if points.all(func(old): return old.distance_squared_to(point) > 400.0):
			points.append(point)
	if foe.move == "clone_cups":
		points.remove_at(0)
	if bool(foe.phase_two_move) and foe.move == "petal_rain":
		points.append(game.clamp_position(aim + Geometry.direction(foe) * 76.0))
	return points

static func shadow_center(game) -> Rect2:
	return game.ARENA.grow(-ROOM_RIM)

static func flight_angles(foe: Dictionary) -> Array[float]:
	var angle = Geometry.direction(foe).angle()
	if foe.move == "saucer_ring":
		return [angle - 0.24, angle + 0.24]
	return [angle]

static func flight_curve(origin: Vector2, vector: Vector2, distance: float) -> Vector2:
	var bend = sin(clampf(distance / 290.0, 0.0, 1.0) * PI) * 38.0
	return origin + vector * distance + vector.orthogonal() * bend

static func flight_extent(game, foe: Dictionary, vector: Vector2, maximum: float) -> float:
	var origin = Geometry.origin(foe)
	var last = 0.0
	for i in range(1, ceili(maximum / 6.0) + 1):
		var next = minf(maximum, i * 6.0)
		var point = flight_curve(origin, vector, next)
		if not game.ARENA.grow(-12.0).has_point(point) or Geometry.blocked(game, point, point, 16.0):
			break
		last = next
	return last

static func flight_position(foe: Dictionary, index: int, ratio: float) -> Vector2:
	var vector = Vector2.from_angle(flight_angles(foe)[index])
	var extent = float(foe.flight_ranges[index])
	return flight_curve(Geometry.origin(foe), vector, extent * (1.0 - absf(ratio * 2.0 - 1.0)))

static func warning(game, foe: Dictionary) -> void:
	if not foe.has("move"):
		return
	if foe.move == Hound.MOVE:
		Hound.warning(game, foe)
		return
	var canvas: Node2D = game.world_canvas
	var origin = Geometry.origin(foe)
	var ratio = Geometry.progress(foe)
	var facing = Geometry.direction(foe)
	var move = str(foe.move)
	if DASH_LENGTH.has(move):
		Geometry.paint_lane(canvas, origin, Geometry.aim(foe), float(HIT_RADIUS[move]), ratio)
		if move == "antlers":
			for i in range(1, 7):
				var point = origin.lerp(Geometry.aim(foe), float(i) / 7.0)
				canvas.draw_arc(point, 5.0, 0, TAU, 10, Color("#f3969a"), 1.0, true)
		return
	match move:
		"thorn_web":
			for lane in intact_lanes(game, foe):
				Geometry.paint_lane(canvas, lane[0], lane[1], WEB_HALF_WIDTH, ratio)
				draw_thorns(canvas, lane[0], lane[1], Color("#f9c1c5"), 0.62)
		"lash":
			for lane in roots(game, foe):
				Geometry.paint_lane(canvas, lane[0], lane[1], ROOT_HALF_WIDTH, ratio)
		"petal_rain", "drain", "steam":
			var radius = 31.0 if move == "petal_rain" else STEAM_RADIUS
			for point in ground_marks(game, foe):
				Geometry.paint_circle(canvas, point, radius, ratio)
				if move == "steam":
					var fill = Color(1, 0.88, 0.79, 0.32)
					for i in range(-2, 3):
						var across = i * 11.0
						canvas.draw_line(point + Vector2(across - 12.0, 12.0), point + Vector2(across + 12.0, -12.0), fill, 1.2, true)
		"saucer", "saucer_ring":
			for index in range(flight_angles(foe).size()):
				draw_flight_path(canvas, foe, index, ratio)
		"curtain":
			draw_curtain_edges(game, Geometry.WARNING_FILL)
			var safe = shadow_center(game)
			canvas.draw_rect(safe, Geometry.WARNING_EDGE, false, 1.7)
			canvas.draw_line(safe.position, Vector2(lerpf(safe.position.x, safe.end.x, ratio), safe.position.y),
				Geometry.WARNING_COUNTDOWN, 3.0, true)
		"duel":
			Cue.cue_sector(canvas, origin, facing.angle() - 0.39, 0.57, 93.0, ratio)
			Cue.cue_sector(canvas, origin, facing.angle() + 0.42, 0.57, 93.0, ratio * 0.79)
		"hot_tea":
			for index in range(-2, 3):
				var vector = facing.rotated(index * 0.15)
				var finish = Geometry.clear_endpoint(game, origin, vector, 188.0, 14.0)
				Geometry.paint_lane(canvas, origin, finish, 7.5, ratio)
		"clone_cups":
			for point in ground_marks(game, foe):
				Geometry.paint_circle(canvas, point, 25.0, ratio)
				canvas.draw_line(point, point.lerp(Geometry.aim(foe), ratio), Geometry.WARNING_EDGE, 1.4, true)

static func draw_flight_path(canvas: Node2D, foe: Dictionary, index: int, ratio: float) -> void:
	var points = PackedVector2Array()
	var fill = PackedVector2Array()
	for i in range(21):
		var t = float(i) * 0.025
		points.append(flight_position(foe, index, t))
		fill.append(flight_position(foe, index, t * ratio))
	canvas.draw_polyline(points, Color(1, 0.48, 0.54, 0.24), 19.0, true)
	canvas.draw_polyline(points, Geometry.WARNING_EDGE, 1.4, true)
	canvas.draw_polyline(fill, Geometry.WARNING_COUNTDOWN, 2.8, true)
	canvas.draw_arc(points[20], 12.0, 0, TAU, 27, Geometry.WARNING_EDGE, 1.6, true)

static func draw_curtain_edges(game, tint: Color) -> void:
	var canvas: Node2D = game.world_canvas
	var bounds: Rect2 = game.ARENA
	var safe = shadow_center(game)
	canvas.draw_rect(Rect2(bounds.position, Vector2(bounds.size.x, ROOM_RIM)), tint)
	canvas.draw_rect(Rect2(Vector2(bounds.position.x, safe.end.y), Vector2(bounds.size.x, ROOM_RIM)), tint)
	canvas.draw_rect(Rect2(Vector2(bounds.position.x, safe.position.y), Vector2(ROOM_RIM, safe.size.y)), tint)
	canvas.draw_rect(Rect2(Vector2(safe.end.x, safe.position.y), Vector2(ROOM_RIM, safe.size.y)), tint)

static func attack_effect(game, foe: Dictionary) -> void:
	if foe.get("move", "") == Hound.MOVE:
		Hound.attack_effect(game, foe)
		return
	var canvas: Node2D = game.world_canvas
	var center: Vector2 = game.target(foe)
	if orchard(foe) and phase_two(foe):
		var point = center + heart_direction(foe) * HEART_RADIUS
		var glow = 0.7 + sin(game.visual_clock * 7.4) * 0.23
		canvas.draw_circle(point, 9.0, Color(1.0, 0.24, 0.41, glow * 0.58), true, -1.0, true)
		canvas.draw_arc(point, 12.0, 0, TAU, 29, Color(1.0, 0.71, 0.79, glow), 2.0, true)
	if not foe.has("move"):
		return
	var move = str(foe.move)
	var origin = Geometry.origin(foe)
	if foe.phase != Geometry.LUNGE:
		splash(game, foe)
		return
	var ratio = Geometry.progress(foe)
	if DASH_LENGTH.has(move):
		if bool(foe.get("latched", false)):
			var aim: Vector2 = game.player
			canvas.draw_arc(aim, 16.0, game.visual_clock, game.visual_clock + 4.5, 28, Color("#ffadb5"), 3.0, true)
			canvas.draw_line(aim, center, Color("#eb808f"), 3.0, true)
		else:
			var tail = center.move_toward(origin, 32.0)
			canvas.draw_line(tail, center, Color(0.90, 0.45, 0.53, 0.67), 10.0, true)
		return
	match move:
		"thorn_web":
			var pulse = (ratio >= 0.13 and ratio <= 0.38) or (ratio >= 0.60 and ratio <= 0.84)
			for lane in intact_lanes(game, foe):
				var tint = Color("#ffb9a7") if pulse else Color("#d194b2")
				var alpha = 0.74 if pulse else 0.38
				canvas.draw_line(lane[0], lane[1], Color(tint, alpha), WEB_HALF_WIDTH * 2.0, true)
				draw_thorns(canvas, lane[0], lane[1], tint, 0.95 if pulse else 0.63)
		"saucer", "saucer_ring":
			for index in range(flight_angles(foe).size()):
				var point = flight_position(foe, index, ratio)
				AttackArt.saucer(canvas, point, ratio + index * 0.25)
		"steam", "drain":
			var steam = move == "steam"
			var tint = Color(0.88, 0.77, 0.84, 0.54) if steam else Color(1, 0.35, 0.59, 0.61)
			for point in ground_marks(game, foe):
				canvas.draw_circle(point, STEAM_RADIUS, Color(tint, 0.23), true, -1.0, true)
				canvas.draw_arc(point, STEAM_RADIUS, 0, TAU, 42, tint, 2.7, true)
				for i in range(12):
					var time = fposmod(game.visual_clock * 0.85 + i * 0.17, 1.0)
					var orbit = Vector2.from_angle(i * 2.4) * time * STEAM_RADIUS * 0.93
					canvas.draw_circle(point + orbit - Vector2(0, time * 8.0), 3.0 + 3.0 * time,
						Color(tint, 0.33 * (1.0 - time)), true, -1.0, true)
		"clone_cups":
			for point in ground_marks(game, foe):
				canvas.draw_circle(point, 20.0, Color(0.66, 0.52, 0.73, 0.49), true, -1.0, true)
				canvas.draw_arc(point, 17.0, -0.2, PI + 0.2, 24, Color("#d9c3e5"), 3.5, true)
				canvas.draw_arc(point + Vector2(17, -2), 7.0, -1.65, 1.65, 17, Color("#d9c3e5"), 2.4, true)
		"duel":
			var angle = Geometry.direction(foe).angle() + (-0.39 if ratio < 0.5 else 0.42)
			canvas.draw_arc(origin, 89.0, angle - 0.57, angle + 0.57, 29, Color("#ffe5cd"), 5, true)

static func draw_thorns(canvas: Node2D, start: Vector2, end: Vector2, tint: Color, alpha: float) -> void:
	var direction = start.direction_to(end)
	var side = direction.orthogonal()
	var zigzag = PackedVector2Array([start])
	for index in range(1, 14):
		var side_sign = -1.0 if index % 2 == 0 else 1.0
		zigzag.append(start.lerp(end, index / 14.0) + side * side_sign * 9.0)
	zigzag.append(end)
	canvas.draw_polyline(zigzag, Color(tint, alpha), 2.0, true)

static func draw_web_anchor(game, foe: Dictionary) -> void:
	var canvas: Node2D = game.world_canvas
	var center: Vector2 = game.target(foe)
	var tint = Color("#fbd5b4")
	canvas.draw_circle(center, 12.0, Color("#44293d"), true, -1.0, true)
	canvas.draw_arc(center, 13.0, 0, TAU, 32, tint, 1.7, true)
	for i in range(5):
		var axis = Vector2.from_angle(game.visual_clock * 0.27 + i * TAU / 5.0)
		canvas.draw_line(center + axis * 3.0, center + axis * 9.0, Color("#efa0ba"), 2.5, true)
	canvas.draw_circle(center, 3.5, tint, true, -1.0, true)
	if game.player.distance_squared_to(center) <= 86.0 * 86.0:
		canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-24, -19), "Cut", HORIZONTAL_ALIGNMENT_CENTER, 48.0, 11, tint)

static func splash(game, foe: Dictionary) -> void:
	var strength = clampf(float(foe.get("impact", 0.0)) * 4.0, 0.0, 1.0)
	if strength <= 0.0:
		return
	var canvas: Node2D = game.world_canvas
	match str(foe.move):
		"curtain":
			draw_curtain_edges(game, Color(0.45, 0.24, 0.62, strength * 0.69))
			canvas.draw_rect(shadow_center(game), Color(0.93, 0.69, 0.92, strength), false, 2.2)
		"lash":
			for lane in roots(game, foe):
				var points = PackedVector2Array([lane[0]])
				var origin: Vector2 = lane[0]
				var end: Vector2 = lane[1]
				var side = origin.direction_to(end).orthogonal()
				for i in range(1, 11):
					var offset = side * sin(i * 2.5) * 13.0
					points.append(origin.lerp(end, float(i) / 11.0) + offset)
				points.append(end)
				canvas.draw_polyline(points, Color(0.68, 0.23, 0.31, strength), 10.0, true)
				canvas.draw_polyline(points, Color(1, 0.68, 0.65, strength), 1.9, true)
		"petal_rain":
			for point in ground_marks(game, foe):
				canvas.draw_arc(point, 30.0 - 18.0 * strength, 0, TAU, 37, Color(1, 0.46, 0.58, strength), 3.0, true)
				for i in range(8):
					var flake = point + Vector2.from_angle(i * 2.4) * (28.0 - 17.0 * strength)
					canvas.draw_circle(flake, 2.5, Color(1, 0.62, 0.67, strength), true, -1.0, true)
