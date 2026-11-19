extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Statuses = preload("res://scripts/combat_statuses.gd")
const WEAPON = "elegy_spiral"
const REFRAIN = "rosebound_refrain"
const INK = "black_rose_ink"
const RECHARGE_COST = 0.80
const ECHO_DELAY = 0.54
const ECHO_RADIUS = 42.0
const ECHO_FLASH = 0.25
const RESIDUE_LIFE = 3.40
const RESIDUE_LIMIT = 6
const WELL_LIFE = 0.68
const WELL_RADIUS = 48.0
const WELL_LIMIT = 2
const WELL_BLOOM_AT = 0.42
const SHOT_MEMORY = 12
const INK_COLOR = Color("#b994dc")
const ROSE_COLOR = Color("#eca8d8")

var residues: Array[Dictionary] = []
var wells: Array[Dictionary] = []
var echo: Dictionary = {}
var echo_flash: Dictionary = {}
var _shots: Array[int] = []


static func is_evolved(game) -> bool:
	var gear = game.get("armory")
	return int(game.hero) == 1 and gear != null and gear.for_hero(1) == WEAPON


static func has_refrain(game) -> bool:
	var relics = game.get("relics")
	return int(game.hero) == 1 and (is_evolved(game) or (relics != null and relics.has_relic(REFRAIN)))


static func has_ink(game) -> bool:
	var relics = game.get("relics")
	return int(game.hero) == 1 and (is_evolved(game) or (relics != null and relics.has_relic(INK)))


func reset() -> void:
	residues.clear()
	wells.clear()
	echo.clear()
	echo_flash.clear()
	_shots.clear()


func snapshot() -> Dictionary:
	return {"residues": residues.duplicate(true), "wells": wells.duplicate(true),
		"echo": echo.duplicate(), "echo_flash": echo_flash.duplicate(), "shots": _shots.duplicate()}


func restore(raw: Variant) -> void:
	reset()
	if not raw is Dictionary:
		return
	for row: Variant in bounded_rows(raw.get("residues"), RESIDUE_LIMIT):
		var entry := read_site(row, RESIDUE_LIFE)
		if not entry.is_empty():
			entry.radius = clampf(float(row.get("radius", 29.0)), 18.0, 33.0)
			entry.evolved = bool(row.get("evolved", false))
			residues.append(entry)
	for row: Variant in bounded_rows(raw.get("wells"), WELL_LIMIT):
		var entry := read_site(row, WELL_LIFE)
		if not entry.is_empty():
			entry.evolved = bool(row.get("evolved", false))
			entry.bloomed = bool(row.get("bloomed", false))
			wells.append(entry)
	var queued: Variant = raw.get("echo")
	echo = read_site(queued, ECHO_DELAY)
	if not echo.is_empty():
		echo.power = clampi(int(queued.get("power", 1)), 1, 150)
		echo.ink = bool(queued.get("ink", false))
		echo.evolved = bool(queued.get("evolved", false))
	echo_flash = read_site(raw.get("echo_flash"), ECHO_FLASH)
	for shot: Variant in bounded_rows(raw.get("shots"), SHOT_MEMORY):
		if (shot is int or shot is float) and int(shot) > 0 and int(shot) not in _shots:
			_shots.append(int(shot))


static func bounded_rows(raw: Variant, limit: int) -> Array:
	return raw.slice(0, limit) if raw is Array else []


static func read_site(raw: Variant, max_time: float) -> Dictionary:
	if not raw is Dictionary or not raw.has_all(["x", "y", "left"]):
		return {}
	var center := Vector2(float(raw.x), float(raw.y))
	var left := clampf(float(raw.left), 0.0, max_time)
	return {"x": center.x, "y": center.y, "left": left} if center.is_finite() and left > 0.0 else {}


func verse_lands(game, center: Vector2, raw_power: int, repeats: bool, inks: bool, evolved: bool) -> void:
	if inks:
		write_residue(game, center, 31.0, evolved)
	if repeats:
		echo = {"x": center.x, "y": center.y, "left": ECHO_DELAY,
			"power": clampi(floori(float(raw_power) * 0.50), 1, 150), "ink": inks, "evolved": evolved}


func spell_trace(game, center: Vector2) -> void:
	if has_ink(game):
		write_residue(game, center, 27.0, is_evolved(game))


func note_basic_hit(game, center: Vector2, sequence: int) -> void:
	if int(game.hero) != 1 or sequence <= 0 or sequence in _shots:
		return
	_shots.append(sequence)
	if _shots.size() > SHOT_MEMORY:
		_shots.pop_front()
	write_residue(game, center, 24.0, true)


func write_residue(game, center: Vector2, radius: float, evolved: bool) -> void:
	if not center.is_finite():
		return
	if wells.size() < WELL_LIMIT and not well_near(game, center):
		var best := -1
		var nearest := INF
		for index in range(residues.size()):
			var old := residues[index]
			var point := Vector2(old.x, old.y)
			var distance := point.distance_to(center)
			if distance < radius + float(old.radius) and distance < nearest \
					and not Geometry.blocked(game, center, point, 12.0):
				best = index
				nearest = distance
		if best >= 0:
			var paired := residues[best]
			var midpoint := center.lerp(Vector2(paired.x, paired.y), 0.5)
			residues.remove_at(best)
			wells.append({"x": midpoint.x, "y": midpoint.y, "left": WELL_LIFE,
				"evolved": evolved or bool(paired.get("evolved", false)), "bloomed": false})
			return
	if residues.size() == RESIDUE_LIMIT:
		residues.pop_front()
	residues.append({"x": center.x, "y": center.y, "left": RESIDUE_LIFE, "radius": radius, "evolved": evolved})


func well_near(game, center: Vector2) -> bool:
	for well: Dictionary in wells:
		var point := Vector2(well.x, well.y)
		if point.distance_squared_to(center) <= 34.0 * 34.0 and not Geometry.blocked(game, center, point, 12.0):
			return true
	return false


func tick(game, delta: float, hit: Callable) -> void:
	for index in range(residues.size() - 1, -1, -1):
		residues[index].left = float(residues[index].left) - delta
		if float(residues[index].left) <= 0.0:
			residues.remove_at(index)
	for index in range(wells.size() - 1, -1, -1):
		var well := wells[index]
		tick_well(game, well, delta, hit)
		if float(well.left) <= 0.0:
			wells.remove_at(index)
	if not echo_flash.is_empty():
		echo_flash.left = float(echo_flash.left) - delta
		if float(echo_flash.left) <= 0.0:
			echo_flash.clear()
	if echo.is_empty():
		return
	echo.left = float(echo.left) - delta
	if float(echo.left) <= 0.0:
		var center := Vector2(echo.x, echo.y)
		pulse(game, center, ECHO_RADIUS, int(echo.power), hit)
		if bool(echo.ink):
			write_residue(game, center, 26.0, bool(echo.evolved))
		echo_flash = {"x": center.x, "y": center.y, "left": ECHO_FLASH}
		echo.clear()
		game.sound.play("vivianne", 1.12)


func tick_well(game, well: Dictionary, delta: float, hit: Callable) -> void:
	var center := Vector2(well.x, well.y)
	var active := minf(delta, float(well.left))
	well.left = maxf(0.0, float(well.left) - delta)
	for foe: Dictionary in game.foes:
		# Gravity never moves bosses or rewrites the endpoint of a committed attack.
		if bool(foe.get("boss", false)) or int(foe.phase) in [Geometry.WINDUP, Geometry.LUNGE] \
				or not Statuses.accepts_status(game, foe):
			continue
		var point: Vector2 = game.target(foe)
		var distance := point.distance_to(center)
		if distance > WELL_RADIUS or distance < 7.0 or Geometry.blocked(game, point, center, 12.0):
			continue
		var travel := minf(distance - 7.0, (1.0 - distance / (WELL_RADIUS * 1.7)) * 155.0 * active)
		var landed := Geometry.clear_endpoint(game, point, point.direction_to(center), travel, game.BARREL_CLEARANCE)
		foe.x = landed.x
		foe.y = landed.y
	if bool(well.evolved) and not bool(well.bloomed) and WELL_LIFE - float(well.left) >= WELL_BLOOM_AT:
		well.bloomed = true
		pulse(game, center, WELL_RADIUS, 9 + clampi(int(game.bonus) / 4, 0, 6), hit)
		game.sound.play("vivianne", 0.84)


static func pulse(game, center: Vector2, radius: float, damage: int, hit: Callable) -> void:
	for foe: Dictionary in game.foes:
		var point: Vector2 = game.target(foe)
		if int(foe.hp) > 0 and center.distance_squared_to(point) <= radius * radius \
				and not Geometry.blocked(game, center, point, 12.0):
			hit.call(game, foe, damage)


static func prepare_bolt(bolt: Dictionary) -> void:
	bolt.spiral_heading = [float(bolt.dx), float(bolt.dy)]
	bolt.spiral_life = float(bolt.life)


static func steer_bolt(bolt: Dictionary, delta: float) -> void:
	var baseline: Variant = bolt.get("spiral_heading")
	if not baseline is Array or baseline.size() != 2:
		prepare_bolt(bolt)
		baseline = bolt.spiral_heading
	var duration := maxf(0.01, float(bolt.get("spiral_life", bolt.life)))
	var age := duration - float(bolt.life) + minf(delta, float(bolt.life)) * 0.5
	var side := 1.0 if int(bolt.get("weapon_attack", 0)) % 2 == 0 else -1.0
	var arc := sin(clampf(age / duration, 0.0, 1.0) * TAU) * 0.25 * side
	var heading := Vector2(baseline[0], baseline[1]).rotated(arc)
	bolt.dx = heading.x
	bolt.dy = heading.y


func draw(game) -> void:
	var canvas: Node2D = game.world_canvas
	for row: Dictionary in residues:
		var center := Vector2(row.x, row.y)
		var radius := float(row.radius)
		var fade := minf(1.0, float(row.left) / 0.38)
		canvas.draw_circle(center, radius, Color(0.15, 0.065, 0.21, 0.25 * fade), true, -1.0, true)
		canvas.draw_arc(center, radius, -0.6, TAU - 1.35, 38, Color(INK_COLOR, 0.66 * fade), 1.3, true)
		draw_runes(canvas, center, radius - 4.0, 5, Color(ROSE_COLOR, 0.62 * fade), 0.12)
	for well: Dictionary in wells:
		draw_well(canvas, well)
	if not echo.is_empty():
		var center := Vector2(echo.x, echo.y)
		var charge := 1.0 - float(echo.left) / ECHO_DELAY
		canvas.draw_arc(center, ECHO_RADIUS, -PI * 0.5, TAU * charge - PI * 0.5, 48,
			Color(ROSE_COLOR, 0.80), 2.0, true)
		draw_runes(canvas, center, ECHO_RADIUS * 0.78, 6, Color(ROSE_COLOR, 0.50), charge * 1.2)
	if not echo_flash.is_empty():
		var center := Vector2(echo_flash.x, echo_flash.y)
		var fade := float(echo_flash.left) / ECHO_FLASH
		canvas.draw_arc(center, lerpf(ECHO_RADIUS, 16.0, fade * fade), 0.0, TAU, 44,
			Color(ROSE_COLOR, fade * 0.75), 3.0, true)


static func draw_well(canvas: Node2D, well: Dictionary) -> void:
	var center := Vector2(well.x, well.y)
	var progress := 1.0 - float(well.left) / WELL_LIFE
	var fade := sin(clampf(progress * 1.11 + 0.10, 0.0, 1.0) * PI) * 0.76 + (1.0 - progress) * 0.22
	canvas.draw_circle(center, WELL_RADIUS, Color(0.115, 0.055, 0.18, fade * 0.43), true, -1.0, true)
	canvas.draw_arc(center, WELL_RADIUS, 0.0, TAU, 56, Color(INK_COLOR, fade * 0.67), 1.4, true)
	for strand in range(2):
		var curl := PackedVector2Array()
		for index in range(28):
			var t := float(index) / 27.0
			curl.append(center + Vector2.from_angle(t * TAU * 0.90 - progress * 4.0 + PI * strand)
				* lerpf(5.0, WELL_RADIUS - 3.0, t))
		canvas.draw_polyline(curl, Color(ROSE_COLOR if strand == 0 else INK_COLOR, fade), 2.3, true)
	if bool(well.bloomed):
		var pulse_phase := clampf((progress * WELL_LIFE - WELL_BLOOM_AT) / (WELL_LIFE - WELL_BLOOM_AT), 0.0, 1.0)
		canvas.draw_arc(center, lerpf(9.0, WELL_RADIUS, sqrt(pulse_phase)), 0.0, TAU, 50,
			Color("#f8c8ea", 1.0 - pulse_phase), 3.2, true)


static func draw_runes(canvas: Node2D, center: Vector2, radius: float, count: int, tint: Color, twist: float) -> void:
	for index in range(count):
		var direction := Vector2.from_angle(twist + float(index) * TAU / float(count))
		var point := center + direction * radius
		canvas.draw_line(point - direction.orthogonal() * 2.1, point + direction * 2.2, tint, 1.2, true)


static func draw_bolt(canvas: Node2D, position: Vector2, direction: Vector2, clock: float) -> void:
	var accent := Color("#f3b5e1")
	canvas.draw_line(position - direction * 18.0, position, Color(0.65, 0.42, 0.82, 0.50), 4.2, true)
	canvas.draw_circle(position, 4.8, Color("#a569bc"), true, -1.0, true)
	canvas.draw_circle(position, 2.7, Color("#ffe1ed"), true, -1.0, true)
	for phase in [0.0, PI]:
		var angle := clock * 14.0 + float(phase)
		var petal := position + direction.orthogonal() * cos(angle) * 7.0 - direction * (4.0 + sin(angle) * 4.0)
		canvas.draw_circle(petal, 1.9, accent, true, -1.0, true)
