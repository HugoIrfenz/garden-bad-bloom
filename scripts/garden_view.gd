extends RefCounted

const Reward = preload("res://scripts/reward_view.gd")
const Art = preload("res://scripts/garden_art.gd")
const Portraits = preload("res://scripts/hero_presentation_art.gd")
const CONSERVATORY = preload("res://assets/art/conservatory.png")
const MENU_ART = {
	"garden": CONSERVATORY,
	"roster": preload("res://assets/art/menus/wardrobe.png"),
	"reward": preload("res://assets/art/menus/apothecary.png"),
	"clear": preload("res://assets/art/menus/daybreak_terrace.png"),
	"summary": preload("res://assets/art/menus/moonlit_pond.png"),
}
const COURTYARD = preload("res://assets/art/forgotten_garden.png")
const CANVAS = Rect2(0, 0, 864, 390)
const ROOM_ART = Rect2(0, 40, 864, 350)
const CREAM = Color("#f6e2c2")
const BRASS = Color("#c3a17b")
const INK = Color("#282236")
const DIM = Color("#d4bfaf")
const ROLE = ["Knight / Counterguard", "Witch / Roseweaver", "Brawler / Security Gremlin",
	"Ranger / Camellia Warden", "Rogue / Chaos Painter"]
const STARTING_WEAPONS = ["Lilyblade", "Rosebound Grimoire", "Orchid Gauntlets",
	"Camellia Longbow", "Iris Twin Daggers"]
const CLASS_SKILLS = ["Royal Guard", "Midnight Verse", "Unauthorized Access",
	"Tidy Arrangement", "Graffiti Cut"]
const CONTINUE = Rect2(62, 196, 205, 42)
const GARDEN_LINK = Rect2(62, 249, 205, 42)
const SETTINGS_LINK = Rect2(62, 302, 205, 42)
const ROSTER_BACK = Rect2(38, 333, 111, 39)
const DESCEND = Rect2(625, 312, 177, 45)
const FIRST_OPTION = Rect2(296, 226, 272, 43)
const SECOND_OPTION = Rect2(296, 280, 272, 43)
const PAUSE = Rect2(781, 3, 56, 36)

const TITLE_ROTATION = 6.0
const ULTIMATE_QUOTES = [
	"Till Death Do Us Part",
	"Let the Thorns Find Their Verse",
	"Security Breach. Try to Keep Up.",
	"Let Every Arrow Find Its Bloom",
	"Let’s Make Something Beautiful",
]
const DEFEAT_QUIPS = [
	"The lily will hear of this.",
	"I had not even found the good ending.",
	"I was just testing the floor.",
	"I packed an extra handkerchief.",
	"That was an artistic accident.",
]

static func text(canvas: Node2D, point: Vector2, line: String, size: int,
		color := CREAM, serif := false, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var font = Art.DISPLAY_FONT if serif else ThemeDB.fallback_font
	canvas.draw_string(font, point, line, align, width, size, color)

static func centered(canvas: Node2D, row: Rect2, line: String, size: int,
		color := CREAM, serif := false) -> void:
	var face: Font = Art.DISPLAY_FONT if serif else ThemeDB.fallback_font
	var baseline := (row.size.y + face.get_ascent(size) - face.get_descent(size)) * 0.5
	canvas.draw_string(face, row.position + Vector2(0, baseline), line,
		HORIZONTAL_ALIGNMENT_CENTER, row.size.x, size, color)

static func bevel_points(box: Rect2, cut: float) -> PackedVector2Array:
	return PackedVector2Array([
		box.position + Vector2(cut, 0.0), Vector2(box.end.x - cut, box.position.y),
		Vector2(box.end.x, box.position.y + cut), box.end - Vector2(0.0, cut),
		box.end - Vector2(cut, 0.0), Vector2(box.position.x + cut, box.end.y),
		Vector2(box.position.x, box.end.y - cut), box.position + Vector2(0.0, cut),
	])

static func frame(canvas: Node2D, box: Rect2, fill: Color, border := BRASS) -> void:
	var cut := minf(6.0, box.size.y * 0.19)
	canvas.draw_colored_polygon(bevel_points(box.grow(2), cut + 2.0), Color(0.07, 0.05, 0.12, 0.58))
	var edge := bevel_points(box, cut)
	canvas.draw_colored_polygon(edge, fill)
	edge.append(edge[0])
	canvas.draw_polyline(edge, border, 1.0, true)
	if box.size.y >= 32.0:
		var inner := bevel_points(box.grow(-3), maxf(2.0, cut - 2.5))
		inner.append(inner[0])
		canvas.draw_polyline(inner, Color(border, 0.47), 1.0, true)
	for corner in [box.position + Vector2(cut, 0), Vector2(box.end.x - cut, box.position.y),
			Vector2(box.position.x + cut, box.end.y), box.end - Vector2(cut, 0)]:
		diamond(canvas, corner, 2.1, border)
	if box.size.y >= 55.0 and box.size.x >= 152.0:
		sprig(canvas, box.position + Vector2(7.0, 8.0), Vector2(1.0, 1.0), Color(border, 0.52))
		sprig(canvas, box.end - Vector2(7.0, 8.0), Vector2(-1.0, -1.0), Color(border, 0.52))

static func sprig(canvas: Node2D, point: Vector2, direction: Vector2, color: Color) -> void:
	var stem := PackedVector2Array([point, point + direction * Vector2(8.0, 3.0),
		point + direction * Vector2(16.0, 6.0), point + direction * Vector2(22.0, 6.0)])
	canvas.draw_polyline(stem, color, 1.0, true)
	for point_on_stem in [Vector2(5.5, 3.0), Vector2(11.5, 5.0), Vector2(17.0, 6.5)]:
		var leaf: Vector2 = point + direction * point_on_stem
		canvas.draw_colored_polygon(PackedVector2Array([leaf,
			leaf + direction * Vector2(-2.5, 5.0), leaf + direction * Vector2(3.8, 3.8)]), color)
		canvas.draw_colored_polygon(PackedVector2Array([leaf,
			leaf + direction * Vector2(2.0, -4.2), leaf + direction * Vector2(4.5, -1.5)]), color)

static func diamond(canvas: Node2D, point: Vector2, size: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([point + Vector2.UP * size, point + Vector2.RIGHT * size,
		point + Vector2.DOWN * size, point + Vector2.LEFT * size]), color)

static func button(canvas: Node2D, box: Rect2, caption: String, primary := false) -> void:
	var motion = canvas.get("menu_motion")
	var hover = motion.hover_amount(box, canvas.get_local_mouse_position()) if motion else 0.0
	var press = motion.press_amount(box) if motion else 0.0
	var fill := CREAM if primary else Color("#392c46")
	var border := BRASS.lerp(Color("#ffe5b3"), 0.38 * hover + 0.42 * press)
	frame(canvas, box, fill.lightened(0.11 * hover + 0.16 * press), border)
	centered(canvas, box, caption, 17 if box.size.y >= 35.0 else 16, INK if primary else CREAM, true)
	if hover > 0.0 or press > 0.0:
		var light := Color("#786147") if primary else Color("#efd8ad")
		var strength := minf(1.0, 0.58 * hover + 0.64 * press)
		var offset := Vector2(10.0 + 4.0 * press, 0.0)
		diamond(canvas, Vector2(box.position.x, box.get_center().y) + offset, 2.7, Color(light, strength))
		diamond(canvas, Vector2(box.end.x, box.get_center().y) - offset, 2.7, Color(light, strength))

static func entrance(game) -> void:
	var progress: float = game.menu_motion.entrance_amount()
	if progress > 0.01:
		game.draw_rect(CANVAS, Color(0.14, 0.085, 0.17, 0.47 * progress))

static func heroine_stage(game, feet: Vector2, height: float, title_pose := false) -> void:
	var index: int = game.hero
	var motion = game.get("menu_motion")
	var reveal: float = motion.selection_amount(motion.hero_age) if motion else 0.0
	var clock: float = game.visual_clock
	var tint: Color = game.COLORS[index]
	var center := feet - Vector2(0.0, height * 0.45)
	var radius := height * 0.36
	game.draw_circle(center, radius, Color(tint, 0.07), true, -1.0, true)
	game.draw_arc(center, radius, 0.0, TAU, 84, Color(tint, 0.33 + 0.27 * reveal), 1.2, true)
	game.draw_arc(center, radius + 5.0, clock * 0.20, clock * 0.20 + PI * 0.76, 39,
		Color(BRASS, 0.48 + reveal * 0.28), 1.2, true)
	for seed in range(7):
		var angle := float(seed) * TAU / 7.0 + clock * 0.28
		var point := center + Vector2.from_angle(angle) * (radius + 9.0 + 18.0 * reveal)
		var pulse := 0.46 + 0.20 * sin(clock * 2.4 + float(seed))
		diamond(game, point, 1.7 + reveal, Color(CREAM, pulse))
	var shift := Vector2(reveal * 12.0, -reveal * 5.0)
	Art.shadow(game, feet, height * 0.24)
	Art.heroine(game, index, feet + shift, height, clock + 0.35, Vector2.ZERO,
		reveal * 0.22, Color(tint.lerp(Color.WHITE, 0.89), 1.0 if title_pose else (1.0 - reveal * 0.18)))

static func petals(canvas: Node2D, clock: float, battle := false) -> void:
	var count = 13 if battle else 25
	for i in range(count):
		var t = clock * (8.0 + i % 4)
		var x = fposmod(i * 127.7 + t + sin(clock * 0.7 + i) * 17.0, CANVAS.size.x)
		var y = fposmod(i * 73.13 + t * 0.53, CANVAS.size.y)
		if battle and (y < 50.0 or y > 307.0):
			continue
		var color = Color(0.99, 0.67, 0.8, 0.12 if battle else 0.46)
		canvas.draw_set_transform(Vector2(x, y), i + clock * 0.7, Vector2(1.0, 0.48))
		canvas.draw_circle(Vector2.ZERO, 1.4 + i % 3 * 0.5, color, true, -1.0, true)
		canvas.draw_set_transform(Vector2.ZERO)

static func menu(game) -> void:
	var backdrop: Texture2D = MENU_ART.get(game.screen, CONSERVATORY)
	var source_size := backdrop.get_size()
	var zoom := maxf(CANVAS.size.x / source_size.x, CANVAS.size.y / source_size.y)
	var crop_size := CANVAS.size / zoom
	game.draw_texture_rect_region(backdrop, CANVAS, Rect2((source_size - crop_size) * 0.5, crop_size))
	petals(game, game.visual_clock)
	if game.screen == "garden":
		title(game)
		return
	if game.screen == "roster":
		roster(game)
		return
	if game.screen == "reward":
		Reward.draw(game)
		return
	draw_result(game)

static func draw_result(game) -> void:
	var summary: Dictionary = result_data(game)
	var outcome := str(summary.get("result", ""))
	var victory: bool = game.screen == "clear" or outcome == "clear"
	var defeated: bool = game.screen == "summary" and (outcome == "defeat"
		or (outcome.is_empty() and game.last_outcome == "The Garden claims another"))
	game.draw_rect(CANVAS, Color(0.07, 0.05, 0.12, 0.25))
	var hue := Color("#aab4e7") if defeated else Color("#ecc38b")
	var stage := Rect2(35, 35, 207, 310)
	draw_portrait_stage(game, int(game.hero), stage, defeated, false, hue, 1.0, victory)
	var name_box := Rect2(53, 323, 176, 34)
	frame(game, name_box, Color(0.15, 0.10, 0.20, 0.91), hue)
	centered(game, name_box, game.NAMES[game.hero], 21, CREAM, true)

	var panel := Rect2(258, 65, 348, 283)
	frame(game, panel, Color(0.14, 0.12, 0.21, 0.95), hue)
	var heading := "Garden Restored" if victory else ("Run Lost" if defeated else "Run Ended")
	centered(game, Rect2(270, 76, 324, 53), heading, 33, CREAM, true)
	game.draw_line(Vector2(294, 135), Vector2(570, 135), Color(hue, 0.56), 1.0, true)
	diamond(game, Vector2(432, 135), 3.6, hue)
	var elapsed := int(summary.get("elapsed_seconds", game.run_time))
	var depth := int(summary.get("depth", game.depth))
	centered(game, Rect2(273, 143, 318, 25),
		"Room %d  ·  %ds" % [depth + 1, elapsed], 15, CREAM)
	if game.screen == "clear":
		var seeds := 1 + depth
		var seed_unit := "Seed" if seeds == 1 else "Seeds"
		centered(game, Rect2(273, 174, 318, 24), "%d Garden %s" % [seeds, seed_unit],
			19, hue, true)
		centered(game, Rect2(273, 199, 318, 17), "Banked when you end the run", 12, DIM)
		var mode_name: String = game.preferences.place_name(game.BIOMES.back())
		button(game, FIRST_OPTION, game.preferences.text("endless.continue", {"garden": mode_name}), true)
		button(game, SECOND_OPTION, "End run")
		return
	if defeated or summary.get("result", "") == "ended":
		draw_loss(game, summary)
		if defeated and game.pending_result.is_empty():
			centered(game, Rect2(268, 242, 328, 23), DEFEAT_QUIPS[game.hero], 16, hue, true)
	else:
		var earned := int(summary.get("seeds_earned", 1 + depth))
		centered(game, Rect2(273, 182, 318, 33), seed_reward(earned), 16, hue)
	if not game.pending_result.is_empty():
		centered(game, Rect2(267, 240, 330, 24), "Run result awaiting save", 13, Color("#ffdaa6"))
	button(game, SECOND_OPTION, "Return to Garden", true)

static func result_data(game) -> Dictionary:
	if game.screen == "clear":
		return {}
	if not game.pending_result.is_empty():
		return game.pending_result
	var saved: Variant = game.get("last_result")
	if saved is Dictionary:
		return saved
	return {}

static func draw_loss(game, summary: Dictionary) -> void:
	var petals_lost := int(summary.get("petals", game.petals))
	var relic_count := int(summary.get("relics", game.relics.owned).size())
	var pocket_item := str(summary.get("pocket_item", ""))
	var earned := int(summary.get("seeds_earned", 1 + game.depth))
	var area := Rect2(280, 171, 304, 64)
	frame(game, area, Color("#422a37"), Color("#bf8692"))
	var rel := "Relic" if relic_count == 1 else "Relics"
	var gear_loss := "%d %s" % [relic_count, rel]
	if not pocket_item.is_empty():
		gear_loss += " + pocket item"
	centered(game, Rect2(287, 175, 290, 18),
		"Lost %d Petals, %s and room progress" % [petals_lost, gear_loss], 12, CREAM)
	var keeping := seed_reward(earned)
	if not game.pending_result.is_empty():
		keeping = "%d Garden Seeds pending" % earned
	centered(game, Rect2(287, 194, 290, 18), keeping, 12, Color("#fae4ae"))
	centered(game, Rect2(287, 211, 290, 18), "Enemy Codex discoveries stay with you", 11, DIM)

static func seed_reward(earned: int) -> String:
	return "Earned %d Garden %s" % [earned, "Seed" if earned == 1 else "Seeds"]

static func draw_portrait_stage(game, index: int, area: Rect2, defeated: bool, close: bool,
		tint: Color, alpha: float = 1.0, victory: bool = false) -> void:
	var clock: float = game.visual_clock
	var radius := minf(area.size.x * 0.48, area.size.y * 0.44)
	var center := area.get_center() - Vector2(0.0, 2.0)
	game.draw_circle(center, radius, Color(tint, 0.11 * alpha), true, -1.0, true)
	game.draw_arc(center, radius, 0.0, TAU, 82, Color(tint, 0.38 * alpha), 1.4, true)
	game.draw_arc(center, radius + 7.0, clock * 0.28, clock * 0.28 + PI, 42,
		Color(tint, 0.43 * alpha), 1.0, true)
	for index_ in range(6):
		var angle := float(index_) * TAU / 6.0 + clock * (0.14 if defeated else 0.26)
		var point := center + Vector2.from_angle(angle) * (radius + 8.0)
		diamond(game, point, 2.1, Color(tint, alpha * (0.55 + 0.18 * sin(clock * 3.0 + index_))))
	area.position.y += sin(clock * 1.4) * 2.2
	var portrait_tint := Color(1.0, 1.0, 1.0, alpha)
	if victory:
		Portraits.victory(game, index, area, portrait_tint)
	else:
		Portraits.portrait(game, index, area, defeated, close, portrait_tint)

static func title_portrait(game) -> void:
	var age: float = game.menu_motion.screen_age
	var rotation := int(age / TITLE_ROTATION)
	var since := fposmod(age, TITLE_ROTATION)
	var index := posmod(int(game.hero) + rotation, game.NAMES.size())
	var progress := smoothstep(0.0, 0.48, since)
	var clock: float = game.visual_clock
	var area := Rect2(384, -42, 514, 468)
	area.position += Vector2(roundf(sin(clock * 0.8) * 5.0), roundf(sin(clock * 1.28) * 3.0))
	if rotation > 0 and progress < 1.0:
		var last := posmod(index - 1, game.NAMES.size())
		var outgoing := area
		outgoing.position.x -= roundf(17.0 * progress)
		Portraits.portrait(game, last, outgoing, false, true, Color(1.0, 1.0, 1.0, 1.0 - progress))
	area.position.x += roundf(28.0 * (1.0 - progress))
	Portraits.portrait(game, index, area, false, true, Color(1.0, 1.0, 1.0, progress))

static func title(game) -> void:
	var preferences = game.preferences
	var bloom := Rect2(42, 28, 246, 350)
	frame(game, bloom, Color(0.10, 0.07, 0.14, 0.73), Color("#a68164"))
	title_portrait(game)
	var point := Vector2(60, 101)
	game.draw_string(Art.TITLE_FONT, point + Vector2(2, 3), "Garden", HORIZONTAL_ALIGNMENT_LEFT, -1, 61, Color("#1e1828"))
	game.draw_string(Art.TITLE_FONT, point, "Garden", HORIZONTAL_ALIGNMENT_LEFT, -1, 61, CREAM)
	game.draw_string(Art.ITALIC_FONT, Vector2(65, 145), "Bad Bloom", HORIZONTAL_ALIGNMENT_LEFT, -1, 43, Color("#f4cbab"))
	game.draw_line(Vector2(65, 167), Vector2(265, 167), Color("#d2ac83"), 1.0, true)
	sprig(game, Vector2(65, 167), Vector2(1, -1), Color(BRASS, 0.84))
	sprig(game, Vector2(265, 167), Vector2(-1, -1), Color(BRASS, 0.84))
	diamond(game, Vector2(165, 167), 4.0 + sin(float(game.visual_clock) * 2.3) * 0.45, CREAM)
	var run_key := "title.continue" if FileAccess.file_exists(game.SAVE) else "title.new_run"
	button(game, CONTINUE, preferences.text(run_key), true)
	button(game, GARDEN_LINK, preferences.text("common.garden"))
	button(game, SETTINGS_LINK, preferences.text("common.settings"))
	centered(game, Rect2(54, 348, 221, 26), preferences.text("title.credit"), 15, CREAM, true)
	var seeds := Rect2(696, 14, 132, 27)
	frame(game, seeds, Color(0.15, 0.10, 0.20, 0.88))
	centered(game, seeds, preferences.text("title.seed_balance", {"amount": game.garden_seeds}), 12, DIM)

static func roster_hit(index: int) -> Rect2:
	return Rect2(38, 70 + index * 49, 224, 43)

static func roster(game) -> void:
	game.draw_rect(CANVAS, Color(0.08, 0.06, 0.14, 0.20))
	frame(game, Rect2(287, 36, 539, 333), Color(0.13, 0.10, 0.19, 0.79))
	text(game, Vector2(38, 53), "The Garden Girls", 26, CREAM, true)
	var motion = game.get("menu_motion")
	for i in range(game.NAMES.size()):
		var tile := roster_hit(i)
		var selected: bool = i == game.hero
		var tint: Color = game.COLORS[i]
		var hover: float = motion.hover_amount(tile, game.get_local_mouse_position()) if motion else 0.0
		var selected_flare: float = motion.selection_amount(motion.hero_age) if selected and motion else 0.0
		var edge := tint.lerp(BRASS, 0.38) if selected else BRASS
		var fill := Color("#63465e").lerp(tint, 0.13 * selected_flare) if selected else Color("#2f253e")
		frame(game, tile, fill.lightened(0.13 * hover), edge)
		Art.heroine(game, i, tile.position + Vector2(25, 42), 41, game.visual_clock)
		text(game, tile.position + Vector2(54, 29), game.NAMES[i], 19, CREAM, true)
		if selected:
			diamond(game, tile.end - Vector2(16.0, 21.0), 4.2 + selected_flare, tint)

	heroine_stage(game, Vector2(440, 337), 268.0)
	text(game, Vector2(587, 105), game.NAMES[game.hero], 38, CREAM, true)
	text(game, Vector2(588, 132), ROLE[game.hero], 14, DIM)
	game.draw_line(Vector2(588, 149), Vector2(800, 149), BRASS, 1.0)
	sprig(game, Vector2(800, 149), Vector2(-1, 1), Color(BRASS, 0.77))
	text(game, Vector2(588, 177), "HP  %d    ·    %s" % [game.HEALTH[game.hero], game.RESOURCES[game.hero]], 15)
	text(game, Vector2(588, 210), STARTING_WEAPONS[game.hero], 22, CREAM, true)
	var hero: int = game.hero
	draw_ability_row(game, Rect2(584, 223, 219, 34), hero, false)
	draw_ability_row(game, Rect2(584, 263, 219, 34), hero, true)
	button(game, ROSTER_BACK, "Back")
	button(game, DESCEND, "Continue Run" if FileAccess.file_exists(game.SAVE) else "Select Heroine", true)

static func draw_ability_row(game, box: Rect2, hero: int, ultimate: bool) -> void:
	var accent: Color = game.COLORS[hero]
	frame(game, box, Color("#2d243b"), Color(accent, 0.65))
	ability_icon(game, hero, ultimate, box.position + Vector2(22.0, 17.0), 28.0)
	var ability_name: String = game.HeroUltimates.NAMES[hero] if ultimate else CLASS_SKILLS[hero]
	centered(game, Rect2(box.position + Vector2(37.0, 1.0), Vector2(box.size.x - 43.0, 20.0)),
		ability_name, 14, CREAM, true)
	centered(game, Rect2(box.position + Vector2(37.0, 20.0), Vector2(box.size.x - 43.0, 11.0)),
		"Ultimate" if ultimate else "Active skill", 9, DIM)

static func ability_icon(canvas: Node2D, hero: int, ultimate: bool, center: Vector2,
		diameter: float, tint := Color.WHITE) -> void:
	Portraits.ability(canvas, hero, ultimate, center, diameter, tint)

static func ultimate_cutin(game) -> void:
	var remaining: float = game.ultimates.cue_time
	var hero: int = game.ultimates.cue_hero
	if remaining <= 0.0 or hero < 0 or hero >= game.NAMES.size():
		return
	if hero == 0:
		remaining /= 0.75
	var elapsed := maxf(0.0, float(game.HeroUltimates.CUTIN_DURATION) - remaining)
	var veil := smoothstep(0.0, 0.12, elapsed) * smoothstep(0.0, 0.12, remaining)
	game.draw_rect(CANVAS, Color(0.085, 0.045, 0.14, 0.36 * veil))

	var strip_in := smoothstep(0.10, 0.23, elapsed)
	var strip_out := smoothstep(0.0, 0.20, remaining)
	var visible := strip_in * strip_out
	if visible <= 0.01:
		return
	var band := Rect2(0, 150, CANVAS.size.x, 114)
	var hue: Color = game.COLORS[hero]
	game.draw_polygon(PackedVector2Array([band.position, Vector2(band.end.x, band.position.y),
		band.end, Vector2(0.0, band.end.y)]), PackedColorArray([
		Color(hue.darkened(0.72), 0.92 * visible), Color(0.10, 0.055, 0.16, 0.97 * visible),
		Color(0.17, 0.09, 0.22, 0.96 * visible), Color(hue.darkened(0.77), 0.94 * visible),
	]))

	var face_in := smoothstep(0.14, 0.36, elapsed)
	var face_x := lerpf(-254.0, 0.0, face_in) - 42.0 * (1.0 - strip_out)
	Portraits.eyes(game, hero, Rect2(face_x, band.position.y + 2.0, 465.0, band.size.y - 4.0),
		Color(1.0, 1.0, 1.0, face_in * strip_out))
	var seam := PackedVector2Array([Vector2(435, 151), Vector2(514, 151),
		Vector2(463, 263), Vector2(387, 263)])
	game.draw_polygon(seam, PackedColorArray([
		Color(0.16, 0.09, 0.22, 0.0), Color(0.16, 0.09, 0.22, 0.88 * visible),
		Color(0.19, 0.10, 0.24, 0.88 * visible), Color(0.19, 0.10, 0.24, 0.0),
	]))

	var rail := Color("#f8d99d")
	for y in [band.position.y, band.end.y]:
		game.draw_line(Vector2(0, y), Vector2(CANVAS.size.x, y), Color(rail, 0.16 * visible), 6.0, true)
		game.draw_line(Vector2(0, y), Vector2(CANVAS.size.x, y), Color(rail, 0.92 * visible), 1.5, true)
	sprig(game, Vector2(17, 158), Vector2(1, 1), Color(rail, 0.75 * visible))
	sprig(game, Vector2(846, 256), Vector2(-1, -1), Color(rail, 0.75 * visible))
	sprig(game, Vector2(827, 158), Vector2(-1, 1), Color(rail, 0.66 * visible))
	for seed in range(13):
		var age := fposmod(elapsed * (0.72 + float(seed % 3) * 0.16) + float(seed) * 0.071, 1.0)
		var p := Vector2(185.0 + 695.0 * age, 203.0 + sin(float(seed) * 3.03 + age * 3.1) * 48.0)
		diamond(game, p, 1.7 + float(seed % 3) * 0.7, Color(hue.lerp(rail, 0.38), (1.0 - age) * visible * 0.71))

	var quote_alpha := smoothstep(0.38, 0.54, elapsed) * strip_out
	var quote: String = ULTIMATE_QUOTES[hero]
	var phrase_size := 34
	var phrase_width := Art.ITALIC_FONT.get_string_size(quote, HORIZONTAL_ALIGNMENT_LEFT, -1, phrase_size).x
	if phrase_width > 370.0:
		phrase_size = maxi(24, floori(float(phrase_size) * 370.0 / phrase_width))
	var box := Rect2(466.0, 168.0, 377.0, 53.0)
	var y_offset := 3.0 * (1.0 - quote_alpha)
	var baseline := box.position.y + (box.size.y + Art.ITALIC_FONT.get_ascent(phrase_size)
		- Art.ITALIC_FONT.get_descent(phrase_size)) * 0.5 + y_offset
	game.draw_string(Art.ITALIC_FONT, Vector2(box.position.x, baseline), quote, HORIZONTAL_ALIGNMENT_CENTER,
		box.size.x, phrase_size, Color(0.99, 0.93, 0.83, quote_alpha))
	centered(game, Rect2(481, 224, 347, 22), game.HeroUltimates.NAMES[hero], 14,
		Color(rail, quote_alpha * 0.88), true)

static func controls(game) -> void:
	var joystick_active: bool = game.joystick_id >= 0
	var joystick_point: Vector2 = game.joystick_origin if joystick_active else game.touch_position(game.JOYSTICK)
	var attack_point: Vector2 = game.touch_position(game.ATTACK)
	var dodge_point: Vector2 = game.touch_position(game.DODGE)
	var skill_point: Vector2 = game.touch_position(game.SKILL)
	var dodge_left := maxf(0.0, float(game.dodge_time))
	var skill_left := maxf(0.0, float(game.skill_time))
	var joystick_tone := Color(0.90, 0.82, 0.78, 0.85 if joystick_active else 0.38)
	ring(game, joystick_point, 44, joystick_tone, 0.45 if joystick_active else 0.21)
	game.draw_circle(joystick_point + game.stick * 35.0, 15.0, joystick_tone, true, -1.0, true)
	ring(game, attack_point, 31, CREAM, 0.72)
	cooldown_ring(game, dodge_point, 23.0, CREAM, dodge_left, game.dodge_cooldown())
	cooldown_ring(game, skill_point, 24.0, game.COLORS[game.hero], skill_left,
		game.skill_cooldown())
	var blade: Vector2 = attack_point + Vector2(0, -5)
	game.draw_line(blade + Vector2(-9, 10), blade + Vector2(10, -10), CREAM, 3.4, true)
	game.draw_line(blade + Vector2(-10, 1), blade + Vector2(-2, 9), BRASS, 2.6, true)
	var dash := dodge_point + Vector2(0, -5)
	var dash_ink := CREAM if dodge_left == 0.0 else Color("#b2a398")
	game.draw_polyline(PackedVector2Array([dash + Vector2(1, -6), dash + Vector2(8, 0), dash + Vector2(1, 6)]), dash_ink, 2.3, true)
	game.draw_line(dash + Vector2(-10, 0), dash + Vector2(7, 0), dash_ink, 2.0, true)
	ability_icon(game, game.hero, false, skill_point + Vector2(0, -7), 27.0,
		Color.WHITE if skill_left == 0.0 else Color(0.72, 0.69, 0.73))
	centered(game, Rect2(attack_point + Vector2(-31, 8), Vector2(62, 17)), "Attack", 10)
	centered(game, Rect2(dodge_point + Vector2(-25, 4), Vector2(50, 17)),
		"Dodge" if dodge_left == 0.0 else "%.1fs" % game.pocket.remaining_cooldown(dodge_left), 9)
	centered(game, Rect2(skill_point + Vector2(-25, 4), Vector2(50, 17)),
		"Skill" if skill_left == 0.0 else "%.1fs" % game.pocket.remaining_cooldown(skill_left), 9)

	draw_ultimate_control(game)
	draw_pocket_control(game)

static func draw_pocket_control(game) -> void:
	var point: Vector2 = game.touch_position(game.POCKET)
	var held: String = game.pocket.held
	var haste := float(game.pocket.haste)
	var active := haste > 0.0
	var accent := Color("#87788a")
	var caption := "Pocket"
	if not held.is_empty():
		var item: Dictionary = game.RunItems.ITEMS[held]
		var usable: bool = game.pocket.usable(game)
		accent = item.accent if usable else Color("#99888e")
		caption = item.short
		ring(game, point, 22.0, accent, 0.69)
		game.RunItems.draw_icon(game, held, point + Vector2(0, -6), 25.0,
			Color.WHITE if usable else Color(0.68, 0.63, 0.65))
	elif active:
		accent = game.RunItems.ITEMS.clockwise_tonic.accent
		caption = "%.1fs" % haste
		ring(game, point, 22.0, accent, 0.66)
		game.RunItems.draw_icon(game, "clockwise_tonic", point + Vector2(0, -6), 25.0, Color(accent, 0.76))
	else:
		ring(game, point, 22.0, accent, 0.28)
		game.draw_arc(point + Vector2(0, -5), 5.5, 0, TAU, 18, accent, 1.0, true)
	centered(game, Rect2(point + Vector2(-25, 4), Vector2(50, 15)), caption, 9, accent)

static func draw_aim_preview(game) -> void:
	var action: String = game.preview_action()
	if action.is_empty():
		return
	var canvas: Node2D = game.world_canvas
	var tint: Color = game.COLORS[game.hero].lightened(0.24)
	if action == "skill":
		var mark: Vector2 = game.HeroAbilities.ranged_skill_landmark(game, game.hero)
		var radius := float(game.HeroAbilities.VERSE_RADIUS if game.hero == 1 else game.HeroAbilities.SNARE_RADIUS)
		aim_reticle(canvas, mark, radius, tint)
	elif game.hero == 1:
		for mark: Vector2 in game.HeroUltimates.elegy_landmarks(game):
			aim_reticle(canvas, mark, game.HeroUltimates.ELEGY_RADIUS, tint)
	else:
		var origin: Vector2 = game.player
		var direction: Vector2 = game.assisted_direction(280.0, true)
		var travel := float(game.HeroUltimates.BLOOM_SPEED * game.HeroUltimates.BLOOM_LIFE)
		for turn: float in game.HeroUltimates.VOLLEY_TURNS:
			var end: Vector2 = game.ForgottenEncounters.clear_endpoint(game, origin, direction.rotated(turn), travel, 14.0)
			if end.distance_to(origin) >= 6.0:
				canvas.draw_dashed_line(origin.round(), end.round(), Color(tint, 0.55), 1.0, 6.0, true, true)
				diamond(canvas, end.round(), 2.5, tint)

static func aim_reticle(canvas: Node2D, mark: Vector2, radius: float, tint: Color) -> void:
	for quarter in range(4):
		var angle := quarter * PI * 0.5
		canvas.draw_arc(mark.round(), radius, angle + 0.18, angle + 1.39, 18, Color(tint, 0.68), 1.2, true)
	diamond(canvas, mark.round(), 3.4, tint)

static func cooldown_ring(game, point: Vector2, radius: float, accent: Color, left: float, duration: float) -> void:
	ring(game, point, radius, Color(accent, 0.42 if left > 0.0 else 1.0), 0.71)
	if left > 0.0:
		var recovery := clampf(1.0 - left / duration, 0.0, 1.0)
		if recovery > 0.01:
			game.draw_arc(point, radius - 1.0, -PI / 2.0, -PI / 2.0 + TAU * recovery, 48, accent, 2.1, true)

static func draw_ultimate_control(game) -> void:
	var point: Vector2 = game.touch_position(game.ULTIMATE)
	var ready: bool = game.ultimate_ready()
	var accent := Color("#f9db95") if ready else Color("#a498b9")
	ring(game, point, 24.0, accent, 0.85 if ready else 0.62)
	ability_icon(game, game.hero, true, point + Vector2(0.0, -7.0), 27.0,
		Color.WHITE if ready else Color(0.64, 0.62, 0.70))
	centered(game, Rect2(point + Vector2(-24, 4), Vector2(48, 17)), "Ultimate", 9, accent)

static func ring(canvas: Node2D, point: Vector2, radius: float, color: Color, alpha: float) -> void:
	canvas.draw_circle(point, radius, Color(0.13, 0.10, 0.20, alpha), true, -1.0, true)
	canvas.draw_arc(point, radius - 1.0, 0.0, TAU, 60, color, 1.6, true)
	canvas.draw_arc(point, radius - 4.0, 0.0, TAU, 60, Color(color, 0.27), 1.0, true)

static func hud(game, biome: int) -> void:
	game.draw_rect(Rect2(0, 0, CANVAS.size.x, 42), Color("#211a2e"))
	game.draw_line(Vector2(0, 42), Vector2(864, 42), BRASS, 1.0)
	game.draw_circle(Vector2(55, 23), 19, INK, true, -1.0, true)
	game.draw_arc(Vector2(55, 23), 19, 0, TAU, 40, BRASS, 1.0, true)
	Art.heroine(game, game.hero, Vector2(55, 41), 35, game.visual_clock)
	game.draw_rect(Rect2(83, 12, 111, 8), Color("#573146"))
	var life = clampf(float(game.hp) / game.HEALTH[game.hero], 0.0, 1.0)
	game.draw_rect(Rect2(83, 12, 111 * life, 8), Color("#ec8191"))
	text(game, Vector2(203, 20), "%d / %d" % [game.hp, game.HEALTH[game.hero]], 12)
	for i in range(5):
		diamond(game, Vector2(88 + 13 * i, 31), 4, game.COLORS[game.hero] if i < game.resource else Color("#54445e"))
	if game.upgrades.rank(game.RunUpgrades.PETAL_AEGIS) > 0:
		var lit: bool = game.upgrades.aegis_ready() and not game.foes.is_empty()
		var ward := Vector2(159, 30)
		var edge := Color("#f3bd9f") if lit else Color("#60475b")
		game.draw_circle(ward, 8.0, Color("#392739"))
		game.draw_arc(ward, 8.0, 0, TAU, 22, edge, 1.0)
		Reward.UpgradeArt.draw_icon(game, game.RunUpgrades.PETAL_AEGIS, ward, 13.0, 1.0 if lit else 0.44)
	var region_name: String = game.BIOMES[biome]
	if biome == game.Dungeon.BIOME_COUNT:
		region_name = game.preferences.place_name(region_name)
	if game.room_title.is_empty():
		centered(game, Rect2(290, 3, 284, 35), region_name, 17, CREAM, true)
	else:
		centered(game, Rect2(290, 2, 284, 23), region_name, 16, CREAM, true)
		centered(game, Rect2(290, 22, 284, 16), game.room_title, 10, DIM)
	var total := int(game.run_time)
	text(game, Vector2(179, 34), "%02d:%02d" % [total / 60, total % 60], 10, DIM)
	game.RouteView.draw_minimap(game)
	button(game, PAUSE, "Ⅱ")

static func boss_health_bar(game) -> void:
	for foe: Dictionary in game.foes:
		if not foe.boss:
			continue
		var boss_biome := int(foe.get("biome", game.active_biome))
		var name: String = game.Codex.BESTIARY[clampi(boss_biome, 0, game.Codex.BESTIARY.size() - 1)][3][0]
		var optional_id: String = foe.get("optional_boss", "")
		if not optional_id.is_empty():
			name = game.OptionalBosses.NAMES.get(optional_id, name)
		var shield: int = game.AstralCore.shield_lives(game) if boss_biome == game.AstralCore.CORE and optional_id.is_empty() else 0
		var shield_name := "ward nodes"
		if optional_id == game.OptionalBosses.CHAIR:
			shield_name = "string posts"
			shield = game.foes.filter(func(actor): return actor.get("chair_post", false) and int(actor.hp) > 0).size()
		var final_phase: bool = boss_biome == game.AstralCore.CORE and int(foe.get("finale_step", 0)) > 0
		var panel := Rect2(267, 44, 330, 35)
		frame(game, panel, Color("#211829"), Color("#d0a474") if final_phase else Color("#b68d80"))
		centered(game, Rect2(277, 45, 237 if final_phase else 310, 17), name, 14, CREAM, true)
		if final_phase:
			var label := "FASE III" if game.preferences.language == "id" else "PHASE III"
			centered(game, Rect2(516, 46, 66, 17), label, 9, Color("#ffc381"), true)
		var bar := Rect2(282, 63, 300, 9)
		var fill := clampf(float(foe.hp) / float(foe.max), 0.0, 1.0)
		game.draw_rect(bar, Color("#462638"))
		game.draw_rect(Rect2(bar.position, Vector2(roundf(300.0 * fill), bar.size.y)),
			Color("#8bb8cf") if shield > 0 else Color("#d06f8c"))
		centered(game, Rect2(286, 62, 292, 11),
			"%d %s" % [shield, shield_name] if shield > 0 else "%d / %d" % [maxi(0, int(foe.hp)), int(foe.max)],
			9, Color("#fff3db"))
		return
