extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const View = preload("res://scripts/garden_view.gd")

const DURATION := 1.48
const LANDING := 0.67
const TINTS := [Color("#dec48a"), Color("#efaa86"), Color("#eabb72"),
	Color("#ee8fa9"), Color("#ddc3f8"), Color("#9adbfa"), Color("#e7a6f4")]
const MATERIALS := ["bark", "crown", "gear", "petal", "porcelain", "star", "crystal"]
const FALL_CUES := ["boss_bark", "boss_crown", "boss_gear", "boss_bark",
	"boss_porcelain", "boss_star", "boss_star"]

var left := 0.0
var spot := Vector2.ZERO
var facing := 1.0


func reset() -> void:
	left = 0.0


func begin(position: Vector2, side: float) -> void:
	spot = position
	facing = 1.0 if side > 0.0 else -1.0
	left = DURATION


func tick(game, delta: float) -> void:
	var before := left
	left = maxf(0.0, left - delta)
	if before > DURATION - LANDING and left <= DURATION - LANDING:
		game.sound.play(FALL_CUES[game.active_biome])
		game.sound.play("boss_triumph")


func snapshot() -> Dictionary:
	return {"left": left, "x": spot.x, "y": spot.y, "facing": facing} if left > 0.0 else {}


func restore(data: Variant) -> void:
	reset()
	if data is Dictionary:
		left = clampf(float(data.get("left", 0.0)), 0.0, DURATION)
		spot = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
		facing = -1.0 if float(data.get("facing", 1.0)) < 0.0 else 1.0


func draw_actor(canvas: Node2D, biome: int) -> void:
	var time := DURATION - left
	var cast_tint: Color = TINTS[biome]
	var feet := spot + Vector2(0, 13)
	var recoil := smoothstep(0.04, 0.26, time)
	var fall := smoothstep(0.35, LANDING, time)
	var fade := 1.0 - smoothstep(0.71, 1.32, time)
	var scale := Vector2(1.0 + fall * 0.16, 1.0 - fall * 0.42)
	var lean := facing * (-0.17 * recoil + 1.15 * fall)
	var motion := Vector2(facing * (fall * 26.0 - recoil * 9.0), -sin(recoil * PI) * 12.0)
	match biome:
		1:
			# Majesty rocks back, tumbles forward, and loses the crown in the bounce.
			motion.y -= 15.0 * sin(fall * PI)
			lean += facing * fall * 0.30
		2:
			# The Bell seizes and drops in short mechanical slips.
			lean = facing * (sin(time * 52.0) * 0.06 * (1.0 - fall) + 0.76 * fall)
			motion.y = -floorf((1.0 - fall) * 4.0) * 2.0
		3:
			lean = facing * 0.84 * fall
			scale.y = lerpf(1.0, 0.40, fall)
		4:
			# A porcelain statue holds upright for a moment before toppling.
			lean = facing * smoothstep(0.44, LANDING, time) * 1.42
			motion.y = 0.0
		5:
			motion = Vector2(facing * fall * 9.0, -42.0 * fall)
			lean = facing * 0.36 * fall
			scale = Vector2.ONE * lerpf(1.0, 0.57, fall)
		6:
			motion.y = -23.0 * sin(fall * PI)
			lean = facing * fall * 0.38
			scale.y = lerpf(1.0, 0.53, fall)
	var tint := Color.WHITE.lerp(Color(2.08, 1.67, 1.44), 1.0 - smoothstep(0.02, 0.18, time))
	tint.a = fade
	if fade > 0.0:
		Art.shadow(canvas, feet + Vector2(motion.x, 0), 24.0 * fade)
		Art.paint_actor(canvas, Art.ENEMY_ATLASES[biome], Art.ENEMY_REGIONS[biome][3],
			feet + motion, 86.0, lean, scale, tint)

	var scatter := clampf((time - 0.48) / 0.91, 0.0, 1.0)
	if scatter <= 0.0 or scatter >= 1.0:
		return
	var spread := ease(scatter, 0.48)
	var opacity := 1.0 - smoothstep(0.32, 1.0, scatter)
	for i in range(13):
		var angle := i * 2.39996
		var ray := Vector2.from_angle(angle)
		var point := (feet + Vector2(0, -16) + ray * Vector2(1.0, 0.32)
			* (12.0 + (30.0 + float(i % 5) * 12.0) * spread)
			- Vector2(0.0, (sin(scatter * PI) * 42.0 + 13.0) * (0.6 + float(i % 4) * 0.17))).round()
		shard(canvas, point, angle + spread * 5.0, 2.4 + float(i % 4), cast_tint, opacity, MATERIALS[biome])
	if biome == 1:
		var spin := (time - 0.48) * TAU * 1.45
		var crown := (feet + Vector2(facing * spread * 46.0, -31.0 - sin(scatter * PI) * 63.0)).round()
		shard(canvas, crown, spin, 8.0, Color("#ffd477"), opacity, "crown")


func draw_stamp(canvas: Node2D, biome: int) -> void:
	var time := DURATION - left
	var opacity := smoothstep(0.53, 0.75, time) * (1.0 - smoothstep(1.19, DURATION, time))
	if opacity <= 0.0:
		return
	var y := roundf(96.0 - (1.0 - opacity) * 9.0)
	var accent := Color(TINTS[biome], opacity)
	var box := Rect2(318, y - 15, 228, 31)
	View.frame(canvas, box, Color("#201628", opacity * 0.93), Color(accent, opacity * 0.81))
	View.centered(canvas, box, "Boss Felled", 20, Color(View.CREAM, opacity), true)
	for x in [321.0, 543.0]:
		View.diamond(canvas, Vector2(x, y), 4.0, accent)
		var side := -1.0 if x < 400.0 else 1.0
		var trail := Vector2(x + side * 13.0, y + 2.0)
		View.sprig(canvas, trail, Vector2(side, -1.0), Color(accent, opacity * 0.74))
		for i in range(4):
			var rise := clampf((time - 0.56 - i * 0.08) / 0.77, 0.0, 1.0)
			var petal := (trail + Vector2(side * (i * 10.0 + rise * 25.0), -rise * 30.0 + sin(rise * 6.0 + i) * 5.0)).round()
			View.diamond(canvas, petal, 1.5 + 1.2 * sin(rise * PI), Color("#ffe4b1", opacity * sin(rise * PI)))


static func shard(canvas: Node2D, position: Vector2, angle: float, size: float,
		tint: Color, opacity: float, material: String) -> void:
	canvas.draw_set_transform(position, angle, Vector2.ONE * size)
	var silhouette := PackedVector2Array()
	match material:
		"bark":
			silhouette = PackedVector2Array([Vector2(-1.1, -0.76), Vector2(0.28, -0.92),
				Vector2(1.25, 0.25), Vector2(0.26, 0.43), Vector2(-0.45, 0.78)])
		"crown":
			silhouette = PackedVector2Array([Vector2(-1.0, -0.6), Vector2(-0.50, -0.10),
				Vector2(0, -0.92), Vector2(0.50, -0.10), Vector2(1.0, -0.6),
				Vector2(0.65, 0.60), Vector2(-0.65, 0.60)])
		"gear", "star":
			for index in range(16):
				var reach := 1.16 if (index % 4 < 2 if material == "gear" else index % 4 == 0) else 0.52
				silhouette.append(Vector2.from_angle(index * TAU / 16.0) * reach)
		"petal":
			silhouette = PackedVector2Array([Vector2(-1.05, 0), Vector2(-0.28, -0.72),
				Vector2(0.65, -0.72), Vector2(1.18, 0), Vector2(0.30, 0.65), Vector2(-0.26, 0.52)])
		_:
			silhouette = PackedVector2Array([Vector2(-0.83, -0.41), Vector2(0.53, -0.92),
				Vector2(0.98, -0.10), Vector2(0.19, 1.2), Vector2(-0.18, 0.23)])
	canvas.draw_colored_polygon(silhouette, Color(tint, opacity))
	canvas.draw_line(Vector2(-0.35, -0.10), Vector2(0.27, -0.35),
		Color(tint.lightened(0.63), opacity), 0.24)
	canvas.draw_set_transform(Vector2.ZERO)
