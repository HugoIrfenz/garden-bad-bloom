extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const GEAR = preload("res://assets/art/clockwork_rail_gear.png")
const GEAR_REGION = Rect2(106, 96, 1040, 1050)
const CLOCK_CENTER = Vector2(432, 224)
const CLOCK_RADIUS = 104.0
const CLOCK_CORE = 24.0
const CLOCK_HALF_ANGLE = PI / 8.0
const RAIL_Y = [139.0, 208.0, 274.0]
const RAIL_LEFT = 154.0
const RAIL_RIGHT = 710.0
const GEAR_RADIUS = 24.0
const RESTING = 0
const WINDUP = 1
const ACTIVE = 2

var mode = ""
var phase = RESTING
var left = 0.0
var sweep = 0
var player_hit = false
var crushed_cover: Array[Vector2] = []

func setup(room: Dictionary) -> void:
	mode = ""
	if room.kind in ["combat", "elite", "challenge", "secret"]:
		match str(room.template_id):
			"clockface_atrium":
				mode = "sector"
			"greenhouse_rails", "gear_orchard":
				mode = "rail"
	phase = RESTING
	left = 1.85
	sweep = 0
	player_hit = false
	crushed_cover.clear()

func snapshot() -> Dictionary:
	var cover: Array = crushed_cover.map(func(point): return [point.x, point.y])
	return {"mode": mode, "phase": phase, "left": left, "sweep": sweep, "player_hit": player_hit, "crushed_cover": cover}

func restore(data: Variant, barrels: Array[Vector2]) -> void:
	if not data is Dictionary or str(data.get("mode", "")) != mode:
		mode = ""
		return
	phase = clampi(int(data.get("phase", RESTING)), RESTING, ACTIVE)
	left = maxf(0.0, float(data.get("left", 0.0)))
	sweep = maxi(0, int(data.get("sweep", 0)))
	player_hit = bool(data.get("player_hit", false))
	for point in data.get("crushed_cover", []):
		if point is Array and point.size() == 2:
			var center = Vector2(point[0], point[1])
			if barrels.has(center):
				barrels.erase(center)
				crushed_cover.append(center)

func tick(game, delta: float) -> void:
	if mode.is_empty():
		return
	var prior_left = left
	left -= delta
	if phase == ACTIVE:
		if mode == "sector":
			if not player_hit and in_sector(game.player, sector_angle()):
				player_hit = true
				game.damage_hero(12)
		else:
			hit_rail(game, gear_at(prior_left), gear_at(left))
	if left > 0:
		return
	match phase:
		RESTING:
			phase = WINDUP
			left += 1.03
			game.sound.play("warning", 1.10)
		WINDUP:
			phase = ACTIVE
			left += active_duration()
			player_hit = false
			game.sound.play("hit", 0.87)
		ACTIVE:
			phase = RESTING
			left += 1.51
			sweep += 1

func active_duration() -> float:
	return 0.52 if mode == "sector" else 1.78

func sector_angle() -> float:
	return -PI * 0.5 + (sweep % 8) * TAU / 8.0

static func in_sector(position: Vector2, angle: float) -> bool:
	var offset = position - CLOCK_CENTER
	var distance = offset.length()
	return distance >= CLOCK_CORE and distance <= CLOCK_RADIUS and absf(Vector2.from_angle(angle).angle_to(offset)) <= CLOCK_HALF_ANGLE

func gear_at(seconds_left: float) -> Vector2:
	var amount = clampf(1.0 - seconds_left / active_duration(), 0.0, 1.0)
	if sweep % 2 == 1:
		amount = 1.0 - amount
	return Vector2(lerpf(RAIL_LEFT, RAIL_RIGHT, amount), RAIL_Y[sweep % RAIL_Y.size()])

func hit_rail(game, start: Vector2, finish: Vector2) -> void:
	for index in range(game.barrels.size() - 1, -1, -1):
		var center: Vector2 = game.barrels[index]
		if Geometry.segment_gap(center, start, finish) <= GEAR_RADIUS:
			crushed_cover.append(center)
			game.barrels.remove_at(index)
	if not player_hit and Geometry.segment_gap(game.player, start, finish) <= GEAR_RADIUS:
		player_hit = true
		game.damage_hero(14)
	for foe: Dictionary in game.foes:
		if int(foe.hp) <= 0 or int(foe.get("rail_hit_sweep", -1)) == sweep:
			continue
		if Geometry.segment_gap(game.target(foe), start, finish) <= GEAR_RADIUS:
			foe.rail_hit_sweep = sweep
			foe.hp -= 14
			foe.flash = 0.14

func disarm() -> void:
	phase = RESTING
	left = 0.0

func draw(game) -> void:
	if mode == "sector":
		draw_sector(game.world_canvas)
	elif mode == "rail":
		draw_rail(game.world_canvas)

func draw_sector(canvas: Node2D) -> void:
	canvas.draw_arc(CLOCK_CENTER, CLOCK_RADIUS, 0.0, TAU, 64, Color(0.87, 0.72, 0.48, 0.43), 1.3, true)
	for index in range(8):
		var vector = Vector2.from_angle((index + 0.5) * TAU / 8.0)
		canvas.draw_line(CLOCK_CENTER + vector * CLOCK_CORE, CLOCK_CENTER + vector * CLOCK_RADIUS, Color(0.87, 0.72, 0.48, 0.31), 1.0, true)
	if phase == RESTING:
		return
	var angle = sector_angle()
	var start_angle = angle - CLOCK_HALF_ANGLE
	var end_angle = angle + CLOCK_HALF_ANGLE
	var wedge = PackedVector2Array()
	for index in range(17):
		var progress = float(index) / 16.0
		wedge.append(CLOCK_CENTER + Vector2.from_angle(lerpf(start_angle, end_angle, progress)) * CLOCK_RADIUS)
	for index in range(17):
		var progress = float(index) / 16.0
		wedge.append(CLOCK_CENTER + Vector2.from_angle(lerpf(end_angle, start_angle, progress)) * CLOCK_CORE)
	canvas.draw_colored_polygon(wedge, Color(1.0, 0.38, 0.20, 0.57 if phase == ACTIVE else 0.24))
	wedge.append(wedge[0])
	canvas.draw_polyline(wedge, Color("#ffc48c"), 2.0, true)
	if phase == WINDUP:
		var progress = clampf(1.0 - left / 1.03, 0.0, 1.0)
		canvas.draw_arc(CLOCK_CENTER, CLOCK_RADIUS - 5.0, start_angle, lerpf(start_angle, end_angle, progress),
			22, Color("#ffe5ae"), 3.0, true)

func draw_rail(canvas: Node2D) -> void:
	for y in RAIL_Y:
		canvas.draw_line(Vector2(RAIL_LEFT, y - 7), Vector2(RAIL_RIGHT, y - 7), Color(0.86, 0.72, 0.53, 0.27), 1.5, true)
		canvas.draw_line(Vector2(RAIL_LEFT, y + 7), Vector2(RAIL_RIGHT, y + 7), Color(0.86, 0.72, 0.53, 0.27), 1.5, true)
	if phase == RESTING:
		return
	var y: float = RAIL_Y[sweep % RAIL_Y.size()]
	if phase == WINDUP:
		var first = Vector2(RAIL_LEFT if sweep % 2 == 0 else RAIL_RIGHT, y)
		var last = Vector2(RAIL_RIGHT if sweep % 2 == 0 else RAIL_LEFT, y)
		Geometry.paint_lane(canvas, first, last, GEAR_RADIUS, clampf(1.0 - left / 1.03, 0.0, 1.0))
		return
	var point = gear_at(left)
	canvas.draw_circle(point, GEAR_RADIUS, Color(0.11, 0.08, 0.10, 0.45), true, -1.0, true)
	canvas.draw_set_transform(point.round(), (RAIL_LEFT - point.x) * 0.044)
	canvas.draw_texture_rect_region(GEAR, Rect2(-GEAR_RADIUS, -GEAR_RADIUS, GEAR_RADIUS * 2, GEAR_RADIUS * 2), GEAR_REGION)
	canvas.draw_set_transform(Vector2.ZERO)
