extends RefCounted

const WIDTH = 14
const HEIGHT = 8
const CELL = 23
const ORIGIN = Vector2(109, 114)
const FIELD = Rect2(ORIGIN, Vector2(WIDTH, HEIGHT) * CELL)
const GOAL = 6
const TIME_LIMIT = 36.0
const DIRECTION_TILES = [
	Rect2(583, 189, 46, 41), Rect2(528, 237, 46, 41),
	Rect2(583, 237, 46, 41), Rect2(638, 237, 46, 41),
]
const VECTORS = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
const KEY_CODES = [KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]
const MOSS = Color("#83a658")
const PETAL = Color("#f8c986")

var state := ""
var match_seed := 0
var body: Array[Vector2i] = []
var direction := Vector2i.RIGHT
var queued := Vector2i.ZERO
var food := Vector2i(-1, -1)
var started := false
var elapsed := 0.0
var carried := 0.0
var petals := 0
var reason := ""
var flash := 0.0

func reset() -> void:
	state = ""
	body.clear()
	direction = Vector2i.RIGHT
	queued = Vector2i.ZERO
	food = Vector2i(-1, -1)
	started = false
	elapsed = 0.0
	carried = 0.0
	petals = 0
	reason = ""
	flash = 0.0

func begin(seed_value: int, _hero_index: int) -> void:
	reset()
	match_seed = posmod(seed_value, 2147483647)
	body.assign([Vector2i(4, 4), Vector2i(3, 4), Vector2i(2, 4)])
	state = "playing"
	choose_food()

func snapshot() -> Dictionary:
	var trail: Array = []
	for segment in body:
		trail.append([segment.x, segment.y])
	return {"state": state, "seed": match_seed, "trail": trail, "direction": [direction.x, direction.y],
		"queued": [queued.x, queued.y], "food": [food.x, food.y], "started": started,
		"elapsed": elapsed, "carried": carried, "petals": petals, "reason": reason, "flash": flash}

func restore(raw: Variant) -> void:
	reset()
	if not raw is Dictionary or str(raw.get("state", "")) not in ["playing", "win", "draw", "loss"]:
		return
	var trail: Variant = raw.get("trail")
	if not trail is Array or trail.size() < 3 or trail.size() > GOAL + 3:
		return
	for pair in trail:
		var cell := point_from(pair)
		if not on_board(cell) or cell in body:
			reset()
			return
		body.append(cell)
	var saved_direction := point_from(raw.get("direction"))
	var saved_food := point_from(raw.get("food"))
	if saved_direction not in VECTORS or not on_board(saved_food):
		reset()
		return
	direction = saved_direction
	food = saved_food
	var saved_turn := point_from(raw.get("queued"))
	queued = saved_turn if saved_turn in VECTORS and saved_turn != -direction else Vector2i.ZERO
	match_seed = int(raw.get("seed", 0))
	state = str(raw.state)
	started = bool(raw.get("started", false))
	elapsed = clampf(float(raw.get("elapsed", 0.0)), 0.0, TIME_LIMIT)
	carried = clampf(float(raw.get("carried", 0.0)), 0.0, 0.25)
	petals = clampi(int(raw.get("petals", 0)), 0, GOAL)
	reason = str(raw.get("reason", ""))
	flash = clampf(float(raw.get("flash", 0.0)), 0.0, 0.35)

static func point_from(raw: Variant) -> Vector2i:
	if raw is Array and raw.size() == 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	return Vector2i(-1, -1)

static func on_board(point: Vector2i) -> bool:
	return point.x >= 0 and point.x < WIDTH and point.y >= 0 and point.y < HEIGHT

func choose_food() -> void:
	var options: Array[Vector2i] = []
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var slot := Vector2i(x, y)
			if slot not in body:
				options.append(slot)
	var rng := RandomNumberGenerator.new()
	rng.seed = match_seed + 117413 * petals
	food = options[rng.randi_range(0, options.size() - 1)]

func queue_turn(game, next: Vector2i) -> void:
	if state != "playing" or next == -direction or queued != Vector2i.ZERO:
		return
	started = true
	if next != direction:
		queued = next
		game.sound.play("board_move")

func tap(game, point: Vector2) -> void:
	for index in range(DIRECTION_TILES.size()):
		if DIRECTION_TILES[index].has_point(point):
			queue_turn(game, VECTORS[index])
			return

func key(game, code: int) -> void:
	var index := KEY_CODES.find(code)
	if index >= 0:
		queue_turn(game, VECTORS[index])

func tick(game, delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	if state != "playing" or not started:
		return
	var step := minf(delta, TIME_LIMIT - elapsed)
	elapsed += step
	carried += step
	while state == "playing" and carried >= move_interval():
		carried -= move_interval()
		advance_snake(game)
	if state == "playing" and elapsed >= TIME_LIMIT:
		state = "draw" if petals >= 3 else "loss"
		reason = "Time ran out"

func move_interval() -> float:
	return maxf(0.18, 0.255 - float(petals) * 0.012)

func advance_snake(game) -> void:
	if queued != Vector2i.ZERO:
		direction = queued
		queued = Vector2i.ZERO
	var head := body[0] + direction
	var grows := head == food
	var segment := body.find(head)
	if not on_board(head) or (segment >= 0 and (grows or segment < body.size() - 1)):
		reason = "Hit the hedge" if not on_board(head) else "Caught your own trail"
		state = "loss"
		game.sound.play("arcade_miss")
		return
	body.push_front(head)
	if grows:
		petals += 1
		flash = 0.35
		game.sound.play("arcade_collect")
		if petals >= GOAL:
			state = "win"
			reason = "Petal basket filled"
		else:
			choose_food()
	else:
		body.pop_back()

static func cell_center(point: Vector2i) -> Vector2:
	return (ORIGIN + (Vector2(point) + Vector2(0.5, 0.5)) * CELL).round()

func draw(game) -> void:
	var view = game.View
	var garden := Rect2(89, 94, 362, 224)
	view.frame(game, garden, Color("#294439"), Color("#9d9f64"))
	game.draw_rect(FIELD, Color("#294239"))
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var tile := Rect2(ORIGIN + Vector2(x, y) * CELL, Vector2.ONE * CELL).grow(-1.0)
			var tint := Color("#3b5746") if (x + 2 * y) % 3 == 0 else Color("#345041")
			game.draw_rect(tile, tint)
	for point: Vector2 in [Vector2(128, 103), Vector2(274, 105), Vector2(415, 103), Vector2(128, 308), Vector2(415, 308)]:
		view.sprig(game, point, Vector2.RIGHT, Color("#94a565"))
	if state != "win" and on_board(food):
		draw_flower(game, cell_center(food), float(game.visual_clock))
	draw_body(game)

	view.frame(game, Rect2(474, 94, 281, 224), Color("#302836"), Color("#b79570"))
	view.centered(game, Rect2(493, 100, 244, 25), "%d / %d Petals gathered" % [petals, GOAL], 19, view.CREAM, true)
	for index in range(GOAL):
		var tint := PETAL if index < petals else Color("#625368")
		view.diamond(game, Vector2(557 + index * 22, 132), 5, tint)
	var message := reason if state != "playing" else ("Choose a direction to begin" if not started else "%ds left" % ceili(TIME_LIMIT - elapsed))
	view.centered(game, Rect2(487, 149, 256, 24), message, 14, PETAL if state == "win" else view.DIM)
	for index in range(DIRECTION_TILES.size()):
		draw_direction_tile(game, DIRECTION_TILES[index], VECTORS[index])
	view.centered(game, Rect2(486, 285, 259, 21), "Steer with arrows. Avoid hedges and your tail.", 11, view.DIM)

func draw_flower(game, center: Vector2, clock: float) -> void:
	var pulse := 0.64 + 0.19 * sin(clock * 5.5)
	game.draw_circle(center, 9.0, Color(PETAL, 0.19), true, -1.0, true)
	for index in range(5):
		var axis := Vector2.from_angle(TAU * index / 5.0 - PI * 0.5)
		var point := (center + axis * 5.0).round()
		game.draw_circle(point, 3.3, Color(PETAL, pulse + 0.12), true, -1.0, true)
	game.View.diamond(game, center, 3.1, Color("#fff0b2"))

func draw_body(game) -> void:
	if body.is_empty():
		return
	for index in range(body.size() - 1, 0, -1):
		var center := cell_center(body[index])
		var joining := cell_center(body[index - 1])
		game.draw_line(center, joining, Color("#284334"), 16.0, true)
		game.draw_line(center, joining, MOSS.darkened(0.18), 11.0, true)
		game.draw_circle(center, 7.3, MOSS, true, -1.0, true)
		game.draw_circle(center - Vector2(1, 1), 2.2, Color("#b7c977"), true, -1.0, true)
	var head := cell_center(body[0])
	var forward := Vector2(direction)
	var cross := forward.orthogonal()
	game.draw_circle(head, 10.0, Color("#234334"), true, -1.0, true)
	game.draw_circle(head, 8.4, Color("#a9c575"), true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		game.draw_circle((head + forward * 3.0 + cross * side * 4.0).round(), 2.0, Color("#2e2736"), true, -1.0, true)
	if flash > 0.0:
		game.draw_arc(head, 12.0 + (1.0 - flash / 0.35) * 10.0, 0.0, TAU, 24,
			Color(PETAL, flash / 0.35), 1.4, true)

func draw_direction_tile(game, area: Rect2, vector: Vector2i) -> void:
	var allowed := state == "playing" and vector != -direction
	var active := allowed and (area.has_point(game.get_local_mouse_position()) or vector == queued)
	var tint := Color("#f8dcad") if active else (Color("#d5b087") if allowed else Color("#67586a"))
	game.View.frame(game, area, Color("#53404b") if active else Color("#382e43"), tint)
	var center := area.get_center().round()
	var aim := Vector2(vector)
	var cross := aim.orthogonal()
	game.draw_line(center - aim * 9.0, center + aim * 6.0, tint, 2.6, true)
	game.draw_colored_polygon(PackedVector2Array([center + aim * 9.0,
		center + cross * 5.5, center - cross * 5.5]), tint)
