extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Abilities = preload("res://scripts/hero_abilities.gd")
const Relics = preload("res://scripts/relic_effects.gd")
const Visuals = preload("res://scripts/hero_combat_visuals.gd")

const SHOTS_REQUIRED := 8
const FRENZY_TIME := 4.8
const CHOKER_EXTENSION := Relics.WOLFBOUND_EXTRA_SECONDS
const FRENZY_SPEED_SCALE := 1.24
const HUMAN_DODGE_CD := 1.25
const HUMAN_DASH_TIME := 0.16
const HUMAN_DASH_DISTANCE := 83.0
const WOLF_DASH_TIME := 0.15
const WOLF_DASH_DISTANCE := 99.0
const WOLF_DASH_GRACE := 0.055
const WOLF_DASH_DAMAGE := 7
const WOLF_DASH_RADIUS := 25.0
const CLAW_INTERVAL := 0.26
const CLAW_DAMAGE := 16
const CLAW_REACH := 70.0
const MOON := Color("#f8c3dd")
const CRIMSON := Color("#ee6f9e")

var gauge := 0
var wolf_left := 0.0
var shot_cycle := 0
var dash_hits: Array[int] = []
var action_left := 0.0
var shifted_left := 0.0
var traces: Array[Dictionary] = []

func in_wolf() -> bool:
	return wolf_left > 0.0

func duration(game) -> float:
	return FRENZY_TIME + (CHOKER_EXTENSION if game.relics.has_relic(Relics.WOLFBOUND_CHOKER) else 0.0)

func reset(new_run := false) -> void:
	if new_run:
		gauge = 0
		shot_cycle = 0
	wolf_left = 0.0
	action_left = 0.0
	shifted_left = 0.0
	dash_hits.clear()
	traces.clear()

func snapshot() -> Dictionary:
	return {"gauge": gauge, "wolf_left": wolf_left, "shot_cycle": shot_cycle, "dash_hits": dash_hits.duplicate()}

func restore(saved: Variant) -> void:
	reset(true)
	if not saved is Dictionary:
		return
	gauge = clampi(int(saved.get("gauge", 0)), 0, SHOTS_REQUIRED)
	wolf_left = clampf(float(saved.get("wolf_left", 0.0)), 0.0, FRENZY_TIME + CHOKER_EXTENSION)
	shot_cycle = maxi(0, int(saved.get("shot_cycle", 0)))
	var saved_hits: Variant = saved.get("dash_hits", [])
	if saved_hits is Array and in_wolf():
		for value in saved_hits:
			dash_hits.append(int(value))

func can_transform(game) -> bool:
	return gauge >= SHOTS_REQUIRED and not in_wolf() and game.dash_remaining <= 0.0 		and game.lily_repeat.is_empty() and not game.ultimates.locks_movement()

func queue_transform(game) -> void:
	gauge = 0
	shot_cycle += 1
	game.ultimates.begin_cutin(game.hero)
	game.checkpoint.call_deferred()

func transform(game) -> void:
	wolf_left = duration(game)
	shifted_left = 0.53
	action_left = 0.0
	game.dodge_time = 0.0
	game.attack_time = 0.0
	if game.relics.has_relic(Relics.BRASSWING_PIN):
		game.brasswing_pin_left = 2.0
	var floor_index: int = game.floor_index if game.floor_index >= 0 else game.depth >> 2
	if game.relics.spend_sixth_seat(floor_index):
		game.hp += game.healing_amount(6)
	game.sound.play("luna_frenzy")
	game.checkpoint.call_deferred()

func tag_shot(bolt: Dictionary) -> void:
	bolt.luna_cycle = shot_cycle
	bolt.luna_x = bolt.x
	bolt.luna_y = bolt.y

func pistol_hit(game, bolt: Dictionary) -> void:
	if in_wolf() or bool(bolt.get("lily_repeat", false)) or bool(bolt.get("luna_counted", false)) 			or int(bolt.get("luna_cycle", -1)) != shot_cycle:
		return
	bolt.luna_counted = true
	if gauge >= SHOTS_REQUIRED:
		return
	gauge += 1
	if gauge == SHOTS_REQUIRED:
		game.sound.play("luna_frenzy", 1.27)
		game.checkpoint.call_deferred()

func shot_bonus(game, bolt: Dictionary, point: Vector2) -> int:
	if not game.relics.has_relic(Relics.MOONLIT_CARTRIDGE):
		return 0
	var origin := Vector2(bolt.get("luna_x", point.x), bolt.get("luna_y", point.y))
	return Relics.MOONLIT_SHOT_BONUS if origin.distance_to(point) >= Relics.MOONLIT_SHOT_DISTANCE else 0

func basic(game, wolf: bool, effect: Dictionary, repeat: bool) -> void:
	if wolf != in_wolf():
		return
	var origin: Vector2 = game.player
	var facing: Vector2 = game.facing
	action_left = 0.23 if wolf else 0.22
	if not wolf:
		game.fire_basic_shot(effect)
		var muzzle := origin + Vector2(-22.0 if facing.x < -0.08 else 22.0, -20.0)
		add_trace("muzzle", muzzle, facing, 0.18)
		game.sound.play("luna_pistol", 0.88 if repeat else 1.0)
		return
	add_trace("claw", origin, facing, 0.24)
	game.sound.play("luna_claw", 1.12 if repeat else 1.0)
	var reach := CLAW_REACH + (12.0 if effect.wide_cone else 0.0)
	var angle := 1.18 if effect.wide_cone or effect.pierce else 0.96
	game.ground_hazards.sever_melee(game, origin, facing, reach)
	for foe: Dictionary in game.foes:
		if Abilities.within_cone(game, foe, origin, facing, reach, angle):
			game.strike(foe, false, effect.weapon_id, int(effect.weapon_attack), 1.0, repeat, CLAW_DAMAGE)

func start_dash(game) -> void:
	var wolf := in_wolf()
	var span := WOLF_DASH_TIME if wolf else HUMAN_DASH_TIME
	var distance := WOLF_DASH_DISTANCE if wolf else HUMAN_DASH_DISTANCE
	var facing: Vector2 = game.facing
	var move: Vector2 = game.stick + Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if move.length_squared() > 0.04:
		facing = move.normalized()
	game.facing = facing
	game.dash_remaining = span
	game.dash_vector = facing * distance * game.ground_hazards.break_snare() / span
	game.dash_evaded = false
	game.dodge_time = game.dodge_cooldown()
	game.mercy = maxf(float(game.mercy), WOLF_DASH_GRACE if wolf else span + 0.025)
	game.talents.start_dodge()
	game.honest_eyes_ready = game.relics.has_relic(Relics.HONEST_EYES)
	if game.relics.has_relic(Relics.FEATHER_CROWN):
		game.feather_crown_left = 1.0
	dash_hits.clear()
	game.sound.play("luna_dodge", 0.82 if wolf else 1.08)

func sweep_dash(game, start: Vector2, finish: Vector2) -> void:
	if start.distance_squared_to(finish) < 0.25:
		return
	add_trace("dash", start, finish, 0.15)
	for foe: Dictionary in game.foes:
		if int(foe.hp) <= 0:
			continue
		var center: Vector2 = game.target(foe)
		if Geometry.segment_gap(center, start, finish) > WOLF_DASH_RADIUS + (8.0 if foe.boss else 0.0):
			continue
		var contact := Geometry2D.get_closest_point_to_segment(center, start, finish)
		if Geometry.blocked(game, contact, center, 12.0):
			continue
		var id: int = game.foe_target_id(foe)
		if id not in dash_hits:
			dash_hits.append(id)
			if Abilities.hero_hit(game, foe, WOLF_DASH_DAMAGE + int(game.bonus / 3.0)):
				add_trace("impact", center, finish - start, 0.20)
				game.sound.play("luna_impact")

func tick(game, delta: float) -> void:
	action_left = maxf(0.0, action_left - delta)
	shifted_left = maxf(0.0, shifted_left - delta)
	for index in range(traces.size() - 1, -1, -1):
		traces[index].left = float(traces[index].left) - delta
		if traces[index].left <= 0.0:
			traces.remove_at(index)
	if not in_wolf():
		return
	wolf_left = maxf(0.0, wolf_left - delta)
	if wolf_left <= 0.0:
		game.dash_remaining = 0.0
		game.dodge_time = maxf(float(game.dodge_time), 0.54)
		game.attack_time = maxf(float(game.attack_time), 0.20)
		action_left = 0.0
		shifted_left = 0.43
		game.sound.play("luna_frenzy", 0.73)
		game.checkpoint.call_deferred()

func add_trace(kind: String, start: Vector2, direction: Vector2, duration_left: float) -> void:
	traces.append({"kind": kind, "start": start.round(), "direction": direction, "left": duration_left, "duration": duration_left})

static func draw_projectile(canvas: Node2D, center: Vector2, direction: Vector2) -> void:
	var tip := (center + direction * 5.0).round()
	var tail := (center - direction * 17.0).round()
	canvas.draw_line(tail, tip, Color("#dc886d", 0.69), 3.0)
	canvas.draw_line((center - direction * 7.0).round(), tip, Color("#ffedcb"), 2.0)

func draw(game) -> void:
	var canvas: Node2D = game.world_canvas
	var center: Vector2 = game.player.round()
	if in_wolf():
		var fraction := wolf_left / duration(game)
		canvas.draw_arc(center + Vector2(0, 11), 28.0, -PI * 0.5, -PI * 0.5 + TAU * fraction, 36, CRIMSON, 2.0)
	if shifted_left > 0.0:
		var strength := shifted_left / 0.53
		var radius := 25.0 + (1.0 - strength) * 61.0
		for index in range(8):
			var point := (center + Vector2.from_angle(index * TAU / 8.0 + strength) * radius).round()
			Visuals.spark(canvas, point, 7.0 * strength, Color(MOON, strength))
	for trace: Dictionary in traces:
		var start: Vector2 = trace.start
		var direction: Vector2 = trace.direction
		var fade := clampf(float(trace.left) / float(trace.duration), 0.0, 1.0)
		match trace.kind:
			"muzzle":
				Visuals.spark(canvas, start, 4.0 + fade * 9.0, Color("#ffdb9c", fade))
				Visuals.spark(canvas, (start + direction * 8.0).round(), 5.0 * fade, Color("#fff5d4", fade))
			"claw":
				for index in range(3):
					var angle := direction.angle() - 0.85 + (1.0 - fade) * 0.54
					var pivot := (start + direction.orthogonal() * (index - 1) * 5.0).round()
					var radius := 42.0 + 8.0 * index + (1.0 - fade) * 12.0
					canvas.draw_arc(pivot, radius, angle, angle + 0.86, 19, Color(CRIMSON, fade * 0.76), 4.0)
					canvas.draw_arc(pivot, radius + 2.0, angle + 0.09, angle + 0.77, 17, Color(MOON, fade), 1.5)
			"dash":
				var gap := start.direction_to(direction)
				for index in range(2):
					var offset := (gap.orthogonal() * (7.0 if index == 0 else -7.0)).round()
					canvas.draw_line(start + offset, direction.round() + offset, Color(CRIMSON, fade * 0.72), 2.0)
			"impact":
				Visuals.spark(canvas, start, 8.0 + fade * 7.0, Color(MOON, fade))
