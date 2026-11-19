extends RefCounted

const BACKDROP = preload("res://assets/art/menus/settings_study.png")
const Text = preload("res://scripts/garden_text.gd")
const BACK = Rect2(369, 322, 126, 42)
const FPS_30 = Rect2(470, 109, 83, 41)
const FPS_60 = Rect2(566, 109, 83, 41)
const LEFT_HAND = Rect2(395, 189, 121, 41)
const RIGHT_HAND = Rect2(529, 189, 120, 41)
const PREVIEW = Rect2(233, 253, 416, 44)
const AUDIO = Rect2(675, 44, 159, 151)
const MUSIC = Rect2(686, 90, 137, 40)
const EFFECTS = Rect2(686, 142, 137, 40)
const LANGUAGES = Rect2(675, 210, 159, 154)
const ENGLISH = Rect2(686, 256, 137, 40)
const INDONESIAN = Rect2(686, 307, 137, 40)
const NAVY = Color("#231f37")
const MIDNIGHT = Color("#2b263d")

static func activate(game, point: Vector2) -> bool:
	var preferences = game.preferences
	if FPS_30.has_point(point):
		preferences.change_frame_cap(30)
	elif FPS_60.has_point(point):
		preferences.change_frame_cap(60)
	elif LEFT_HAND.has_point(point):
		preferences.change_layout(true)
	elif RIGHT_HAND.has_point(point):
		preferences.change_layout(false)
	elif MUSIC.has_point(point):
		preferences.change_audio(not preferences.music_enabled, preferences.effects_enabled)
		game.apply_audio_preferences()
	elif EFFECTS.has_point(point):
		preferences.change_audio(preferences.music_enabled, not preferences.effects_enabled)
		game.apply_audio_preferences()
	elif ENGLISH.has_point(point):
		preferences.change_language(Text.ENGLISH)
	elif INDONESIAN.has_point(point):
		preferences.change_language(Text.INDONESIAN)
	else:
		return BACK.has_point(point)
	return false

static func draw(game) -> void:
	var view = game.View
	var preferences = game.preferences
	game.draw_texture_rect(BACKDROP, view.CANVAS, false)
	game.draw_rect(view.CANVAS, Color(0.08, 0.06, 0.12, 0.14))
	view.petals(game, game.visual_clock)
	var panel := Rect2(199, 22, 466, 287)
	view.frame(game, panel, Color(NAVY, 0.90))
	view.centered(game, Rect2(227, 38, 410, 42), preferences.text("common.settings"), 28, view.CREAM, true)
	divider(game, 87.0)

	view.text(game, Vector2(223, 126), preferences.text("settings.frame_cap"), 18, view.CREAM, true)
	view.text(game, Vector2(223, 146), preferences.text("settings.frame_help"), 12, view.DIM)
	option(game, FPS_30, preferences.text("settings.fps_30"), preferences.frame_cap == 30)
	option(game, FPS_60, preferences.text("settings.fps_60"), preferences.frame_cap == 60)
	divider(game, 168.0)

	view.text(game, Vector2(223, 207), preferences.text("settings.touch"), 18, view.CREAM, true)
	view.text(game, Vector2(223, 226), preferences.text("settings.touch_help"), 12, view.DIM)
	option(game, LEFT_HAND, preferences.text("settings.left_hand"), preferences.left_handed)
	option(game, RIGHT_HAND, preferences.text("settings.right_hand"), not preferences.left_handed)
	layout_preview(game)
	draw_audio_language(game)
	view.button(game, BACK, preferences.text("common.back"), true)

	if preferences.save_failed:
		var warning_box := Rect2(229, 367, 406, 19)
		game.draw_rect(warning_box, Color(NAVY, 0.96))
		view.centered(game, warning_box, preferences.text("settings.save_error"), 11, Color("#ffd6b5"))

static func draw_audio_language(game) -> void:
	var view = game.View
	var preferences = game.preferences
	view.frame(game, AUDIO, Color(NAVY, 0.93))
	view.centered(game, Rect2(681, 49, 147, 34), preferences.text("settings.audio"), 22, view.CREAM, true)
	var music: bool = preferences.music_enabled
	var effects: bool = preferences.effects_enabled
	option(game, MUSIC, preferences.text("settings.music_on" if music else "settings.music_off"), music)
	option(game, EFFECTS, preferences.text("settings.effects_on" if effects else "settings.effects_off"), effects)
	view.frame(game, LANGUAGES, Color(NAVY, 0.93))
	view.centered(game, Rect2(681, 215, 147, 35), preferences.text("settings.language"), 22, view.CREAM, true)
	option(game, ENGLISH, preferences.text("settings.english"), preferences.language == Text.ENGLISH)
	option(game, INDONESIAN, preferences.text("settings.indonesian"), preferences.language == Text.INDONESIAN)

static func option(game, box: Rect2, label: String, selected: bool) -> void:
	var view = game.View
	if selected:
		var glow := Color("#eac189").lightened(0.07 + sin(float(game.visual_clock) * 3.0) * 0.05)
		game.draw_rect(box.grow(2.0), Color(glow, 0.47), false, 1.4)
	view.button(game, box, label, selected)

static func divider(game, y: float) -> void:
	game.draw_line(Vector2(224, y), Vector2(642, y), Color("#876b64"), 1.0, true)
	game.View.diamond(game, Vector2(433, y), 2.7, game.View.BRASS)

static func layout_preview(game) -> void:
	var view = game.View
	view.frame(game, PREVIEW, MIDNIGHT, Color("#685569"))
	var left: bool = game.preferences.left_handed
	var joystick := Vector2(616.0 if left else 262.0, 275.0)
	var attacks := Vector2(262.0 if left else 616.0, 276.0)
	view.ring(game, joystick, 14.0, view.BRASS, 0.55)
	game.draw_circle(joystick, 5.4, Color("#c0b0aa"), true, -1.0, true)
	for offset in [Vector2(-10.0, -5.0), Vector2(5.0, -7.0), Vector2(11.0, 5.0), Vector2(-4.0, 7.0)]:
		view.diamond(game, attacks + offset, 4.0, view.CREAM)
	var label: String = game.preferences.text("settings.move_right" if left else "settings.move_left")
	view.centered(game, Rect2(307, 256, 270, 38), label, 12, view.DIM)
