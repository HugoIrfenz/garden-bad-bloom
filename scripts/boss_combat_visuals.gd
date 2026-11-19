extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const Encounter = preload("res://scripts/forgotten_encounters.gd")
const MAJESTY = preload("res://assets/art/mushroom_majesty_actions.png")
const MAJESTY_POSES = [
	Rect2(42, 44, 503, 627),
	Rect2(633, 54, 783, 632),
	Rect2(1475, 48, 638, 627),
]
# Each horizontal anchor marks the middle of the boots rather than the width of the cleavers.
const MAJESTY_FEET = [292.0, 370.0, 319.0]
const MAJESTY_WARN = 0
const MAJESTY_STRIKE = 1
const MAJESTY_RECOVER = 2
const BOSS_TINTS = [
	Color("#f2aa85"), Color("#f5b29a"), Color("#f9ce82"), Color("#f893b2"),
	Color("#e3b4f0"), Color("#b5ceff"), Color("#ef9fdc"),
]


static func draw(canvas: Node2D, biome: int, foe: Dictionary, feet: Vector2, height: float,
		clock: float, hit: float, visibility: float) -> void:
	var phase := int(foe.get("phase", Encounter.APPROACH))
	var move := str(foe.get("move", ""))
	var final_core := biome == 6 and int(foe.get("finale_step", 0)) > 0
	if final_core:
		draw_core_mantle(canvas, feet, height, clock, visibility, move == "petal_gates" and phase in [Encounter.WINDUP, Encounter.LUNGE])
	if phase == Encounter.APPROACH or move.is_empty():
		Art.garden_enemy(canvas, biome, 3, feet, height, clock, 0.0, hit, visibility)
		return

	var facing := Vector2(float(foe.get("dx", 1.0)), float(foe.get("dy", 0.0)))
	var side := -1.0 if facing.x < 0.0 else 1.0
	var time := Encounter.progress(foe) if phase != Encounter.RECOVERY else 0.0
	var impact := clampf(float(foe.get("impact", 0.0)) * 4.0, 0.0, 1.0)
	var tint := Color.WHITE.lerp(BOSS_TINTS[biome], time * 0.44 if phase == Encounter.WINDUP else impact * 0.35)
	if final_core:
		tint = tint.lerp(Color("#ffd394"), 0.24)
	tint = tint.lerp(Color(2.3, 1.9, 1.8), hit)
	tint.a = visibility
	if biome == 1:
		draw_majesty(canvas, foe, feet, height, side, time, tint)
		return

	var lean := 0.0
	var lift := 0.0
	var stretch := Vector2.ONE
	var step := 0.0
	match phase:
		Encounter.WINDUP:
			lean = -0.07 * time
			stretch = Vector2(1.0 + time * 0.09, 1.0 - time * 0.09)
			match move:
				"shears", "hand", "lash":
					lean *= 2.25
					step = -4.0 * time
				"bell", "steam", "gravity":
					stretch += Vector2(-0.19, 0.23) * time
					lift = 5.0 * time
				"rain", "petal_rain", "falling_stars", "constellation", "sequence":
					lift = 8.0 * smoothstep(0.0, 1.0, time)
					stretch += Vector2(-0.12, 0.16) * time
				"planets", "gears", "saucer_ring", "echo":
					lean = -0.09 * sin(time * TAU)
				"petal_gates":
					lean = sin(time * TAU) * 0.08
					lift = 10.0 * time
					stretch = Vector2(1.0 - 0.10 * time, 1.0 + 0.14 * time)
		Encounter.LUNGE:
			var crest := sin(time * PI)
			match move:
				"hand":
					lean = lerpf(-0.21, 0.26, time)
					step = -4.0 + 10.0 * time
				"bell", "steam", "gravity":
					lift = 5.0 * (1.0 - time)
					var pulse := sin(time * TAU * 2.0) * (1.0 - time)
					stretch += Vector2(0.14, -0.14) * pulse
				"petal_rain", "falling_stars", "constellation", "sequence":
					lift = 10.0 * crest
					stretch += Vector2(-0.04, 0.11) * crest
				"planets", "saucer_ring", "echo":
					lean = sin(time * TAU) * 0.14
					lift = 7.0 * crest
				"drain", "clone_cups":
					stretch += Vector2(0.11, -0.06) * crest
				"petal_gates":
					lift = 9.0 * crest
					lean = 0.14 * sin(time * TAU * 2.0)
					stretch = Vector2(1.13 - 0.12 * crest, 0.9 + 0.12 * crest)
				_:
					lean = 0.09 * crest
		Encounter.RECOVERY:
			lean = impact * (0.20 if move in ["shears", "lash", "hot_tea"] else 0.06)
			step = impact * (6.0 if move in ["shears", "lash", "hot_tea"] else 1.0)
			stretch = Vector2(1.0 + impact * 0.09, 1.0 - impact * 0.12)
	if biome in [5, 6]:
		lift += 3.0 + sin(clock * 3.2) * 2.0
	Art.paint_actor(canvas, Art.ENEMY_ATLASES[biome], Art.ENEMY_REGIONS[biome][3],
		feet + Vector2(side * step, -lift), height, side * lean, stretch, tint)


static func draw_core_mantle(canvas: Node2D, feet: Vector2, height: float, clock: float,
		visibility: float, charged: bool) -> void:
	var center := feet - Vector2(0.0, height * 0.53)
	var color := Color("#ffc181", visibility * (0.84 if charged else 0.58))
	var radius := height * (0.59 if charged else 0.53) + sin(clock * 4.0) * 2.0
	for index in range(5):
		var angle := clock * (2.15 if charged else 0.95) + index * TAU / 5.0
		canvas.draw_arc(center, radius, angle, angle + 0.72, 14, color, 2.2 if charged else 1.35, true)
		var axis := Vector2.from_angle(angle + 0.84)
		var position := center + axis * (radius + 4.0)
		var petal := axis.orthogonal() * 5.5
		canvas.draw_colored_polygon(PackedVector2Array([position - petal, position + axis * 4.0,
			position + petal, position - axis * 3.0]), color)


static func majesty_frame(foe: Dictionary) -> int:
	var move := str(foe.get("move", ""))
	var phase := int(foe.get("phase", Encounter.APPROACH))
	match phase:
		Encounter.WINDUP:
			return MAJESTY_WARN
		Encounter.LUNGE:
			var progress := Encounter.progress(foe)
			match move:
				"cyclone":
					return MAJESTY_STRIKE
				"crown":
					return MAJESTY_STRIKE if progress < 0.23 else MAJESTY_RECOVER
				"mines":
					return MAJESTY_STRIKE if progress >= 0.63 else MAJESTY_WARN
		Encounter.RECOVERY:
			return MAJESTY_STRIKE if move == "cross" and float(foe.get("impact", 0.0)) > 0.08 else MAJESTY_RECOVER
	return -1


static func draw_majesty(canvas: Node2D, foe: Dictionary, feet: Vector2, height: float,
		side: float, time: float, tint: Color) -> void:
	var frame := majesty_frame(foe)
	if frame == -1:
		Art.garden_enemy(canvas, 1, 3, feet, height, 0.0, 0.0, 0.0, tint.a)
		return
	var width_scale := 1.0
	var height_scale := 1.0
	var lean := 0.0
	var foot_shift := Vector2.ZERO
	match frame:
		MAJESTY_WARN:
			height_scale = 1.0 - 0.08 * time
			width_scale = 1.0 + 0.09 * time
			lean = -0.09 * time
			foot_shift.x = -3.0 * time
		MAJESTY_STRIKE:
			var cyclone := str(foe.move) == "cyclone"
			var force := sin(time * PI) if cyclone else 1.0
			lean = 0.09 + 0.13 * force
			if cyclone:
				lean += sin(time * TAU * 2.0) * 0.16
			foot_shift = Vector2(4.0 + 4.0 * force, -3.0 * force)
		MAJESTY_RECOVER:
			height_scale = lerpf(0.81, 1.0, 1.0 - clampf(float(foe.clock) * 1.1, 0.0, 1.0))
			width_scale = 1.0 + (1.0 - height_scale) * 0.45
			lean = 0.05
	var region: Rect2 = MAJESTY_POSES[frame]
	var ratio := height / region.size.y
	var anchor := float(MAJESTY_FEET[frame])
	canvas.draw_set_transform((feet + Vector2(foot_shift.x * side, foot_shift.y)).round(),
		lean * side, Vector2(side * width_scale, height_scale))
	canvas.draw_texture_rect_region(MAJESTY, Rect2(-anchor * ratio, -height, region.size.x * ratio, height), region, tint)
	canvas.draw_set_transform(Vector2.ZERO)
