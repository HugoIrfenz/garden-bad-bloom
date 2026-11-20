extends RefCounted

const Roster = preload("res://scripts/guest_roster.gd")
const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Abilities = preload("res://scripts/hero_abilities.gd")
const Visuals = preload("res://scripts/hero_combat_visuals.gd")

const TEMPER_TIME := 22.0
const TEMPER_BONUS := 0.55
const RAGE_TIME := 2.0
const RAGE_COOLDOWN := 3.0
const RAGE_ATTACK_SPEED := 1.35
const RAGE_MOVE_SPEED := 1.28
const RAGE_COLOR := Color("#ffb185")
const SLAM_RADIUS := 76.0
const SWEEP_RADIUS := 68.0
const SPIN_RADIUS := 86.0
const PROP_CONTACT_MARGIN := 8.0
const SPIN_STUN_TIME := 5.0
const SPIN_DIZZY_TIME := 2.35
const SPIN_HEAL := 5
const MERCY_RADIUS := 40.0
const JUDGMENT_WINDOW := 10.0
const TRANCE_TIME := 5.0
const RAY_RANGE := 410.0
const JUDGMENT_BEAT := 0.14

var temper := 0.0
var next_slam := true
var mode := 0
var landed_modes := 0
var judgment_hits := 0
var judgment_left := 0.0
var combo_window := 0.0
var trance_left := 0.0
var stun_left := 0.0
var dizzy_left := 0.0
var rage_left := 0.0
var action_variant := 0
var action_until := 0.0
var traces: Array[Dictionary] = []

func reset(new_run := false) -> void:
	temper = 0.0
	next_slam = true
	landed_modes = 0
	judgment_hits = 0
	judgment_left = 0.0
	combo_window = 0.0
	trance_left = 0.0
	action_until = 0.0
	traces.clear()
	if new_run:
		mode = 0
		stun_left = 0.0
		dizzy_left = 0.0
		rage_left = 0.0

func snapshot() -> Dictionary:
	return {"temper": temper, "next_slam": next_slam, "mode": mode, "landed": landed_modes,
		"judgment_hits": judgment_hits, "judgment_left": judgment_left, "combo_window": combo_window,
		"trance_left": trance_left, "stun_left": stun_left, "dizzy_left": dizzy_left, "rage_left": rage_left}

func restore(state: Variant) -> void:
	reset(true)
	if not state is Dictionary:
		return
	temper = clampf(float(state.get("temper", 0.0)), 0.0, TEMPER_TIME)
	next_slam = bool(state.get("next_slam", true))
	mode = clampi(int(state.get("mode", 0)), 0, 2)
	landed_modes = int(state.get("landed", 0)) & 7
	judgment_hits = clampi(int(state.get("judgment_hits", 0)), 0, 5)
	judgment_left = clampf(float(state.get("judgment_left", 0.0)), 0.0, JUDGMENT_BEAT)
	combo_window = clampf(float(state.get("combo_window", 0.0)), 0.0, JUDGMENT_WINDOW)
	trance_left = clampf(float(state.get("trance_left", 0.0)), 0.0, TRANCE_TIME)
	stun_left = clampf(float(state.get("stun_left", 0.0)), 0.0, SPIN_STUN_TIME)
	dizzy_left = clampf(float(state.get("dizzy_left", 0.0)), 0.0, SPIN_DIZZY_TIME)
	rage_left = clampf(float(state.get("rage_left", 0.0)), 0.0, RAGE_TIME)
	if trance_left > 0.0:
		mode = 0

func set_mode(game, wanted: int) -> void:
	if wanted == mode or trance_left > 0.0:
		return
	mode = wanted
	action_variant = mode
	action_until = 0.24
	add_trace("stance", game.player, game.player, Roster.MODE_COLORS[mode], 29.0, 0.30)
	game.sound.play("whi", [1.14, 0.84, 1.22][mode])
	game.checkpoint.call_deferred()

func take_variant(hero: int) -> int:
	if hero == Roster.WHI:
		return mode
	var variant := 1 if next_slam else 0
	next_slam = not next_slam
	return variant

func damage_factor() -> float:
	return 1.0 + TEMPER_BONUS * temper / TEMPER_TIME

func cast_rage(game) -> void:
	if game.skill_time > 0.0 or rage_left > 0.0:
		return
	rage_left = RAGE_TIME
	game.skill_time = RAGE_COOLDOWN
	if game.attack_time > 0.0:
		game.attack_time /= RAGE_ATTACK_SPEED
	if game.relics.has_relic(game.Relics.BRASSWING_PIN):
		game.brasswing_pin_left = 2.0
	add_trace("rage", game.player, game.player, RAGE_COLOR, 57.0, 0.45)
	game.sound.play("mina", 0.79)
	game.checkpoint.call_deferred()

func basic(game, variant: int, effect: Dictionary, repeat: bool) -> void:
	action_variant = variant
	action_until = 0.26
	var weapon: String = game.armory.for_hero(game.hero)
	var seq := int(effect.weapon_attack)
	if int(game.hero) == Roster.MINA:
		var heavy := variant == 1
		game.sound.play("mina", 0.83 if heavy else 1.13)
		var center: Vector2 = game.player + game.facing * (23.0 if heavy else 12.0)
		var radius := (SLAM_RADIUS if heavy else SWEEP_RADIUS) + (12.0 if effect.wide_cone else 0.0)
		if game.talents.owns(game.RunTalents.WIDE_SWING):
			radius *= 1.15
		var hue := Color("#ffc2a6") if heavy else Color("#f685ae")
		add_trace("slam" if heavy else "sweep", center, center + game.facing, hue, radius, 0.36)
		for foe: Dictionary in game.foes:
			var point: Vector2 = game.target(foe)
			if point.distance_to(center) <= radius and not Geometry.blocked(game, game.player, point, 14.0):
				game.strike(foe, false, weapon, seq, 1.35 if heavy else 0.78, repeat)
		if heavy and not repeat:
			game.attack_time += 0.12 / RAGE_ATTACK_SPEED if rage_left > 0.0 else 0.12
		return

	var landed := false
	var origin: Vector2 = game.player
	var hue: Color = Roster.MODE_COLORS[variant]
	game.sound.play("whi", [1.06, 0.88, 1.25][variant])
	match variant:
		0:
			var foe := holy_target(game)
			if not foe.is_empty():
				var point: Vector2 = game.target(foe)
				game.attack_visual_facing = origin.direction_to(point)
				add_trace("holy", origin, point, hue, 21.0, 0.31)
				landed = hit_basic(game, foe, weapon, seq, 0.73 if trance_left > 0.0 else 1.0, repeat)
			else:
				add_trace("stance", origin, origin, hue, 24.0, 0.25)
		1:
			var radius := MERCY_RADIUS + (8.0 if effect.wide_cone else 0.0)
			add_trace("mercy", origin, origin, hue, radius, 0.37)
			for foe: Dictionary in game.foes:
				var point: Vector2 = game.target(foe)
				if point.distance_to(origin) <= radius and not Geometry.blocked(game, origin, point, 14.0):
					var power := 0.58 if game.talents.owns(game.RunTalents.GENTLE_LIGHT) else 0.46
					landed = hit_basic(game, foe, weapon, seq, power, repeat) or landed
			if landed and not repeat:
				game.hp += mini(1, game.healing_amount(1))
		2:
			var direction: Vector2 = game.assisted_direction(RAY_RANGE)
			game.attack_visual_facing = direction
			var endpoint := Geometry.clear_endpoint(game, origin, direction, RAY_RANGE, 13.0)
			var half_width := 17.0 if effect.pierce else 11.0
			add_trace("ray", origin, endpoint, hue, half_width, 0.26)
			for foe: Dictionary in game.foes:
				var point: Vector2 = game.target(foe)
				if Geometry.segment_gap(point, origin, endpoint) <= half_width and not Geometry.blocked(game, origin, point, 13.0):
					landed = hit_basic(game, foe, weapon, seq, 0.61, repeat) or landed
	if landed and trance_left <= 0.0:
		landed_modes |= 1 << variant
		if landed_modes == 7 and judgment_hits == 0:
			queue_judgment(game)

func queue_judgment(game) -> void:
	landed_modes = 0
	if not game.foes.any(func(foe): return int(foe.hp) > 0):
		return
	judgment_hits = 5
	judgment_left = 0.0
	if combo_window > 0.0:
		combo_window = 0.0
		game.ultimates.begin_cutin(Roster.WHI)
	else:
		combo_window = JUDGMENT_WINDOW
	game.checkpoint.call_deferred()

func begin_trance(game) -> void:
	trance_left = TRANCE_TIME
	combo_window = 0.0
	landed_modes = 0
	mode = 0
	game.attack_time = 0.0
	add_trace("stance", game.player, game.player, Color("#fff3c1"), 64.0, 0.68)
	game.sound.hero_ultimate(Roster.WHI)
	game.checkpoint.call_deferred()

static func hit_basic(game, foe: Dictionary, weapon: String, sequence: int, scale: float, repeat: bool) -> bool:
	var before := int(foe.hp)
	game.strike(foe, false, weapon, sequence, scale, repeat)
	return int(foe.hp) < before

static func holy_target(game) -> Dictionary:
	var best: Dictionary = {}
	var range_sq := INF
	var warded: bool = game.AstralCore.shield_lives(game) > 0 or game.OptionalBosses.chair_posts_active(game.foes)
	var drone: bool = game.foes.any(func(foe): return foe.get("brasswing_drone", false) and int(foe.hp) > 0)
	for foe: Dictionary in game.foes:
		if int(foe.hp) <= 0:
			continue
		if foe.boss and (warded or (drone and foe.get("optional_boss", "") == game.OptionalBosses.BRASSWING)):
			continue
		var distance: float = game.player.distance_squared_to(game.target(foe))
		if distance < range_sq:
			best = foe
			range_sq = distance
	return best

func tick(game, delta: float) -> void:
	action_until = maxf(0.0, action_until - delta)
	for index in range(traces.size() - 1, -1, -1):
		traces[index].left -= delta
		if float(traces[index].left) <= 0.0:
			traces.remove_at(index)
	var fighting: bool = game.room_arrival <= 0.0 and not game.foes.is_empty() and not game.room_complete and not game.pending_chest
	if int(game.hero) == Roster.MINA:
		stun_left = maxf(0.0, stun_left - delta)
		dizzy_left = maxf(0.0, dizzy_left - delta)
		if rage_left > 0.0:
			rage_left = maxf(0.0, rage_left - delta)
			if rage_left <= 0.0 and game.attack_time > 0.0:
				game.attack_time *= RAGE_ATTACK_SPEED
		if fighting:
			var pace := 1.34 if game.relics.has_relic(Roster.RELICS[0]) else 1.0
			temper = minf(TEMPER_TIME, temper + delta * pace)
		else:
			temper = 0.0
		return
	if int(game.hero) != Roster.WHI:
		return
	combo_window = maxf(0.0, combo_window - delta)
	trance_left = maxf(0.0, trance_left - delta)
	if judgment_hits == 0:
		return
	judgment_left -= delta
	while judgment_hits > 0 and judgment_left <= 0.0:
		var targets: Array = game.foes.filter(func(foe): return int(foe.hp) > 0)
		if targets.is_empty():
			judgment_hits = 0
			break
		var target: Dictionary = targets.pick_random()
		var power := 8 + int(game.bonus / 2.0)
		if game.relics.has_relic(Roster.RELICS[1]):
			power += 2
		var point: Vector2 = game.target(target)
		action_variant = 0 if trance_left > 0.0 else 2
		action_until = 0.20
		game.attack_visual_facing = game.player.direction_to(point)
		add_trace("judgment", game.player, point, Color("#fff5bf"), 20.0, 0.26)
		Abilities.hero_hit(game, target, power)
		game.sound.play("whi", 0.94 + (5 - judgment_hits) * 0.09)
		judgment_hits -= 1
		judgment_left += JUDGMENT_BEAT
	if judgment_hits == 0 and landed_modes == 7:
		queue_judgment(game)

func mina_movement(input: Vector2, clock: float) -> Vector2:
	if stun_left > 0.0:
		return Vector2.ZERO
	if dizzy_left > 0.0:
		return input.rotated(PI + sin(clock * 9.0) * 0.46) * 0.67
	return input

static func spin_radius(game) -> float:
	return SPIN_RADIUS * (1.15 if game.talents.owns(game.RunTalents.WIDE_SWING) else 1.0)

func spin_prop(game, player_before: Vector2) -> Vector2:
	var origin: Vector2 = game.player
	var start := player_before if player_before.is_finite() else origin
	var nearest := spin_radius(game) + PROP_CONTACT_MARGIN
	var contact := Vector2.INF
	for prop: Vector2 in game.barrels:
		var gap := Geometry.segment_gap(prop, start, origin)
		if gap <= nearest:
			nearest = gap
			contact = prop
	return contact

func stop_spin(game, prop: Vector2, dizzy: bool) -> void:
	action_until = 0.0
	if prop.is_finite():
		stun_left = SPIN_STUN_TIME
		dizzy_left = 0.0
		add_trace("bonk", prop, prop, Color("#ffc254"), 43.0, 0.53)
		game.sound.play("mina", 0.60)
		game.sound.play("boss_break", 1.18)
	elif dizzy:
		dizzy_left = SPIN_DIZZY_TIME
		game.sound.play("mina", 0.72)
	game.checkpoint.call_deferred()

func spin(game, beat: int) -> bool:
	action_variant = 2
	action_until = 0.29
	var origin: Vector2 = game.player
	var radius := spin_radius(game)
	add_trace("spin", origin, origin + Vector2.from_angle(beat * 1.85), Color("#ffc19a"), radius, 0.33)
	var connected := false
	for foe: Dictionary in game.foes:
		var point: Vector2 = game.target(foe)
		if int(foe.hp) > 0 and origin.distance_to(point) <= radius and not Geometry.blocked(game, origin, point, 14.0):
			if Abilities.hero_hit(game, foe, 6 + int(game.bonus / 3.0)):
				connected = true
				Abilities.stun_foe(foe, 0.12)
	game.sound.play("mina", 1.05 + 0.12 * (beat % 3))
	return connected

func recover_from_spin_hit(game) -> void:
	var amount: int = game.healing_amount(SPIN_HEAL)
	if amount <= 0:
		return
	game.hp += amount
	add_trace("spin_heal", game.player, Vector2(amount, 0), Color("#b9eaa0"), 34.0, 0.66)
	game.sound.play("reward", 1.12)
	game.checkpoint.call_deferred()

func add_trace(kind: String, from: Vector2, to: Vector2, hue: Color, radius: float, lifespan: float) -> void:
	traces.append({"kind": kind, "from": from, "to": to, "hue": hue, "radius": radius,
		"left": lifespan, "lifespan": lifespan})

func draw(game) -> void:
	var canvas: Node2D = game.world_canvas
	if int(game.hero) == Roster.WHI:
		var hue: Color = Roster.MODE_COLORS[mode]
		canvas.draw_arc(game.player + Vector2(0, 8), 17.0, 0.0, TAU, 32, Color(hue, 0.62), 1.6, true)
		if trance_left > 0.0:
			var halo: Vector2 = (game.player - Vector2(0, 35)).round()
			canvas.draw_arc(halo, 22.0, PI, TAU, 20, Color("#ffe5a0", 0.9), 2.0)
			for index in range(5):
				var twinkle := Vector2.from_angle(PI + index * PI / 4.0) * 25.0
				Visuals.spark(canvas, (halo + twinkle).round(), 4.0 + sin(game.visual_clock * 13.0 + index), Color("#fff4cf"))
		for pip in range(3):
			var turn := float(game.visual_clock) + float(pip) * TAU / 3.0
			var point: Vector2 = game.player + Vector2.from_angle(turn) * Vector2(21, 12)
			Visuals.spark(canvas, point.round(), 3.0, Color(Roster.MODE_COLORS[pip], 0.95 if landed_modes & (1 << pip) else 0.26))
	elif temper > 1.0:
		var fill := temper / TEMPER_TIME
		var ground: Vector2 = game.player + Vector2(0, 8)
		canvas.draw_arc(ground, 20.0, -PI * 0.5, -PI * 0.5 + TAU * fill, 32, Color("#f48d9f", 0.68), 2.0, true)
		for index in range(ceili(4.0 * fill)):
			var t := float(game.visual_clock) * 2.0 + index * 1.6
			Visuals.spark(canvas, (ground + Vector2.from_angle(t) * Vector2(23, 12)).round(), 2.5 + fill, Color("#ffc593", fill))
	if rage_left > 0.0:
		var center: Vector2 = (game.player + Vector2(0, 8)).round()
		var progress := rage_left / RAGE_TIME
		canvas.draw_arc(center, 29.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 35, RAGE_COLOR, 2.0)
		for index in range(4):
			var turn: float = index * TAU / 4.0 + game.visual_clock * 6.6
			var point := (center + Vector2.from_angle(turn) * Vector2(29.0, 16.0)).round()
			Visuals.spark(canvas, point, 5.0, RAGE_COLOR)
	if stun_left > 0.0 or dizzy_left > 0.0:
		var stunned := stun_left > 0.0
		var accent := Color("#ffe39a") if stunned else Color("#f4baff")
		var ground: Vector2 = (game.player + Vector2(0, 9)).round()
		var head: Vector2 = (game.player - Vector2(0, 38)).round()
		var fraction := stun_left / SPIN_STUN_TIME if stunned else dizzy_left / SPIN_DIZZY_TIME
		canvas.draw_arc(ground, 22.0, 0.0, TAU, 28, Color("#281b33", 0.76), 4.0)
		canvas.draw_arc(ground, 22.0, -PI * 0.5, -PI * 0.5 + TAU * fraction, 28, accent, 2.5)
		for index in range(4):
			var angle: float = game.visual_clock * 6.0 + index * TAU / 4.0
			var star := (head + Vector2.from_angle(angle) * Vector2(23, 6)).round()
			Visuals.spark(canvas, star, 6.0, accent)
		var row := Rect2(Vector2(head.x - 36.0, maxf(51.0, head.y - 25.0)), Vector2(72, 16))
		canvas.draw_rect(row, Color("#251a2f", 0.94))
		canvas.draw_rect(row, Color(accent, 0.68), false, 1.0)
		game.View.centered(canvas, row, "STUNNED" if stunned else "DIZZY", 10, accent, true)
	for trace: Dictionary in traces:
		var a: Vector2 = trace["from"]
		var b: Vector2 = trace["to"]
		var hue: Color = trace.hue
		var fade := clampf(float(trace.left) / float(trace.lifespan), 0.0, 1.0)
		var size: float = trace.radius
		var progress := 1.0 - fade
		match str(trace.kind):
			"ray":
				canvas.draw_line(a.round(), b.round(), Color(hue, fade * 0.36), size * 1.35, true)
				canvas.draw_line(a.round(), b.round(), Color("#fffbff", fade), 2.8, true)
				Visuals.spark(canvas, b.round(), 5.0 + 4.0 * fade, Color(hue, fade))
			"holy", "judgment":
				var launch := a - Vector2(0, 21)
				var crown := b - Vector2(0, 51.0 - progress * 17.0)
				canvas.draw_line(launch.round(), crown.round(), Color(hue, fade * 0.57), 2.3, true)
				canvas.draw_line(crown.round(), b.round(), Color(hue, fade), 4.5, true)
				Visuals.spark(canvas, b.round(), size * (0.63 + 0.37 * fade), Color(hue, fade))
			"bonk":
				Visuals.spark(canvas, a.round(), size * (0.18 + 0.28 * fade), Color("#fff2ad", fade))
				for index in range(7):
					var unit := Vector2.from_angle(float(index) * TAU / 7.0 + 0.22)
					var start := (a + unit * (8.0 + size * progress * 0.38)).round()
					var tip := (start + unit * (6.0 + 14.0 * fade)).round()
					canvas.draw_line(start, tip, Color(hue, fade), 3.0)
			"spin_heal":
				for index in range(5):
					var turn := float(index) * TAU / 5.0 + progress * 0.9
					var spark := (a + Vector2.from_angle(turn) * size - Vector2(0, progress * 21.0)).round()
					Visuals.spark(canvas, spark, 5.0 * fade, Color(hue, fade))
				var label := Rect2(a + Vector2(-24, -49 - 16.0 * progress), Vector2(48, 17))
				game.View.centered(canvas, label, "+%d HP" % int(b.x), 12, Color(hue, fade), true)
			"sweep", "spin":
				var turn := a.direction_to(b).angle() + progress * TAU
				canvas.draw_arc(a, size * (0.65 + progress * 0.35), turn, turn + PI * 1.33, 44, Color(hue, fade * 0.72), 6.0, true)
				canvas.draw_arc(a, size * (0.69 + progress * 0.35), turn + 0.15, turn + PI * 1.24, 44, Color("#fff0d8", fade), 1.8, true)
			_:
				canvas.draw_arc(a, size * (0.47 + progress * 0.53), 0.0, TAU, 44, Color(hue, fade), 3.0, true)
				for index in range(6):
					var angle := float(index) * TAU / 6.0 + progress * 0.42
					var point := (a + Vector2.from_angle(angle) * size * (0.46 + progress * 0.47)).round()
					Visuals.spark(canvas, point, 4.0 + 3.0 * fade, Color(hue, fade))
