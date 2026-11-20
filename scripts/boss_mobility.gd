extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Optional = preload("res://scripts/optional_bosses.gd")
const HOP_TIME := 0.38
const CLOSE_TINT := Color("#ffc995")
const FAR_TINT := Color("#d2b4ff")

static func is_ranged(foe: Dictionary) -> bool:
	var optional := str(foe.get("optional_boss", ""))
	if not optional.is_empty():
		return optional in [Optional.QUEEN, Optional.MOTHER, Optional.BRASSWING, Optional.HOUR,
			Optional.BRIDE, Optional.VELVET, Optional.MOONS, Optional.LIBRARIAN, Optional.CHAIR]
	return int(foe.get("biome", 0)) in [2, 5, 6]

# Called before the encounter advances. Only a committed hop holds the attack clock.
static func tick(game, foe: Dictionary, delta: float, foot_scale: float) -> bool:
	if not bool(foe.boss):
		return false
	var phase := int(foe.phase)
	if phase != Geometry.APPROACH and phase != Geometry.RECOVERY:
		return false
	var left := float(foe.get("hop_left", 0.0))
	if left > 0.0:
		advance_hop(foe, left, delta)
		return true
	var cooldown := float(foe.get("footwork_cd", 0.65)) - delta
	foe.footwork_cd = cooldown
	var origin: Vector2 = game.target(foe)
	var arena: Rect2 = game.ARENA
	var away: Vector2 = game.player.direction_to(origin)
	var ranged := is_ranged(foe)
	var distance := origin.distance_to(game.player)
	var at_edge := not arena.grow(-40.0).has_point(origin)
	if phase == Geometry.RECOVERY and float(foe.clock) > 0.4:
		return false
	if cooldown <= 0.0 and at_edge:
		var center := arena.get_center()
		var opposite := center + Vector2((center.x - origin.x) * 0.80, (center.y - origin.y) * 0.65)
		var desired := opposite if ranged else center
		var landing := find_landing(game, desired, origin)
		if landing.is_finite():
			foe.hop_left = HOP_TIME
			foe.hop_from_x = origin.x
			foe.hop_from_y = origin.y
			foe.hop_end_x = landing.x
			foe.hop_end_y = landing.y
			foe.footwork_cd = 3.6 if ranged else 2.7
			game.sound.play("enemy_gear" if ranged else "enemy_crash", 1.24)
			return true
	if ranged and cooldown <= 0.0:
		var threat := incoming_shot(game, origin)
		if not threat.is_zero_approx() or distance < 100.0:
			var steer := threat.orthogonal() if not threat.is_zero_approx() else away
			if steer.is_zero_approx():
				steer = Vector2.RIGHT
			if steer.dot(arena.get_center() - origin) < 0.0 and (at_edge or not threat.is_zero_approx()):
				steer = -steer
			var step: Vector2 = game.slide_with_cover(origin, steer * 57.0)
			if step.distance_to(origin) >= 19.0:
				foe.slide_x = steer.x
				foe.slide_y = steer.y
				foe.slide_left = 0.20
				foe.footwork_cd = 1.38 if int(foe.hp) * 2 < int(foe.max) else 2.05
	var sliding := float(foe.get("slide_left", 0.0))
	if sliding > 0.0:
		var steer := Vector2(foe.slide_x, foe.slide_y)
		var point: Vector2 = game.slide_with_cover(origin, steer * 310.0 * foot_scale * minf(sliding, delta))
		foe.x = point.x
		foe.y = point.y
		foe.slide_left = maxf(0.0, sliding - delta)
		return sliding > delta
	if phase == Geometry.APPROACH and foe.has("optional_boss") and not ranged and distance > 85.0:
		var aim := -away
		var step: Vector2 = game.slide_with_cover(origin, aim * 103.0 * foot_scale * delta)
		if step.distance_to(origin) < 36.0 * delta:
			var flank := aim.orthogonal()
			if flank.dot(arena.get_center() - origin) < 0.0:
				flank = -flank
			step = game.slide_with_cover(origin, flank * 84.0 * foot_scale * delta)
		foe.x = step.x
		foe.y = step.y
	return false

static func find_landing(game, desired: Vector2, origin: Vector2) -> Vector2:
	for offset: Vector2 in [Vector2.ZERO, Vector2(0, 48), Vector2(0, -48), Vector2(66, 0), Vector2(-66, 0)]:
		var point: Vector2 = game.clamp_position(desired + offset)
		if origin.distance_to(point) < 76.0:
			continue
		if game.barrels.any(func(prop): return point.distance_to(prop) < game.BARREL_CLEARANCE + 10.0):
			continue
		return point
	return Vector2.INF

static func incoming_shot(game, point: Vector2) -> Vector2:
	for bolt: Dictionary in game.bolts:
		if not bolt.has("hero_projectile"):
			continue
		var start := Vector2(bolt.x, bolt.y)
		var direction := Vector2(bolt.dx, bolt.dy)
		var offset := point - start
		var forward := offset.dot(direction)
		if forward > 32.0 and forward < 139.0 and absf(offset.cross(direction)) < 24.0:
			return direction
	return Vector2.ZERO

static func advance_hop(foe: Dictionary, left: float, delta: float) -> void:
	var remaining := maxf(0.0, left - delta)
	foe.hop_left = remaining
	var start := Vector2(foe.hop_from_x, foe.hop_from_y)
	var landing := Vector2(foe.hop_end_x, foe.hop_end_y)
	var progress := 1.0 - remaining / HOP_TIME
	var point := start.lerp(landing, smoothstep(0.0, 1.0, progress))
	if is_ranged(foe):
		point = start if progress < 0.48 else landing
	foe.x = point.x
	foe.y = point.y

static func paint(game, foe: Dictionary) -> Vector2:
	var left := float(foe.get("hop_left", 0.0))
	if left <= 0.0:
		return Vector2(0.0, 1.0)
	var progress := clampf(1.0 - left / HOP_TIME, 0.0, 1.0)
	var canvas: Node2D = game.world_canvas
	var landing := Vector2(foe.hop_end_x, foe.hop_end_y).round() + Vector2(0, 8)
	var ranged := is_ranged(foe)
	var hue := FAR_TINT if ranged else CLOSE_TINT
	canvas.draw_arc(landing, 17.0 + 11.0 * progress, 0.0, TAU, 30, Color(hue, 0.85), 2.0)
	for index in range(4):
		var point := (landing + Vector2.from_angle(index * PI * 0.5 + progress * PI) * 24.0).round()
		game.View.diamond(canvas, point, 3.0, hue)
	return Vector2(0.0, absf(1.0 - 2.0 * progress)) if ranged else Vector2(sin(progress * PI) * 42.0, 1.0)
