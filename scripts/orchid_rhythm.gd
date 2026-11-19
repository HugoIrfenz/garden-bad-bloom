extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const WEAPON = "orchid_overclock"
const PUNCH_CARD = "orchid_punch_card"
const METRONOME = "metronome_heart"
const BEAT_PERIOD = 0.44
const BEAT_TOLERANCE = 0.075
const CARD_GOAL = 8
const RHYTHM_GOAL = 3
const BURST_RADIUS = 29.0
const BURST_DAMAGE = 8
const BURST_FLASH = 0.30
const ORCHID = Color("#e6a4f1")
const GOLD = Color("#ffe2a4")

var room_depth := -1
var room_elapsed := 0.0
var card_hits := 0
var refund_ready := false
var streak := 0
var last_beat := -1
var overclock_ready := false
var pending: Dictionary = {}
var burst: Dictionary = {}


static func evolved(game) -> bool:
	var armory = game.get("armory")
	return int(game.hero) == 2 and armory != null and armory.for_hero(2) == WEAPON


static func relic_enabled(game, id: String) -> bool:
	if int(game.hero) != 2:
		return false
	var relics = game.get("relics")
	return (relics != null and relics.has_relic(id)) or evolved(game)


func reset() -> void:
	room_depth = -1
	room_elapsed = 0.0
	card_hits = 0
	refund_ready = false
	streak = 0
	last_beat = -1
	overclock_ready = false
	pending.clear()
	burst.clear()


func visit(depth: int) -> void:
	if depth == room_depth:
		return
	room_depth = depth
	room_elapsed = 0.0
	streak = 0
	last_beat = -1
	pending.clear()
	burst.clear()


func snapshot() -> Dictionary:
	return {"depth": room_depth, "elapsed": room_elapsed, "card_hits": card_hits, "refund": refund_ready,
		"streak": streak, "last_beat": last_beat, "overclock": overclock_ready,
		"pending": pending.duplicate(), "burst": burst.duplicate()}


func restore(saved: Variant) -> void:
	reset()
	if not saved is Dictionary:
		return
	room_depth = maxi(-1, int(saved.get("depth", -1)))
	var elapsed := float(saved.get("elapsed", 0.0))
	room_elapsed = maxf(0.0, elapsed) if is_finite(elapsed) else 0.0
	card_hits = clampi(int(saved.get("card_hits", 0)), 0, CARD_GOAL - 1)
	refund_ready = bool(saved.get("refund", false))
	streak = clampi(int(saved.get("streak", 0)), 0, RHYTHM_GOAL)
	last_beat = clampi(int(saved.get("last_beat", -1)), -1, roundi(room_elapsed / BEAT_PERIOD))
	overclock_ready = bool(saved.get("overclock", false))
	var strike: Variant = saved.get("pending")
	if strike is Dictionary and int(strike.get("sequence", 0)) > 0:
		pending = {"sequence": int(strike.sequence), "beat": int(strike.get("beat", -1)), "hit": bool(strike.get("hit", false))}
	var impact: Variant = saved.get("burst")
	if impact is Dictionary and impact.has_all(["x", "y", "left"]):
		var point := Vector2(float(impact.x), float(impact.y))
		var left := clampf(float(impact.left), 0.0, BURST_FLASH)
		if point.is_finite() and left > 0.0:
			burst = {"x": point.x, "y": point.y, "left": left}


func tick(game, delta: float) -> void:
	visit(int(game.depth))
	if game.room_arrival <= 0.0 and not game.foes.is_empty():
		room_elapsed += delta
	if streak > 0 and room_elapsed > float(last_beat + 1) * BEAT_PERIOD + BEAT_TOLERANCE:
		streak = 0
		last_beat = -1
	if not burst.is_empty():
		burst.left = float(burst.left) - delta
		if float(burst.left) <= 0.0:
			burst.clear()


func note_input(game, sequence: int) -> void:
	if not relic_enabled(game, PUNCH_CARD) and not relic_enabled(game, METRONOME):
		return
	visit(int(game.depth))
	var beat := roundi(room_elapsed / BEAT_PERIOD)
	var on_beat: bool = game.room_arrival <= 0.0 and absf(room_elapsed - float(beat) * BEAT_PERIOD) <= BEAT_TOLERANCE
	if not on_beat:
		beat = -1
		streak = 0
		last_beat = -1
	pending = {"sequence": sequence, "beat": beat, "hit": false}


func note_hit(game, foe: Dictionary, sequence: int, hit: Callable) -> bool:
	if pending.is_empty() or int(pending.sequence) != sequence or bool(pending.hit):
		return false
	pending.hit = true
	var changed := false
	if relic_enabled(game, PUNCH_CARD):
		card_hits += 1
		if card_hits == CARD_GOAL:
			card_hits = 0
			fire_burst(game, game.target(foe), hit)
			changed = true
	var beat := int(pending.beat)
	if beat >= 0 and relic_enabled(game, METRONOME):
		if not refund_ready:
			refund_ready = true
			changed = true
		if evolved(game) and not overclock_ready:
			streak = streak + 1 if beat == last_beat + 1 and streak > 0 else 1
			last_beat = beat
			if streak == RHYTHM_GOAL:
				overclock_ready = true
				changed = true
	return changed


func fire_burst(game, center: Vector2, hit: Callable) -> void:
	burst = {"x": center.x, "y": center.y, "left": BURST_FLASH}
	for foe: Dictionary in game.foes:
		var point: Vector2 = game.target(foe)
		if int(foe.hp) > 0 and center.distance_squared_to(point) <= BURST_RADIUS * BURST_RADIUS \
				and not Geometry.blocked(game, center, point, 12.0):
			hit.call(game, foe, BURST_DAMAGE)
	game.sound.play("nixia", 1.22)


func take_refund(game, spent: int) -> int:
	if spent <= 0 or not refund_ready or not relic_enabled(game, METRONOME):
		return 0
	refund_ready = false
	return 1


func take_overclock(game) -> bool:
	if not overclock_ready or not evolved(game):
		return false
	overclock_ready = false
	streak = 0
	last_beat = -1
	return true


func draw(game) -> void:
	var canvas: Node2D = game.world_canvas
	var center: Vector2 = game.player + Vector2(0.0, 10.0)
	if relic_enabled(game, METRONOME) and game.room_arrival <= 0.0 and not game.foes.is_empty():
		var phase := fposmod(room_elapsed, BEAT_PERIOD) / BEAT_PERIOD
		var distance := minf(phase, 1.0 - phase)
		var edge := BEAT_TOLERANCE / BEAT_PERIOD
		canvas.draw_arc(center, 21.0, -PI * 0.5, TAU * phase - PI * 0.5, 38, Color(ORCHID, 0.62), 1.5, true)
		if distance <= edge:
			var glow := lerpf(0.88, 0.60, distance / edge)
			canvas.draw_arc(center, 22.5, 0.0, TAU, 40, Color(GOLD, glow), 2.15, true)
		if refund_ready:
			var pip := center + Vector2(-22.0, 0.0)
			canvas.draw_colored_polygon(PackedVector2Array([pip + Vector2(0, -3), pip + Vector2(3, 0),
				pip + Vector2(0, 3), pip + Vector2(-3, 0)]), GOLD)
		if evolved(game):
			for pip in range(RHYTHM_GOAL):
				var point := center + Vector2(13.0 + 5.0 * pip, 9.0)
				var filled := overclock_ready or pip < streak
				canvas.draw_circle(point, 1.75, Color(GOLD, 0.95 if filled else 0.45), filled, 1.0, true)
	if relic_enabled(game, PUNCH_CARD) and card_hits > 0:
		canvas.draw_arc(center, 25.0, PI * 0.55, PI * 0.55 + PI * 0.78 * float(card_hits) / CARD_GOAL,
			24, Color("#ca81e4", 0.84), 2.0, true)
	if burst.is_empty():
		return
	var origin := Vector2(burst.x, burst.y)
	var alpha := float(burst.left) / BURST_FLASH
	var radius := lerpf(6.0, BURST_RADIUS, sqrt(1.0 - alpha))
	canvas.draw_arc(origin, radius, 0.0, TAU, 40, Color(ORCHID, alpha), 3.1, true)
	for petal in range(6):
		var direction := Vector2.from_angle(float(petal) * TAU / 6.0)
		canvas.draw_line(origin + direction * maxf(1.0, radius - 5.0), origin + direction * radius,
			Color(GOLD, alpha), 2.2, true)
