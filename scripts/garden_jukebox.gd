extends Node

const Media = preload("res://scripts/garden_media.gd")
const PANEL_ART = preload("res://assets/art/menus/arcade_pavilion.png")
const BACK := Rect2(37, 20, 106, 40)
const SHOP := Rect2(671, 20, 156, 40)
const CABINET := Rect2(37, 74, 282, 289)
const LIST := Rect2(334, 74, 493, 289)
const PLAY := Rect2(55, 315, 121, 37)
const REPEAT := Rect2(186, 315, 114, 37)
const PREV := Rect2(354, 317, 96, 34)
const NEXT := Rect2(710, 317, 96, 34)
const ROWS := 7
const INK := Color("#271d34")
const BRASS := Color("#cbaa7a")
const ACTIVE := Color("#fad598")

var player := AudioStreamPlayer.new()
var page := 0
var track_id := ""
var repeat := false
var requested_pause := false
var backgrounded := false
var message := ""


func _ready() -> void:
	player.name = "VHSPlayback"
	player.volume_db = linear_to_db(0.22)
	add_child(player)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			backgrounded = true
			apply_pause()
		NOTIFICATION_APPLICATION_RESUMED:
			backgrounded = false
			apply_pause()


func apply_pause() -> void:
	player.stream_paused = backgrounded or requested_pause


func stop() -> void:
	if player.stream != null:
		player.stop()
		player.stream = null
	requested_pause = false
	apply_pause()


func play_track(game, id: String) -> void:
	if not game.profile.has_unlock(Media.JUKEBOX) or not game.profile.has_unlock(id) or Media.cue(id).is_empty():
		return
	track_id = id
	message = ""
	if not game.preferences.music_enabled:
		message = "media.music_off"
		return
	var original := game.sound.stream_for("music", Media.cue(id), "ogg") as AudioStreamOggVorbis
	if original == null:
		return
	stop()
	var cassette := original.duplicate() as AudioStreamOggVorbis
	cassette.loop = repeat
	player.stream = cassette
	if AudioServer.get_driver_name() != "Dummy":
		player.play()
	apply_pause()


func toggle_play(game) -> void:
	if requested_pause:
		requested_pause = false
		apply_pause()
		return
	if player.playing:
		requested_pause = true
		apply_pause()
		return
	if not track_id.is_empty() and game.profile.has_unlock(track_id):
		play_track(game, track_id)
		return
	for id: String in Media.TAPES:
		if game.profile.has_unlock(id):
			play_track(game, id)
			return
	game.open_seed_shop(game.SeedShop.Shelf.MEDIA, Media.TAPES[0])


func page_count() -> int:
	return ceili(float(Media.TAPES.size()) / ROWS)


func row(index: int) -> Rect2:
	return Rect2(352, 84 + index * 32, 457, 30)


func tap(game, point: Vector2) -> void:
	var device: bool = game.profile.has_unlock(Media.JUKEBOX)
	if BACK.has_point(point):
		game.screen = "garden_hub"
	elif SHOP.has_point(point):
		game.open_seed_shop(game.SeedShop.Shelf.MEDIA, "" if device else Media.JUKEBOX)
	elif PLAY.has_point(point):
		if device:
			toggle_play(game)
		else:
			game.open_seed_shop(game.SeedShop.Shelf.MEDIA, Media.JUKEBOX)
	elif REPEAT.has_point(point) and device:
		repeat = not repeat
		if player.stream is AudioStreamOggVorbis:
			player.stream.loop = repeat
		game.sound.play("ui")
	elif PREV.has_point(point) and page > 0:
		page -= 1
		game.sound.play("ui")
	elif NEXT.has_point(point) and page < page_count() - 1:
		page += 1
		game.sound.play("ui")
	else:
		for index in range(ROWS):
			var slot := page * ROWS + index
			if slot >= Media.TAPES.size() or not row(index).has_point(point):
				continue
			var id: String = Media.TAPES[slot]
			if not game.profile.has_unlock(id):
				game.open_seed_shop(game.SeedShop.Shelf.MEDIA, id)
			elif not device:
				game.open_seed_shop(game.SeedShop.Shelf.MEDIA, Media.JUKEBOX)
			else:
				play_track(game, id)
			return


func draw(game) -> void:
	var view = game.View
	var prefs = game.preferences
	game.draw_texture_rect(PANEL_ART, view.CANVAS, false)
	game.draw_rect(view.CANVAS, Color("#191329", 0.46))
	view.petals(game, game.visual_clock)
	var header := Rect2(232, 19, 400, 43)
	view.frame(game, header, INK)
	view.centered(game, header, prefs.text("media.jukebox"), 27, view.CREAM, true)
	view.button(game, BACK, prefs.text("common.back"))
	view.button(game, SHOP, prefs.text("hub.seed_shop"))
	draw_cabinet(game)
	draw_library(game)


func draw_cabinet(game) -> void:
	var view = game.View
	var prefs = game.preferences
	var owned: bool = game.profile.has_unlock(Media.JUKEBOX)
	view.frame(game, CABINET, INK, BRASS)
	var playing := player.playing and not requested_pause
	var center := Vector2(178, 173 + roundf(sin(float(game.visual_clock) * 1.8)))
	var color := ACTIVE if playing else BRASS
	game.draw_circle(center, 80, Color(color, 0.09))
	game.draw_arc(center, 79, 0, TAU, 40, Color(color, 0.34), 1.0)
	Media.draw_icon(game, Media.JUKEBOX, center, 155.0)
	if playing:
		for i in range(7):
			var angle := float(game.visual_clock) * 0.8 + i * TAU / 7.0
			var point := (center + Vector2.from_angle(angle) * Vector2(72, 64)).round()
			view.diamond(game, point, 2.6, Color(ACTIVE, 0.55 + sin(angle * 3.0) * 0.35))
	var title: String = Media.item(track_id).get("name", prefs.text("media.select_tape"))
	if not owned:
		title = prefs.text("media.jukebox_locked")
	view.centered(game, Rect2(46, 258, 265, 24), title, 18, view.CREAM, true)
	var info: String
	if not message.is_empty():
		info = prefs.text(message)
	elif not owned:
		info = prefs.text("seed_shop.cost", {"amount": Media.PRICES[Media.JUKEBOX]})
	elif player.stream != null:
		var position := player.get_playback_position()
		var duration := player.stream.get_length()
		info = "%s / %s" % [timecode(position), timecode(duration)]
		var progress := clampf(position / maxf(0.01, duration), 0.0, 1.0)
		game.draw_rect(Rect2(66, 306, 224, 3), Color("#573a52"))
		game.draw_rect(Rect2(66, 306, roundf(224.0 * progress), 3), ACTIVE)
	else:
		info = prefs.text("media.tapes_owned", {"amount": total_owned(game), "total": Media.TAPES.size()})
	view.centered(game, Rect2(45, 283, 265, 18), info, 11, view.DIM)
	var play_label := "media.pause" if playing else "media.play"
	if not owned:
		play_label = "seed_shop.unlock_button"
	view.button(game, PLAY, prefs.text(play_label), true)
	if owned:
		view.button(game, REPEAT, prefs.text("media.repeat_on" if repeat else "media.repeat_off"))


func draw_library(game) -> void:
	var view = game.View
	var prefs = game.preferences
	view.frame(game, LIST, Color(INK, 0.98), BRASS)
	for index in range(ROWS):
		var slot := page * ROWS + index
		if slot >= Media.TAPES.size():
			break
		var id: String = Media.TAPES[slot]
		var area := row(index)
		var owned: bool = game.profile.has_unlock(id)
		var selected := id == track_id
		var accent := ACTIVE if selected else BRASS
		var fill := Color("#47314b") if selected else Color("#302337")
		view.frame(game, area, fill, Color(accent, 0.84 if owned else 0.49))
		Media.draw_icon(game, id, area.position + Vector2(25, 15), 33.0)
		var tape: Dictionary = Media.item(id)
		view.text(game, area.position + Vector2(50, 14), tape.name, 14, view.CREAM, true)
		view.text(game, area.position + Vector2(50, 25), tape.effect, 9, view.DIM)
		var status: String = prefs.text("seed_shop.owned") if owned \
			else prefs.text("seed_shop.cost", {"amount": Media.PRICES[id]})
		view.text(game, area.position + Vector2(316, 20), status, 11, accent,
			false, HORIZONTAL_ALIGNMENT_RIGHT, 128.0)
	if page > 0:
		view.button(game, PREV, prefs.text("history.previous"))
	if page < page_count() - 1:
		view.button(game, NEXT, prefs.text("history.next"))
	view.centered(game, Rect2(471, 317, 194, 34), "%d / %d" % [page + 1, page_count()], 13, view.CREAM)


func total_owned(game) -> int:
	var count := 0
	for id: String in Media.TAPES:
		if game.profile.has_unlock(id):
			count += 1
	return count


static func timecode(seconds: float) -> String:
	var total := maxi(0, int(seconds))
	return "%d:%02d" % [floori(total / 60.0), total % 60]
