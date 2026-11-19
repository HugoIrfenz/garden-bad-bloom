extends Node2D

const PROLOGUE_SCENE = "res://prologue.tscn"
const CANVAS = Rect2(0, 0, 864, 390)
const BACKGROUND = Color("#201e23")
const ART = preload("res://assets/art/menus/studio_splash.png")
const FADE_IN = 0.32
const FADE_OUT = 0.28
const HOLD_UNTIL = 2.08
const FAST_SKIP_AT = 0.55
const CENTERS = [Vector2(193, 190), Vector2(432, 184), Vector2(673, 189)]
const WIDTHS = [108.0, 232.0, 99.0]
const ARRIVALS = [0.15, 0.09, 0.23]
const SWAY = [1.0, 1.5, 2.0]
const MARKS = [
	Rect2(84, 266, 375, 259), Rect2(666, 72, 815, 597), Rect2(1704, 287, 347, 207),
]

var elapsed := 0.0
var exit_started := -1.0
var skip_requested := false

func _process(delta: float) -> void:
	elapsed += delta
	if exit_started < 0.0 and (elapsed >= HOLD_UNTIL or (skip_requested and elapsed >= FAST_SKIP_AT)):
		exit_started = elapsed
	if exit_started >= 0.0 and elapsed - exit_started >= FADE_OUT:
		open_prologue()
		return
	queue_redraw()

func _input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = event.pressed and not event.canceled
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventKey:
		pressed = event.pressed and not event.echo
	if pressed:
		skip_requested = true
		get_viewport().set_input_as_handled()

func open_prologue() -> void:
	set_process(false)
	set_process_input(false)
	var error := get_tree().change_scene_to_file(PROLOGUE_SCENE)
	if error != OK:
		push_error("Could not open Garden: Bad Bloom: %s" % error_string(error))

func _draw() -> void:
	draw_rect(CANVAS, BACKGROUND)
	var fade := 1.0 if exit_started < 0.0 else 1.0 - smoothstep(0.0, FADE_OUT, elapsed - exit_started)
	for index in range(CENTERS.size()):
		draw_mark(index, fade)

func draw_mark(index: int, fade: float) -> void:
	var age := maxf(0.0, elapsed - float(ARRIVALS[index]))
	var arrive := smoothstep(0.0, FADE_IN, age)
	if arrive <= 0.0 or fade <= 0.0:
		return
	var source: Rect2 = MARKS[index]
	var width: float = WIDTHS[index]
	var extent := Vector2(width, width * source.size.y / source.size.x).round()
	var center: Vector2 = CENTERS[index]
	var drift := float(SWAY[index]) * sin(age * (2.6 + index * 0.7) + index * 0.8)
	center.y += roundf((1.0 - arrive) * 5.0 + drift * arrive)
	draw_texture_rect_region(ART, Rect2((center - extent / 2.0).round(), extent), source, Color(1, 1, 1, fade * arrive))

