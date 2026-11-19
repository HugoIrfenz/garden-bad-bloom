extends RefCounted

const FILE_PATH = "user://settings.cfg"
const Text = preload("res://scripts/garden_text.gd")

var frame_cap := 60
var left_handed := false
var music_enabled := true
var effects_enabled := true
var language := Text.ENGLISH
var save_failed := false
var _language_override := ""

func load_local() -> void:
	var config := ConfigFile.new()
	_language_override = ""
	if config.load(FILE_PATH) == OK:
		frame_cap = 30 if config.get_value("play", "frame_cap", 60) == 30 else 60
		left_handed = config.get_value("play", "left_handed", false) == true
		music_enabled = config.get_value("audio", "music", true) == true
		effects_enabled = config.get_value("audio", "effects", true) == true
		var saved_language := str(config.get_value("ui", "language", ""))
		if Text.supports(saved_language):
			_language_override = saved_language
	language = Text.device_language(OS.get_locale()) if _language_override.is_empty() else _language_override
	Engine.max_fps = frame_cap

func change_frame_cap(cap: int) -> void:
	if cap not in [30, 60] or (frame_cap == cap and not save_failed):
		return
	if write_local(cap, left_handed, music_enabled, effects_enabled):
		frame_cap = cap
		Engine.max_fps = cap

func change_layout(mirror: bool) -> void:
	if left_handed == mirror and not save_failed:
		return
	if write_local(frame_cap, mirror, music_enabled, effects_enabled):
		left_handed = mirror

func change_audio(music: bool, effects: bool) -> void:
	if music == music_enabled and effects == effects_enabled and not save_failed:
		return
	if write_local(frame_cap, left_handed, music, effects):
		music_enabled = music
		effects_enabled = effects

func change_language(preferred: String) -> void:
	if not Text.supports(preferred) or (_language_override == preferred and not save_failed):
		return
	if write_local(frame_cap, left_handed, music_enabled, effects_enabled, preferred):
		_language_override = preferred
		language = preferred

func text(key: String, fields: Dictionary = {}, fallback := "") -> String:
	return Text.message(language, key, fields, fallback)

func place_name(original: String) -> String:
	return Text.place_name(language, original)

func write_local(cap: int, mirror: bool, music: bool, effects: bool, preferred := "") -> bool:
	var config := ConfigFile.new()
	config.set_value("play", "frame_cap", cap)
	config.set_value("play", "left_handed", mirror)
	config.set_value("audio", "music", music)
	config.set_value("audio", "effects", effects)
	var explicit_language := preferred if Text.supports(preferred) else _language_override
	if not explicit_language.is_empty():
		config.set_value("ui", "language", explicit_language)
	var temporary_file := FILE_PATH + ".tmp"
	var error := config.save(temporary_file)
	if error == OK:
		error = DirAccess.rename_absolute(temporary_file, FILE_PATH)
	save_failed = error != OK
	if save_failed:
		push_warning("Could not save settings: " + error_string(error))
	return not save_failed

func touch_point(default_position: Vector2, width: float) -> Vector2:
	if left_handed:
		return Vector2(width - default_position.x, default_position.y)
	return default_position
