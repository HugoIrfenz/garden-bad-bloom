extends RefCounted

const Catalog = preload("res://scripts/weapon_catalog.gd")
const Geometry = preload("res://scripts/forgotten_encounters.gd")
const SNAPSHOT_VERSION = 1
const ECHO_DELAY = 0.31
const WARD_DURATION = 3.0

var equipped := ""
var basic_sequence := 0
var last_thunder_attack := -1
var thunder_hits := 0
var next_palette_color := 0
var ward_used := false
var ward_time := 0.0
var echo: Dictionary = {}
var flourishes: Array[Dictionary] = []

func reset(hero: int, entry := "") -> void:
	equipped = entry if Catalog.usable_by(entry, hero) else Catalog.starter(hero)
	enter_room()

func enter_room() -> void:
	basic_sequence = 0
	thunder_hits = 0
	last_thunder_attack = -1
	next_palette_color = 0
	ward_used = false
	ward_time = 0.0
	echo.clear()
	flourishes.clear()

func for_hero(hero: int) -> String:
	return equipped if Catalog.usable_by(equipped, hero) else Catalog.starter(hero)

func equip(id: String, hero: int) -> bool:
	if id == for_hero(hero) or not Catalog.usable_by(id, hero):
		return false
	reset(hero, id)
	return true

func offer(hero: int, seed_value: int, offset := 0, exclusions: Array = []) -> String:
	var ids := Catalog.available(hero, for_hero(hero))
	for id in exclusions:
		ids.erase(id)
	if ids.is_empty():
		return ""
	return ids[posmod(posmod(seed_value, ids.size()) + offset, ids.size())]

func snapshot() -> Dictionary:
	return {"version": SNAPSHOT_VERSION, "equipped": equipped, "basic_sequence": basic_sequence,
		"last_thunder_attack": last_thunder_attack, "thunder_hits": thunder_hits, "next_palette_color": next_palette_color,
		"ward_used": ward_used, "ward_time": ward_time, "echo": echo.duplicate()}

func restore(hero: int, data: Variant) -> void:
	reset(hero)
	if not data is Dictionary or int(data.get("version", 0)) != SNAPSHOT_VERSION:
		return
	var id := str(data.get("equipped", ""))
	if Catalog.usable_by(id, hero):
		equipped = id
	basic_sequence = maxi(0, int(data.get("basic_sequence", 0)))
	last_thunder_attack = clampi(int(data.get("last_thunder_attack", -1)), -1, basic_sequence)
	thunder_hits = clampi(int(data.get("thunder_hits", 0)), 0, 2)
	next_palette_color = posmod(int(data.get("next_palette_color", 0)), 2)
	ward_used = bool(data.get("ward_used", false))
	ward_time = clampf(float(data.get("ward_time", 0.0)), 0.0, WARD_DURATION) if ward_used else 0.0
	var queued: Variant = data.get("echo")
	if equipped == "clockface_shank" and queued is Dictionary and queued.has_all(["x", "y", "dx", "dy", "left", "damage"]):
		echo = queued.duplicate()

func begin_attack(game, id: String) -> int:
	basic_sequence += 1
	if int(game.hero) == 2:
		game.abilities.note_orchid_input(game, basic_sequence)
	if id == "clockface_shank" and basic_sequence % 4 == 0:
		var origin: Vector2 = game.player
		var facing: Vector2 = game.facing
		var damage := clampi(int((Catalog.item(id).damage + game.bonus) * 0.70), 1, 500)
		echo = {"x": origin.x, "y": origin.y, "dx": facing.x, "dy": facing.y,
			"left": ECHO_DELAY, "damage": damage}
	return basic_sequence

func reduce_hit(amount: int) -> int:
	if ward_time <= 0.0 or amount < 2:
		return amount
	ward_time = 0.0
	return maxi(1, ceili(float(amount) * 0.60))

func after_hit(game, foe: Dictionary, id: String, hit_sequence: int, was_marked: bool) -> void:
	var center: Vector2 = game.target(foe)
	if int(game.hero) == 2:
		game.abilities.note_orchid_hit(game, foe, hit_sequence)
	match id:
		"royal_cleaver":
			if int(foe.hp) > 0:
				game.combat_status.apply_foe(foe, "guardbreak", 2.0, 1.0, id)
		"morning_promise":
			if not ward_used:
				ward_used = true
				ward_time = WARD_DURATION
		"black_margin":
			drawn_ink(game, center, id)
		"elegy_spiral":
			game.abilities.note_elegy_hit(game, center, hit_sequence)
		"pocket_thunder":
			thunder(game, foe, hit_sequence)
		"ribbon_string":
			if was_marked and int(foe.hp) > 0 and can_move(foe):
				var pull: Vector2 = center.direction_to(game.player) * minf(34.0, center.distance_to(game.player))
				move_target(game, foe, center, pull, true)
				add_trace("ribbon", center, game.target(foe), Color("#f5a9bd"))
		"palette_knives":
			var warm := next_palette_color == 0
			next_palette_color = 1 - next_palette_color
			if int(foe.hp) > 0:
				game.combat_status.apply_foe(foe, "burn" if warm else "chill", 2.1 if warm else 1.7, 1.0, id)
			add_trace("spark", center, center, Color("#f4a17d") if warm else Color("#88d9ed"))

func drawn_ink(game, center: Vector2, id: String) -> void:
	var forward: Vector2 = game.player.direction_to(center)
	if forward.is_zero_approx():
		forward = Vector2.RIGHT
	var perpendicular := forward.orthogonal()
	add_trace("ink", center - perpendicular * 29.0, center + perpendicular * 29.0, Color("#cf93d9"))
	for foe: Dictionary in game.foes:
		var point: Vector2 = game.target(foe)
		if Geometry.segment_gap(point, center - perpendicular * 29.0, center + perpendicular * 29.0) <= 13.0 \
				and not Geometry.blocked(game, center, point, 12.0):
			game.combat_status.apply_foe(foe, "bleed", 2.8, 1.0, id)

func thunder(game, hit: Dictionary, attack_id: int) -> void:
	if attack_id < 0 or attack_id == last_thunder_attack:
		return
	last_thunder_attack = attack_id
	thunder_hits = (thunder_hits + 1) % 3
	if thunder_hits != 0:
		return
	var center: Vector2 = game.target(hit)
	var nearest := 92.0
	var other: Dictionary = {}
	for foe: Dictionary in game.foes:
		if int(foe.hp) <= 0 or is_same(hit, foe):
			continue
		var point: Vector2 = game.target(foe)
		var distance := center.distance_to(point)
		if distance < nearest and not Geometry.blocked(game, center, point, 12.0):
			nearest = distance
			other = foe
	if not other.is_empty():
		second_hit(game, other, 4)
		add_trace("lightning", center, game.target(other), Color("#ffda96"))

func knockback(game, foe: Dictionary, distance: float, id: String) -> void:
	if not can_move(foe):
		return
	var start: Vector2 = game.target(foe)
	var far := id == "tiny_hammerfists"
	var length := 49.0 if far else distance
	var finish := move_target(game, foe, start, (start - game.player).normalized() * length, far)
	if not far or start.distance_squared_to(finish) < 10.0 * 10.0:
		return
	add_trace("ribbon", start, finish, Color("#f2bc89"))
	var closest: Dictionary = {}
	var nearest_distance := INF
	for other: Dictionary in game.foes:
		if is_same(other, foe) or int(other.hp) <= 0:
			continue
		var point: Vector2 = game.target(other)
		var offset := start.distance_squared_to(point)
		if Geometry.segment_gap(point, start, finish) <= 18.0 and offset < nearest_distance:
			nearest_distance = offset
			closest = other
	if not closest.is_empty():
		second_hit(game, closest, 4)

static func can_move(foe: Dictionary) -> bool:
	return not bool(foe.boss) and not bool(foe.get("flower_node", false)) and not bool(foe.get("web_anchor", false))

static func move_target(game, foe: Dictionary, start: Vector2, motion: Vector2, swept: bool) -> Vector2:
	var finish: Vector2 = Geometry.clear_endpoint(game, start, motion.normalized(), motion.length(), game.BARREL_CLEARANCE) \
		if swept else game.slide_with_cover(start, motion)
	foe.x = finish.x
	foe.y = finish.y
	return finish

static func second_hit(game, foe: Dictionary, amount: int) -> void:
	var damage: int = game.defend_foe(foe, game.player_hit_amount(amount))
	if damage <= 0:
		return
	foe.hp -= damage
	foe.flash = 0.14
	game.sound.play("hit")

func lunar_bloom(game, center: Vector2) -> void:
	for foe: Dictionary in game.foes:
		var point: Vector2 = game.target(foe)
		if int(foe.hp) > 0 and point.distance_squared_to(center) <= 43.0 * 43.0 \
				and not Geometry.blocked(game, center, point, 12.0):
			second_hit(game, foe, 12 + mini(12, int(game.bonus)))
	add_trace("bloom", center, center, Color("#c5dafa"))

func tick(game, delta: float) -> void:
	ward_time = maxf(0.0, ward_time - delta)
	for index in range(flourishes.size() - 1, -1, -1):
		flourishes[index].left -= delta
		if float(flourishes[index].left) <= 0.0:
			flourishes.remove_at(index)
	if echo.is_empty():
		return
	echo.left -= delta
	if float(echo.left) > 0.0:
		return
	var center := Vector2(echo.x, echo.y)
	var forward := Vector2(echo.dx, echo.dy).normalized()
	for foe: Dictionary in game.foes:
		var point: Vector2 = game.target(foe)
		var offset := point - center
		if int(foe.hp) > 0 and offset.length_squared() < 69.0 * 69.0 and (offset.is_zero_approx() or offset.normalized().dot(forward) > 0.15) \
				and not Geometry.blocked(game, center, point, 12.0):
			second_hit(game, foe, clampi(int(echo.damage), 1, 500))
	add_trace("echo", center, center + forward * 60.0, Color("#f9d7a1"))
	echo.clear()

func add_trace(style: String, from: Vector2, to: Vector2, color: Color) -> void:
	flourishes.append({"style": style, "from": from, "to": to, "color": color, "left": 0.28})

func draw(game) -> void:
	var canvas: Node2D = game.world_canvas
	if ward_time > 0.0:
		canvas.draw_arc(game.player, 21.0, -PI / 2.0, -PI / 2.0 + TAU * (ward_time / WARD_DURATION), 40, Color("#f9d694"), 2.0, true)
	if not echo.is_empty():
		canvas.draw_arc(Vector2(echo.x, echo.y), 16.0, 0.0, TAU, 24, Color("#d6b383"), 1.2, true)
	for trace: Dictionary in flourishes:
		var ratio := float(trace.left) / 0.28
		var center: Vector2 = trace.from
		var finish: Vector2 = trace.to
		var tint := Color(trace.color, ratio)
		match trace.style:
			"lightning", "ink", "ribbon":
				var axis := center.direction_to(finish)
				var offset := axis.orthogonal() * (6.0 if trace.style == "lightning" else 4.0)
				canvas.draw_polyline(PackedVector2Array([center.round(), (center.lerp(finish, 0.34) + offset).round(),
					(center.lerp(finish, 0.62) - offset).round(), finish.round()]), tint, 2.2, true)
			"bloom", "spark":
				var radius := (44.0 if trace.style == "bloom" else 17.0) * (1.0 - ratio * 0.62)
				canvas.draw_arc(center, radius, 0.0, TAU, 42, tint, 2.2, true)
				for index in range(6):
					game.View.diamond(canvas, (center + Vector2.from_angle(index * TAU / 6.0) * radius).round(), 2.8 * ratio, tint)
			"echo":
				var angle := center.angle_to_point(finish)
				canvas.draw_arc(center, lerpf(47.0, 68.0, 1.0 - ratio), angle - 1.08, angle + 1.08, 28, tint, 3.8, true)
