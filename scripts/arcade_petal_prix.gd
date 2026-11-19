extends RefCounted

const EVENT_ID := "petal_prix"
const TRACK_ART := preload("res://assets/art/petal_prix_track.png")
const KART_ART := preload("res://assets/art/petal_prix_karts.png")
const PILOT_REGION := Rect2(130, 59, 794, 646)
const RIVAL_REGION := Rect2(1245, 29, 827, 676)
const TRACK := Rect2(81, 128, 501, 171)
const LEFT_PEDAL := Rect2(608, 188, 78, 86)
const RIGHT_PEDAL := Rect2(695, 188, 78, 86)
const FINISH := 1810.0
const READY_TIME := 2.15
const ROUND_LIMIT := 29.0
const PHOTO_WINDOW := 0.075
const STEP := 1.0 / 120.0
const COAST := 20.0
const TOP_SPEED := 108.0
const BOOST_SPEED := 128.0
const MAX_STREAK := 6
const SECTIONS := [224.0, 474.0, 701.0, 936.0, 1175.0, 1422.0, 1610.0]
const CREAM := Color("#fff0cb")
const GOLD := Color("#f0ce83")
const ROSE := Color("#e29391")
const INK := Color("#251c32")
const BRASS := Color("#927657")

var state := ""
var seed_value := 0
var hero_index := 0
var ready := 0.0
var elapsed := 0.0
var remainder := 0.0
var distance := 0.0
var rival_distance := 0.0
var speed := COAST
var rival_phase := 0.0
var last_tap := -10.0
var last_pedal := -1
var streak := 0
var boost := 0.0
var splash := 0.0
var next_marker := 0
var player_finish := -1.0
var rival_finish := -1.0
var markers: Array[Dictionary] = []


func begin(new_seed: int, new_hero: int) -> void:
	state = "playing"
	seed_value = new_seed
	hero_index = clampi(new_hero, 0, 4)
	ready = READY_TIME
	elapsed = 0.0
	remainder = 0.0
	distance = 0.0
	rival_distance = 0.0
	speed = COAST
	last_tap = -10.0
	last_pedal = -1
	streak = 0
	boost = 0.0
	splash = 0.0
	next_marker = 0
	player_finish = -1.0
	rival_finish = -1.0
	var course := RandomNumberGenerator.new()
	course.seed = seed_value
	rival_phase = course.randf_range(0.0, TAU)
	markers.clear()
	for index in SECTIONS.size():
		markers.append({"at": SECTIONS[index] + course.randf_range(-20.0, 20.0),
			"flower": index % 2 == 0})


func snapshot() -> Dictionary:
	return {
		"state": state, "seed": str(seed_value), "hero": hero_index, "ready": ready,
		"elapsed": elapsed, "remainder": remainder, "distance": distance,
		"rival_distance": rival_distance, "speed": speed, "last_tap": last_tap,
		"last_pedal": last_pedal, "streak": streak, "boost": boost, "splash": splash,
		"next_marker": next_marker, "player_finish": player_finish, "rival_finish": rival_finish,
	}


func restore(raw: Variant) -> void:
	state = ""
	if not raw is Dictionary or raw.get("state", "") not in ["playing", "win", "draw", "loss"]:
		return
	var saved_seed: Variant = raw.get("seed", "0")
	var saved_hero := int(_saved_number(raw, "hero", 0, 0, 4))
	begin(int(saved_seed) if saved_seed is String or saved_seed is int else 0, saved_hero)
	state = raw.state
	ready = _saved_number(raw, "ready", 0.0, 0.0, READY_TIME)
	elapsed = _saved_number(raw, "elapsed", 0.0, 0.0, ROUND_LIMIT + STEP)
	remainder = _saved_number(raw, "remainder", 0.0, 0.0, STEP)
	distance = _saved_number(raw, "distance", 0.0, 0.0, FINISH)
	rival_distance = _saved_number(raw, "rival_distance", 0.0, 0.0, FINISH)
	speed = _saved_number(raw, "speed", COAST, 0.0, BOOST_SPEED)
	last_tap = _saved_number(raw, "last_tap", -10.0, -10.0, elapsed)
	last_pedal = int(_saved_number(raw, "last_pedal", -1, -1, 1))
	streak = int(_saved_number(raw, "streak", 0, 0, MAX_STREAK - 1))
	boost = _saved_number(raw, "boost", 0.0, 0.0, 1.2)
	splash = _saved_number(raw, "splash", 0.0, 0.0, 0.38)
	next_marker = int(_saved_number(raw, "next_marker", 0, 0, markers.size()))
	player_finish = _saved_number(raw, "player_finish", -1.0, -1.0, elapsed)
	rival_finish = _saved_number(raw, "rival_finish", -1.0, -1.0, elapsed)


func _saved_number(raw: Dictionary, field: String, fallback: float,
		low: float, high: float) -> float:
	var value: Variant = raw.get(field, fallback)
	if (value is float or value is int) and is_finite(float(value)):
		return clampf(float(value), low, high)
	return fallback


func tick(game, delta: float) -> void:
	if state != "playing":
		return
	remainder += clampf(delta, 0.0, 0.25)
	while remainder >= STEP and state == "playing":
		remainder -= STEP
		_step(game)


func _step(game) -> void:
	if ready > 0.0:
		ready = maxf(0.0, ready - STEP)
		return
	elapsed += STEP
	boost = maxf(0.0, boost - STEP)
	splash = maxf(0.0, splash - STEP)
	if elapsed - last_tap > 0.66:
		streak = 0
	if player_finish < 0.0:
		speed = move_toward(speed, COAST, (8.0 + (speed - COAST) * 0.255) * STEP)
		speed = minf(speed, BOOST_SPEED if boost > 0.0 else TOP_SPEED)
		distance += speed * STEP
		while next_marker < markers.size() and distance >= markers[next_marker].at:
			var flower: bool = markers[next_marker].flower
			next_marker += 1
			if flower and speed >= 76.0:
				_fire_boost(game, 0.82, 17.0)
			elif not flower and boost <= 0.0:
				speed *= 0.78
				splash = 0.38
				game.sound.play("kart_bump")
		if distance >= FINISH:
			player_finish = elapsed - (distance - FINISH) / speed
			distance = FINISH
	if rival_finish < 0.0:
		var rival_speed := 75.0 + sin(elapsed * 1.42 + rival_phase) * 4.5
		rival_distance += rival_speed * STEP
		if rival_distance >= FINISH:
			rival_finish = elapsed - (rival_distance - FINISH) / rival_speed
			rival_distance = FINISH
	if player_finish >= 0.0 and rival_finish >= 0.0:
		if absf(player_finish - rival_finish) <= PHOTO_WINDOW:
			state = "draw"
		else:
			state = "win" if player_finish < rival_finish else "loss"
	elif player_finish >= 0.0 and elapsed - player_finish > PHOTO_WINDOW:
		state = "win"
	elif rival_finish >= 0.0 and elapsed - rival_finish > PHOTO_WINDOW:
		state = "loss"
	elif elapsed >= ROUND_LIMIT:
		state = "win" if distance > rival_distance else "loss"


func _fire_boost(game, duration: float, thrust: float) -> void:
	boost = maxf(boost, duration)
	speed = minf(speed + thrust, BOOST_SPEED)
	game.sound.play("kart_boost")


func _pedal(game, side: int) -> void:
	var interval := elapsed - last_tap
	if state != "playing" or ready > 0.0 or player_finish >= 0.0 or interval < 0.12:
		return
	var alternating := last_pedal != side and interval <= 0.57
	speed = minf(speed + (13.0 if alternating else 9.0), BOOST_SPEED if boost > 0.0 else TOP_SPEED)
	streak = streak + 1 if alternating else 1
	last_pedal = side
	last_tap = elapsed
	if streak == MAX_STREAK:
		streak = 0
		_fire_boost(game, 1.2, 16.0)
	else:
		game.sound.play("kart_pedal")


func tap(game, point: Vector2) -> void:
	if LEFT_PEDAL.has_point(point):
		_pedal(game, 0)
	elif RIGHT_PEDAL.has_point(point):
		_pedal(game, 1)


func key(game, code: int) -> void:
	if code in [KEY_A, KEY_LEFT]:
		_pedal(game, 0)
	elif code in [KEY_D, KEY_RIGHT]:
		_pedal(game, 1)
	elif code == KEY_SPACE:
		_pedal(game, 1 if last_pedal == 0 else 0)


func draw(game) -> void:
	if state == "":
		return
	var hero_color: Color = game.COLORS[hero_index].lerp(CREAM, 0.30)
	game.View.frame(game, Rect2(77, 89, 509, 215), INK, BRASS)
	game.View.frame(game, Rect2(597, 89, 187, 215), INK, BRASS)
	_draw_standings(game, hero_color)
	_draw_track(game, hero_color)
	_draw_controls(game, hero_color)


func _draw_standings(game, hero_color: Color) -> void:
	var rank := "—"
	if ready <= 0.0 and state != "draw":
		var first := state == "win" or (state == "playing" and distance > rival_distance)
		rank = _copy(game, "1ST", "KE-1") if first else _copy(game, "2ND", "KE-2")
	game.View.text(game, Vector2(89, 111), rank, 16, CREAM, true)
	game.View.text(game, Vector2(133, 106), game.NAMES[hero_index], 10, hero_color)
	game.View.text(game, Vector2(205, 106), _copy(game, "Capkeeper", "Penjaga"), 10, ROSE)
	var finish_flag := Vector2(488, 115)
	game.draw_rect(Rect2(133, 112, 350, 5), Color("#4b3a48"))
	game.draw_rect(Rect2(133, 112, 350 * distance / FINISH, 2), Color(hero_color, 0.53))
	game.View.diamond(game, Vector2(133 + 348 * distance / FINISH, 111.5), 4, hero_color)
	game.draw_circle(Vector2(133 + 348 * rival_distance / FINISH, 117), 3.0, ROSE, true, -1.0, true)
	_finish_pattern(game, finish_flag, 3, 2, 2)
	game.View.centered(game, Rect2(502, 94, 72, 28), _clock_label(game), 17, CREAM, true)


func _draw_track(game, hero_color: Color) -> void:
	var leader := maxf(distance, rival_distance)
	var camera := clampf(minf(leader - 247.0, distance - 100.0), -64.0, FINISH - 410.0)
	game.draw_texture_rect_region(TRACK_ART, TRACK,
		Rect2(170.0 * leader / FINISH, 0.0, 2000.0, 724.0))
	game.draw_rect(TRACK, Color(0.16, 0.12, 0.26, 0.11))
	var lane_tint := Color(0.30, 0.17, 0.29, 0.43)
	for index in range(11):
		var dash_x := TRACK.position.x + index * 52.0 - fposmod(camera, 52.0)
		if dash_x > TRACK.position.x + 4.0 and dash_x + 28.0 < TRACK.end.x - 4.0:
			game.draw_line(Vector2(dash_x, 242), Vector2(dash_x + 28, 242), lane_tint, 1.5)
	for line in [0.0, FINISH]:
		var x: float = TRACK.position.x + line - camera
		if x > TRACK.position.x + 8.0 and x < TRACK.end.x - 15.0:
			_finish_pattern(game, Vector2(x, 208.0), 4, 3, 18)
	for index in range(next_marker, markers.size()):
		var x: float = TRACK.position.x + markers[index].at - camera
		if x > TRACK.position.x + 26.0 and x < TRACK.end.x - 26.0:
			_draw_marker(game, Vector2(x, 270.0), markers[index].flower)
	var rival_x := TRACK.position.x + rival_distance - camera
	var player_x := clampf(TRACK.position.x + distance - camera, TRACK.position.x + 44, TRACK.end.x - 44)
	if rival_x < TRACK.position.x + 39 or rival_x > TRACK.end.x - 39:
		var ahead := rival_x > TRACK.end.x - 39
		var side_x := TRACK.end.x - 87 if ahead else TRACK.position.x + 8
		var rival_tag := _copy(game, "Capkeeper", "Penjaga")
		var tag_box := Rect2(side_x, 213, 79, 19)
		game.View.frame(game, tag_box, Color(INK, 0.81), ROSE)
		game.View.centered(game, tag_box, rival_tag + " →" if ahead else "← " + rival_tag, 10, CREAM)
	else:
		_draw_kart(game, Vector2(rival_x, 231), false, ROSE)
	_draw_kart(game, Vector2(player_x, 272), true, hero_color)
	if ready > 0.0:
		_race_callout(game, str(clampi(ceili(ready / (READY_TIME / 3.0)), 1, 3)),
			_copy(game, "Get ready", "Bersiap"), CREAM)
	elif state != "playing":
		var caption := _copy(game, "First across!", "Kamu menang!") if state == "win" else _copy(game, "Capkeeper wins", "Penjaga menang")
		if state == "draw":
			caption = _copy(game, "Photo finish", "Seri dramatis")
		_race_callout(game, caption, _clock_label(game), GOLD if state != "loss" else ROSE)
	elif elapsed < 0.50:
		game.View.centered(game, Rect2(288, 148, 90, 37), _copy(game, "GO!", "MULAI!"), 30, GOLD, true)


func _draw_kart(game, ground: Vector2, player: bool, tint: Color) -> void:
	var motion := distance if player else rival_distance
	var active_boost := player and boost > 0.0
	var bouncing := sin(motion * 0.24) * (1.7 if player else 1.1)
	var spray := splash if player else 0.0
	var width := 65.0 if player else 60.0
	var height := 53.0 if player else 49.0
	var offset := Vector2(-width * 0.5, -height + bouncing - 9.0 * spray)
	game.draw_line(ground - Vector2(width * 0.34, 0), ground + Vector2(width * 0.38, 0), Color(0.13, 0.08, 0.17, 0.32), 5.0, true)
	if active_boost:
		for index in range(3):
			var front := ground + Vector2(-width * 0.36, -8 - index * 6)
			var tail_x := maxf(TRACK.position.x + 5.0, front.x - 34.0 - 11.0 * sin(motion * 0.23 + index))
			game.draw_line(front, Vector2(tail_x, front.y), Color(GOLD, 0.61 - index * 0.12), 1.6, true)
	if motion > 0.0:
		for index in range(4):
			var offset_x := fposmod(motion * (0.26 + 0.06 * index) + index * 5.0, 15.0)
			var particle := ground + Vector2(-width * 0.4 - offset_x, -2.0 - index * 3.0 - offset_x * 0.22)
			if particle.x > TRACK.position.x + 4.0:
				var dust := GOLD if active_boost else Color("#dcd0c4")
				game.View.diamond(game, particle, 2.5 - 0.06 * offset_x, Color(dust, 0.74 - offset_x * 0.038))
	game.draw_texture_rect_region(KART_ART, Rect2(ground + offset, Vector2(width, height)),
		PILOT_REGION if player else RIVAL_REGION)
	for wheel in [Vector2(0.157, 0.833), Vector2(0.672, 0.866)]:
		var hub: Vector2 = ground + offset + wheel * Vector2(width, height)
		var spoke := Vector2.from_angle(motion * 0.24 + wheel.x * TAU) * 2.65
		game.draw_line(hub - spoke, hub + spoke, Color(GOLD, 0.80), 0.85, true)
	game.View.diamond(game, ground + offset + Vector2(width * 0.46, -2), 3.6, tint)
	if spray > 0.0:
		for index in range(5):
			var progress := 1.0 - spray / 0.38
			var drop := ground + Vector2(-20 + index * 9, 0) + Vector2(-8 - index * 2, -19 - index * 2) * progress
			game.View.diamond(game, drop, 2.9, Color("#aedff0", 1.0 - progress))


func _draw_marker(game, point: Vector2, flower: bool) -> void:
	if flower:
		var wave := sin(elapsed * 4.5 + point.x * 0.05)
		var petal := point + Vector2(0, -22 + wave)
		game.draw_line(point, petal, Color("#578c61"), 2.0, true)
		for index in range(5):
			var center := petal + Vector2.from_angle(index * TAU / 5 + elapsed * 0.7) * 5.1
			game.draw_circle(center, 3.7, Color("#ffe399"), true, -1.0, true)
		game.draw_circle(petal, 2.5, Color("#a66c48"), true, -1.0, true)
		game.draw_arc(point, 11.0, 0.0, PI, 12, Color(GOLD, 0.65), 1.0, true)
	else:
		var pool := PackedVector2Array([point + Vector2(-22, 2), point + Vector2(-13, -5),
			point + Vector2(8, -8), point + Vector2(23, -3), point + Vector2(20, 4),
			point + Vector2(5, 9), point + Vector2(-17, 7)])
		game.draw_colored_polygon(pool, Color("#3d6278", 0.83))
		var shimmer := sin(elapsed * 5.0 + point.x * 0.16) * 4.0
		game.draw_line(point + Vector2(-11 + shimmer, -1), point + Vector2(6 + shimmer, -3),
			Color("#b5dddb", 0.83), 1.1, true)


func _finish_pattern(game, origin: Vector2, tile: float, columns: int, rows: int) -> void:
	for column in range(columns):
		for row in range(rows):
			var shade := Color(CREAM, 0.87) if (column + row) % 2 == 0 else Color(INK, 0.74)
			game.draw_rect(Rect2(origin + Vector2(column * tile, row * tile), Vector2(tile, tile)), shade)


func _race_callout(game, main: String, detail: String, color: Color) -> void:
	var box := Rect2(241, 150, 180, 51)
	game.View.frame(game, box, Color(INK, 0.93), BRASS)
	game.View.centered(game, Rect2(box.position, Vector2(box.size.x, 32)), main, 22, color, true)
	game.View.centered(game, Rect2(box.position + Vector2(0, 30), Vector2(box.size.x, 17)), detail, 11, CREAM)


func _draw_controls(game, hero_color: Color) -> void:
	game.View.centered(game, Rect2(606, 95, 169, 25), _copy(game, "Pedal Boost", "Dorongan Pedal"), 18, CREAM, true)
	var charging := boost > 0.0
	for index in range(MAX_STREAK):
		var lit := charging or index < streak
		var fill := (GOLD if charging else hero_color) if lit else Color("#55455d")
		game.View.diamond(game, Vector2(626 + index * 25, 135), 7.5, fill)
		if lit:
			game.View.diamond(game, Vector2(625 + index * 25, 133), 2.3, CREAM)
	var instruction := _copy(game, "Alternate taps to boost", "Ketuk bergantian agar melaju")
	if charging:
		instruction = _copy(game, "BOOSTING", "MELAJU")
	elif splash > 0.0:
		instruction = _copy(game, "Puddle! Keep pedaling", "Genangan! Terus kayuh")
	game.View.centered(game, Rect2(606, 149, 169, 22), instruction, 11, GOLD if charging else CREAM)
	game.draw_line(Vector2(612, 179), Vector2(769, 179), Color(BRASS, 0.55))
	_draw_pedal(game, LEFT_PEDAL, 0, hero_color)
	_draw_pedal(game, RIGHT_PEDAL, 1, hero_color)
	var footer := _copy(game, "Flowers boost when fast", "Laju cepat untuk dorongan bunga")
	if not DisplayServer.is_touchscreen_available():
		footer = _copy(game, "A / D   or   ← / →", "A / D   atau   ← / →")
	game.View.centered(game, Rect2(606, 279, 169, 21), footer, 10, Color(CREAM, 0.68))


func _draw_pedal(game, box: Rect2, side: int, hero_color: Color) -> void:
	var pressed := last_pedal == side and elapsed - last_tap < 0.13
	var suggested := last_pedal != side and streak != 0 and state == "playing"
	var fill := Color("#4e4057") if suggested else Color("#392c44")
	var rim := hero_color if suggested else BRASS
	if pressed:
		fill = Color("#675368")
		rim = GOLD
	game.View.frame(game, box, fill, rim)
	var center := box.get_center() - Vector2(0, 10) + Vector2(0, 3 if pressed else 0)
	var direction := -1.0 if side == 0 else 1.0
	for index in range(2):
		var tip := center + Vector2((index * 11 - 1) * direction, 0)
		game.draw_polyline(PackedVector2Array([tip + Vector2(-direction * 9, -10), tip,
			tip + Vector2(-direction * 9, 10)]), CREAM, 2.8, true)
	game.View.centered(game, Rect2(box.position + Vector2(0, 55), Vector2(box.size.x, 20)),
		_copy(game, "LEFT", "KIRI") if side == 0 else _copy(game, "RIGHT", "KANAN"), 12, CREAM, true)


func _copy(game, english: String, indonesian: String) -> String:
	return indonesian if game.preferences.language == "id" else english


func _clock_label(game) -> String:
	return "%.2f%s" % [_clock(), _copy(game, "s", " dtk")]


func _clock() -> float:
	if state == "win" and player_finish >= 0.0:
		return player_finish
	if state == "loss" and rival_finish >= 0.0:
		return rival_finish
	if state == "draw" and player_finish >= 0.0 and rival_finish >= 0.0:
		return minf(player_finish, rival_finish)
	return elapsed
