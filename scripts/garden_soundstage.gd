extends Node

const THEMES = ["forgotten", "mushroom", "clockwork", "bloodbloom", "hollow", "astral", "bloomheart"]
const HERO_EFFECTS = ["angela", "vivianne", "nixia", "virelia", "zaria", "mina", "whi", "luna_pistol"]
const FADE_SECONDS = 0.68
const MUSIC_GAIN = 0.21
const EFFECT_GAIN = 0.45
const VOICES = 8
const EFFECT_BUS = &"Garden Effects"
const TRACK_STATES = {
	"garden": "title", "garden_hub": "garden", "roster": "roster",
	"preparation": "preparation", "settings": "settings", "codex": "archive",
	"reward": "reward", "clear": "victory",
	"talent": "reward", "forge": "rest", "armory": "archive", "seed_shop": "garden", "run_history": "archive",
	"minigame": "board", "garden_arcade": "garden", "relic_ledger": "archive",
}
const SIDE_ROOMS = ["shop", "rest", "curse", "event"]

var active_cue = ""
var summary_clear = false
var music_enabled = true
var music_suppressed := false
var effects_enabled = true
var fade_duration := FADE_SECONDS
var music_gain = MUSIC_GAIN
var effects_gain = EFFECT_GAIN
var deck: Array[AudioStreamPlayer] = []
var voices: Array[AudioStreamPlayer] = []
var deck_gain: Array[float] = [0.0, 0.0]
var clock = 0.0
var deck_index = 0
var cursor = 0
var played_at: Dictionary = {}
var streams: Dictionary = {}
var output_available = false
var shutting_down = false
var music_duck := 1.0
var triumph_hold := 0.0

func _ready() -> void:
	output_available = AudioServer.get_driver_name() != "Dummy"
	if AudioServer.get_bus_index(EFFECT_BUS) < 0:
		var bus = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(bus, EFFECT_BUS)
		var limiter = AudioEffectHardLimiter.new()
		limiter.ceiling_db = -4.0
		AudioServer.add_bus_effect(bus, limiter)
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.name = "MusicA" if i == 0 else "MusicB"
		player.volume_db = -70.0
		add_child(player)
		deck.append(player)
	for i in range(VOICES):
		var player = AudioStreamPlayer.new()
		player.name = "Effect%d" % i
		player.bus = EFFECT_BUS
		add_child(player)
		voices.append(player)

static func cue_for(screen: String, biome: int, room_kind: String, boss_active: bool, cleared: bool) -> String:
	if TRACK_STATES.has(screen):
		return TRACK_STATES[screen]
	if screen == "summary":
		return "victory" if cleared else "defeat"
	if screen == "room_choice":
		return room_kind if room_kind in SIDE_ROOMS else "event"
	if screen == "fight":
		return THEMES[clampi(biome, 0, THEMES.size() - 1)] + ("_boss" if boss_active else "")
	return "title"

func sync(screen: String, biome: int, room_kind: String, boss_active: bool) -> void:
	request(cue_for(screen, biome, room_kind, boss_active, summary_clear))

func request(cue: String) -> void:
	if shutting_down or cue == active_cue or deck.is_empty():
		return
	var stream = stream_for("music", cue, "ogg") as AudioStreamOggVorbis
	if stream == null:
		return
	var other = 1 - deck_index
	if deck_gain[other] > deck_gain[deck_index]:
		other = deck_index
	deck_index = other
	deck_gain[deck_index] = 0.0
	var player = deck[deck_index]
	player.stop()
	player.stream = stream
	stream.loop = not cue.begins_with("prologue_")
	player.volume_db = -70.0
	if output_available:
		player.play()
	active_cue = cue

func play(cue: String, tone := 1.0) -> void:
	if shutting_down or not effects_enabled or voices.is_empty():
		return
	var interval = 0.19 if cue.begins_with("warning") else (0.074 if cue == "hit" else 0.038)
	if cue.begins_with("enemy_"):
		interval = 0.14
	if clock - float(played_at.get(cue, -10.0)) < interval:
		return
	var stream = stream_for("sfx", cue, "wav")
	if stream == null:
		return
	var index = cursor
	for i in range(voices.size()):
		var available = (cursor + i) % voices.size()
		if not voices[available].playing:
			index = available
			break
	cursor = (index + 1) % voices.size()
	var gain = effects_gain
	if cue == "warning":
		gain *= 0.72
	if cue == "hit":
		gain *= 0.78
	if cue == "hurt":
		gain *= 1.32
	if cue == "ultimate":
		gain *= 1.38
	if cue == "luna_pistol":
		gain *= 0.80
	elif cue == "luna_impact":
		gain *= 0.76
	if cue.begins_with("enemy_"):
		gain *= 0.67
	if cue == "boss_triumph":
		gain *= 1.20
		triumph_hold = 0.90
	elif cue == "boss_break":
		triumph_hold = 0.72
	var player = voices[index]
	player.stream = stream
	player.volume_db = linear_to_db(maxf(0.001, gain))
	player.pitch_scale = clampf(tone, 0.78, 1.28)
	if output_available:
		player.play()
	played_at[cue] = clock

func hero_attack(hero: int, skill := false) -> void:
	play(HERO_EFFECTS[clampi(hero, 0, HERO_EFFECTS.size() - 1)], 0.86 if skill else 1.0)

func hero_ultimate(hero: int) -> void:
	if hero == 7:
		play("luna_frenzy")
		return
	play("ultimate", [0.94, 1.05, 0.83, 1.13, 1.20, 0.88, 1.18][hero])
	play(HERO_EFFECTS[clampi(hero, 0, HERO_EFFECTS.size() - 1)], 0.82)

func enemy_release(move: String) -> void:
	match move:
		"lunge", "lance", "knife", "shears", "cross", "duel", "lash", "antlers", "siphon", "latch":
			play("enemy_blade")
		"slime", "peas", "petals", "bomb", "mines":
			play("enemy_spore")
		"needle", "gears", "hand", "pendulum", "bell":
			play("enemy_gear")
		"leap", "cyclone", "crown", "roots", "steam", "hot_tea", "rain":
			play("enemy_crash")
		_:
			play("enemy_arcane")

func stream_for(folder: String, cue: String, extension: String) -> AudioStream:
	var key = folder + "/" + cue
	if not streams.has(key):
		streams[key] = load("res://assets/audio/%s.%s" % [key, extension])
	return streams[key]

func _process(delta: float) -> void:
	clock += delta
	triumph_hold = maxf(0.0, triumph_hold - delta)
	music_duck = move_toward(music_duck, 0.30 if triumph_hold > 0.0 else 1.0, delta * 4.0)
	for i in range(deck.size()):
		var goal = 1.0 if i == deck_index and music_enabled and not music_suppressed else 0.0
		deck_gain[i] = move_toward(deck_gain[i], goal, delta / fade_duration)
		var player = deck[i]
		player.volume_db = linear_to_db(maxf(0.0003, deck_gain[i] * music_gain * music_duck))
		if i != deck_index and deck_gain[i] <= 0.0 and player.playing:
			player.stop()

func shutdown() -> void:
	shutting_down = true
	for player in deck + voices:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	streams.clear()

func _exit_tree() -> void:
	shutdown()

func _notification(what: int) -> void:
	if what not in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_RESUMED]:
		return
	var pause = what == NOTIFICATION_APPLICATION_PAUSED
	for player in deck:
		player.stream_paused = pause
	for player in voices:
		player.stream_paused = pause
