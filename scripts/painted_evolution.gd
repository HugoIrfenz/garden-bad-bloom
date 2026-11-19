extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const GLITTER = "glitter_crime"
const EXIT = "painted_exit"
const WEAPON = "colorstorm_path"
const PAINT_LIFE = 2.8
const EXIT_LIFE = 4.2
const RETURN_LIMIT = 184.0
const PAINT_LIMIT = 3
const COLORS = [Color("#f5a6c6"), Color("#a8ebd6"), Color("#f4cb85")]

var return_mark: Dictionary = {}
var paints: Array[Dictionary] = []
var bursts: Array[Dictionary] = []
var last_cut := -1
var color_hits := 0
var returning := false

func reset() -> void:
	return_mark.clear()
	paints.clear()
	bursts.clear()
	last_cut = -1
	color_hits = 0
	returning = false

func snapshot() -> Dictionary:
	return {"exit": return_mark.duplicate(), "paints": paints.duplicate(true), "last_cut": last_cut,
		"color_hits": color_hits, "returning": returning}

func restore(saved: Variant) -> void:
	reset()
	if not saved is Dictionary:
		return
	return_mark = read_mark(saved.get("exit"), EXIT_LIFE)
	var records: Variant = saved.get("paints")
	if records is Array:
		for data in records.slice(0, PAINT_LIMIT):
			var site := read_mark(data, PAINT_LIFE)
			if not site.is_empty():
				site.color = clampi(int(data.get("color", 0)), 0, COLORS.size() - 1)
				paints.append(site)
	last_cut = maxi(-1, int(saved.get("last_cut", -1)))
	color_hits = clampi(int(saved.get("color_hits", 0)), 0, 2)
	returning = bool(saved.get("returning", false))

static func read_mark(raw: Variant, duration: float) -> Dictionary:
	if not raw is Dictionary or not raw.has_all(["x", "y", "left"]):
		return {}
	var point := Vector2(float(raw.x), float(raw.y))
	var time := clampf(float(raw.left), 0.0, duration)
	if not point.is_finite() or time <= 0.0:
		return {}
	return {"x": point.x, "y": point.y, "left": time}

static func evolved(game) -> bool:
	return game.hero == 4 and game.armory.for_hero(4) == WEAPON

static func flank(game, foe: Dictionary) -> bool:
	if game.hero != 4 or not game.relics.has_relic(GLITTER) or not foe.has_all(["dx", "dy"]) \
			or foe.get("flower_node", false) or foe.get("web_anchor", false):
		return false
	var heading := Vector2(float(foe.dx), float(foe.dy)).normalized()
	var position: Vector2 = game.target(foe)
	return not heading.is_zero_approx() and heading.dot(position.direction_to(game.player)) < -0.54

func mark_exit(game, origin: Vector2) -> void:
	if game.hero != 4 or not game.relics.has_relic(EXIT) or origin.distance_squared_to(game.player) < 8.0 * 8.0:
		return
	return_mark = {"x": origin.x, "y": origin.y, "left": EXIT_LIFE}

func take_return(game) -> Vector2:
	if return_mark.is_empty() or game.hero != 4 or not game.relics.has_relic(EXIT):
		return Vector2.INF
	var origin: Vector2 = game.player
	var point := Vector2(return_mark.x, return_mark.y)
	var gap := origin.distance_to(point)
	var aim := origin.direction_to(point)
	if gap < 15.0 or gap > RETURN_LIMIT or aim.dot(game.facing) < 0.46:
		return Vector2.INF
	if Geometry.blocked(game, origin, point, game.BARREL_CLEARANCE):
		return Vector2.INF
	return_mark.clear()
	returning = true
	return point

func after_basic(game, foe: Dictionary, attack_id: int, was_flank: bool) -> void:
	if game.hero != 4 or attack_id < 0 or attack_id == last_cut:
		return
	last_cut = attack_id
	var hue := color_hits
	var overpaint := false
	if evolved(game):
		color_hits = (color_hits + 1) % 3
		overpaint = color_hits == 0
	if not was_flank and not overpaint:
		return
	var position: Vector2 = game.target(foe)
	if paints.size() >= PAINT_LIMIT:
		paints.pop_front()
	paints.append({"x": position.x, "y": position.y, "left": PAINT_LIFE, "color": hue})

func tick(game, before: Vector2, delta: float) -> void:
	if not return_mark.is_empty():
		return_mark.left = float(return_mark.left) - delta
		if return_mark.left <= 0.0:
			return_mark.clear()
	for index in range(bursts.size() - 1, -1, -1):
		bursts[index].left -= delta
		if bursts[index].left <= 0.0:
			bursts.remove_at(index)

	var landed_return: bool = returning and float(game.dash_remaining) <= 0.0
	if landed_return:
		returning = false
		if evolved(game) and not paints.is_empty():
			pulse(game, game.player, 57.0, 12, 0)
			paints.clear()
			game.checkpoint.call_deferred()
			return
	for index in range(paints.size() - 1, -1, -1):
		var patch := paints[index]
		patch.left -= delta
		if patch.left <= 0.0:
			paints.remove_at(index)
			continue
		var point := Vector2(patch.x, patch.y)
		if not (returning and evolved(game)) and before.distance_squared_to(point) > 18.0 * 18.0 \
				and Geometry.segment_gap(point, before, game.player) <= 18.0:
			paints.remove_at(index)
			pulse(game, point, 36.0, 6, int(patch.color))
			game.checkpoint.call_deferred()

func pulse(game, point: Vector2, radius: float, damage: int, color: int) -> void:
	bursts.append({"point": point, "radius": radius, "left": 0.32, "color": color})
	for foe: Dictionary in game.foes:
		var center: Vector2 = game.target(foe)
		if int(foe.hp) <= 0 or center.distance_squared_to(point) > radius * radius \
				or Geometry.blocked(game, point, center, 12.0):
			continue
		var loss: int = game.defend_foe(foe, game.player_hit_amount(damage))
		if loss > 0:
			foe.hp -= loss
			foe.flash = 0.14
	game.sound.play("zaria", 1.15)

func draw(game) -> void:
	var canvas: Node2D = game.world_canvas
	if not return_mark.is_empty():
		var point := Vector2(return_mark.x, return_mark.y).round()
		var direction: Vector2 = game.player.direction_to(point)
		var across := direction.orthogonal()
		canvas.draw_circle(point, 15.0, Color("#a8ebd6", 0.15), true, -1.0, true)
		canvas.draw_arc(point, 14.0, 0, TAU, 30, Color("#a8ebd6", 0.68), 1.5, true)
		canvas.draw_colored_polygon(PackedVector2Array([point + direction * 9.0,
			point - direction * 5.0 + across * 5.0, point - direction * 5.0 - across * 5.0]), Color("#a8ebd6"))
	for patch in paints:
		var point := Vector2(patch.x, patch.y).round()
		var tint: Color = COLORS[int(patch.color)]
		canvas.draw_circle(point, 18.0, Color(tint, 0.17), true, -1.0, true)
		for index in range(4):
			var edge := (point + Vector2.from_angle(game.visual_clock * 0.42 + PI * index * 0.5) * 14.0).round()
			game.View.diamond(canvas, edge, 2.7, Color(tint, 0.65))
	for sweep in bursts:
		var progress := 1.0 - float(sweep.left) / 0.32
		var point: Vector2 = sweep.point
		for index in range(3):
			var tint: Color = COLORS[(int(sweep.color) + index) % COLORS.size()]
			var angle := TAU * float(index) / 3.0 + progress * 2.1
			canvas.draw_arc(point, lerpf(10.0, float(sweep.radius), progress), angle, angle + 1.3,
				22, Color(tint, 1.0 - progress), 4.0 - progress * 2.0, true)
