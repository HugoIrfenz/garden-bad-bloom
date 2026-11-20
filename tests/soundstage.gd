extends SceneTree

const Soundstage = preload("res://scripts/garden_soundstage.gd")
const MUSIC = ["title", "garden", "roster", "preparation", "settings", "archive", "shop", "rest", "event", "curse", "reward", "victory", "defeat"]
const EFFECTS = ["ui", "confirm", "cancel", "angela", "vivianne", "nixia", "virelia", "zaria", "mina", "whi",
	"dodge", "hit", "hurt", "guard", "warning", "warning_boss", "chest", "reward", "clear", "boss_enter", "ultimate", "fall"]

func _initialize() -> void:
	call_deferred("run")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var music = MUSIC.duplicate()
	for theme in Soundstage.THEMES:
		music.append(theme)
		music.append(theme + "_boss")
	for cue in music:
		var stream = game.sound.stream_for("music", cue, "ogg")
		if not require(stream is AudioStreamOggVorbis and stream.get_length() > 12.0, "Missing loop " + cue):
			return
	for cue: String in game.OptionalBosses.NAMES:
		var tape := "vhs_" + cue
		var shelf: int = game.SeedShop.Shelf.MEDIA
		var page: int = game.SeedShop.page_of(shelf, tape)
		var stream = game.sound.stream_for("music", game.GardenMedia.cue(tape), "ogg")
		if not require(tape in game.GardenMedia.TAPES and tape in game.SeedShop.page_offers(shelf, page)
				and game.RunProfile.SEED_OFFERS.has(tape) and stream is AudioStreamOggVorbis and stream.get_length() > 0.0,
				"Missing hidden boss VHS, shop entry, or score for " + cue):
			return
	for effect in EFFECTS:
		var stream = game.sound.stream_for("sfx", effect, "wav")
		if not require(stream is AudioStreamWAV and stream.get_length() > 0.21, "Missing effect " + effect):
			return
	var bus = AudioServer.get_bus_index(Soundstage.EFFECT_BUS)
	if not require(bus >= 0 and AudioServer.get_bus_effect(bus, 0) is AudioEffectHardLimiter, "Effects bus missing headroom limiter"):
		return

	game._process(0.03)
	var title_deck = game.sound.deck_index
	if not require(game.sound.active_cue == "title" and game.sound.deck[title_deck].stream.loop,
			"Title did not begin a loop"):
		return
	game.sound._process(0.70)
	game.tap(game.View.GARDEN_LINK.get_center())
	game._process(0.03)
	var hub_deck = game.sound.deck_index
	if not require(hub_deck != title_deck and game.sound.active_cue == "garden" and game.sound.played_at.has("confirm"),
			"Title-to-Garden transition did not switch music and play UI confirmation"):
		return
	game.sound._process(0.28)
	if not require(game.sound.deck_gain[title_deck] > 0.2 and game.sound.deck_gain[hub_deck] > 0.2,
			"Music transition did not crossfade"):
		return
	game.sound._process(0.48)
	if not require(is_zero_approx(game.sound.deck_gain[title_deck]) and is_equal_approx(game.sound.deck_gain[hub_deck], 1.0),
			"Music did not finish its transition"):
		return

	game.start_run(true)
	game.act("attack")
	if not require(game.sound.played_at.has("angela"), "Angela attack did not trigger its effect"):
		return
	game.act("dodge")
	if not require(game.sound.played_at.has("dodge"), "Dodge did not trigger its effect"):
		return
	game.mercy = 0.0
	game.damage_hero(4)
	if not require(game.sound.played_at.has("hurt"), "Health damage did not trigger impact audio"):
		return

	for biome in range(Soundstage.THEMES.size()):
		var theme: String = Soundstage.THEMES[biome]
		game.depth = biome * 4
		game.enter_room()
		game._process(0.03)
		if not require(game.sound.active_cue == theme, "Exploration did not begin the " + theme + " loop"):
			return
		var exploration: AudioStreamOggVorbis = game.sound.deck[game.sound.deck_index].stream
		game.sound._process(Soundstage.FADE_SECONDS)
		game.sound.played_at.erase("boss_enter")
		game.depth += 3
		game.enter_room()
		game._process(0.03)
		var boss_stream: AudioStreamOggVorbis = game.sound.deck[game.sound.deck_index].stream
		if not require(game.sound.active_cue == theme + "_boss" and boss_stream != exploration
				and boss_stream.loop and boss_stream.get_length() > 15.0 and game.sound.played_at.has("boss_enter"),
			"The " + theme + " boss did not trigger its dedicated loop and arrival accent"):
			return
	game.pending_chest = true
	game.player = game.chest_position
	game.open_chest()
	if not require(game.sound.played_at.has("chest"), "Chest interaction did not sound"):
		return
	for kind in Soundstage.SIDE_ROOMS:
		if not require(Soundstage.cue_for("room_choice", 0, kind, false, false) == kind,
				"Room menu does not resolve its own musical palette"):
			return
	game.sound.shutdown()
	await create_timer(0.12).timeout
	print("PASS: campaign audio and hidden boss VHS assets imported, audible event mapping, menu fades, combat/boss music, and one-shot routing.")
	quit(0)
