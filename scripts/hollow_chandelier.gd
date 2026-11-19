extends RefCounted

const Art = preload("res://scripts/garden_art.gd")
const Dungeon = preload("res://scripts/dungeon_generation.gd")
const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Abilities = preload("res://scripts/hero_abilities.gd")
const ATLAS = preload("res://assets/art/hollow_chandelier.png")
const ATLAS_LANTERN = Rect2(119, 63, 637, 749)
const ATLAS_DEBRIS = Rect2(1005, 340, 653, 430)
const TELL = 0.93
const FALL = 0.40
const SETTLE = 0.32
const RADIUS = 44.0
const TRIGGER = 72.0
const HERO_DAMAGE = 18
const HANG_HEIGHT = 60.0

static func place(room: Dictionary) -> Dictionary:
	var candidates := [Vector2(432, 202), Vector2(350, 198), Vector2(514, 194),
		Vector2(322, 237), Vector2(542, 231)]
	if int(room.encounter_seed) % 2 == 0:
		candidates.reverse()
	for center: Vector2 in candidates:
		if center.distance_to(room.entry) < TRIGGER + 14.0:
			continue
		if Dungeon.clear_of(center, room.cover, 50.0) and Dungeon.clear_of(center, room.spawns, 43.0) \
				and Dungeon.routes_reachable(room.cover + [center], room.exit_positions.values() + [room.reward]):
			return {"x": center.x, "y": center.y, "kind": "chandelier", "phase": 0,
				"left": 0.0, "contact": false}
	return {}

static func tick(game, patch: Dictionary, delta: float) -> void:
	var center: Vector2 = game.target(patch)
	if patch.phase == 0:
		if game.player.distance_squared_to(center) <= TRIGGER * TRIGGER:
			patch.phase = 1
			patch.left = TELL
			game.sound.play("warning", 0.84)
		return
	patch.left = maxf(0.0, float(patch.left) - delta)
	if patch.left > 0.0:
		return
	if patch.phase == 1:
		patch.phase = 2
		patch.left = FALL
		return
	if patch.phase == 2:
		land(game, patch, center)

static func land(game, patch: Dictionary, center: Vector2) -> void:
	patch.phase = 3
	patch.left = SETTLE
	patch.contact = true
	if game.player.distance_squared_to(center) <= RADIUS * RADIUS and not Geometry.blocked(game, center, game.player, 12.0):
		game.damage_hero(HERO_DAMAGE, center)
	for foe: Dictionary in game.foes:
		var target: Vector2 = game.target(foe)
		if target.distance_squared_to(center) <= RADIUS * RADIUS and not Geometry.blocked(game, center, target, 12.0):
			if Abilities.damage_foe(game, foe, 35):
				Abilities.stun_foe(foe, 0.36)
	game.sound.play("hit", 0.78)
	game.checkpoint.call_deferred()

static func draw(game, patch: Dictionary, center: Vector2) -> void:
	var canvas: Node2D = game.world_canvas
	var phase := int(patch.phase)
	var left := float(patch.left)
	var time: float = game.visual_clock
	if phase == 3 and patch.contact:
		draw_debris(canvas, center, left)
		return
	var warn := 1.0 - left / TELL if phase == 1 else (1.0 if phase == 2 else 0.0)
	var descent := 1.0 - left / FALL if phase == 2 else 0.0
	if warn > 0.0:
		Geometry.paint_circle(canvas, center, RADIUS, warn)
	var height := HANG_HEIGHT * (1.0 - descent * descent)
	var sway := sin(time * (12.0 if phase == 1 else 2.2)) * (2.0 + 5.0 * warn)
	var feet := (center + Vector2(sway * (1.0 - descent), -height)).round()
	Art.shadow(canvas, center, lerpf(16.0, 29.0, descent))
	if phase != 2:
		var top := Vector2(feet.x - sway, 42).round()
		canvas.draw_line(top, feet + Vector2(0, -54), Color("#b99073"), 1.2, true)
	draw_chandelier_sprite(canvas, feet, sway, warn)
	if phase == 2:
		for index in range(4):
			var end := feet + Vector2(-24 + 16 * index, -3)
			canvas.draw_line(end + Vector2(0, -12 - 20.0 * descent), end,
				Color("#f7bdad", descent * 0.62), 1.3, true)

static func draw_chandelier_sprite(canvas: Node2D, feet: Vector2, sway: float, warn: float) -> void:
	Art.paint_actor(canvas, ATLAS, ATLAS_LANTERN, feet, 57.0,
		sway * 0.025, Vector2.ONE, Color.WHITE.lerp(Color("#f2b49c"), warn * 0.55))

static func draw_debris(canvas: Node2D, center: Vector2, left: float) -> void:
	Art.paint_actor(canvas, ATLAS, ATLAS_DEBRIS, center + Vector2(0, 9), 27.0, 0.0, Vector2.ONE, Color.WHITE)
	if left <= 0.0:
		return
	var strength := clampf(left / SETTLE, 0.0, 1.0)
	var radius := lerpf(13.0, RADIUS, 1.0 - strength * strength)
	canvas.draw_arc(center, radius, 0.0, TAU, 40, Color("#ffe2b6", strength), 2.4, true)
	for index in range(8):
		var axis := Vector2.from_angle(index * TAU / 8.0 + 0.2)
		var point := center + axis * radius * (0.73 + (index % 2) * 0.14)
		canvas.draw_colored_polygon(PackedVector2Array([point + axis * 7, point + axis.orthogonal() * 2,
			point - axis * 4]), Color("#f5b9d6", strength))

