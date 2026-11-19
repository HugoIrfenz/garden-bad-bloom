extends RefCounted

const EVENT_ID := "clockwork_encore"
const LENGTHS := [3, 4, 6]
const PITCHES := [Color("#f29eb0"), Color("#f4ce8e"), Color("#b8d197"), Color("#acbbf3")]
const CONSOLE := Rect2(74, 87, 716, 229)
const KEY_START := Vector2(361, 153)
const KEY_SIZE := Vector2(90, 107)
const KEY_GAP := 101.0
const GEAR_GOLD := Color("#bd976d")
const DARK := Color("#251b30")

var state := ""
var sequence: Array[int] = []
var verse := 0
var phase := ""
var shown := 0
var answered := 0
var retries := 1
var clock := 0.0
var lit := -1
var glow := 0.0


func begin(seed_value: int, _hero: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	sequence.clear()
	sequence.append(rng.randi_range(0, PITCHES.size() - 1))
	for i in range(1, LENGTHS.back()):
		sequence.append((sequence[i - 1] + rng.randi_range(1, PITCHES.size() - 1)) % PITCHES.size())
	state = "playing"
	verse = 0
	retries = 1
	start_verse(0.85)


func start_verse(delay: float) -> void:
	shown = 0
	answered = 0
	lit = -1
	glow = 0.0
	phase = "show_gap"
	clock = delay


func snapshot() -> Dictionary:
	return {"state": state, "sequence": sequence.duplicate(), "verse": verse,
		"phase": phase, "shown": shown, "answered": answered, "retries": retries,
		"clock": clock, "lit": lit, "glow": glow}


func restore(raw: Variant) -> void:
	state = ""
	sequence.clear()
	if not raw is Dictionary:
		return
	var saved: Variant = raw.get("sequence")
	if not saved is Array or saved.size() != LENGTHS.back():
		return
	for key_index: Variant in saved:
		if not (key_index is int or key_index is float) or int(key_index) not in [0, 1, 2, 3]:
			return
		sequence.append(int(key_index))
	phase = str(raw.get("phase", ""))
	if phase not in ["show_gap", "show_note", "answer", "verse_done", "retry"]:
		return
	verse = clampi(int(raw.get("verse", 0)), 0, LENGTHS.size() - 1)
	shown = clampi(int(raw.get("shown", 0)), 0, int(LENGTHS[verse]) - 1)
	answered = clampi(int(raw.get("answered", 0)), 0, int(LENGTHS[verse]))
	retries = clampi(int(raw.get("retries", 0)), 0, 1)
	clock = clampf(float(raw.get("clock", 0.0)), 0.0, 13.0)
	lit = clampi(int(raw.get("lit", -1)), -1, PITCHES.size() - 1)
	glow = clampf(float(raw.get("glow", 0.0)), 0.0, 0.50)
	state = str(raw.get("state", ""))


func tick(game, delta: float) -> void:
	if state != "playing":
		return
	glow = maxf(0.0, glow - delta)
	clock -= delta
	if clock > 0.0:
		return
	match phase:
		"show_gap":
			note(game, sequence[shown], 0.43)
			phase = "show_note"
			clock = 0.43
		"show_note":
			shown += 1
			lit = -1
			if shown >= int(LENGTHS[verse]):
				phase = "answer"
				clock = 7.5 + verse * 1.6
			else:
				phase = "show_gap"
				clock = 0.18
		"answer":
			miss(game)
		"verse_done":
			verse += 1
			start_verse(0.38)
		"retry":
			start_verse(0.52)


func note(game, slot: int, length: float) -> void:
	lit = slot
	glow = length
	game.sound.play("encore_%d" % slot)


func tap(game, point: Vector2) -> void:
	for i in range(PITCHES.size()):
		if key_rect(i).has_point(point):
			answer(game, i)
			return


func key(game, code: int) -> void:
	if code >= KEY_1 and code <= KEY_4:
		answer(game, code - KEY_1)


func answer(game, slot: int) -> void:
	if state != "playing" or phase != "answer" or answered >= int(LENGTHS[verse]):
		return
	if sequence[answered] != slot:
		lit = slot
		glow = 0.34
		miss(game)
		return
	note(game, slot, 0.25)
	answered += 1
	if answered < int(LENGTHS[verse]):
		return
	if verse == LENGTHS.size() - 1:
		state = "win"
	else:
		phase = "verse_done"
		clock = 0.83
		game.sound.play("arcade_collect")


func miss(game) -> void:
	if retries <= 0:
		state = "loss"
	else:
		retries -= 1
		phase = "retry"
		clock = 1.0
		game.sound.play("arcade_miss")


func key_rect(index: int) -> Rect2:
	return Rect2(KEY_START + Vector2(index * KEY_GAP, 0), KEY_SIZE)


func draw(game) -> void:
	var view = game.View
	var text = game.preferences
	var time: float = game.visual_clock
	view.frame(game, CONSOLE, Color("#302634"), GEAR_GOLD)
	gears(game, Vector2(160, 198), time)
	gears(game, Vector2(261, 234), -time * 1.4, 0.55)
	var banner := Rect2(105, 110, 237, 39)
	view.centered(game, banner, text.text("arcade.encore.stage", {"stage": verse + 1}), 22, view.CREAM, true)
	var message := "arcade.encore.listen"
	if phase == "answer":
		message = "arcade.encore.repeat"
	elif phase == "retry":
		message = "arcade.encore.retry"
	elif phase == "verse_done" or state == "win":
		message = "arcade.encore.cleared"
	if state == "loss":
		message = "arcade.encore.lost"
	view.centered(game, Rect2(105, 256, 237, 32), text.text(message), 18, view.CREAM, true)
	for index in range(PITCHES.size()):
		draw_key(game, index)
	draw_sequence_progress(game)
	if phase == "answer" and state == "playing":
		var remaining := clampf(clock / (7.5 + verse * 1.6), 0.0, 1.0)
		game.draw_rect(Rect2(376, 286, 363, 5), Color("#1f1826"))
		game.draw_rect(Rect2(376, 286, roundf(363.0 * remaining), 5), GEAR_GOLD)


func draw_key(game, index: int) -> void:
	var view = game.View
	var target := key_rect(index)
	var active := lit == index and glow > 0.0 and state == "playing"
	var pulse := clampf(glow / 0.34, 0.0, 1.0)
	var tint: Color = PITCHES[index]
	if active:
		target.position.y += 3.0 if phase == "answer" else -3.0
	var fill := tint.darkened(0.52) if phase == "answer" else tint.darkened(0.69)
	if active:
		fill = tint.lightened(pulse * 0.33)
	var dark_border := GEAR_GOLD.lerp(tint, 0.69 if active else 0.28)
	view.frame(game, target, fill, dark_border)
	if active:
		view.frame(game, target.grow(-4), Color(tint, 0.42), Color(tint.lightened(0.55), 0.91))
	var symbol_ink := DARK if active else Color(tint, 0.84)
	draw_symbol(game, target.position + Vector2(KEY_SIZE.x * 0.5, 40), index, symbol_ink)
	view.centered(game, Rect2(target.position + Vector2(0, 74), Vector2(KEY_SIZE.x, 22)),
		str(index + 1), 13, symbol_ink)

func draw_symbol(game, center: Vector2, index: int, ink: Color) -> void:
	match index:
		0:
			for ray in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
				game.draw_circle(center + ray * 7.0, 4.5, ink)
			game.draw_circle(center, 2.5, ink)
		1:
			game.View.diamond(game, center, 11.0, ink)
		2:
			game.draw_circle(center, 9.0, ink)
		3:
			game.View.diamond(game, center, 10.0, ink)
			game.draw_rect(Rect2(center + Vector2(-1, -14), Vector2(2, 28)), ink)


func draw_sequence_progress(game) -> void:
	var count := int(LENGTHS[verse])
	var completed := answered if phase in ["answer", "verse_done"] else 0
	var origin := Vector2(557.0 - (count - 1) * 9.0, 127.0)
	for i in range(count):
		var point := origin + Vector2(i * 18.0, 0)
		game.View.diamond(game, point, 4.5, GEAR_GOLD if i < completed else Color("#584556"))


func gears(game, center: Vector2, time: float, size := 1.0) -> void:
	var outer := PackedVector2Array()
	for i in range(32):
		var radius := (48.0 if i % 4 in [1, 2] else 38.0) * size
		outer.append(center + Vector2.from_angle(time * 0.53 + i * TAU / 32.0) * radius)
	game.draw_colored_polygon(outer, Color("#68505b"))
	outer.append(outer[0])
	game.draw_polyline(outer, GEAR_GOLD, 1.5)
	game.draw_circle(center, 26.0 * size, DARK)
	for i in range(4):
		var axis := Vector2.from_angle(time * 0.53 + i * TAU * 0.25)
		game.draw_line(center + axis * 9.0 * size, center + axis * 25.0 * size, GEAR_GOLD, 3.0 * size)
	game.draw_circle(center, 7.0 * size, GEAR_GOLD)
