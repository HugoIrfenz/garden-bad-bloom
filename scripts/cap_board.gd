extends RefCounted

const Text = preload("res://scripts/garden_text.gd")
const EVENT_ID = "cap_board"
const STAKE = 6
const PLAYER = 1
const KEEPER = 2
const TURN_DELAY = 0.34
const EXIT = Rect2(448, 306, 299, 45)
const GRID = Vector2(128, 104)
const CELL_SIZE = 72.0
const CELL_STEP = 80.0
const LINES = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

var cells: Array[int] = []
var match_seed = 0
var keeper_wait = 0.0
var state = ""

func reset() -> void:
	cells.clear()
	match_seed = 0
	keeper_wait = 0.0
	state = ""

func begin(seed_value: int) -> void:
	reset()
	cells.resize(9)
	cells.fill(0)
	match_seed = posmod(seed_value, 2147483647)
	state = "playing"

func snapshot() -> Dictionary:
	return {"cells": cells.duplicate(), "seed": match_seed, "keeper_wait": keeper_wait, "state": state}

func restore(data: Variant) -> void:
	reset()
	if not data is Dictionary:
		return
	var saved_cells: Variant = data.get("cells")
	if not saved_cells is Array or saved_cells.size() != 9:
		return
	for value in saved_cells:
		if not (value is int or value is float) or int(value) not in [0, PLAYER, KEEPER]:
			reset()
			return
		cells.append(int(value))
	match_seed = int(data.get("seed", 0))
	keeper_wait = clampf(float(data.get("keeper_wait", 0.0)), 0.0, TURN_DELAY)
	update_result()
	if state == "playing" and cells.count(PLAYER) > cells.count(KEEPER):
		keeper_wait = maxf(0.01, keeper_wait)

func cell_rect(index: int) -> Rect2:
	var column := index % 3
	var row := floori(float(index) / 3.0)
	return Rect2(GRID + Vector2(column, row) * CELL_STEP, Vector2.ONE * CELL_SIZE)

func tick(game, delta: float) -> void:
	if state != "playing" or keeper_wait <= 0.0:
		return
	keeper_wait = maxf(0.0, keeper_wait - delta)
	if keeper_wait > 0.0:
		return
	var move := keeper_move()
	if move >= 0:
		cells[move] = KEEPER
	move_committed(game)

func tap(game, point: Vector2) -> void:
	if state.is_empty():
		return
	if EXIT.has_point(point):
		game.arcade.settle(game)
		return
	if state != "playing" or keeper_wait > 0.0:
		return
	for index in range(cells.size()):
		if cells[index] == 0 and cell_rect(index).has_point(point):
			cells[index] = PLAYER
			keeper_wait = TURN_DELAY
			move_committed(game)
			return

func move_committed(game) -> void:
	update_result()
	match state:
		"win": game.sound.play("board_win")
		"loss": game.sound.play("board_loss")
		_: game.sound.play("board_move")
	if not game.arcade.practice:
		game.checkpoint()

func update_result() -> void:
	var winner := board_winner()
	if winner == PLAYER:
		state = "win"
	elif winner == KEEPER:
		state = "loss"
	elif not cells.has(0):
		state = "draw"
	else:
		state = "playing"
	if state != "playing":
		keeper_wait = 0.0

func board_winner() -> int:
	for line: Array in LINES:
		var mark := cells[line[0]]
		if mark != 0 and cells[line[1]] == mark and cells[line[2]] == mark:
			return mark
	return 0

func keeper_move() -> int:
	var free: Array[int] = []
	var encoded := 0
	for index in range(cells.size()):
		encoded = encoded * 3 + cells[index]
		if cells[index] == 0:
			free.append(index)
	if free.is_empty():
		return -1
	var winning := decisive_cell(free, KEEPER)
	if winning >= 0:
		return winning
	var rng := RandomNumberGenerator.new()
	rng.seed = match_seed + encoded * 12143
	var block := decisive_cell(free, PLAYER)
	# The capkeeper is a willing rival, not a solved minimax opponent.
	if block >= 0 and rng.randi_range(0, 4) != 0:
		return block
	return free[rng.randi_range(0, free.size() - 1)]

func decisive_cell(free: Array[int], mark: int) -> int:
	for index in free:
		cells[index] = mark
		var wins := board_winner() == mark
		cells[index] = 0
		if wins:
			return index
	return -1

func draw(game) -> void:
	var view = game.View
	var preferences = game.preferences
	game.draw_rect(view.CANVAS, Color(0.13, 0.08, 0.17, 0.53))
	view.petals(game, game.visual_clock)
	view.frame(game, Rect2(83, 41, 698, 325), Color("#291d2c"), Color("#b99470"))
	view.centered(game, Rect2(152, 49, 559, 37), preferences.text("three_caps.title"), 26, view.CREAM, true)
	view.sprig(game, Vector2(191, 69), Vector2.RIGHT, view.BRASS)
	view.sprig(game, Vector2(673, 69), Vector2.LEFT, view.BRASS)
	for index in range(cells.size()):
		var tile := cell_rect(index)
		var can_play := state == "playing" and keeper_wait <= 0.0 and cells[index] == 0
		var hover: bool = can_play and tile.has_point(game.get_local_mouse_position())
		var fill := Color("#fff0cd") if hover else Color("#d3a678")
		view.frame(game, tile, fill, Color("#f1c89d"))
		draw_mark(game, tile.get_center(), cells[index])
	view.centered(game, Rect2(429, 112, 338, 32), status_text(preferences.language), 22, view.CREAM, true)
	view.centered(game, Rect2(429, 153, 338, 28), preferences.text("three_caps.markers"), 12, view.DIM)
	view.centered(game, Rect2(429, 178, 338, 28), preferences.text("three_caps.instructions"), 12, view.DIM)
	view.centered(game, Rect2(429, 220, 338, 26), odds_text(game), 14, view.CREAM)
	var stake_line: String = preferences.text("arcade.free_practice") if game.arcade.practice \
		else preferences.text("three_caps.draw_refund", {"amount": STAKE})
	view.centered(game, Rect2(429, 247, 338, 24), stake_line, 12, view.DIM)
	var exit_key := "common.back" if game.arcade.practice else ("three_caps.forfeit" if state == "playing" else "three_caps.claim")
	view.button(game, EXIT, preferences.text(exit_key), state != "playing")

func draw_mark(game, center: Vector2, mark: int) -> void:
	if mark == 0:
		game.draw_circle(center, 2.5, Color("#af805c"), true, -1.0, true)
		return
	if mark == KEEPER:
		var tint := Color("#397d83")
		game.draw_line(center + Vector2(-14, 0), center + Vector2(14, 0), tint, 6.0, true)
		game.draw_line(center + Vector2(0, -14), center + Vector2(0, 14), tint, 6.0, true)
		game.draw_circle(center, 6.0, Color("#e7d29d"), true, -1.0, true)
		game.draw_arc(center, 18.0, 0.0, TAU, 32, tint, 2.0, true)
		return
	var tint := Color("#ab4565")
	var cap := PackedVector2Array()
	for segment in range(13):
		var angle := PI + PI * float(segment) / 12.0
		cap.append((center + Vector2(cos(angle) * 19.0, sin(angle) * 15.0)).round())
	game.draw_colored_polygon(cap, tint)
	game.draw_rect(Rect2(center + Vector2(-4, 0), Vector2(8, 15)), Color("#f3dfad"))
	for offset: Vector2 in [Vector2(-9, -5), Vector2(1, -10), Vector2(9, -4)]:
		game.draw_circle(center + offset, 2.1, Color("#f5d5ba"), true, -1.0, true)

func status_text(language := Text.ENGLISH) -> String:
	match state:
		"win": return Text.message(language, "three_caps.won")
		"draw": return Text.message(language, "three_caps.draw")
		"loss": return Text.message(language, "three_caps.lost")
	return Text.message(language, "three_caps.wait" if keeper_wait > 0.0 else "three_caps.turn")

func odds_text(game) -> String:
	if game.arcade.practice:
		return ""
	var prize_key := "item.petal_bomb.name" if game.pocket.held.is_empty() else "three_caps.damage_prize"
	var prize: String = game.preferences.text(prize_key)
	return game.preferences.text("three_caps.prize" if state == "win" else "three_caps.prize_preview", {"prize": prize})
