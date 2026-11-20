extends RefCounted

const BOUNDS := Rect2(31, 78, 802, 286)
const CLEARANCE := 26.0
const ACTOR_MARGIN := 16.0
const INPUT_TIMEOUT := 0.30
const SPEED := [143.0, 167.0, 302.0, 151.0, 175.0, 162.0, 166.0, 169.0]

var controls: Dictionary = {}

func clear() -> void:
	controls.clear()

func forget(id: String) -> void:
	controls.erase(id)

func submit(id: String, direction: Vector2, sequence: int, now: float) -> bool:
	if not direction.is_finite() or direction.length_squared() > 1.05 or sequence < 0:
		return false
	var previous: Dictionary = controls.get(id, {})
	if not previous.is_empty() and sequence <= int(previous.sequence):
		return false
	controls[id] = {"direction": direction.limit_length(), "sequence": sequence, "received": now}
	return true

func advance(campaign, delta: float, now: float) -> bool:
	var changed := false
	for id: String in campaign.party.players:
		var player: Dictionary = campaign.party.players[id]
		var input: Dictionary = controls.get(id, {})
		if input.is_empty() or not player.connected or not player.alive or player.departed:
			continue
		if now - float(input.received) > INPUT_TIMEOUT:
			controls.erase(id)
			continue
		var direction: Vector2 = input.direction
		if direction.length_squared() < 0.01:
			continue
		var origin: Vector2 = player.position
		var speed: float = SPEED[int(player.hero)]
		var moved := slide_with_cover(origin, direction * speed * delta, campaign.room.cover)
		if moved != origin:
			campaign.party.update_position(id, moved)
			player.facing = direction.normalized()
			changed = true
	return changed

static func slide_with_cover(start: Vector2, step: Vector2, cover: Array) -> Vector2:
	var moved := (start + step).clamp(BOUNDS.position + Vector2.ONE * ACTOR_MARGIN,
		BOUNDS.end - Vector2.ONE * ACTOR_MARGIN)
	for obstacle: Vector2 in cover:
		var offset := moved - obstacle
		if offset.length_squared() < CLEARANCE * CLEARANCE:
			var normal := offset.normalized() if not offset.is_zero_approx() else Vector2.UP
			moved = (obstacle + normal * CLEARANCE).clamp(BOUNDS.position + Vector2.ONE * ACTOR_MARGIN,
				BOUNDS.end - Vector2.ONE * ACTOR_MARGIN)
	return moved
