extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const Encounter = preload("res://scripts/forgotten_encounters.gd")
const Hound = preload("res://scripts/porcelain_hound.gd")


static func draw(canvas: Node2D, biome: int, kind: int, foe: Dictionary, feet: Vector2, height: float,
		clock: float, hit: float, visibility: float) -> void:
	var phase := int(foe.get("phase", Encounter.APPROACH))
	var move := str(foe.get("move", ""))
	if biome == 4 and kind == Hound.KIND:
		draw_hound(canvas, foe, feet, height, clock, hit, visibility)
		return
	if phase == Encounter.APPROACH or move.is_empty() or not foe.has("duration"):
		Art.garden_enemy(canvas, biome, kind, feet, height, clock, 0.0, hit, visibility)
		return

	var heading := Vector2(float(foe.get("dx", 1.0)), float(foe.get("dy", 0.0)))
	var side := -1.0 if heading.x < -0.10 else 1.0
	var wind := smoothstep(0.0, 1.0, Encounter.progress(foe)) if phase == Encounter.WINDUP else 0.0
	var active := Encounter.progress(foe) if phase == Encounter.LUNGE else 0.0
	var sustain := sin(PI * active)
	var settle := clampf(float(foe.clock) / 0.65, 0.0, 1.0) if phase == Encounter.RECOVERY else 0.0
	var impact := clampf(float(foe.get("impact", 0.0)) / 0.25, 0.0, 1.0) if phase == Encounter.RECOVERY else 0.0
	var lean := 0.0
	var scale := Vector2.ONE
	var recoil := 0.0
	var lift := 0.0
	var accent := Color("#ffc5a8")
	var mirror := 1.0
	match move:
		"lunge", "lance", "knife", "needle", "siphon", "antlers", "latch", "wish_dash":
			var armored := move == "lance"
			var charge := 0.64 + sustain * 0.36 if phase == Encounter.LUNGE else 0.0
			# A step back loads the spring. The silhouette then pitches in the same direction as the dash.
			lean = -wind * (0.19 if armored else 0.31) + charge * (0.51 if armored else 0.38) + settle * 0.12
			scale += Vector2(0.17, -0.23) * wind + Vector2(0.16, -0.07) * charge + Vector2(0.03, -0.12) * settle
			recoil = -wind * 6.0 + charge * 5.0
			if move in ["lunge", "knife", "lance"]:
				mirror = side
			if move == "needle":
				lift = 3.0 + sustain * 5.0
				accent = Color("#ffe6a1")
			elif move == "wish_dash":
				accent = Color("#c2b4ff")
		"peas", "petals", "curtain", "mote", "spokes", "glitch", "saucer", "reflection":
			# Raise the head before a shot, then kick it back at the release.
			var fire := maxf(impact, 1.0 - active * 3.0) if phase == Encounter.LUNGE else impact
			fire = clampf(fire, 0.0, 1.0)
			lean = wind * 0.15 - fire * 0.34 - settle * 0.04
			scale += Vector2(-0.11, 0.18) * wind + Vector2(0.17, -0.13) * fire
			recoil = 3.0 * wind - 6.0 * fire
			lift = sustain * 3.0
			accent = Color("#d5e897") if move == "peas" else Color("#e6b6ea")
			if move == "peas":
				mirror = side
		"slime":
			mirror = side
			lean = wind * 0.08
			scale += Vector2(-0.09, 0.27) * wind + Vector2(0.24, -0.34) * settle
			recoil = 3.0 * wind - 2.0 * settle
			accent = Color("#d8e884")
		"bomb":
			scale += Vector2(0.23, 0.28) * wind + Vector2(0.12, -0.52) * impact
			recoil = sin(clock * 41.0) * wind * 2.5
			lift = sin(wind * PI) * 3.0
			accent = Color("#ff91b8")
		"ward":
			# The butler lifts and fans the umbrella at the moment the ward is granted.
			scale += Vector2(-0.05, 0.14) * wind + Vector2(0.22, -0.13) * settle
			lean = wind * -0.14 + 0.19 * impact
			lift = 4.0 * wind
			accent = Color("#c5e3ab")
		"leap":
			scale += Vector2(0.25, -0.30) * wind + Vector2(-0.16, 0.19) * sustain + Vector2(0.16, -0.1) * settle
			lean = -0.09 * wind + lerpf(-0.16, 0.20, active) * sustain
			accent = Color("#d4b5f2")
		"pendulum", "duel":
			lean = -0.26 * wind + sin(TAU * active - 0.8) * sustain * 0.48 + settle * 0.12
			recoil = -4.0 * wind + sin(TAU * active) * sustain * 6.0
			scale += Vector2(0.08, -0.12) * wind + Vector2(-0.04, 0.11) * sustain
			accent = Color("#ffdba9")
		"thorn_web":
			scale += Vector2(0.15, 0.17) * wind + Vector2(0.15, -0.13) * sustain + Vector2(0.05, -0.10) * settle
			lift = wind * 5.0 + (1.0 - active) * sustain * 4.0
			lean = sin(active * TAU * 2.0) * sustain * 0.17
			accent = Color("#f8b7d9")
		"fracture":
			lift = wind * 5.0 + sustain * 9.0
			scale += Vector2(-0.12, 0.20) * (wind + sustain) - Vector2(0.05, 0.10) * settle
			lean = -0.12 * wind + sin(active * TAU) * sustain * 0.18
			accent = Color("#bb9cfc")

	var tint := Color.WHITE.lerp(accent, wind * (0.58 if move == "bomb" else 0.33) + impact * 0.17)
	tint = tint.lerp(Color(2.3, 1.9, 1.8), hit)
	tint.a = visibility
	var foot_position := feet + heading * recoil - Vector2(0, lift)
	scale.x *= mirror
	Art.paint_enemy(canvas, biome, kind, foot_position, height, lean * side, scale, tint)
	if move == "peas":
		pea_muzzle(canvas, Transform2D(lean * side, scale, 0.0, foot_position), height, wind, impact, visibility)


static func pea_muzzle(canvas: Node2D, body: Transform2D, height: float, wind: float, impact: float,
		visibility: float) -> void:
	var pressure := smoothstep(0.50, 1.0, wind)
	if pressure <= 0.0 and impact <= 0.0:
		return
	var nozzle := Vector2(0.39, -0.51) * height
	var tint := Color(0.88, 0.98, 0.58, visibility * maxf(pressure * 0.74, impact))
	canvas.draw_circle(body * nozzle, 1.7 + 2.2 * maxf(pressure, impact), tint, true, -1.0, true)
	if impact > 0.0:
		for offset: float in [-4.0, 0.0, 4.0]:
			canvas.draw_line(body * (nozzle + Vector2(2.0, offset * 0.5)),
				body * (nozzle + Vector2(8.0 + (1.0 - impact) * 3.0, offset)), tint, 1.2, true)


static func draw_hound(canvas: Node2D, foe: Dictionary, feet: Vector2, height: float,
		clock: float, hit: float, visibility: float) -> void:
	var phase := int(foe.phase)
	var side := -1.0 if float(foe.get("dx", 1.0)) < -0.10 else 1.0
	var tint := Color.WHITE.lerp(Color(2.3, 1.9, 1.8), hit)
	tint.a = visibility
	var pose := 0
	var lean := 0.0
	var lift := 0.0
	var scale := Vector2(side, 1.0)
	match phase:
		Encounter.APPROACH:
			lift = absf(sin(clock * 12.0)) * 2.8
		Encounter.WINDUP:
			pose = 1
			var wind := Encounter.progress(foe)
			scale.y = lerpf(0.94, 0.77, wind) + sin(wind * TAU * 3.0) * 0.026
			lean = wind * 0.08
		Encounter.LUNGE:
			pose = 2
			var bound := absf(sin(Encounter.progress(foe) * TAU))
			lift = 2.0 + 7.0 * bound
			scale.y = 0.86 + bound * 0.09
			lean = lerpf(0.16, -0.06, bound)
		Encounter.RECOVERY:
			var stumble := smoothstep(0.0, 0.8, float(foe.clock))
			pose = 1 if stumble > 0.35 else 0
			lean = 0.19 * stumble
			scale.y = lerpf(1.0, 0.72, stumble)
	Art.paint_hound(canvas, pose, feet - Vector2(0.0, lift), height * 0.90, lean * side, scale, tint)
