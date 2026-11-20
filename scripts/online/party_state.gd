extends RefCounted

const REJOIN_SECONDS := 60.0
const RESUME_COUNTDOWN := 3.0
const DOOR_RADIUS := 30.0
const HERO_HEALTH := [125, 80, 70, 95, 65, 145, 35, 72]

var players: Dictionary = {}
var room_health_multiplier := 1.0
var doors: Dictionary = {}
var room_cleared := false
var resume_left := 0.0

func configure(roster: Dictionary) -> void:
	players.clear()
	for id: String in roster:
		var entry: Dictionary = roster[id]
		players[id] = {
			"hero": int(entry.hero), "connected": bool(entry.connected), "departed": false,
			"username": str(entry.get("username", "")), "damage_dealt": 0,
			"alive": true, "hp": HERO_HEALTH[int(entry.hero)], "position": Vector2.ZERO, "door": "",
			"deadline": 0.0, "build": {}, "cooldowns": {}, "revives": 0,
			"starting_relic": str(entry.get("relic", "")), "starting_weapon": str(entry.get("weapon", "")),
		}
	start_room({})

func living_count() -> int:
	var count := 0
	for player: Dictionary in players.values():
		if player.alive and not player.departed:
			count += 1
	return count

func start_room(exits: Dictionary) -> void:
	doors = exits.duplicate(true)
	room_cleared = false
	room_health_multiplier = 1.2 * living_count()
	for player: Dictionary in players.values():
		player.door = ""

func scale_health(solo_health: int) -> int:
	return maxi(1, roundi(float(solo_health) * room_health_multiplier))

func paused(now: float) -> bool:
	for player: Dictionary in players.values():
		if player.alive and not player.connected and not player.departed and float(player.deadline) > now:
			return true
	return resume_left > 0.0

func tick(delta: float, now: float) -> Array[String]:
	var expired: Array[String] = []
	for id: String in players:
		var player: Dictionary = players[id]
		if not player.connected and not player.departed and float(player.deadline) > 0.0 and float(player.deadline) <= now:
			player.departed = true
			player.deadline = 0.0
			player.door = ""
			expired.append(id)
	if not any_waiting(now) and resume_left > 0.0:
		resume_left = maxf(0.0, resume_left - delta)
	return expired

func any_waiting(now: float) -> bool:
	for player: Dictionary in players.values():
		if player.alive and not player.connected and not player.departed and float(player.deadline) > now:
			return true
	return false

func disconnect_player(id: String, now: float) -> void:
	if not players.has(id):
		return
	var player: Dictionary = players[id]
	player.connected = false
	player.door = ""
	if player.alive and not player.departed:
		player.deadline = now + REJOIN_SECONDS
		resume_left = 0.0

func reconnect_player(id: String, now: float) -> bool:
	if not players.has(id):
		return false
	var player: Dictionary = players[id]
	if player.departed or player.connected:
		return false
	if player.alive and (float(player.deadline) <= 0.0 or float(player.deadline) <= now):
		return false
	player.connected = true
	player.deadline = 0.0
	if player.alive and not any_waiting(now):
		resume_left = RESUME_COUNTDOWN
	return true

func leave_player(id: String) -> void:
	if not players.has(id):
		return
	var player: Dictionary = players[id]
	player.connected = false
	player.departed = true
	player.deadline = 0.0
	player.door = ""

func update_position(id: String, point: Vector2) -> void:
	if not players.has(id) or not point.is_finite():
		return
	var player: Dictionary = players[id]
	if not player.alive or not player.connected or player.departed:
		return
	player.position = point
	player.door = ""
	if not room_cleared:
		return
	for door_id: String in doors:
		if point.distance_to(doors[door_id]) <= DOOR_RADIUS:
			player.door = door_id
			return

func refresh_door_votes() -> void:
	for id: String in players:
		var player: Dictionary = players[id]
		if player.alive and player.connected and not player.departed:
			update_position(id, player.position)
		else:
			player.door = ""

func unanimous_door() -> String:
	if not room_cleared or living_count() == 0:
		return ""
	var chosen := ""
	for player: Dictionary in players.values():
		if not player.alive or player.departed:
			continue
		if not player.connected or str(player.door).is_empty():
			return ""
		if chosen.is_empty():
			chosen = player.door
		elif chosen != player.door:
			return ""
	return chosen

func door_count(door: String) -> int:
	var count := 0
	for player: Dictionary in players.values():
		if player.alive and not player.departed and player.connected and player.door == door:
			count += 1
	return count

func revive(user: String, target: String, max_health: int, encounter_cleared := false) -> bool:
	if not (room_cleared or encounter_cleared) or not players.has(user) or not players.has(target) or user == target:
		return false
	var rescuer: Dictionary = players[user]
	var fallen: Dictionary = players[target]
	if not rescuer.alive or not rescuer.connected or rescuer.departed or int(rescuer.revives) < 1:
		return false
	if fallen.alive or not fallen.connected or fallen.departed or max_health <= 0:
		return false
	rescuer.revives -= 1
	fallen.alive = true
	fallen.hp = maxi(1, ceili(max_health * 0.4))
	fallen.position = rescuer.position
	fallen.door = ""
	return true

func wipe() -> bool:
	return living_count() == 0

# Deadlines are relative to the current host's clock. Serialize remaining time
# so a different phone can resume without inheriting that clock's epoch.
func snapshot(now: float) -> Dictionary:
	var members := players.duplicate(true)
	for player: Dictionary in members.values():
		player.rejoin_left = maxf(0.0, float(player.get("deadline", 0.0)) - now) if float(player.get("deadline", 0.0)) > 0.0 else 0.0
		player.erase("deadline")
	return {"players": members, "room_health_multiplier": room_health_multiplier,
		"doors": doors.duplicate(true), "room_cleared": room_cleared, "resume_left": resume_left}

func restore(data: Dictionary, now: float) -> bool:
	var saved_players: Variant = data.get("players")
	var saved_doors: Variant = data.get("doors")
	if not saved_players is Dictionary or saved_players.is_empty() or saved_players.size() > 5 or not saved_doors is Dictionary:
		return false
	var restored: Dictionary = saved_players.duplicate(true)
	for id: Variant in restored:
		var player: Variant = restored[id]
		if not id is String or not player is Dictionary or not player.has_all(["hero", "connected", "departed", "alive", "hp", "position"]):
			return false
		var hero := int(player.hero)
		if hero < 0 or hero >= HERO_HEALTH.size() or not player.position is Vector2 or not player.position.is_finite():
			return false
		var left := clampf(float(player.get("rejoin_left", 0.0)), 0.0, REJOIN_SECONDS)
		player.deadline = now + left if left > 0.0 else 0.0
		player.erase("rejoin_left")
	for point: Variant in saved_doors.values():
		if not point is Vector2 or not point.is_finite():
			return false
	var multiplier := float(data.get("room_health_multiplier", 0.0))
	if not is_finite(multiplier) or multiplier < 1.2 or multiplier > 6.0:
		return false
	players = restored
	doors = saved_doors.duplicate(true)
	room_health_multiplier = multiplier
	room_cleared = bool(data.get("room_cleared", false))
	resume_left = clampf(float(data.get("resume_left", 0.0)), 0.0, RESUME_COUNTDOWN)
	return true
