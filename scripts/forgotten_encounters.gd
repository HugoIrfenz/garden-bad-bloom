extends RefCounted

const Statuses = preload("res://scripts/combat_statuses.gd")
const AttackArt = preload("res://scripts/enemy_attack_art.gd")

const TULIP = 0
const SLUG = 1
const PEA_SHOOTER = 2
const GARDENER = 3
const HEDGE_KNIGHT = 4
const LANCE_REACH = 188.0
const APPROACH = 0
const WINDUP = 1
const LUNGE = 2
const RECOVERY = 3
const TULIP_REACH = 131.0
const ROOT_REACH = 292.0
const ROOT_HALF_WIDTH = 17.0
const SHEAR_REACH = 86.0
const SHEAR_HALF_ANGLE = 0.73
const PEA_SPREAD = 0.19
const PEA_SPEED = 157.0
const THORN_RADIUS = 19.0
const RAIN_RADIUS = 31.0
const WARNING_FILL = Color(0.95, 0.29, 0.30, 0.20)
const WARNING_EDGE = Color("#ffbb9f")
const WARNING_COUNTDOWN = Color("#ffdfae")

static func advance(game, foe: Dictionary, delta: float) -> void:
	foe.impact = maxf(0.0, float(foe.get("impact", 0.0)) - delta)
	if foe.phase == WINDUP and not foe.has("move"):
		# A run saved before this enemy had an authored attack can safely telegraph anew.
		foe.phase = APPROACH
		foe.clock = 0.0
	match int(foe.phase):
		APPROACH:
			approach(game, foe, delta)
		WINDUP:
			if foe.clock <= 0.0:
				release(game, foe)
		LUNGE:
			lunge(game, foe)
		RECOVERY:
			if foe.clock <= 0.0:
				foe.phase = APPROACH

static func approach(game, foe: Dictionary, delta: float) -> void:
	var pos: Vector2 = game.target(foe)
	var gap: Vector2 = game.player - pos
	var move = next_move(foe)
	if int(foe.kind) == HEDGE_KNIGHT and (not foe.has("dx") or gap.length() > 154.0):
		var heading: Vector2 = gap.normalized()
		foe.dx = heading.x
		foe.dy = heading.y
	var reach = float({"lunge": 99.0, "slime": 86.0, "peas": 241.0,
		"shears": 78.0, "rain": 315.0, "roots": 238.0, "lance": 154.0}[move])
	if gap.length() > reach:
		var speed = float([69.0, 41.0, 52.0, 72.0, 48.0][int(foe.kind)])
		var step = gap.normalized() * speed * delta
		var moved: Vector2 = game.slide_with_cover(pos, step)
		if moved.distance_to(pos) < step.length() * 0.45:
			var side = -1.0 if pos.y > game.ARENA.get_center().y else 1.0
			moved = game.slide_with_cover(pos, step.rotated(PI * 0.5 * side))
		foe.x = moved.x
		foe.y = moved.y
		return
	if foe.clock <= 0.0:
		arm(game, foe, move)

static func next_move(foe: Dictionary) -> String:
	match int(foe.kind):
		TULIP:
			return "lunge"
		SLUG:
			return "slime"
		PEA_SHOOTER:
			return "peas"
		HEDGE_KNIGHT:
			return "lance"
		_:
			var cycle = int(foe.get("cycle", 0))
			var pattern = ["shears", "rain", "roots", "rain"] if phase_two(foe) else ["shears", "rain", "roots"]
			return pattern[cycle % pattern.size()]

static func phase_two(foe: Dictionary) -> bool:
	return float(foe.hp) <= float(foe.max) * 0.55

static func arm(game, foe: Dictionary, move: String) -> void:
	var pos: Vector2 = game.target(foe)
	var direction: Vector2 = pos.direction_to(game.player)
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	var duration = float({"lunge": 0.66, "slime": 0.68, "peas": 0.74,
		"shears": 0.75, "rain": 0.92, "roots": 0.82, "lance": 0.91}[move])
	foe.merge({"move": move, "phase": WINDUP, "clock": duration, "duration": duration,
		"ox": pos.x, "oy": pos.y, "dx": direction.x, "dy": direction.y,
		"tx": game.player.x, "ty": game.player.y, "phase_two_move": phase_two(foe)}, true)
	if move in ["lunge", "lance"]:
		var reach = LANCE_REACH if move == "lance" else TULIP_REACH
		var stop = clear_endpoint(game, pos, direction, reach, game.BARREL_CLEARANCE)
		foe.tx = stop.x
		foe.ty = stop.y
		foe.hit_cover = origin(foe).distance_to(stop) < reach - 6.0

static func release(game, foe: Dictionary) -> void:
	match str(foe.move):
		"lunge", "lance":
			var speed = 532.0 if foe.move == "lance" else 440.0
			var duration = maxf(0.10, origin(foe).distance_to(aim(foe)) / speed)
			foe.merge({"phase": LUNGE, "clock": duration, "duration": duration, "landed": false}, true)
			return
		"slime":
			for point in slime_points(game, foe):
				game.bolts.append({"x": point.x, "y": point.y, "dx": 0.0, "dy": 0.0,
					"life": 1.8, "damage": 7, "terrain": true, "radius": THORN_RADIUS})
		"peas":
			for index in range(-1, 2):
				var vector = direction(foe).rotated(index * PEA_SPREAD)
				var point = origin(foe) + vector * 8.0
				game.bolts.append({"x": point.x, "y": point.y, "dx": vector.x, "dy": vector.y,
					"life": 2.15, "speed": PEA_SPEED, "damage": 8})
		"shears":
			var offset: Vector2 = game.player - origin(foe)
			if offset.length_squared() <= SHEAR_REACH * SHEAR_REACH and (offset.is_zero_approx() or absf(direction(foe).angle_to(offset)) < SHEAR_HALF_ANGLE):
				game.damage_hero(17, origin(foe))
		"rain":
			for point in rain_points(game, foe):
				if game.player.distance_squared_to(point) <= RAIN_RADIUS * RAIN_RADIUS:
					game.damage_hero(13)
					break
		"roots":
			for index in root_offsets(foe):
				var start: Vector2 = game.clamp_position(origin(foe) + direction(foe).orthogonal() * index)
				var end = line_endpoint(game, start, direction(foe), ROOT_REACH)
				if segment_gap(game.player, start, end) <= ROOT_HALF_WIDTH:
					game.damage_hero(16)
					break
	foe.cycle = int(foe.get("cycle", 0)) + 1
	foe.impact = 0.27
	recover(foe)

static func lunge(game, foe: Dictionary) -> void:
	var start: Vector2 = game.target(foe)
	var finish = origin(foe).lerp(aim(foe), progress(foe))
	var knight = int(foe.kind) == HEDGE_KNIGHT
	foe.x = finish.x
	foe.y = finish.y
	if knight and game.ground_hazards.catch_charge(game, start, finish):
		foe.hp -= 10
		foe.flash = 0.14
		recover(foe)
		foe.clock = 1.75
		return
	if not foe.landed and segment_gap(game.player, start, finish) <= 22.0:
		foe.landed = true
		game.damage_hero(15 if knight else 10, start)
	if foe.clock <= 0.0:
		recover(foe)
		if knight and foe.get("hit_cover", false):
			foe.clock = 1.75

static func recover(foe: Dictionary) -> void:
	foe.phase = RECOVERY
	foe.clock = float([0.78, 1.47, 1.05, 1.15, 0.96][int(foe.kind)])

static func defend(game, foe: Dictionary, amount: int) -> int:
	if int(foe.get("kind", TULIP)) == HEDGE_KNIGHT and foe.phase != RECOVERY and foe.has("dx"):
		var front: Vector2 = game.target(foe).direction_to(game.player)
		if direction(foe).dot(front) > 0.38:
			return Statuses.guarded_damage(foe, amount, maxi(1, ceili(float(amount) * 0.25)))
	if int(foe.get("kind", TULIP)) != SLUG or foe.phase != RECOVERY:
		return amount
	var to_hero: Vector2 = game.target(foe).direction_to(game.player)
	return maxi(1, int(ceil(float(amount) * 0.35))) if direction(foe).dot(to_hero) > -0.23 else amount

static func slime_points(game, foe: Dictionary) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for distance in [17.0, 39.0, 61.0]:
		var point = clear_endpoint(game, origin(foe), direction(foe), distance, 16.0)
		if points.is_empty() or points.back().distance_squared_to(point) >= 100.0:
			points.append(point)
	return points

static func rain_points(game, foe: Dictionary) -> Array[Vector2]:
	var across = direction(foe).orthogonal() * 56.0
	var points: Array[Vector2] = [game.clamp_position(aim(foe)),
		game.clamp_position(aim(foe) + across), game.clamp_position(aim(foe) - across)]
	if bool(foe.get("phase_two_move", false)):
		points.append(game.clamp_position(aim(foe) + direction(foe) * 65.0))
	return points

static func root_offsets(foe: Dictionary) -> Array[float]:
	var offsets: Array[float] = [0.0]
	if bool(foe.get("phase_two_move", false)):
		offsets.append_array([-62.0, 62.0])
	return offsets

static func origin(foe: Dictionary) -> Vector2:
	return Vector2(foe.ox, foe.oy)

static func direction(foe: Dictionary) -> Vector2:
	return Vector2(foe.dx, foe.dy)

static func aim(foe: Dictionary) -> Vector2:
	return Vector2(foe.tx, foe.ty)

static func progress(foe: Dictionary) -> float:
	return clampf(1.0 - float(foe.clock) / maxf(0.01, float(foe.duration)), 0.0, 1.0)

static func segment_gap(point: Vector2, start: Vector2, end: Vector2) -> float:
	if start.is_equal_approx(end):
		return point.distance_to(start)
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, end))

static func clear_endpoint(game, start: Vector2, vector: Vector2, distance: float, clearance: float) -> Vector2:
	var last = start
	for i in range(1, ceili(distance / 4.0) + 1):
		var point: Vector2 = game.clamp_position(start + vector * minf(distance, float(i) * 4.0))
		if blocked(game, point, point, clearance):
			break
		last = point
	return last

static func line_endpoint(game, start: Vector2, vector: Vector2, distance: float) -> Vector2:
	var end: Vector2 = start + vector * distance
	var edges: Rect2 = game.ARENA.grow(-8.0)
	if edges.has_point(end):
		return end
	var result = end
	var shortest = distance
	var corners = [edges.position, Vector2(edges.end.x, edges.position.y), edges.end, Vector2(edges.position.x, edges.end.y)]
	for i in range(corners.size()):
		var cross: Variant = Geometry2D.segment_intersects_segment(start, end, corners[i], corners[(i + 1) % corners.size()])
		if cross is Vector2 and start.distance_to(cross) < shortest:
			shortest = start.distance_to(cross)
			result = cross
	return result

static func blocked(game, start: Vector2, finish: Vector2, clearance: float) -> bool:
	for barrel in game.barrels:
		if segment_gap(barrel, start, finish) <= clearance:
			return true
	return false

static func warning(game, foe: Dictionary) -> void:
	var canvas: Node2D = game.world_canvas
	var elapsed = progress(foe)
	match str(foe.move):
		"lunge", "lance":
			paint_lane(canvas, origin(foe), aim(foe), 22.0, elapsed)
		"slime":
			for point in slime_points(game, foe):
				paint_circle(canvas, point, THORN_RADIUS, elapsed)
		"peas":
			for index in range(-1, 2):
				var vector = direction(foe).rotated(index * PEA_SPREAD)
				var end = clear_endpoint(game, origin(foe), vector, PEA_SPEED * 2.15, 16.0)
				paint_lane(canvas, origin(foe), end, 8.0, elapsed)
		"shears":
			paint_cone(canvas, origin(foe), direction(foe).angle(), elapsed)
		"rain":
			for point in rain_points(game, foe):
				paint_circle(canvas, point, RAIN_RADIUS, elapsed)
		"roots":
			for index in root_offsets(foe):
				var start: Vector2 = game.clamp_position(origin(foe) + direction(foe).orthogonal() * index)
				paint_lane(canvas, start, line_endpoint(game, start, direction(foe), ROOT_REACH), ROOT_HALF_WIDTH, elapsed)

static func attack_effect(game, foe: Dictionary) -> void:
	var canvas: Node2D = game.world_canvas
	var impact = clampf(float(foe.get("impact", 0.0)) / 0.27, 0.0, 1.0)
	if foe.phase == LUNGE:
		var point: Vector2 = game.target(foe)
		var trail = point.move_toward(origin(foe), 27.0)
		var petals = Color(1.0, 0.54, 0.62, 0.43)
		canvas.draw_line(trail, point, petals, 11.0, true)
		for i in range(3):
			var petal = trail.lerp(point, float(i) * 0.25) + direction(foe).orthogonal() * (-8.0 + 8.0 * i)
			canvas.draw_circle(petal, 2.2, petals, true, -1.0, true)
	if impact <= 0.0:
		return
	match str(foe.get("move", "")):
		"shears":
			var ang = direction(foe).angle()
			var radius = SHEAR_REACH * lerpf(0.65, 1.0, 1.0 - impact)
			canvas.draw_arc(origin(foe), radius, ang - SHEAR_HALF_ANGLE, ang + SHEAR_HALF_ANGLE,
				30, Color(1.0, 0.72, 0.54, impact * 0.78), 7.0, true)
			canvas.draw_arc(origin(foe), radius, ang - SHEAR_HALF_ANGLE, ang + SHEAR_HALF_ANGLE,
				30, Color(1.0, 0.95, 0.76, impact), 2.0, true)
		"rain":
			for point in rain_points(game, foe):
				var water = Color(0.63, 0.82, 0.97, impact)
				canvas.draw_arc(point, RAIN_RADIUS * lerpf(0.35, 1.0, 1.0 - impact), 0, TAU, 28, water, 2.0, true)
				for i in range(5):
					var offset = Vector2.from_angle(i * TAU / 5.0) * (12.0 + 15.0 * (1.0 - impact))
					canvas.draw_line(point + offset - Vector2(2, 7), point + offset, water, 2.4, true)
		"roots":
			for index in root_offsets(foe):
				var start: Vector2 = game.clamp_position(origin(foe) + direction(foe).orthogonal() * index)
				var finish = line_endpoint(game, start, direction(foe), ROOT_REACH)
				AttackArt.brambles(canvas, start, finish, impact)

static func paint_lane(canvas: Node2D, start: Vector2, finish: Vector2, half_width: float, elapsed: float) -> void:
	var side = (finish - start).normalized().orthogonal() * half_width
	canvas.draw_colored_polygon(PackedVector2Array([start - side, finish - side, finish + side, start + side]), WARNING_FILL)
	for sign_value in [-1.0, 1.0]:
		canvas.draw_line(start + side * sign_value, finish + side * sign_value, WARNING_EDGE, 1.5, true)
	canvas.draw_line(start, start.lerp(finish, elapsed), WARNING_COUNTDOWN, 2.0, true)
	canvas.draw_arc(finish, half_width * 0.5, 0.0, TAU, 20, WARNING_EDGE, 1.5, true)

static func paint_circle(canvas: Node2D, point: Vector2, radius: float, elapsed: float) -> void:
	canvas.draw_circle(point, radius, WARNING_FILL, true, -1.0, true)
	canvas.draw_arc(point, radius, 0.0, TAU, 35, WARNING_EDGE, 1.5, true)
	canvas.draw_arc(point, radius - 4.0, -PI * 0.5, -PI * 0.5 + TAU * elapsed, 35, WARNING_COUNTDOWN, 2.5, true)

static func paint_cone(canvas: Node2D, point: Vector2, angle: float, elapsed: float) -> void:
	var fan = PackedVector2Array([point])
	for i in range(25):
		fan.append(point + Vector2.from_angle(angle - SHEAR_HALF_ANGLE + 2.0 * SHEAR_HALF_ANGLE * i / 24.0) * SHEAR_REACH)
	canvas.draw_colored_polygon(fan, WARNING_FILL)
	fan.append(point)
	canvas.draw_polyline(fan, WARNING_EDGE, 1.6, true)
	canvas.draw_arc(point, SHEAR_REACH - 4.0, angle - SHEAR_HALF_ANGLE,
		angle - SHEAR_HALF_ANGLE + 2.0 * SHEAR_HALF_ANGLE * elapsed, 28, WARNING_COUNTDOWN, 2.6, true)
