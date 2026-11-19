extends RefCounted

const TEA_ART = preload("res://assets/art/items/room_rewards.png")
const TEA_REGION = Rect2(40, 141, 819, 680)
const LANES = 5
const LANE_WIDTH = 85.0
const FIELD = Rect2(96, 105, 425, 200)
const GOAL = 8
const LIMIT = 21.0
const SPILL_LIMIT = 3
const DROP_PERIOD = 0.77
const DROP_TIME = 1.71
const STEP = 1.0 / 60.0
const RECEIVING_Y = 277.0
const CUP_TOP = 123.0
const GOLD = Color("#fad29f")
const CRACKED = Color("#f1a2ae")

var state := ""
var match_seed := 0
var drops: Array[Dictionary] = []
var lane := 2
var tray_x := lane_center(2)
var started := false
var elapsed := 0.0
var carried := 0.0
var spawned := 0
var caught := 0
var spills := 0
var feedback := ""
var feedback_x := 0.0
var flare := 0.0

func reset() -> void:
	state = ""
	drops.clear()
	lane = 2
	tray_x = lane_center(2)
	started = false
	elapsed = 0.0
	carried = 0.0
	spawned = 0
	caught = 0
	spills = 0
	feedback = ""
	feedback_x = 0.0
	flare = 0.0

func begin(seed_value: int, _hero_index: int) -> void:
	reset()
	match_seed = posmod(seed_value, 2147483647)
	state = "playing"

func snapshot() -> Dictionary:
	return {"state": state, "seed": match_seed, "drops": drops.duplicate(true), "lane": lane,
		"tray_x": tray_x, "started": started, "elapsed": elapsed, "carried": carried,
		"spawned": spawned, "caught": caught, "spills": spills, "feedback": feedback,
		"feedback_x": feedback_x, "flare": flare}

func restore(raw: Variant) -> void:
	reset()
	if not raw is Dictionary or str(raw.get("state", "")) not in ["playing", "win", "draw", "loss"]:
		return
	var saved_drops: Variant = raw.get("drops", [])
	if not saved_drops is Array or saved_drops.size() > 8:
		return
	for entry in saved_drops:
		if not entry is Dictionary or int(entry.get("lane", -1)) not in range(LANES):
			reset()
			return
		drops.append({"lane": int(entry.lane), "bad": bool(entry.get("bad", false)),
			"age": clampf(float(entry.get("age", 0.0)), 0.0, DROP_TIME)})
	state = str(raw.state)
	match_seed = int(raw.get("seed", 0))
	lane = clampi(int(raw.get("lane", 2)), 0, LANES - 1)
	tray_x = clampf(float(raw.get("tray_x", lane_center(lane))), lane_center(0), lane_center(LANES - 1))
	started = bool(raw.get("started", false))
	elapsed = clampf(float(raw.get("elapsed", 0.0)), 0.0, LIMIT)
	carried = clampf(float(raw.get("carried", 0.0)), 0.0, STEP)
	spawned = clampi(int(raw.get("spawned", 0)), 0, 30)
	caught = clampi(int(raw.get("caught", 0)), 0, GOAL)
	spills = clampi(int(raw.get("spills", 0)), 0, SPILL_LIMIT)
	feedback = str(raw.get("feedback", ""))
	feedback_x = float(raw.get("feedback_x", lane_center(lane)))
	flare = clampf(float(raw.get("flare", 0.0)), 0.0, 0.44)

static func lane_center(index: int) -> float:
	return FIELD.position.x + (float(index) + 0.5) * LANE_WIDTH

func set_lane(game, next: int) -> void:
	if state != "playing":
		return
	var destination := clampi(next, 0, LANES - 1)
	if lane != destination or not started:
		game.sound.play("board_move")
	lane = destination
	started = true

func tap(game, point: Vector2) -> void:
	if FIELD.grow_individual(0.0, 0.0, 0.0, 5.0).has_point(point):
		set_lane(game, floori((point.x - FIELD.position.x) / LANE_WIDTH))

func key(game, code: int) -> void:
	if code == KEY_LEFT:
		set_lane(game, lane - 1)
	elif code == KEY_RIGHT:
		set_lane(game, lane + 1)
	elif code in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]:
		set_lane(game, code - KEY_1)

func tick(game, delta: float) -> void:
	if state != "playing" or not started:
		return
	carried += delta
	while state == "playing" and carried >= STEP:
		carried -= STEP
		advance_dropper(game)

func advance_dropper(game) -> void:
	elapsed += STEP
	flare = maxf(0.0, flare - STEP)
	tray_x = move_toward(tray_x, lane_center(lane), LANE_WIDTH * 8.2 * STEP)
	while elapsed >= 0.18 + spawned * DROP_PERIOD and elapsed < LIMIT - DROP_TIME:
		spawn_wave()
	for index in range(drops.size() - 1, -1, -1):
		var drop := drops[index]
		drop.age = float(drop.age) + STEP
		if float(drop.age) >= DROP_TIME:
			drops.remove_at(index)
			finish_drop(game, drop)
			if state != "playing":
				return
	if elapsed >= LIMIT:
		state = "draw" if caught >= GOAL / 2 else "loss"
		feedback = "Service is over"

func spawn_wave() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = match_seed + spawned * 79613
	var target := 2 if spawned == 0 else rng.randi_range(0, LANES - 1)
	drops.append({"lane": target, "bad": spawned % 5 == 3, "age": 0.0})
	if spawned > 2 and spawned % 4 == 2:
		var decoy := (target + rng.randi_range(1, LANES - 1)) % LANES
		drops.append({"lane": decoy, "bad": true, "age": 0.0})
	spawned += 1

func finish_drop(game, drop: Dictionary) -> void:
	var target := lane_center(int(drop.lane))
	var intercepted := absf(tray_x - target) < LANE_WIDTH * 0.43
	if intercepted and not drop.bad:
		caught += 1
		feedback = "Cup served"
		game.sound.play("arcade_collect")
		if caught >= GOAL:
			state = "win"
			feedback = "Order complete"
	elif intercepted and drop.bad:
		spills += 1
		feedback = "Cracked cup spilled"
		game.sound.play("arcade_miss")
		if spills >= SPILL_LIMIT:
			state = "loss"
			feedback = "Too many spills"
	elif not drop.bad:
		feedback = "Cup missed"
		game.sound.play("arcade_miss")
	else:
		return
	feedback_x = target
	flare = 0.44

func draw(game) -> void:
	var view = game.View
	view.frame(game, Rect2(83, 91, 451, 223), Color("#392a36"), Color("#b68a64"))
	view.frame(game, Rect2(554, 91, 214, 223), Color("#30263a"), Color("#b68a64"))
	draw_lanes(game)
	for drop in drops:
		draw_cup(game, drop)
	draw_tray(game)
	if flare > 0.0:
		draw_feedback(game)

	view.centered(game, Rect2(563, 101, 195, 29), "%d / %d cups served" % [caught, GOAL], 19, view.CREAM, true)
	var ratio := clampf(float(caught) / GOAL, 0.0, 1.0)
	game.draw_rect(Rect2(580, 139, 162, 5), Color("#655168"))
	game.draw_rect(Rect2(580, 139, roundf(162.0 * ratio), 5), GOLD)
	view.centered(game, Rect2(564, 153, 193, 24), "%d / %d spills" % [spills, SPILL_LIMIT], 13, CRACKED)
	var prompt := "%ds left" % ceili(maxf(0.0, LIMIT - elapsed))
	if not started:
		prompt = "Tap a lane to begin"
	elif state != "playing":
		prompt = feedback
	view.centered(game, Rect2(560, 182, 202, 26), prompt, 16, view.CREAM)
	view.centered(game, Rect2(560, 222, 201, 23), "Catch the gold tea cups.", 12, view.DIM)
	view.centered(game, Rect2(560, 245, 201, 23), "Avoid cracked cups with ! marks.", 11, view.DIM)
	view.centered(game, Rect2(558, 274, 207, 23), "Tap lanes or use ←  → / 1–5.", 11, view.DIM)

func draw_lanes(game) -> void:
	for index in range(LANES):
		var area := Rect2(FIELD.position + Vector2(index * LANE_WIDTH, 0), Vector2(LANE_WIDTH, FIELD.size.y)).grow(-1.0)
		var active := index == lane
		var hover: bool = state == "playing" and area.has_point(game.get_local_mouse_position())
		var tint := Color("#513b48") if active else Color("#412e3d")
		if hover:
			tint = tint.lightened(0.10)
		game.draw_rect(area, tint)
		game.draw_line(Vector2(lane_center(index), 139.0), Vector2(lane_center(index), 260.0), Color("#624a57"), 1.0)
		game.View.diamond(game, Vector2(lane_center(index), 114), 3.4, GOLD if active else Color("#856875"))
		game.View.centered(game, Rect2(area.position.x, 288, area.size.x, 14), "%d" % (index + 1), 10, Color("#ddb69b"))
	game.draw_line(Vector2(FIELD.position.x + 4, RECEIVING_Y), Vector2(FIELD.end.x - 4, RECEIVING_Y),
		Color("#b59079"), 1.3, true)

func draw_cup(game, drop: Dictionary) -> void:
	var phase := clampf(float(drop.age) / DROP_TIME, 0.0, 1.0)
	var x := lane_center(int(drop.lane))
	var y := lerpf(CUP_TOP, RECEIVING_Y, phase)
	var center := Vector2(roundf(x), roundf(y))
	var is_bad: bool = drop.bad
	var tint := Color("#edb2b4") if is_bad else Color.WHITE
	var size := Vector2(39, 32)
	game.draw_texture_rect_region(TEA_ART, Rect2((center - size * 0.5).round(), size), TEA_REGION, tint)
	if is_bad:
		game.draw_polyline(PackedVector2Array([center + Vector2(-6, -10), center + Vector2(3, -5),
			center + Vector2(-3, 2), center + Vector2(4, 8)]), Color("#60283b"), 2.5, true)
		game.draw_circle(center + Vector2(20, -10), 7.0, Color("#893f58"), true, -1.0, true)
		game.View.centered(game, Rect2(center + Vector2(14, -17), Vector2(12, 13)), "!", 10, Color("#fff4d8"))
	elif phase > 0.1:
		game.View.diamond(game, center + Vector2(16, -7), 2.1, Color(GOLD, 0.7 + sin(phase * TAU) * 0.22))

func draw_tray(game) -> void:
	var center := Vector2(roundf(tray_x), RECEIVING_Y + 5.0)
	var tray := PackedVector2Array([center + Vector2(-31, -4), center + Vector2(31, -4),
		center + Vector2(26, 4), center + Vector2(-26, 4)])
	game.draw_colored_polygon(tray, Color("#d6a974"))
	game.draw_polyline(PackedVector2Array([center + Vector2(-31, -4),
		center + Vector2(31, -4), center + Vector2(26, 4)]), Color("#ffe3ad"), 2.0, true)
	game.View.diamond(game, center, 3.7, Color("#ecd19e"))

func draw_feedback(game) -> void:
	var strength := flare / 0.44
	var tint := GOLD if feedback in ["Cup served", "Order complete"] else CRACKED
	var center := Vector2(feedback_x, RECEIVING_Y - 17.0)
	for index in range(5):
		var axis := Vector2.from_angle(TAU * index / 5.0)
		var point := (center + axis * (8.0 + (1.0 - strength) * 20.0)).round()
		game.View.diamond(game, point, 3.2 * strength, Color(tint, strength))
