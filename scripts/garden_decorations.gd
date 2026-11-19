extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const ENCOUNTER_ART = preload("res://assets/art/menus/encounter_props.png")
const CLOCKWORK_ART = preload("res://assets/art/menus/clockwork_events.png")
const ASTRAL_LANTERNS = "astral_lanterns"
const ROSEWOOD_BENCH = "rosewood_bench"
const SONGBIRD_CHOIR = "songbird_choir"
const MOONLIT_BASIN = "moonlit_basin"
const CLOCKWORK_DIAL = "clockwork_garden_dial"
const PAINTED_BUTTERFLIES = "painted_butterflies"
const STARLIGHT_FOUNTAIN = "starlight_fountain"
const SPORE_PUFF_NOOK = "spore_puff_nook"
const PRICES := {
	ROSEWOOD_BENCH: 27, SPORE_PUFF_NOOK: 32, PAINTED_BUTTERFLIES: 37,
	CLOCKWORK_DIAL: 44, ASTRAL_LANTERNS: 49, SONGBIRD_CHOIR: 58,
	MOONLIT_BASIN: 63, STARLIGHT_FOUNTAIN: 72,
}
const ITEMS := {
	ROSEWOOD_BENCH: {"name": "Rosewood Bench", "effect": "Set a petal-strewn bench by the west gate.", "accent": Color("#efb5aa")},
	SPORE_PUFF_NOOK: {"name": "Spore Puff Nook", "effect": "Two tame spore puffs hop around the west beds.", "accent": Color("#e6bde9")},
	PAINTED_BUTTERFLIES: {"name": "Painted Butterflies", "effect": "Colorful butterflies flutter around the courtyard.", "accent": Color("#f4b2d3")},
	CLOCKWORK_DIAL: {"name": "Clockwork Dial", "effect": "A brass clock sweeps golden lights by the east path.", "accent": Color("#f5c278")},
	ASTRAL_LANTERNS: {"name": "Astral Lanterns", "effect": "Two crystal lamps light up the fountain path.", "accent": Color("#a5e8f0")},
	SONGBIRD_CHOIR: {"name": "Songbird Choir", "effect": "Clockwork birds trail music notes by the west arch.", "accent": Color("#f6b8a4")},
	MOONLIT_BASIN: {"name": "Moonlit Basin", "effect": "A crescent basin sends blue ripples across the east beds.", "accent": Color("#bde5f5")},
	STARLIGHT_FOUNTAIN: {"name": "Starlight Fountain", "effect": "Thread violet starlight through the central fountain.", "accent": Color("#d5c8ff")},
}
const SPRITES := {
	ROSEWOOD_BENCH: [ENCOUNTER_ART, Rect2(189, 487, 392, 232)],
	CLOCKWORK_DIAL: [CLOCKWORK_ART, Rect2(61, 53, 629, 618)],
	ASTRAL_LANTERNS: [Art.COVER, Art.COVER_REGIONS[5]],
	SONGBIRD_CHOIR: [CLOCKWORK_ART, Rect2(1493, 81, 619, 602)],
	MOONLIT_BASIN: [ENCOUNTER_ART, Rect2(1646, 239, 302, 232)],
}
const PLACEMENTS := {
	ROSEWOOD_BENCH: [Vector3(76, 265, 43)],
	CLOCKWORK_DIAL: [Vector3(727, 141, 43)],
	ASTRAL_LANTERNS: [Vector3(250, 132, 45), Vector3(612, 132, 45)],
	SONGBIRD_CHOIR: [Vector3(192, 164, 48)],
	MOONLIT_BASIN: [Vector3(678, 179, 54)],
}
const BUTTERFLY_COLORS := [Color("#f49db9"), Color("#a896e9"), Color("#82d6c3"), Color("#f4bb78")]

static func item(id: String) -> Dictionary:
	return ITEMS.get(id, {})

static func draw(game, clock: float) -> void:
	var canvas: Node2D = game
	for id: String in PLACEMENTS:
		if not game.profile.has_unlock(id):
			continue
		for slot: Vector3 in PLACEMENTS[id]:
			draw_furnishing(canvas, id, Vector2(slot.x, slot.y), slot.z, clock + slot.x * 0.02)
	if game.profile.has_unlock(SPORE_PUFF_NOOK):
		draw_puff(canvas, Vector2(111, 305) + Vector2(sin(clock * 0.78) * 17, 0), 32.0, clock)
		draw_puff(canvas, Vector2(150, 312) + Vector2(sin(clock * 0.94 + 1.8) * 10, 0), 24.0, clock + 1.8)
	if game.profile.has_unlock(PAINTED_BUTTERFLIES):
		for index in range(7):
			var phase := clock * (0.9 + index * 0.07) + index * 1.4
			var spot := Vector2(95 + index * 108, 86 + posmod(index * 51, 152))
			var point := spot + Vector2(sin(phase) * (24.0 + index * 2.0), cos(phase * 1.21) * 14.0)
			draw_butterfly(canvas, point, phase, 1.0, BUTTERFLY_COLORS[index % BUTTERFLY_COLORS.size()])
	if game.profile.has_unlock(STARLIGHT_FOUNTAIN):
		draw_starlight(canvas, Vector2(432, 121), Vector2(96, 35), clock)

static func draw_icon(game, id: String, center: Vector2, size: float) -> void:
	var clock: float = game.visual_clock
	if SPRITES.has(id):
		var source: Rect2 = SPRITES[id][1]
		var height := size * minf(1.0, source.size.y / source.size.x)
		draw_furnishing(game, id, center + Vector2(0, height * 0.48), height, clock)
		return
	match id:
		SPORE_PUFF_NOOK:
			draw_puff(game, center + Vector2(-10, size * 0.34), size * 0.71, clock)
			draw_puff(game, center + Vector2(15, size * 0.34), size * 0.49, clock + 0.6)
		PAINTED_BUTTERFLIES:
			draw_butterfly(game, center + Vector2(-9, 6), clock * 2.0, 2.4, BUTTERFLY_COLORS[0])
			draw_butterfly(game, center + Vector2(12, -8), clock * 2.0 + 1.9, 1.7, BUTTERFLY_COLORS[2])
		STARLIGHT_FOUNTAIN:
			draw_starlight(game, center + Vector2(0, 10), Vector2(size * 0.48, size * 0.56), clock)

static func draw_furnishing(canvas: Node2D, id: String, feet: Vector2, height: float, clock: float) -> void:
	var sprite: Array = SPRITES[id]
	Art.shadow(canvas, feet, height * 0.39)
	Art.paint_actor(canvas, sprite[0], sprite[1], feet, height, 0.0, Vector2.ONE, Color.WHITE)
	var origin := feet - Vector2(0, height * 0.64)
	var accent: Color = ITEMS[id].accent
	var angle := clock * 0.73
	match id:
		ASTRAL_LANTERNS, CLOCKWORK_DIAL:
			for index in range(3):
				var orbit := angle + index * TAU / 3.0
				var point := origin + Vector2.from_angle(orbit) * Vector2(height * 0.47, height * 0.37)
				step(canvas, point, 1.4, Color(accent, 0.44 + 0.28 * sin(orbit)))
		ROSEWOOD_BENCH:
			for index in range(3):
				var fall := fposmod(clock * 0.42 + index * 0.33, 1.0)
				var point := origin + Vector2((fall - 0.5) * height, fall * (height * 0.56) - 7.0 + sin(angle + index) * 3.0)
				step(canvas, point, 1.4, Color(accent, sin(PI * fall) * 0.78))
		SONGBIRD_CHOIR:
			var rise := fposmod(clock * 0.6, 1.0)
			var note := (origin + Vector2(height * 0.18 + sin(angle) * 6.0, -height * 0.27 - rise * 11.0)).round()
			var tint := Color(accent, sin(PI * rise))
			canvas.draw_line(note, note + Vector2(0, -6), tint, 1.0)
			canvas.draw_line(note + Vector2(0, -6), note + Vector2(3, -4), tint, 1.0)
			canvas.draw_rect(Rect2(note - Vector2(2, 0), Vector2(3, 2)), tint)
		MOONLIT_BASIN:
			draw_ripples(canvas, feet - Vector2(0, height * 0.23), height * 0.23, clock, accent)

static func draw_ripples(canvas: Node2D, center: Vector2, radius: float, clock: float, accent: Color) -> void:
	canvas.draw_set_transform(center.round(), 0.0, Vector2(1.0, 0.37))
	for index in range(2):
		var age := fposmod(clock * 0.71 + index * 0.5, 1.0)
		canvas.draw_arc(Vector2.ZERO, lerpf(2.0, radius, age), 0, TAU, 24, Color(accent, sin(PI * age) * 0.64), 1.2, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_starlight(canvas: Node2D, center: Vector2, spread: Vector2, clock: float) -> void:
	var tint := Color("#d4b9ff")
	draw_ripples(canvas, center, spread.x, clock, tint)
	for index in range(8):
		var progress := fposmod(clock * (0.53 + index * 0.027) + index * 0.29, 1.0)
		var across := sin(index * 2.4 + progress * PI) * spread.x * 0.73
		var point := center + Vector2(across, -progress * spread.y)
		var light := Color(tint, sin(PI * progress) * 0.84)
		step(canvas, point, 1.6 + index % 3 * 0.4, light)
		canvas.draw_line(point.round(), (point + Vector2(0, -3)).round(), light, 1.0)

static func draw_puff(canvas: Node2D, feet: Vector2, height: float, clock: float) -> void:
	Art.shadow(canvas, feet, height * 0.28)
	Art.garden_enemy(canvas, 1, 1, feet - Vector2(0, 5.0), height, clock, 0.0, 0.0)

static func draw_butterfly(canvas: Node2D, point: Vector2, phase: float, size: float, light: Color) -> void:
	var pivot := point.round()
	var wing := size * (2.5 + absf(sin(phase * 7.0)) * 3.4)
	var rise := size * 4.0
	for side in [-1.0, 1.0]:
		var tip := pivot + Vector2(side * wing, -rise)
		var tail := pivot + Vector2(side * wing * 0.76, rise * 0.53)
		canvas.draw_colored_polygon(PackedVector2Array([pivot + Vector2(0, rise * 0.55), tip,
			tip + Vector2(side * wing * 0.24, rise * 0.34), tail]), Color("#51405d"))
		canvas.draw_colored_polygon(PackedVector2Array([pivot, tip + Vector2(0, 1), tail - Vector2(0, 1)]), light)
	canvas.draw_rect(Rect2(pivot - Vector2(1, 1), Vector2(2, 3)), Color("#f8e2b8"))

static func step(canvas: Node2D, point: Vector2, size: float, tint: Color) -> void:
	var origin := point.round()
	canvas.draw_colored_polygon(PackedVector2Array([origin + Vector2.UP * size,
		origin + Vector2.RIGHT * size, origin + Vector2.DOWN * size, origin + Vector2.LEFT * size]), tint)
