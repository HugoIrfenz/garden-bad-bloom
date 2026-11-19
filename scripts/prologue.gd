extends Node2D

const View = preload("res://scripts/garden_view.gd")
const Effects = preload("res://scripts/prologue_effects.gd")
const Soundstage = preload("res://scripts/garden_soundstage.gd")
const Preferences = preload("res://scripts/garden_preferences.gd")
const Text = preload("res://scripts/garden_text.gd")
const FRAME = preload("res://assets/art/prologue/frame.png")
const BLOOM_BEFORE = preload("res://assets/art/prologue/bloom_before.png")
const PANELS = [
	preload("res://assets/art/prologue/creator.png"),
	preload("res://assets/art/prologue/bloom.png"),
	preload("res://assets/art/prologue/happiness.png"),
	preload("res://assets/art/prologue/corruption.png"),
	preload("res://assets/art/prologue/adventure.png"),
]
const LINES := [
	["Once, there was a creator who loved flowers."],
	["With love and patience, he grew a garden", "where five extraordinary girls came to life."],
	["Together, they laughed, created, and dreamed", "of a Garden that would bloom forever."],
	["But one day, a strange blight began to spread,", "twisting their beloved Garden into a world of chaos."],
	["And so, the five Garden girls set out to reclaim their home,", "defeat the darkness, and make their Garden bloom once more."],
]
const CUES := ["creator", "bloom", "happiness", "corruption", "adventure"]
const ACTION_SOUNDS := ["water", "sprout", "laughter", "thorns", "draw"]
const DURATIONS := [5.5, 7.0, 6.7, 7.1, 8.4]
const SOUND_AT := [0.82, 1.38, 0.93, 1.19, 1.55]
const CAMERA_DRIFT := [Vector2(5, -2), Vector2(0, -4), Vector2(-6, 1),
	Vector2(4, 2), Vector2(0, -6)]
const TRANSITION := 0.46
const TITLE_SCENE := "res://main.tscn"
const CANVAS := Rect2(0, 0, 864, 390)
const IMAGE := Rect2(28, 22, 808, 337)
const BORDER_TINT := Color("#2b1e32")
const CAPTION := Rect2(127, 282, 610, 61)
const FINAL_CAPTION := Rect2(127, 292, 610, 51)
const SKIP := Rect2(748, 31, 69, 29)
const NEXT := Rect2(748, 360, 69, 25)

var sound := Soundstage.new()
var preferences := Preferences.new()
var page := 0
var age := 0.0
var outgoing_age := 0.0
var transition_age := 0.0
var leaving := false
var backgrounded := false


func _ready() -> void:
	preferences.load_local()
	sound.music_enabled = preferences.music_enabled
	sound.effects_enabled = preferences.effects_enabled
	sound.effects_gain *= 0.74
	sound.fade_duration = 0.36
	add_child(sound)
	request_music()


func _process(delta: float) -> void:
	if backgrounded:
		return
	if leaving:
		transition_age += delta
		if transition_age >= TRANSITION:
			set_process(false)
			set_process_input(false)
			var error := get_tree().change_scene_to_file(TITLE_SCENE)
			if error != OK:
				push_error("Could not open the title screen: %s" % error_string(error))
			return
		queue_redraw()
		return

	transition_age = minf(TRANSITION, transition_age + delta)
	var previous_age := age
	age += delta
	if previous_age < float(SOUND_AT[page]) and age >= float(SOUND_AT[page]):
		sound.play("prologue_" + ACTION_SOUNDS[page])
	if age >= float(DURATIONS[page]):
		next_page()
	queue_redraw()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			backgrounded = true
		NOTIFICATION_APPLICATION_RESUMED:
			backgrounded = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				finish()
			KEY_RIGHT, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
				get_viewport().set_input_as_handled()
				if age >= TRANSITION:
					next_page()
		return
	var pointer: Vector2
	if event is InputEventScreenTouch and event.pressed and not event.canceled:
		pointer = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pointer = event.position
	else:
		return
	get_viewport().set_input_as_handled()
	if SKIP.grow(6.0).has_point(pointer):
		finish()
	elif age >= TRANSITION:
		next_page()


func next_page() -> void:
	if leaving:
		return
	if page == PANELS.size() - 1:
		finish()
		return
	outgoing_age = age
	page += 1
	age = 0.0
	transition_age = 0.0
	request_music()


func finish() -> void:
	if leaving:
		return
	leaving = true
	transition_age = 0.0
	sound.music_enabled = false


func request_music() -> void:
	sound.request("prologue_" + CUES[page])


func _draw() -> void:
	draw_rect(CANVAS, BORDER_TINT)
	var old_alpha := 1.0 - smoothstep(0.0, TRANSITION, transition_age)
	if page > 0 and not leaving and old_alpha > 0.0:
		draw_story_page(page - 1, outgoing_age, 1.0)
	var alpha := 1.0 if leaving else (1.0 - old_alpha)
	draw_story_page(page, age, alpha)
	draw_texture_rect(FRAME, CANVAS, false)
	draw_caption(alpha)
	draw_navigation()
	if leaving:
		draw_rect(CANVAS, Color(BORDER_TINT, 1.0 - old_alpha))


func draw_story_page(index: int, time: float, alpha: float) -> void:
	var texture: Texture2D = PANELS[index]
	var progress := clampf(time / float(DURATIONS[index]), 0.0, 1.0)
	var camera := camera_region(texture, progress, CAMERA_DRIFT[index])
	if index == 1:
		var reveal := smoothstep(1.53, 2.98, time)
		draw_texture_rect_region(BLOOM_BEFORE, IMAGE,
			camera_region(BLOOM_BEFORE, progress, CAMERA_DRIFT[index]), Color(1, 1, 1, alpha))
		draw_texture_rect_region(texture, IMAGE, camera, Color(1, 1, 1, reveal * alpha))
	else:
		draw_texture_rect_region(texture, IMAGE, camera, Color(1, 1, 1, alpha))
	Effects.draw(self, index, time, camera, texture.get_size(), IMAGE, alpha)


func camera_region(texture: Texture2D, progress: float, travel: Vector2) -> Rect2:
	var size := texture.get_size()
	var scale := maxf(IMAGE.size.x / size.x, IMAGE.size.y / size.y) * lerpf(1.009, 1.034, progress)
	var extent := (IMAGE.size / scale).floor()
	var shift := travel * (progress - 0.5) / scale
	var origin := (size - extent) * 0.5
	return Rect2((origin + shift).round().clamp(Vector2.ZERO, size - extent), extent)


func draw_caption(art_alpha: float) -> void:
	var strength := minf(art_alpha, smoothstep(0.12, 0.58, age))
	if strength <= 0.0:
		return
	var box := FINAL_CAPTION if page == PANELS.size() - 1 else CAPTION
	draw_colored_polygon(View.bevel_points(box.grow(2.0), 12.0), Color("#452c39", strength * 0.87))
	draw_colored_polygon(View.bevel_points(box, 11.0), Color("#f6d9a9", strength))
	var trim := View.bevel_points(box.grow(-3.0), 9.0)
	trim.append(trim[0])
	draw_polyline(trim, Color("#a36954", strength), 2.0)
	var paper := box.grow(-7.0)
	draw_colored_polygon(View.bevel_points(paper, 7.0), Color("#ffe8c2", strength))
	for i in range(18):
		var side := -1.0 if i % 2 == 0 else 1.0
		var end := paper.get_center().x + side * (paper.size.x * 0.5 - 7.0 - fmod(i * 7.0, 32.0))
		var speck := Vector2(end, paper.position.y + 3.0 + fmod(i * 11.0, paper.size.y - 6.0)).round()
		draw_rect(Rect2(speck, Vector2(2 + i % 2, 1)), Color("#b1715a", strength * 0.30))
	for x in [box.position.x + 17.0, box.end.x - 17.0]:
		var point := Vector2(x, box.get_center().y)
		for axis in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			View.diamond(self, point + axis * 4.0, 2.6, Color("#a56c58", strength * 0.72))
	var lines: Array = LINES[page]
	var ink := Color("#372639", strength)
	var line_height := 20.5
	var row_y := box.get_center().y - lines.size() * line_height * 0.5
	for line: String in lines:
		View.centered(self, Rect2(box.position.x + 32, row_y, box.size.x - 64, line_height),
			line, 21, ink, true)
		row_y += line_height


func draw_navigation() -> void:
	var indonesian := preferences.language == Text.INDONESIAN
	var skip := "Lewati" if indonesian else "Skip intro"
	var advance := "Lanjut" if indonesian else "Next"
	if page == PANELS.size() - 1:
		advance = "Judul" if indonesian else "Title"
	View.frame(self, SKIP, Color("#291d31", 0.91), Color("#c49875"))
	View.centered(self, SKIP, skip, 13, View.CREAM, true)
	View.frame(self, NEXT, Color("#291d31", 0.91), Color("#c49875"))
	View.centered(self, NEXT, advance, 13, View.CREAM, true)
