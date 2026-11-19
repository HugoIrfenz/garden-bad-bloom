extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const KIND = 4
const MOVE = "hound_zigzag"
const REACH = 142.0
const FIRST_LEG = 88.0
const SECOND_LEG = 135.0
const WINDUP_TIME = 0.83
const SPEED = 518.0
const HIT_RADIUS = 18.0
const WEAK_SIDE = Color("#9fe4d1")


static func advance(game, foe: Dictionary, delta: float) -> void:
	foe.impact = maxf(0.0, float(foe.get("impact", 0.0)) - delta)
	match int(foe.phase):
		Geometry.APPROACH:
			approach(game, foe, delta)
		Geometry.WINDUP:
			if bool(foe.get("hound_interrupted", false)):
				recover(foe, true)
			elif foe.clock <= 0.0:
				release(foe)
		Geometry.LUNGE:
			rush(game, foe)
		Geometry.RECOVERY:
			if foe.clock <= 0.0:
				foe.phase = Geometry.APPROACH


static func approach(game, foe: Dictionary, delta: float) -> void:
	var start: Vector2 = game.target(foe)
	var gap: Vector2 = game.player - start
	if gap.length_squared() <= REACH * REACH:
		if foe.clock <= 0.0:
			arm(game, foe)
		return
	var walk := gap.normalized() * 84.0 * delta
	var next: Vector2 = game.slide_with_cover(start, walk)
	if next.distance_squared_to(start) < walk.length_squared() * 0.20:
		next = game.slide_with_cover(start, walk.rotated(PI * 0.43 * side(foe)))
	var step := start.direction_to(next)
	if not step.is_zero_approx():
		foe.dx = step.x
		foe.dy = step.y
	foe.x = next.x
	foe.y = next.y


static func arm(game, foe: Dictionary) -> void:
	var start: Vector2 = game.target(foe)
	var aim: Vector2 = game.player
	var forward := start.direction_to(aim)
	if forward.is_zero_approx():
		forward = Vector2.DOWN
	var first := forward.rotated(side(foe) * 0.61)
	var around := open_segment(game, start, first, FIRST_LEG)
	var stop := around
	var trips := start.distance_to(around) < FIRST_LEG - 5.0
	if not trips:
		var second := around.direction_to(aim)
		if around.distance_squared_to(aim) < 35.0 * 35.0:
			second = forward.rotated(-0.48 * side(foe))
		var reach := clampf(around.distance_to(aim) + 38.0, 65.0, SECOND_LEG)
		stop = open_segment(game, around, second, reach)
		trips = around.distance_to(stop) < reach - 5.0
	var heading := start.direction_to(around)
	if heading.is_zero_approx():
		heading = first
	foe.merge({
		"move": MOVE, "phase": Geometry.WINDUP, "clock": WINDUP_TIME, "duration": WINDUP_TIME,
		"ox": start.x, "oy": start.y, "hound_turn_x": around.x, "hound_turn_y": around.y,
		"tx": stop.x, "ty": stop.y, "dx": heading.x, "dy": heading.y,
		"hound_trips": trips, "hound_interrupted": false, "hound_distance": 0.0, "hound_hit": false,
	}, true)


static func open_segment(game, start: Vector2, heading: Vector2, distance: float) -> Vector2:
	var end: Vector2 = game.clamp_position(start + heading * distance)
	var clearance := float(game.BARREL_CLEARANCE)
	if not Geometry.blocked(game, start, end, clearance):
		return end
	var near := 0.0
	var far := 1.0
	for i in range(9):
		var middle := (near + far) * 0.5
		if Geometry.blocked(game, start, start.lerp(end, middle), clearance):
			far = middle
		else:
			near = middle
	return start.lerp(end, near)


static func release(foe: Dictionary) -> void:
	var first := Geometry.origin(foe).distance_to(turn(foe))
	var second := turn(foe).distance_to(Geometry.aim(foe))
	if first + second < 2.0:
		recover(foe, true)
		return
	var duration := maxf(0.14, (first + second) / SPEED)
	foe.merge({"phase": Geometry.LUNGE, "clock": duration, "duration": duration}, true)


static func rush(game, foe: Dictionary) -> void:
	var start := Geometry.origin(foe)
	var pivot := turn(foe)
	var end := Geometry.aim(foe)
	var first := start.distance_to(pivot)
	var second := pivot.distance_to(end)
	var before := float(foe.hound_distance)
	var traveled := maxf(before, (first + second) * Geometry.progress(foe))
	var p := start.lerp(pivot, clampf(traveled / maxf(first, 0.01), 0.0, 1.0))
	if before < first:
		contact(game, foe, start.lerp(pivot, before / first), p)
	if traveled > first and second > 0.01:
		var tail := pivot.lerp(end, clampf((before - first) / second, 0.0, 1.0))
		p = pivot.lerp(end, clampf((traveled - first) / second, 0.0, 1.0))
		contact(game, foe, tail, p)
		var heading := pivot.direction_to(end)
		foe.dx = heading.x
		foe.dy = heading.y
	foe.hound_distance = traveled
	foe.x = p.x
	foe.y = p.y
	if foe.clock <= 0.0:
		recover(foe, bool(foe.hound_trips))


static func contact(game, foe: Dictionary, start: Vector2, finish: Vector2) -> void:
	if bool(foe.hound_hit) or start.is_equal_approx(finish):
		return
	if Geometry.segment_gap(game.player, start, finish) <= HIT_RADIUS:
		foe.hound_hit = true
		game.damage_hero(12, start)


static func recover(foe: Dictionary, trips: bool) -> void:
	foe.phase = Geometry.RECOVERY
	foe.clock = 1.35 if trips else 0.93
	foe.impact = 0.25 if trips else 0.0
	foe.cycle = int(foe.get("cycle", 0)) + 1


static func turn(foe: Dictionary) -> Vector2:
	return Vector2(foe.hound_turn_x, foe.hound_turn_y)


static func side(foe: Dictionary) -> float:
	return float(int(foe.get("hound_side", 1))) * (1.0 if int(foe.get("cycle", 0)) % 2 == 0 else -1.0)


static func weak_side(foe: Dictionary) -> Vector2:
	# Recovery has already advanced the next cast's gait. Keep this cast's side.
	var cast_side := -side(foe) if foe.phase == Geometry.RECOVERY else side(foe)
	return Geometry.direction(foe).orthogonal() * -cast_side


static func defend(game, foe: Dictionary, amount: int) -> int:
	if foe.get("move", "") != MOVE or foe.phase not in [Geometry.WINDUP, Geometry.RECOVERY]:
		return amount
	var attacker: Vector2 = game.target(foe).direction_to(game.player)
	var flank := weak_side(foe).dot(attacker) >= 0.61
	if flank and foe.phase == Geometry.WINDUP and amount >= 8:
		foe.hound_interrupted = true
	if flank:
		return ceili(amount * 1.4)
	if foe.phase == Geometry.WINDUP:
		return maxi(1, floori(amount * 0.70))
	return amount


static func warning(game, foe: Dictionary) -> void:
	var canvas: Node2D = game.world_canvas
	var from := Geometry.origin(foe)
	var pivot := turn(foe)
	var end := Geometry.aim(foe)
	var wind := Geometry.progress(foe)
	if from.distance_squared_to(pivot) > 4.0:
		Geometry.paint_lane(canvas, from, pivot, HIT_RADIUS, wind)
	if pivot.distance_squared_to(end) > 4.0:
		Geometry.paint_lane(canvas, pivot, end, HIT_RADIUS, wind)
		canvas.draw_arc(pivot, 7.0, 0.0, TAU, 22, Geometry.WARNING_EDGE, 1.5, true)
	var heading := Geometry.direction(foe)
	var paw := from + heading * 18.0
	for index in range(-1, 2):
		var scratch := paw + heading.orthogonal() * index * 5.0
		canvas.draw_line(scratch, scratch + heading * lerpf(3.0, 14.0, wind),
			Geometry.WARNING_COUNTDOWN, 1.75, true)


static func attack_effect(game, foe: Dictionary) -> void:
	var canvas: Node2D = game.world_canvas
	var position: Vector2 = game.target(foe)
	var heading := Geometry.direction(foe)
	match int(foe.phase):
		Geometry.WINDUP, Geometry.RECOVERY:
			var angle := weak_side(foe).angle()
			canvas.draw_arc(position, 23.0, angle - 0.48, angle + 0.48, 21, WEAK_SIDE, 2.1, true)
			var edge := Vector2.from_angle(angle)
			var chip := position + edge * 26.0
			canvas.draw_polyline(PackedVector2Array([chip + edge.orthogonal() * 3.0,
				chip - edge * 3.0, chip - edge.orthogonal() * 3.0]), WEAK_SIDE, 1.4, true)
			if float(foe.get("impact", 0.0)) > 0.0:
				var progress := 1.0 - float(foe.impact) / 0.25
				for offset: float in [-0.62, 0.0, 0.71]:
					var shard := heading.rotated(offset)
					var chip_end := position + shard * lerpf(10.0, 32.0, progress)
					canvas.draw_line(chip_end - shard * 6.0, chip_end, Color("#fbd9c2", 1.0 - progress), 2.2, true)
		Geometry.LUNGE:
			canvas.draw_line(position - heading * 33.0, position - heading * 8.0,
				Color("#c9bad7", 0.61), 7.0, true)
