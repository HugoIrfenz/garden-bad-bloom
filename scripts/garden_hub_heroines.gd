extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const GuestRoster = preload("res://scripts/guest_roster.gd")
const PERIOD := 31.0
const EMOTE_TIME := 1.75
const HEIGHTS := [74.0, 76.0, 68.0, 76.0, 75.0, 64.0, 70.0, 82.0]
const IDLE_FACING := [Vector2.RIGHT, Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.LEFT, Vector2.RIGHT, Vector2.LEFT, Vector2.RIGHT]

# Angela meets Nixia near the west path. Vivianne meets Zaria by the
# east path. Virelia tends the edge of the fountain between visits.
const ROUTES := [
	[[0.0, Vector2(188, 228)], [1.1, Vector2(188, 228)], [5.7, Vector2(299, 227)],
		[9.1, Vector2(299, 227)], [14.8, Vector2(226, 286)], [17.1, Vector2(226, 286)],
		[24.2, Vector2(157, 234)], [27.0, Vector2(157, 234)], [31.0, Vector2(188, 228)]],
	[[0.0, Vector2(655, 220)], [2.7, Vector2(655, 220)], [8.0, Vector2(572, 258)],
		[12.7, Vector2(572, 258)], [19.2, Vector2(633, 294)], [21.6, Vector2(633, 294)],
		[27.7, Vector2(701, 225)], [31.0, Vector2(655, 220)]],
	[[0.0, Vector2(345, 302)], [0.5, Vector2(345, 302)], [5.8, Vector2(356, 230)],
		[9.8, Vector2(356, 230)], [14.2, Vector2(416, 268)], [16.5, Vector2(416, 268)],
		[23.9, Vector2(307, 278)], [25.3, Vector2(307, 278)], [31.0, Vector2(345, 302)]],
	[[0.0, Vector2(510, 250)], [1.8, Vector2(510, 250)], [6.7, Vector2(436, 211)],
		[10.2, Vector2(436, 211)], [16.1, Vector2(467, 276)], [19.9, Vector2(467, 276)],
		[24.3, Vector2(543, 283)], [26.4, Vector2(543, 283)], [31.0, Vector2(510, 250)]],
	[[0.0, Vector2(724, 280)], [3.3, Vector2(724, 280)], [8.5, Vector2(634, 257)],
		[12.0, Vector2(634, 257)], [16.7, Vector2(719, 303)], [20.2, Vector2(719, 303)],
		[26.4, Vector2(747, 226)], [27.9, Vector2(747, 226)], [31.0, Vector2(724, 280)]],
	[[0.0, Vector2(132, 290)], [1.6, Vector2(132, 290)], [6.6, Vector2(225, 302)],
		[10.1, Vector2(225, 302)], [16.0, Vector2(277, 259)], [19.4, Vector2(277, 259)],
		[25.2, Vector2(164, 259)], [27.1, Vector2(164, 259)], [31.0, Vector2(132, 290)]],
	[[0.0, Vector2(561, 207)], [2.8, Vector2(561, 207)], [7.8, Vector2(609, 222)],
		[11.7, Vector2(609, 222)], [16.2, Vector2(537, 244)], [19.0, Vector2(537, 244)],
		[26.1, Vector2(489, 212)], [28.7, Vector2(489, 212)], [31.0, Vector2(561, 207)]],
	[[0.0, Vector2(776, 244)], [3.1, Vector2(776, 244)], [9.8, Vector2(660, 306)],
		[13.1, Vector2(660, 306)], [19.7, Vector2(586, 284)], [23.2, Vector2(586, 284)],
		[29.3, Vector2(776, 244)], [31.0, Vector2(776, 244)]],
]
const EMOTES := [
	[[6.4, 0], [15.3, 2], [25.3, 1]], [[9.2, 2], [20.0, 3]],
	[[7.2, 1], [14.4, 2], [24.1, 1]], [[7.8, 0], [17.0, 3], [24.6, 0]],
	[[10.2, 3], [18.1, 1], [26.5, 2]],
	[[7.3, 1], [17.1, 0], [25.4, 2]], [[8.8, 3], [17.0, 2], [26.5, 0]],
	[[1.1, 2], [11.0, 1], [20.4, 3]],
]

static func pose(index: int, phase: float) -> Dictionary:
	var track: Array = ROUTES[index]
	var distance := 0.0
	for segment_index in range(track.size() - 1):
		var current: Array = track[segment_index]
		var following: Array = track[segment_index + 1]
		var start: Vector2 = current[1]
		var finish: Vector2 = following[1]
		var segment := finish - start
		if phase < float(following[0]):
			var progress := smoothstep(float(current[0]), float(following[0]), phase)
			var moving := segment.length_squared() > 1.0
			return {"hero": index, "feet": start + segment * progress, "moving": moving,
				"facing": segment if moving else IDLE_FACING[index], "distance": distance + segment.length() * progress}
		distance += segment.length()
	return {"hero": index, "feet": track[0][1], "moving": false,
		"facing": IDLE_FACING[index], "distance": 0.0}

static func draw(game) -> void:
	var clock: float = game.visual_clock
	var phase := fposmod(clock, PERIOD)
	var actors: Array[Dictionary] = []
	for index in ROUTES.size():
		if GuestRoster.is_unlocked(game.profile, index):
			actors.append(pose(index, phase))
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.feet.y < b.feet.y)
	for actor: Dictionary in actors:
		draw_heroine(game, actor, phase)

static func draw_heroine(game, actor: Dictionary, phase: float) -> void:
	var index: int = actor.hero
	var feet: Vector2 = actor.feet.round()
	var size: float = HEIGHTS[index]
	var emote := -1
	var emote_age := 0.0
	for beat: Array in EMOTES[index]:
		if phase >= float(beat[0]) and phase < float(beat[0]) + EMOTE_TIME:
			emote = beat[1]
			emote_age = phase - float(beat[0])
	if game.menu_motion.garden_reaction_hero == index and game.menu_motion.garden_reaction_age < EMOTE_TIME:
		emote = game.menu_motion.garden_reaction_kind
		emote_age = game.menu_motion.garden_reaction_age
	if index == game.hero:
		var accent: Color = game.COLORS[index]
		game.draw_arc(feet - Vector2(0, 3), 18.0, 0.0, TAU, 30, Color(accent, 0.77), 1.0, true)
	Art.shadow(game, feet, 17.0)
	var hop := roundf(5.0 * sin(PI * clampf(emote_age / 0.37, 0.0, 1.0))) if emote >= 0 else 0.0
	var idle := roundf(sin(float(game.visual_clock) * 2.3 + index) * 1.3) if not actor.moving else 0.0
	Art.walk(game, index, feet - Vector2(0, hop + idle), size, actor.distance * 1.65, actor.facing, actor.moving, Color.WHITE)
	if emote >= 0:
		draw_emote(game, feet - Vector2(0, size + 17.0 + hop), emote, emote_age)

static func react_at(game, point: Vector2) -> void:
	var phase := fposmod(game.visual_clock, PERIOD)
	var front := -1
	var lowest := -INF
	for index in ROUTES.size():
		if not GuestRoster.is_unlocked(game.profile, index):
			continue
		var feet: Vector2 = pose(index, phase).feet
		var height: float = HEIGHTS[index]
		var hitbox := Rect2(feet - Vector2(27, height), Vector2(54, height + 10))
		if hitbox.has_point(point) and feet.y > lowest:
			front = index
			lowest = feet.y
	if front >= 0:
		game.menu_motion.react_in_garden(front)
		game.sound.play("ui")

static func draw_emote(game, center: Vector2, kind: int, age: float) -> void:
	var alpha := smoothstep(0.0, 0.18, age) * (1.0 - smoothstep(1.27, EMOTE_TIME, age))
	var origin := (center + Vector2(0, lerpf(6.0, -3.0, smoothstep(0.0, 0.5, age)))).round()
	var paper := Color(1.0, 0.92, 0.81, alpha)
	var ink := Color(0.25, 0.16, 0.26, alpha)
	var bubble := Rect2(origin - Vector2(13, 10), Vector2(26, 20))
	game.draw_colored_polygon(game.View.bevel_points(bubble.grow(1), 5.0), ink)
	game.draw_colored_polygon(game.View.bevel_points(bubble, 4.0), paper)
	game.draw_colored_polygon(PackedVector2Array([origin + Vector2(-3, 8), origin + Vector2(3, 8),
		origin + Vector2(0, 14)]), paper)
	match kind:
		0:
			var rose := Color(0.76, 0.28, 0.43, alpha)
			game.draw_circle(origin + Vector2(-2, -2), 2.7, rose)
			game.draw_circle(origin + Vector2(2, -2), 2.7, rose)
			game.draw_colored_polygon(PackedVector2Array([origin + Vector2(-4, -1), origin + Vector2(4, -1),
				origin + Vector2(0, 5)]), rose)
		1:
			game.draw_rect(Rect2(origin - Vector2(1, 5), Vector2(2, 6)), ink)
			game.draw_rect(Rect2(origin + Vector2(-1, 3), Vector2(2, 2)), ink)
		2:
			for dot in [-4, 0, 4]:
				game.draw_circle(origin + Vector2(dot, 1), 1.25, ink)
		3:
			game.draw_line(origin + Vector2(1, -5), origin + Vector2(1, 4), ink, 1.5)
			game.draw_line(origin + Vector2(1, -5), origin + Vector2(5, -3), ink, 1.5)
			game.draw_circle(origin + Vector2(-1, 4), 2.2, ink)
