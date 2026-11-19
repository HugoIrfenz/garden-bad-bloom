extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Statuses = preload("res://scripts/combat_statuses.gd")
const Talents = preload("res://scripts/run_talents.gd")
const SNAREWOOD = "snarewood_bow"
const TIDY_DISASTER = "tidy_disaster"
const SOURCES = ["wall", "skill"]
const PIN_TIME = 8.0
const THREAD_TIME = 9.0
const ARM_TIME = 0.24
const PULSE_TIME = 0.28
const WIDTH = 10.0
const MIN_LENGTH = 42.0
const MAX_LENGTH = 525.0
const ARROW_DAMAGE = 18
const THREAD_COLOR = Color("#e4c18b")
const EVOLVED_COLOR = Color("#f591c2")

var pins: Dictionary = {}
var lines: Dictionary = {}
var _pulses: Array[Dictionary] = []

static func can_pin(weapon: String) -> bool:
	return weapon == SNAREWOOD or weapon == TIDY_DISASTER

func reset() -> void:
	pins.clear()
	lines.clear()
	_pulses.clear()

func snapshot() -> Dictionary:
	return {"pins": pins.duplicate(true), "lines": lines.duplicate(true)}

func restore(data: Variant) -> void:
	reset()
	if not data is Dictionary:
		return
	var saved_pins: Variant = data.get("pins", {})
	var saved_lines: Variant = data.get("lines", {})
	for source: String in SOURCES:
		if saved_pins is Dictionary:
			var pin: Variant = saved_pins.get(source)
			if pin is Dictionary and pin.has_all(["x", "y", "left", "side"]) and site(pin).is_finite():
				var left := clampf(float(pin.left), 0.0, PIN_TIME)
				var side := int(pin.side)
				if left > 0.0 and ((source == "wall" and side >= 0 and side < 4) or (source == "skill" and side == -1)):
					pins[source] = {"x": float(pin.x), "y": float(pin.y), "left": left, "side": side}
		if saved_lines is Dictionary:
			var line: Variant = saved_lines.get(source)
			if line is Dictionary and line.has_all(["x", "y", "ex", "ey", "left"]):
				var from := site(line)
				var to := Vector2(line.ex, line.ey)
				var left := clampf(float(line.left), 0.0, THREAD_TIME)
				if from.is_finite() and to.is_finite() and left > 0.0 and link_length_ok(from, to):
					lines[source] = make_line(from, to, bool(line.get("evolved", false)), left)

static func wall_contact(bounds: Rect2, start: Vector2, finish: Vector2) -> Dictionary:
	if not bounds.has_point(start) or bounds.has_point(finish):
		return {}
	var corners := PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y),
		bounds.end, Vector2(bounds.position.x, bounds.end.y)])
	var distance := INF
	var result := {}
	for index in range(corners.size()):
		var crossing: Variant = Geometry2D.segment_intersects_segment(start, finish, corners[index], corners[(index + 1) % corners.size()])
		if crossing is Vector2:
			var along := start.distance_squared_to(Vector2(crossing))
			if along < distance:
				distance = along
				result = {"tip": crossing, "point": Vector2(crossing).clamp(bounds.position + Vector2(8, 8), bounds.end - Vector2(8, 8)),
					"side": index}
	return result

func pin_wall(game, contact: Dictionary, weapon: String) -> void:
	place(game, "wall", contact.point, int(contact.side), weapon == TIDY_DISASTER)

func pin_skill(game, point: Vector2) -> void:
	var talents = game.get("talents")
	if talents == null or not talents.owns(Talents.SEWING_THREAD):
		return
	place(game, "skill", point, -1, game.armory.for_hero(game.hero) == TIDY_DISASTER)

func place(game, source: String, point: Vector2, side: int, evolved: bool) -> void:
	var pin: Dictionary = pins.get(source, {})
	if not pin.is_empty():
		var from := site(pin)
		if (source != "wall" or int(pin.side) != side) and link_length_ok(from, point) \
				and not Geometry.blocked(game, from, point, 16.0):
			lines[source] = make_line(from, point, evolved, THREAD_TIME)
			pins.erase(source)
			game.sound.play("guard")
			game.checkpoint.call_deferred()
			return
	pins[source] = {"x": point.x, "y": point.y, "left": PIN_TIME, "side": side}
	game.checkpoint.call_deferred()

static func make_line(from: Vector2, to: Vector2, evolved: bool, left: float) -> Dictionary:
	return {"x": from.x, "y": from.y, "ex": to.x, "ey": to.y, "left": left, "evolved": evolved}

static func link_length_ok(from: Vector2, to: Vector2) -> bool:
	var length := from.distance_squared_to(to)
	return length >= MIN_LENGTH * MIN_LENGTH and length <= MAX_LENGTH * MAX_LENGTH

static func site(data: Dictionary) -> Vector2:
	return Vector2(data.x, data.y)

func sample_foes(game) -> Array[Dictionary]:
	var samples: Array[Dictionary] = []
	if not lines.is_empty():
		for foe: Dictionary in game.foes:
			if Statuses.accepts_status(game, foe):
				samples.append({"foe": foe, "point": game.target(foe)})
	return samples

func tick(game, samples: Array[Dictionary], delta: float) -> void:
	for index in range(_pulses.size() - 1, -1, -1):
		_pulses[index].left -= delta
		if _pulses[index].left <= 0.0:
			_pulses.remove_at(index)
	for source: String in SOURCES:
		if pins.has(source):
			pins[source].left -= delta
			if pins[source].left <= 0.0:
				pins.erase(source)
		if not lines.has(source):
			continue
		var line: Dictionary = lines[source]
		line.left -= delta
		if line.left <= 0.0:
			lines.erase(source)
		elif THREAD_TIME - float(line.left) >= ARM_TIME:
			cross_line(game, source, line, samples)

func cross_line(game, source: String, line: Dictionary, samples: Array[Dictionary]) -> void:
	var from := site(line)
	var to := Vector2(line.ex, line.ey)
	var victims: Array[Dictionary] = []
	for sample in samples:
		var foe: Dictionary = sample.foe
		if Statuses.accepts_status(game, foe) and crosses(from, to, sample.point, game.target(foe)):
			victims.append(foe)
	if victims.is_empty():
		return
	lines.erase(source)
	_pulses.append(make_line(from, to, line.evolved, PULSE_TIME))
	var power: int = game.player_hit_amount(maxi(1, ARROW_DAMAGE + int(game.bonus))) if line.evolved else 0
	var credit := Talents.SEWING_THREAD if source == "skill" else SNAREWOOD
	for foe in victims:
		game.combat_status.apply_foe(foe, Statuses.ROOT, 1.15, 1.0, credit)
		if power > 0:
			var damage: int = game.defend_foe(foe, power)
			if damage > 0:
				foe.hp -= damage
				foe.flash = 0.14
	game.sound.play("hit" if line.evolved else "guard")
	game.checkpoint.call_deferred()

static func crosses(from: Vector2, to: Vector2, start: Vector2, finish: Vector2) -> bool:
	return Geometry.segment_gap(start, from, to) <= WIDTH or Geometry.segment_gap(finish, from, to) <= WIDTH \
		or Geometry.segment_gap(from, start, finish) <= WIDTH or Geometry.segment_gap(to, start, finish) <= WIDTH \
		or Geometry2D.segment_intersects_segment(from, to, start, finish) != null

func draw(game) -> void:
	var canvas: Node2D = game.world_canvas
	for source: String in SOURCES:
		if pins.has(source):
			var pin: Dictionary = pins[source]
			draw_pin(game, canvas, site(pin), Color(THREAD_COLOR, minf(1.0, float(pin.left))), source == "skill")
		if lines.has(source):
			var line: Dictionary = lines[source]
			var tint := EVOLVED_COLOR if bool(line.evolved) else THREAD_COLOR
			var from := site(line)
			var to := Vector2(line.ex, line.ey)
			var armed := THREAD_TIME - float(line.left) >= ARM_TIME
			var opacity := 0.66 + 0.16 * sin(float(game.visual_clock) * 6.0) if armed else 0.37
			canvas.draw_line(from.round(), to.round(), Color(tint, opacity * minf(1.0, float(line.left))), 1.5, true)
			var marks := clampi(roundi(from.distance_to(to) / 34.0), 2, 16)
			for index in range(1, marks):
				game.View.diamond(canvas, from.lerp(to, float(index) / marks).round(), 2.0, Color(tint, opacity))
			draw_pin(game, canvas, from, tint, source == "skill")
			draw_pin(game, canvas, to, tint, source == "skill")
	for pulse in _pulses:
		draw_pulse(game, canvas, pulse)

static func draw_pin(game, canvas: Node2D, point: Vector2, tint: Color, skill: bool) -> void:
	var center := point.round()
	canvas.draw_arc(center, 7.0 if skill else 5.5, 0, TAU, 18, Color(tint, tint.a * 0.6), 1.2, true)
	game.View.diamond(canvas, center, 3.8, tint)

static func draw_pulse(game, canvas: Node2D, pulse: Dictionary) -> void:
	var fade := float(pulse.left) / PULSE_TIME
	var from := site(pulse)
	var to := Vector2(pulse.ex, pulse.ey)
	var tint := EVOLVED_COLOR if bool(pulse.evolved) else THREAD_COLOR
	canvas.draw_line(from.round(), to.round(), Color(tint, fade * 0.55), 3.0, true)
	if bool(pulse.evolved):
		var direction := from.direction_to(to)
		for index in range(3):
			var progress := clampf((1.0 - fade) * 1.26 - index * 0.12, 0.0, 1.0)
			var point := from.lerp(to, progress).round()
			canvas.draw_line(point - direction * 14.0, point, Color("#ffda98", fade), 2.0, true)
			game.View.diamond(canvas, point, 4.4, Color("#ffe5b2", fade))
