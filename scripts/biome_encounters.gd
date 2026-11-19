extends RefCounted

const AttackArt = preload("res://scripts/enemy_attack_art.gd")

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const MUSHROOM = 1
const CLOCKWORK = 2
const MYCELIUM_LEAPER = 4
const LANDING_RADIUS = 31.0

const SPECS = {
	"knife": [106.0, 0.67, 0.92],
	"bomb": [63.0, 0.95, 1.1],
	"ward": [198.0, 0.72, 1.24],
	"leap": [162.0, 0.83, 0.98],
	"cross": [106.0, 0.87, 1.12],
	"crown": [225.0, 0.8, 1.0],
	"mines": [310.0, 0.8, 1.1],
	"cyclone": [180.0, 0.79, 1.24],
	"needle": [133.0, 0.7, 0.88],
	"pendulum": [73.0, 0.74, 1.05],
	"petals": [213.0, 1.0, 1.0],
	"hand": [123.0, 0.9, 1.1],
	"bell": [153.0, 1.02, 1.14],
	"gears": [255.0, 0.9, 1.08],
}
const DASH_RANGE = {"knife": 153.0, "needle": 190.0, "cyclone": 214.0}
const DASH_RADIUS = {"knife": 21.0, "needle": 13.0, "cyclone": 30.0}
const ACTIVE_TIME = {"crown": 1.25, "mines": 0.81, "pendulum": 0.47, "hand": 0.70, "bell": 0.78, "leap": 0.44}
const CROWN_DISTANCE = 247.0
const MINE_RADIUS = 40.0
const HAND_RANGE = 137.0
const HAND_SWEEP = 1.89
const BELL_RANGE = 184.0

static func advance(game, foe: Dictionary, delta: float) -> void:
	foe.impact = maxf(0.0, float(foe.get("impact", 0.0)) - delta)
	foe.ward_time = maxf(0.0, float(foe.get("ward_time", 0.0)) - delta)
	if foe.phase == Geometry.WINDUP and not foe.has("move"):
		foe.phase = Geometry.APPROACH
		foe.clock = 0.0
	match int(foe.phase):
		Geometry.APPROACH:
			spawn_phase_two_attendants(game, foe)
			approach(game, foe, delta)
		Geometry.WINDUP:
			if foe.clock <= 0.0:
				release(game, foe)
		Geometry.LUNGE:
			active(game, foe)
		Geometry.RECOVERY:
			spawn_phase_two_attendants(game, foe)
			if foe.clock <= 0.0:
				if foe.get("detonated", false):
					foe.hp = 0
				else:
					foe.phase = Geometry.APPROACH

static func choose_move(foe: Dictionary) -> String:
	var cycle = int(foe.get("cycle", 0))
	var kind = int(foe.kind)
	if int(foe.biome) == MUSHROOM:
		if kind == MYCELIUM_LEAPER:
			return "leap"
		if kind < 3:
			return ["knife", "bomb", "ward"][kind]
		var pattern = ["cyclone", "crown", "cross", "mines"] if phase_two(foe) else ["cross", "crown", "mines"]
		return pattern[cycle % pattern.size()]
	if kind < 3:
		return ["needle", "pendulum", "petals"][kind]
	var pattern = ["hand", "bell", "gears"] if phase_two(foe) else ["hand", "gears", "bell"]
	return pattern[cycle % pattern.size()]

static func phase_two(foe: Dictionary) -> bool:
	return bool(foe.boss) and float(foe.hp) <= float(foe.max) * 0.5

static func spawn_phase_two_attendants(game, foe: Dictionary) -> void:
	if int(foe.biome) != MUSHROOM or not phase_two(foe) or foe.get("attendants", false):
		return
	foe.attendants = true
	var center: Vector2 = game.target(foe)
	var player_gap: Vector2 = game.player - center
	var across: Vector2 = player_gap.normalized().orthogonal() if player_gap.length_squared() > 4.0 else Vector2.RIGHT
	var multiplier := maxi(1, int(foe.get("boss_health_multiplier", 1)))
	var life := maxi(22, floori(float(foe.max) / (4.0 * multiplier)))
	for index in [-1, 1]:
		var point: Vector2 = Geometry.clear_endpoint(game, center, across * index, 73.0, 20.0)
		game.foes.append({"biome": MUSHROOM, "kind": 0, "boss": false, "hp": life, "max": life,
			"phase": Geometry.APPROACH, "clock": 1.2 + float(index + 1) * 0.3,
			"x": point.x, "y": point.y, "tx": point.x, "ty": point.y})

static func approach(game, foe: Dictionary, delta: float) -> void:
	var pos: Vector2 = game.target(foe)
	var gap: Vector2 = game.player - pos
	var move = choose_move(foe)
	if gap.length() > float(SPECS[move][0]):
		var speed = float([73.0, 48.0, 47.0, 68.0, 86.0][int(foe.kind)])
		var direction = gap.normalized()
		if move == "needle":
			speed = 93.0
			direction = direction.rotated(0.30 if pos.y < game.player.y else -0.30)
		var step = direction * speed * delta
		var moved: Vector2 = game.slide_with_cover(pos, step)
		if moved.distance_to(pos) < step.length() * 0.4:
			moved = game.slide_with_cover(pos, step.rotated(PI * 0.5))
		foe.x = moved.x
		foe.y = moved.y
	elif foe.clock <= 0.0:
		arm(game, foe, move)

static func arm(game, foe: Dictionary, move: String) -> void:
	var point: Vector2 = game.target(foe)
	var direction: Vector2 = point.direction_to(game.player)
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	var second = phase_two(foe)
	var duration = float(SPECS[move][1])
	foe.merge({"move": move, "phase": Geometry.WINDUP, "clock": duration, "duration": duration,
		"ox": point.x, "oy": point.y, "dx": direction.x, "dy": direction.y,
		"tx": game.player.x, "ty": game.player.y, "phase_two_move": second, "hit_bits": 0}, true)
	if DASH_RANGE.has(move):
		var stop: Vector2 = Geometry.clear_endpoint(game, point, direction, DASH_RANGE[move], game.BARREL_CLEARANCE)
		foe.tx = stop.x
		foe.ty = stop.y
	elif move == "leap":
		var destination: Vector2 = game.clamp_position(point.move_toward(game.player, 154.0))
		for offset in [Vector2.ZERO, direction.orthogonal() * 40.0, direction.orthogonal() * -40.0, direction * -43.0]:
			var candidate: Vector2 = game.clamp_position(destination + offset)
			if not Geometry.blocked(game, candidate, candidate, game.BARREL_CLEARANCE):
				destination = candidate
				break
		if Geometry.blocked(game, destination, destination, game.BARREL_CLEARANCE):
			destination = point
		foe.tx = destination.x
		foe.ty = destination.y
	elif move == "crown":
		var stop: Vector2 = Geometry.clear_endpoint(game, point, direction, CROWN_DISTANCE, 13.0)
		foe.tx = stop.x
		foe.ty = stop.y

static func release(game, foe: Dictionary) -> void:
	var move = str(foe.move)
	if DASH_RANGE.has(move) or ACTIVE_TIME.has(move):
		var duration = float(ACTIVE_TIME.get(move, 0.24))
		if DASH_RANGE.has(move):
			duration = maxf(0.14, Geometry.origin(foe).distance_to(Geometry.aim(foe)) / dash_speed(move))
		foe.merge({"phase": Geometry.LUNGE, "clock": duration, "duration": duration}, true)
		return
	match move:
		"bomb":
			explode(game, foe, Geometry.origin(foe), 62.0, 12, 10)
			foe.detonated = true
		"ward":
			var targets = ward_targets(game, foe)
			for ally in targets:
				ally.ward_time = 2.5
			if targets.is_empty() and game.player.distance_to(Geometry.origin(foe)) <= 49.0:
				game.damage_hero(9)
		"cross":
			for vector in cross_axes(foe):
				var center = Geometry.origin(foe)
				var start: Vector2 = game.clamp_position(center - vector * 115.0)
				var end: Vector2 = game.clamp_position(center + vector * 115.0)
				if Geometry.segment_gap(game.player, start, end) <= 19.0:
					game.damage_hero(19, center)
					break
		"petals", "gears":
			for angle in projectile_angles(foe):
				var vector = Vector2.from_angle(angle)
				var point = Geometry.origin(foe) + vector * 12.0
				var damage = 9 if move == "petals" else 14
				game.bolts.append({"x": point.x, "y": point.y, "dx": vector.x, "dy": vector.y,
					"life": 2.4, "speed": 158.0 if move == "petals" else 202.0, "damage": damage,
					"art": "petal" if move == "petals" else "gear"})
	recover(foe)

static func active(game, foe: Dictionary) -> void:
	var move = str(foe.move)
	var ratio = Geometry.progress(foe)
	if DASH_RANGE.has(move):
		var prior: Vector2 = game.target(foe)
		var center = Geometry.origin(foe).lerp(Geometry.aim(foe), ratio)
		foe.x = center.x
		foe.y = center.y
		if Geometry.segment_gap(game.player, prior, center) <= float(DASH_RADIUS[move]):
			hit_once(game, foe, 0, 17 if move == "cyclone" else 11, prior)
	else:
		match move:
			"leap":
				var center = Geometry.origin(foe).lerp(Geometry.aim(foe), ratio)
				foe.x = center.x
				foe.y = center.y
				if foe.clock <= 0.0 and game.player.distance_to(center) <= LANDING_RADIUS:
					hit_once(game, foe, 0, 13, center)
			"crown":
				if game.player.distance_to(crown_position(foe)) <= 18.0:
					var source = Geometry.aim(foe) if ratio > 0.5 else Geometry.origin(foe)
					hit_once(game, foe, 0, 16, source)
			"mines":
				var points = mine_points(game, foe)
				for index in range(points.size()):
					var bit = 1 << index
					if ratio >= 0.63 + index * 0.17 and int(foe.hit_bits) & bit == 0:
						foe.hit_bits = int(foe.hit_bits) | bit
						explode(game, foe, points[index], MINE_RADIUS, 13, 20)
			"pendulum":
				if ratio < 0.23:
					swipe_hit(game, foe, -0.35, 0, 76.0, 9)
				elif ratio > 0.59:
					swipe_hit(game, foe, 0.35, 1, 84.0, 11)
			"hand":
				var from = Geometry.origin(foe)
				var to: Vector2 = game.clamp_position(from + Vector2.from_angle(hand_angle(foe)) * HAND_RANGE)
				if Geometry.segment_gap(game.player, from, to) <= 14.0:
					hit_once(game, foe, 0, 17, from)
			"bell":
				var distance: float = game.player.distance_to(Geometry.origin(foe))
				var radius = bell_radius(foe)
				if absf(distance - radius) <= 16.0:
					hit_once(game, foe, 0, 16, Geometry.origin(foe))
	if foe.clock <= 0.0:
		recover(foe)

static func dash_speed(move: String) -> float:
	return float({"knife": 481.0, "needle": 645.0, "cyclone": 385.0}[move])

static func hit_once(game, foe: Dictionary, bit_index: int, damage: int, source: Vector2) -> void:
	var bit = 1 << bit_index
	if int(foe.hit_bits) & bit == 0:
		foe.hit_bits = int(foe.hit_bits) | bit
		game.damage_hero(damage, source)

static func swipe_hit(game, foe: Dictionary, shift: float, bit: int, radius: float, damage: int) -> void:
	var offset: Vector2 = game.player - Geometry.origin(foe)
	var facing: Vector2 = Geometry.direction(foe).rotated(shift)
	if offset.length_squared() <= radius * radius and (offset.is_zero_approx() or absf(facing.angle_to(offset)) < 0.63):
		hit_once(game, foe, bit, damage, Geometry.origin(foe))

static func explode(game, foe: Dictionary, point: Vector2, radius: float, damage: int, friendly: int) -> void:
	if game.player.distance_squared_to(point) <= radius * radius:
		game.damage_hero(damage)
	for other in game.foes:
		if not is_same(other, foe) and game.target(other).distance_squared_to(point) <= radius * radius and not game.endless.protected_at(game.target(other)):
			other.hp -= friendly
			other.flash = 0.14
	if bool(foe.boss) and game.target(foe).distance_squared_to(point) <= radius * radius and not game.endless.protected_at(game.target(foe)):
		foe.hp -= friendly
		foe.flash = 0.14

static func ward_targets(game, foe: Dictionary) -> Array:
	var allies = []
	for other in game.foes:
		if not is_same(other, foe) and other.hp > 0 and game.target(other).distance_to(Geometry.origin(foe)) <= 142.0:
			allies.append(other)
	allies.sort_custom(func(a, b): return game.target(a).distance_squared_to(Geometry.origin(foe)) < game.target(b).distance_squared_to(Geometry.origin(foe)))
	return allies.slice(0, 2)

static func defend(game, foe: Dictionary, amount: int) -> int:
	if float(foe.get("ward_time", 0.0)) > 0.0:
		return maxi(1, ceili(amount * 0.42))
	if int(foe.get("biome", game.active_biome)) == MUSHROOM and int(foe.kind) == 2 and foe.phase == Geometry.RECOVERY:
		var facing: Vector2 = game.target(foe).direction_to(game.player)
		if Geometry.direction(foe).dot(facing) > 0.2:
			return maxi(1, ceili(amount * 0.32))
	return amount

static func recover(foe: Dictionary) -> void:
	foe.phase = Geometry.RECOVERY
	foe.cycle = int(foe.get("cycle", 0)) + 1
	foe.clock = 0.25 if foe.get("detonated", false) else float(SPECS[str(foe.move)][2])
	foe.impact = 0.25

static func cross_axes(foe: Dictionary) -> Array[Vector2]:
	var facing = Geometry.direction(foe)
	return [facing.rotated(-PI * 0.25), facing.rotated(PI * 0.25)]

static func mine_points(game, foe: Dictionary) -> Array[Vector2]:
	var across = Geometry.direction(foe).orthogonal() * 63.0
	var points: Array[Vector2] = [game.clamp_position(Geometry.aim(foe)),
		game.clamp_position(Geometry.aim(foe) + across),
		game.clamp_position(Geometry.aim(foe) - across)]
	return points

static func crown_position(foe: Dictionary) -> Vector2:
	var traveled = 1.0 - absf(Geometry.progress(foe) * 2.0 - 1.0)
	return Geometry.origin(foe).lerp(Geometry.aim(foe), traveled)

static func hand_angle(foe: Dictionary) -> float:
	return Geometry.direction(foe).angle() + lerpf(-HAND_SWEEP * 0.5, HAND_SWEEP * 0.5, Geometry.progress(foe))

static func bell_radius(foe: Dictionary) -> float:
	return lerpf(30.0, BELL_RANGE, Geometry.progress(foe))

static func projectile_angles(foe: Dictionary) -> Array[float]:
	var facing = Geometry.direction(foe).angle()
	var angles: Array[float] = []
	if str(foe.move) == "petals":
		for index in range(6):
			angles.append(facing + PI / 6.0 + index * TAU / 6.0)
	else:
		for index in [-1.0, 0.0, 1.0]:
			angles.append(facing + index * 0.22)
	return angles

static func warning(game, foe: Dictionary) -> void:
	if not foe.has("move"):
		return
	var canvas: Node2D = game.world_canvas
	var origin = Geometry.origin(foe)
	var facing = Geometry.direction(foe)
	var ratio = Geometry.progress(foe)
	var move = str(foe.move)
	if DASH_RANGE.has(move):
		Geometry.paint_lane(canvas, origin, Geometry.aim(foe), float(DASH_RADIUS[move]), ratio)
		return
	match move:
		"leap":
			var landing = Geometry.aim(foe)
			for i in range(1, 6):
				canvas.draw_circle(origin.lerp(landing, i / 6.0), 2.0, Color("#e6c4ac"), true, -1.0, true)
			Geometry.paint_circle(canvas, landing, LANDING_RADIUS, ratio)
		"bomb":
			Geometry.paint_circle(canvas, origin, 62.0, ratio)
		"ward":
			var allies = ward_targets(game, foe)
			if allies.is_empty():
				Geometry.paint_circle(canvas, origin, 49.0, ratio)
			for ally in allies:
				var ally_position: Vector2 = game.target(ally)
				canvas.draw_line(origin, origin.lerp(ally_position, ratio), Color("#b3efbd"), 2.0, true)
				canvas.draw_arc(ally_position, 22.0, 0, TAU, 24, Color("#a4d8b6"), 1.7, true)
		"cross":
			for vector in cross_axes(foe):
				Geometry.paint_lane(canvas, game.clamp_position(origin - vector * 115.0),
					game.clamp_position(origin + vector * 115.0), 19.0, ratio)
		"crown":
			Geometry.paint_lane(canvas, origin, Geometry.aim(foe), 18.0, ratio)
		"mines":
			for point in mine_points(game, foe):
				Geometry.paint_circle(canvas, point, MINE_RADIUS, ratio * 0.55)
		"pendulum":
			cue_sector(canvas, origin, facing.angle() - 0.35, 0.63, 76.0, ratio)
			cue_sector(canvas, origin, facing.angle() + 0.35, 0.63, 84.0, ratio * 0.7)
		"petals", "gears":
			var angles = projectile_angles(foe)
			for i in range(angles.size()):
				var vector = Vector2.from_angle(angles[i])
				var end = Geometry.clear_endpoint(game, origin, vector, 107.0 if move == "petals" else 248.0, 13.0)
				var lit = ratio >= float(i) / angles.size()
				Geometry.paint_lane(canvas, origin, end, 10.0 if lit else 5.0, ratio)
		"hand":
			cue_sector(canvas, origin, facing.angle(), HAND_SWEEP * 0.5, HAND_RANGE, ratio)
		"bell":
			var border = Geometry.WARNING_EDGE
			canvas.draw_arc(origin, BELL_RANGE, 0, TAU, 52, border, 1.6, true)
			canvas.draw_arc(origin, lerpf(30.0, BELL_RANGE, ratio * 0.64), 0, TAU, 44,
				Geometry.WARNING_COUNTDOWN, 2.3, true)

static func cue_sector(canvas: Node2D, from: Vector2, angle: float, half: float, reach: float, ratio: float) -> void:
	var points = PackedVector2Array([from])
	for i in range(23):
		points.append(from + Vector2.from_angle(angle - half + 2.0 * half * i / 22.0) * reach)
	canvas.draw_colored_polygon(points, Geometry.WARNING_FILL)
	points.append(from)
	canvas.draw_polyline(points, Geometry.WARNING_EDGE, 1.5, true)
	canvas.draw_arc(from, reach - 4.0, angle - half, angle - half + 2.0 * half * ratio, 33,
		Geometry.WARNING_COUNTDOWN, 2.4, true)

static func attack_effect(game, foe: Dictionary) -> void:
	var canvas: Node2D = game.world_canvas
	var center: Vector2 = game.target(foe)
	var shield = float(foe.get("ward_time", 0.0))
	if shield > 0.0:
		canvas.draw_arc(center, 21.0, game.visual_clock, game.visual_clock + TAU * 0.77, 32,
			Color(0.65, 0.93, 0.73, clampf(shield, 0.25, 0.8)), 2.2, true)
	if not foe.has("move"):
		return
	var move = str(foe.move)
	var origin = Geometry.origin(foe)
	var facing = Geometry.direction(foe)
	if foe.phase == Geometry.RECOVERY and move == "ward":
		canvas.draw_arc(center, 23.0, facing.angle() - 0.84, facing.angle() + 0.84, 26,
			Color("#bce3a3"), 3.4, true)
	if foe.phase != Geometry.LUNGE:
		recovery_effect(canvas, foe, origin)
		return
	var ratio = Geometry.progress(foe)
	if move == "leap":
		Geometry.paint_circle(canvas, Geometry.aim(foe), LANDING_RADIUS, ratio)
		return
	if DASH_RANGE.has(move):
		var tail = center.move_toward(origin, 31.0)
		var tint = Color(0.96, 0.86, 0.52, 0.61) if move == "needle" else Color(1.0, 0.67, 0.73, 0.68)
		canvas.draw_line(tail, center, tint, 10.0 if move == "needle" else 16.0, true)
		if move == "cyclone":
			canvas.draw_arc(center, 28.0, ratio * TAU * 2.0 - 2.5, ratio * TAU * 2.0 + 1.0, 40, tint, 5.0, true)
		return
	match move:
		"crown":
			AttackArt.crown(canvas, crown_position(foe), ratio)
		"mines":
			var points = mine_points(game, foe)
			for index in range(points.size()):
				var point = points[index]
				var time = 0.63 + index * 0.17
				if ratio < time:
					Geometry.paint_circle(canvas, point, MINE_RADIUS, ratio / time)
					draw_puff_mine(canvas, point, ratio / time)
				else:
					var fade = clampf(1.0 - (ratio - time) * 4.0, 0.0, 1.0)
					canvas.draw_arc(point, MINE_RADIUS * (1.0 - fade * 0.55), 0, TAU, 35,
						Color(0.98, 0.57, 0.76, fade), 3.3, true)
					if fade > 0.0:
						AttackArt.shatter(canvas, point, fade, Color("#f0a1ad"))
		"pendulum":
			var aim_angle = facing.angle() + (-0.35 if ratio < 0.5 else 0.35)
			var width = 0.63
			canvas.draw_arc(origin, 77.0, aim_angle - width, aim_angle + width, 25,
				Color("#efc276"), 5.0, true)
		"hand":
			var to: Vector2 = game.clamp_position(origin + Vector2.from_angle(hand_angle(foe)) * HAND_RANGE)
			AttackArt.clock_hand(canvas, origin, to, game.visual_clock)
		"bell":
			var radius = bell_radius(foe)
			canvas.draw_arc(origin, radius, 0, TAU, 60, Color(1.0, 0.75, 0.49, 0.65), 8.0, true)
			canvas.draw_arc(origin, radius, 0, TAU, 60, Color("#ffdf96"), 2.0, true)

static func recovery_effect(canvas: Node2D, foe: Dictionary, from: Vector2) -> void:
	var ratio = clampf(float(foe.get("impact", 0.0)) / 0.25, 0.0, 1.0)
	if ratio <= 0.0:
		return
	if str(foe.move) == "bomb":
		canvas.draw_arc(from, lerpf(21.0, 62.0, 1.0 - ratio), 0, TAU, 36, Color(1.0, 0.54, 0.81, ratio), 7.0, true)
	elif str(foe.move) == "cross":
		for vector in cross_axes(foe):
			draw_cross_slash(canvas, from, vector, ratio)

static func draw_cross_slash(canvas: Node2D, center: Vector2, axis: Vector2, power: float) -> void:
	var edge := axis.orthogonal()
	var length := 109.0 + 6.0 * (1.0 - power)
	var ribbon := PackedVector2Array([center - axis * length,
		center - axis * 62.0 + edge * 5.0, center + edge * 13.0,
		center + axis * 61.0 + edge * 10.0, center + axis * length,
		center + axis * 57.0 - edge * 4.0, center - edge * 5.0, center - axis * 69.0 - edge * 3.0])
	canvas.draw_colored_polygon(ribbon, Color("#e66d9a", 0.84 * power))
	canvas.draw_polyline(PackedVector2Array([ribbon[0], ribbon[1], ribbon[2], ribbon[3], ribbon[4]]),
		Color("#ffe8d1", power), 2.0, true)
	for index in range(4):
		var spark := center + axis * (37.0 + 21.0 * index) + edge * (13.0 + 11.0 * (1.0 - power))
		canvas.draw_colored_polygon(PackedVector2Array([spark - axis * 5.0, spark + edge * 2.0,
			spark + axis * 6.0, spark - edge * 2.0]), Color("#ffb49c", power * (1.0 - 0.10 * index)))

static func draw_puff_mine(canvas: Node2D, point: Vector2, fuse: float) -> void:
	var swelling := lerpf(0.88, 1.30, fuse)
	canvas.draw_circle(point + Vector2(1, 4), 10.0 * swelling, Color("#4c2a50"), true, -1.0, true)
	canvas.draw_circle(point, 8.0 * swelling, Color("#d986b8"), true, -1.0, true)
	canvas.draw_arc(point, 7.3 * swelling, PI * 1.06, PI * 1.84, 16, Color("#f8bbd8"), 1.4, true)
	for offset: Vector2 in [Vector2(-4, -2), Vector2(1, -5), Vector2(4, 1)]:
		canvas.draw_circle(point + offset * swelling, 1.4, Color("#ffe2cb"), true)
	var flicker := Color("#fff1b5").lerp(Color("#f18f9c"), fuse)
	canvas.draw_line(point + Vector2(0, -9) * swelling, point + Vector2(4, -13) * swelling, flicker, 1.8, true)
