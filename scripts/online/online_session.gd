extends Node

# Phone-hosted authoritative campaign state. Gameplay controllers consume the
# snapshots and send inputs through this node; no server simulates the fight.
signal campaign_changed(campaign_state: Dictionary)
signal frame_received(snapshot: Dictionary)
signal host_recovery_failed
signal party_wiped
signal enemy_defeated(foe: Dictionary)

const EnemySimulation = preload("res://scripts/online/enemy_simulation.gd")
const HeroSimulation = preload("res://scripts/online/hero_simulation.gd")
const Campaign = preload("res://scripts/online/campaign_state.gd")
const SNAPSHOT_INTERVAL := 0.08

var peer: Node
var campaign: RefCounted
var room: Dictionary = {}
var active_run := ""
var snapshot_timer := 0.0
var initial_party_pending: Dictionary = {}
var room_ack_after := 0.0
var local_sequence := 0
var host_waiting_snapshot := false
var heroes: Dictionary = {}
var enemies = EnemySimulation.new()
var last_actions: Dictionary = {}
var local_luna_known := false
var local_luna_unlocked := false
var ownership_retry := 0.0

func configure(connection: Node) -> void:
	peer = connection
	peer.room_changed.connect(_room_changed)
	peer.peer_joined.connect(_republish_for_peer)
	peer.replica.snapshot_received.connect(_snapshot_received)
	peer.replica.host_transfer_started.connect(_transfer_started)
	peer.replica.host_transfer_ready.connect(_transfer_ready)
	peer.replica.host_transfer_unavailable.connect(_transfer_unavailable)
	enemies.defeated.connect(_enemy_defeated)
	enemies.player_fell.connect(_player_fell)

func reset() -> void:
	for actor: Node in heroes.values():
		actor.queue_free()
	heroes.clear()
	last_actions.clear()
	campaign = null
	room.clear()
	active_run = ""
	snapshot_timer = 0.0
	initial_party_pending.clear()
	room_ack_after = 0.0
	local_sequence = 0
	host_waiting_snapshot = false
	local_luna_known = false
	local_luna_unlocked = false
	ownership_retry = 0.0

func now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0

func _room_changed(next_room: Dictionary) -> void:
	room = next_room
	if str(room.get("phase", "")) != "playing":
		return
	var run_id := str(room.get("runId", ""))
	if run_id.is_empty():
		return
	if active_run != run_id:
		active_run = run_id
		campaign = null
		# The replica can start recovery before this room signal arrives when
		# an app reopens as host. Never start a fresh run over that snapshot.
		host_waiting_snapshot = peer.replica.recovery_epoch >= 0
		local_sequence = 0
		if str(room.get("host", "")) == peer.player_id and not host_waiting_snapshot:
			var roster := {}
			for player: Dictionary in room.get("players", []):
				roster[str(player.id)] = {"hero": int(player.hero), "connected": bool(player.connected),
					"relic": str(player.get("relic", "")), "weapon": str(player.get("weapon", "")),
					"username": str(player.get("username", ""))}
			campaign = Campaign.new()
			campaign.begin(int(room.get("runSeed", 0)), roster)
			campaign.run_id = active_run
			for id: String in roster:
				if id != peer.player_id and roster[id].connected:
					initial_party_pending[id] = true
			_sync_connections()
			_create_heroes()
			enemies.reset(campaign)
			_publish()
	elif is_host() and campaign != null:
		_sync_connections()
		_send_luna_ownership()

func is_host() -> bool:
	return peer != null and not peer.player_id.is_empty() and str(room.get("host", "")) == peer.player_id

func host_local_position(fallback: Vector2) -> Vector2:
	if not is_host() or campaign == null or host_waiting_snapshot:
		return fallback
	var member: Dictionary = campaign.party.players.get(peer.player_id, {})
	return member.get("position", fallback)

func _physics_process(delta: float) -> void:
	if not is_host() or campaign == null or host_waiting_snapshot:
		return
	var now := now_seconds()
	campaign.party.tick(delta, now)
	for id: String in initial_party_pending.keys():
		if bool(campaign.party.players.get(id, {}).get("departed", true)):
			initial_party_pending.erase(id)
	# A party can lose its last living member through a disconnect timeout or
	# voluntary leave, not only a damage event. Spectators still need a result.
	if campaign.terminal.is_empty() and campaign.party.wipe():
		campaign.finish_online("defeat", heroes)
		_publish()
		party_wiped.emit()
	if initial_party_pending.is_empty() and not campaign.party.paused(now):
		var step := minf(delta, 0.05)
		var previous_room_serial: int = campaign.room_serial
		campaign.tick_room(heroes, 0.0)
		if campaign.room_serial != previous_room_serial:
			enemies.reset(campaign)
			previous_room_serial = campaign.room_serial
		_advance_heroes(step, now)
		enemies.advance(campaign, heroes, step)
		campaign.tick_room(heroes, step)
		if campaign.room_serial != previous_room_serial:
			enemies.reset(campaign)
		for actor: Node in heroes.values():
			actor.finish_frame(step)
		campaign.party.refresh_door_votes()
		if campaign.accept_unanimous_exit(now):
			enemies.reset(campaign)
	snapshot_timer += delta
	if snapshot_timer >= SNAPSHOT_INTERVAL:
		snapshot_timer = 0.0
		_publish()

func _sync_connections() -> void:
	if campaign == null:
		return
	var present := {}
	var now := now_seconds()
	for row: Dictionary in room.get("players", []):
		var id := str(row.id)
		present[id] = true
		if not campaign.party.players.has(id):
			continue
		var member: Dictionary = campaign.party.players[id]
		member.username = str(row.get("username", member.get("username", "")))
		if bool(row.connected) and not member.connected and not member.departed:
			campaign.party.reconnect_player(id, now)
		elif not bool(row.connected) and member.connected and not member.departed:
			campaign.motion.forget(id)
			# A reopened app starts a fresh input sequence. Do not reject its
			# actions using the sequence from its previous connection.
			last_actions.erase(id)
			campaign.party.disconnect_player(id, now)
	for id: String in campaign.party.players:
		if not present.has(id) and not campaign.party.players[id].departed:
			campaign.motion.forget(id)
			campaign.party.leave_player(id)

func _create_heroes(saved: Dictionary = {}, recovering := false) -> bool:
	for actor: Node in heroes.values():
		actor.queue_free()
	heroes.clear()
	for id: String in campaign.party.players:
		var member: Dictionary = campaign.party.players[id]
		if member.departed:
			continue
		var actor := HeroSimulation.new()
		add_child(actor)
		actor.setup(id, int(member.hero), campaign)
		if (recovering and not saved.has(id)) or (saved.has(id) and not actor.restore(saved[id], campaign)):
			actor.queue_free()
			host_waiting_snapshot = true
			host_recovery_failed.emit()
			return false
		heroes[id] = actor
	return true

func _advance_heroes(delta: float, now: float) -> void:
	for id: String in heroes:
		var member: Dictionary = campaign.party.players[id]
		if not member.alive or member.departed or not member.connected:
			continue
		var input: Dictionary = campaign.motion.controls.get(id, {})
		var direction := Vector2.ZERO
		if not input.is_empty() and now - float(input.received) <= campaign.motion.INPUT_TIMEOUT:
			direction = input.direction
		heroes[id].advance(campaign, delta, direction)
		if int(member.hp) <= 0 and member.alive:
			member.hp = 0
			member.alive = false
			member.door = ""
			campaign.motion.forget(id)
			_player_fell(id)

func _publish() -> void:
	if campaign == null:
		return
	var state: Dictionary = campaign.snapshot(now_seconds())
	var hero_states := {}
	for id: String in heroes:
		hero_states[id] = heroes[id].snapshot()
	var frame := {"run_id": active_run, "campaign": state, "heroes": hero_states,
		"party_starting": not initial_party_pending.is_empty()}
	if peer.replica.publish(frame):
		campaign_changed.emit(state)
		frame_received.emit(frame)

func _republish_for_peer(_remote: int) -> void:
	if is_host() and campaign != null and not host_waiting_snapshot:
		_publish.call_deferred()

@rpc("any_peer", "call_remote", "reliable")
func _acknowledge_initial_room(run_id: String, room_serial: int) -> void:
	if not is_host() or campaign == null or run_id != active_run or room_serial != int(campaign.room_serial):
		return
	var sender := multiplayer.get_remote_sender_id()
	for id: String in initial_party_pending.keys():
		if int(peer.replica.peer_ids.get(id, 0)) == sender:
			initial_party_pending.erase(id)
			_publish.call_deferred()
			return

func _snapshot_received(snapshot: Dictionary) -> void:
	if str(snapshot.get("run_id", "")) != active_run or not snapshot.get("campaign") is Dictionary:
		return
	if local_luna_known:
		var members: Dictionary = snapshot.campaign.get("party", {}).get("players", {})
		var own: Dictionary = members.get(peer.player_id, {})
		var now := now_seconds()
		if (not own.has("luna_unlocked") or bool(own.luna_unlocked) != local_luna_unlocked) and now >= ownership_retry:
			ownership_retry = now + 1.0
			_send_luna_ownership()
	campaign_changed.emit(snapshot.campaign)
	frame_received.emit(snapshot)
	if bool(snapshot.get("party_starting", false)) and now_seconds() >= room_ack_after:
		var host := int(peer.replica.peer_ids.get(str(room.get("host", "")), 0))
		var members: Dictionary = snapshot.campaign.get("party", {}).get("players", {})
		if not snapshot.get("heroes") is Dictionary:
			return
		if host > 1 and host in multiplayer.get_peers() and members.has(peer.player_id) and snapshot.heroes.has(peer.player_id):
			room_ack_after = now_seconds() + 0.5
			_acknowledge_initial_room.rpc_id(host, active_run, int(snapshot.campaign.get("room_serial", -1)))

# The host must use the buyer's profile ownership, not its own, for the
# merchant's Luna offer. This contains no credentials or profile data.
func set_luna_ownership(unlocked: bool) -> void:
	local_luna_known = true
	local_luna_unlocked = unlocked
	_send_luna_ownership()

func _send_luna_ownership() -> void:
	if not local_luna_known or peer == null:
		return
	if is_host():
		_accept_luna_ownership(peer.player_id, local_luna_unlocked)
	else:
		var remote := int(peer.replica.peer_ids.get(str(room.get("host", "")), 0))
		if remote > 1 and remote in multiplayer.get_peers():
			_luna_ownership_input.rpc_id(remote, local_luna_unlocked)

@rpc("any_peer", "call_remote", "reliable")
func _luna_ownership_input(unlocked: bool) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	for id: String in peer.replica.peer_ids:
		if int(peer.replica.peer_ids[id]) == sender:
			_accept_luna_ownership(id, unlocked)
			return

func _accept_luna_ownership(id: String, unlocked: bool) -> void:
	if campaign != null and campaign.party.players.has(id):
		var member: Dictionary = campaign.party.players[id]
		# A purchase receipt may be in flight while an older profile report
		# arrives. Once owned in this run, ownership cannot be rolled back.
		member.luna_unlocked = bool(member.get("luna_unlocked", false)) or unlocked

func _transfer_ready(snapshot: Dictionary, _epoch: int) -> void:
	if str(snapshot.get("run_id", "")) != active_run or not snapshot.get("campaign") is Dictionary:
		host_waiting_snapshot = true
		host_recovery_failed.emit()
		return
	var restored = Campaign.new()
	if not restored.restore(snapshot.campaign, now_seconds()):
		host_waiting_snapshot = true
		host_recovery_failed.emit()
		return
	campaign = restored
	if not _create_heroes(snapshot.get("heroes", {}), true):
		return
	enemies.reset(campaign)
	# Recovery now waits for other peers, so the room update has already
	# arrived. Apply its current connection roster before gameplay resumes.
	_sync_connections()
	host_waiting_snapshot = false

func _transfer_started(_epoch: int) -> void:
	host_waiting_snapshot = true

func _transfer_unavailable(_epoch: int) -> void:
	if not active_run.is_empty():
		host_waiting_snapshot = true
		host_recovery_failed.emit()

func move(direction: Vector2) -> void:
	if campaign == null and is_host():
		return
	if not direction.is_finite() or direction.length_squared() > 1.05:
		return
	local_sequence += 1
	if is_host():
		_accept_move(peer.player_id, direction, local_sequence)
	else:
		var remote := int(peer.replica.peer_ids.get(str(room.get("host", "")), 0))
		if remote > 1 and remote in multiplayer.get_peers():
			_move_input.rpc_id(remote, direction, local_sequence)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _move_input(direction: Vector2, sequence: int) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	for id: String in peer.replica.peer_ids:
		if int(peer.replica.peer_ids[id]) == sender:
			_accept_move(id, direction, sequence)
			return

func _accept_move(id: String, direction: Vector2, sequence: int) -> void:
	if campaign == null or not initial_party_pending.is_empty() or not campaign.party.players.has(id) or campaign.party.paused(now_seconds()):
		return
	var player: Dictionary = campaign.party.players[id]
	if not player.alive or not player.connected or player.departed:
		return
	campaign.motion.submit(id, direction, sequence, now_seconds())

# Called by the authoritative combat simulation after all defenses resolve.
func apply_player_damage(player_id: String, damage: int) -> bool:
	if not is_host() or campaign == null or damage <= 0 or not campaign.party.players.has(player_id):
		return false
	var member: Dictionary = campaign.party.players[player_id]
	if not member.alive or member.departed or not member.connected:
		return false
	member.hp = maxi(0, int(member.hp) - damage)
	if member.hp == 0:
		member.alive = false
		member.door = ""
		campaign.motion.forget(player_id)
		_player_fell(player_id)
	_publish()
	return true

func request_revive(target_id: String) -> void:
	if is_host():
		_accept_revive(peer.player_id, target_id)
	else:
		var host_id := int(peer.replica.peer_ids.get(str(room.get("host", "")), 0))
		if host_id > 1 and host_id in multiplayer.get_peers():
			_revive_input.rpc_id(host_id, target_id)

@rpc("any_peer", "call_remote", "reliable")
func _revive_input(target_id: String) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	for id: String in peer.replica.peer_ids:
		if int(peer.replica.peer_ids[id]) == sender:
			_accept_revive(id, target_id)
			return

func _accept_revive(rescuer_id: String, target_id: String) -> bool:
	if campaign == null or not campaign.party.players.has(target_id) or campaign.party.paused(now_seconds()):
		return false
	var fallen: Dictionary = campaign.party.players[target_id]
	var max_health := int(fallen.get("build", {}).get("max_hp", campaign.party.HERO_HEALTH[int(fallen.hero)]))
	var cleared: bool = campaign.foes.is_empty() and campaign.room_phase in ["choices", "cleared"]
	if not campaign.party.revive(rescuer_id, target_id, max_health, cleared):
		return false
	if heroes.has(target_id):
		heroes[target_id].game.hp = int(fallen.hp)
		heroes[target_id].game.player = fallen.position
		if not bool(fallen.get("room_done", false)) and campaign.room_phase == "cleared":
			campaign.room_phase = "choices"
			campaign.party.room_cleared = false
	peer.send({"type": "life", "player": target_id, "alive": true})
	_publish()
	return true

# Inputs contain intent only; the host resolves damage, cooldowns and effects.
func action(action_name: String, charge := 0.0) -> void:
	if action_name not in ["attack", "dodge", "skill", "ultimate", "mode_0", "mode_1", "mode_2"] or not is_finite(charge):
		return
	local_sequence += 1
	if is_host():
		_accept_action(peer.player_id, action_name, charge, local_sequence)
	else:
		var host_id := int(peer.replica.peer_ids.get(str(room.get("host", "")), 0))
		if host_id > 1 and host_id in multiplayer.get_peers():
			_action_input.rpc_id(host_id, action_name, charge, local_sequence)

@rpc("any_peer", "call_remote", "reliable")
func _action_input(action_name: String, charge: float, sequence: int) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	for id: String in peer.replica.peer_ids:
		if int(peer.replica.peer_ids[id]) == sender:
			_accept_action(id, action_name, charge, sequence)
			return

func _accept_action(id: String, action_name: String, charge: float, sequence: int) -> void:
	if not initial_party_pending.is_empty():
		return
	if campaign == null or not heroes.has(id) or campaign.party.paused(now_seconds()) 			or action_name not in ["attack", "dodge", "skill", "ultimate", "mode_0", "mode_1", "mode_2"] 			or not is_finite(charge) or sequence <= int(last_actions.get(id, -1)):
		return
	var member: Dictionary = campaign.party.players[id]
	if not member.alive or member.departed or not member.connected:
		return
	last_actions[id] = sequence
	heroes[id].act(campaign, action_name, charge)

func _enemy_defeated(foe: Dictionary) -> void:
	enemy_defeated.emit(foe)

func _player_fell(player_id: String) -> void:
	if is_host():
		peer.send({"type": "life", "player": player_id, "alive": false})
	if campaign != null and campaign.party.wipe():
		campaign.finish_online("defeat", heroes)
		_publish()
		party_wiped.emit()

func interact() -> void:
	_send_room_input("interact", {})

func tap(point: Vector2) -> void:
	if point.is_finite():
		_send_room_input("tap", {"x": point.x, "y": point.y})

func use_pocket() -> void:
	_send_room_input("pocket", {})

func key(keycode: int) -> void:
	_send_room_input("key", {"key": keycode})

func _send_room_input(kind: String, payload: Dictionary) -> void:
	local_sequence += 1
	if is_host():
		_accept_room_input(peer.player_id, kind, payload, local_sequence)
	else:
		var host_id := int(peer.replica.peer_ids.get(str(room.get("host", "")), 0))
		if host_id > 1 and host_id in multiplayer.get_peers():
			_room_input.rpc_id(host_id, kind, payload, local_sequence)

@rpc("any_peer", "call_remote", "reliable")
func _room_input(kind: String, payload: Dictionary, sequence: int) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	for id: String in peer.replica.peer_ids:
		if int(peer.replica.peer_ids[id]) == sender:
			_accept_room_input(id, kind, payload, sequence)
			return

func _accept_room_input(id: String, kind: String, payload: Dictionary, sequence: int) -> void:
	if not initial_party_pending.is_empty():
		return
	if campaign == null or not heroes.has(id) or campaign.party.paused(now_seconds()) or sequence <= int(last_actions.get(id, -1)):
		return
	var member: Dictionary = campaign.party.players[id]
	if not member.alive or member.departed or not member.connected:
		return
	last_actions[id] = sequence
	var previous_room: int = campaign.room_serial
	match kind:
		"interact":
			campaign.interact_player(id, heroes)
		"tap":
			var point := Vector2(float(payload.get("x", -1)), float(payload.get("y", -1)))
			campaign.tap_player(id, heroes, point)
		"pocket":
			campaign.use_pocket_player(id, heroes)
		"key":
			campaign.key_player(id, heroes, int(payload.get("key", 0)))
		_:
			return
	if campaign.room_serial != previous_room:
		enemies.reset(campaign)
	_publish()

func acknowledge_award(award_id: String) -> void:
	if award_id.is_empty():
		return
	if is_host():
		_accept_award(peer.player_id, award_id)
	else:
		var host_id := int(peer.replica.peer_ids.get(str(room.get("host", "")), 0))
		if host_id > 1 and host_id in multiplayer.get_peers():
			_ack_award.rpc_id(host_id, award_id)

@rpc("any_peer", "call_remote", "reliable")
func _ack_award(award_id: String) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	for id: String in peer.replica.peer_ids:
		if int(peer.replica.peer_ids[id]) == sender:
			_accept_award(id, award_id)
			return

func _accept_award(id: String, award_id: String) -> void:
	if campaign != null and campaign.acknowledge_award(id, award_id):
		_publish()

func prepare_leave() -> void:
	if is_host():
		_accept_leave(peer.player_id)
	else:
		var host_id := int(peer.replica.peer_ids.get(str(room.get("host", "")), 0))
		if host_id > 1 and host_id in multiplayer.get_peers():
			_prepare_leave.rpc_id(host_id)

@rpc("any_peer", "call_remote", "reliable")
func _prepare_leave() -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	for id: String in peer.replica.peer_ids:
		if int(peer.replica.peer_ids[id]) == sender:
			_accept_leave(id)
			return

func _accept_leave(id: String) -> void:
	if campaign != null and campaign.finish_player(id, heroes):
		_publish()
