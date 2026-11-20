extends Node

# Distributes authoritative snapshots over the established peer mesh. The room
# service chooses a host; it does not run combat or hold private run state.
signal snapshot_received(snapshot: Dictionary)
signal host_transfer_started(epoch: int)
signal host_transfer_ready(snapshot: Dictionary, epoch: int)
signal host_transfer_unavailable(epoch: int)

const MAX_SNAPSHOT_BYTES := 1024 * 1024
const RECOVERY_WAIT_SECONDS := 3.0
const RECOVERY_RETRY_SECONDS := 0.35
const RECOVERY_FILE := "user://online_run_recovery.bin"
const RECOVERY_SAVE_INTERVAL := 1.0
var local_player_id := ""
var host_player_id := ""
var epoch := -1
var peer_ids: Dictionary = {}
var latest_snapshot: Dictionary = {}
var latest_epoch := -1
var latest_sequence := -1
var next_sequence := 0
var run_id := ""
var connected_ids: Dictionary = {}
var recovery_epoch := -1
var recovery_until := 0.0
var recovery_retry := 0.0
var recovery_expected: Dictionary = {}
var recovery_replied: Dictionary = {}
var recovery_best: Dictionary = {}
var recovery_best_epoch := -1
var recovery_best_sequence := -1
var last_recovery_save := 0.0
var recovery_allow_current_epoch := false

func clear() -> void:
	local_player_id = ""
	host_player_id = ""
	epoch = -1
	peer_ids.clear()
	connected_ids.clear()
	latest_snapshot.clear()
	latest_epoch = -1
	latest_sequence = -1
	next_sequence = 0
	run_id = ""
	last_recovery_save = 0.0
	recovery_epoch = -1
	recovery_expected.clear()
	recovery_replied.clear()
	recovery_best.clear()

func update_roster(room: Dictionary, own_id: String) -> void:
	var previous_host := host_player_id
	var previous_epoch := epoch
	local_player_id = own_id
	host_player_id = str(room.get("host", ""))
	epoch = int(room.get("epoch", -1))
	run_id = str(room.get("runId", ""))
	peer_ids.clear()
	connected_ids.clear()
	for player: Dictionary in room.get("players", []):
		var id := str(player.id)
		peer_ids[id] = int(player.get("peerId", 0))
		if bool(player.get("connected", false)):
			connected_ids[id] = true
	# A process can be killed while all friends are offline. Keep the most
	# recent shared state on each phone, but never use it for a different run.
	if previous_epoch < 0 and str(room.get("phase", "")) == "playing" and not run_id.is_empty():
		_load_recovery()
	if epoch != previous_epoch:
		next_sequence = 0
		recovery_epoch = -1
		if previous_epoch >= 0 and host_player_id == local_player_id and previous_host != local_player_id and str(room.get("phase", "")) == "playing":
			_begin_recovery()
		elif previous_epoch < 0 and host_player_id == local_player_id and str(room.get("phase", "")) == "playing":
			# This is a rejoin into an existing run, not a lobby starting a new one.
			_begin_recovery(true)
	elif recovery_epoch == epoch:
		_refresh_recovery_roster()

func _begin_recovery(allow_current_epoch := false) -> void:
	recovery_epoch = epoch
	recovery_allow_current_epoch = allow_current_epoch
	recovery_until = Time.get_ticks_msec() / 1000.0 + RECOVERY_WAIT_SECONDS
	recovery_retry = 0.0
	recovery_expected.clear()
	recovery_replied.clear()
	recovery_best.clear()
	recovery_best_epoch = -1
	recovery_best_sequence = -1
	_consider_recovery(latest_epoch, latest_sequence, latest_snapshot)
	_refresh_recovery_roster()
	host_transfer_started.emit(epoch)

func _refresh_recovery_roster() -> void:
	recovery_expected.clear()
	for id: String in connected_ids:
		if id != local_player_id:
			recovery_expected[id] = true

func _process(_delta: float) -> void:
	if recovery_epoch < 0 or recovery_epoch != epoch or host_player_id != local_player_id:
		return
	var now := Time.get_ticks_msec() / 1000.0
	var all_replied := true
	for id: String in recovery_expected:
		if not recovery_replied.has(id):
			all_replied = false
			break
	if (all_replied and not recovery_best.is_empty()) or now >= recovery_until:
		_finish_recovery()
		return
	if now < recovery_retry or multiplayer.multiplayer_peer == null:
		return
	recovery_retry = now + RECOVERY_RETRY_SECONDS
	for id: String in recovery_expected:
		var target := int(peer_ids.get(id, 0))
		if not recovery_replied.has(id) and target > 1 and target in multiplayer.get_peers():
			_request_recovery.rpc_id(target, recovery_epoch)

func _finish_recovery() -> void:
	var finished_epoch := recovery_epoch
	recovery_epoch = -1
	if recovery_best.is_empty():
		host_transfer_unavailable.emit(finished_epoch)
	else:
		# A reopened host can replace its stale socket without changing the
		# room epoch. Continue its old sequence so friends accept new frames.
		if recovery_best_epoch == finished_epoch:
			next_sequence = maxi(next_sequence, recovery_best_sequence)
		host_transfer_ready.emit(recovery_best.duplicate(true), finished_epoch)

func _consider_recovery(source_epoch: int, sequence: int, snapshot: Dictionary) -> void:
	if source_epoch < 0 or source_epoch > recovery_epoch or (source_epoch == recovery_epoch and not recovery_allow_current_epoch) or sequence < 1 or snapshot.is_empty():
		return
	if str(snapshot.get("run_id", "")) != run_id or not snapshot.get("campaign") is Dictionary or not snapshot.get("heroes") is Dictionary:
		return
	if var_to_bytes(snapshot).size() > MAX_SNAPSHOT_BYTES:
		return
	if source_epoch > recovery_best_epoch or (source_epoch == recovery_best_epoch and sequence > recovery_best_sequence):
		recovery_best = snapshot.duplicate(true)
		recovery_best_epoch = source_epoch
		recovery_best_sequence = sequence

@rpc("any_peer", "call_remote", "reliable")
func _request_recovery(request_epoch: int) -> void:
	if request_epoch != epoch or host_player_id.is_empty() or host_player_id == local_player_id:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not connected_ids.has(host_player_id) or sender != int(peer_ids.get(host_player_id, 0)):
		return
	var saved: Dictionary = latest_snapshot if str(latest_snapshot.get("run_id", "")) == run_id else {}
	_recovery_response.rpc_id(sender, request_epoch, latest_epoch, latest_sequence, saved)

@rpc("any_peer", "call_remote", "reliable")
func _recovery_response(request_epoch: int, source_epoch: int, sequence: int, snapshot: Dictionary) -> void:
	if request_epoch != recovery_epoch or request_epoch != epoch or host_player_id != local_player_id:
		return
	var sender := multiplayer.get_remote_sender_id()
	for id: String in recovery_expected:
		if int(peer_ids.get(id, 0)) == sender and connected_ids.has(id):
			recovery_replied[id] = true
			_consider_recovery(source_epoch, sequence, snapshot)
			return

func publish(snapshot: Dictionary) -> bool:
	if local_player_id.is_empty() or local_player_id != host_player_id or epoch < 0 or snapshot.is_empty():
		return false
	if var_to_bytes(snapshot).size() > MAX_SNAPSHOT_BYTES:
		return false
	next_sequence += 1
	latest_snapshot = snapshot.duplicate(true)
	latest_epoch = epoch
	latest_sequence = next_sequence
	_save_recovery()
	_receive_snapshot.rpc(epoch, next_sequence, snapshot)
	return true

@rpc("any_peer", "call_remote", "reliable")
func _receive_snapshot(snapshot_epoch: int, sequence: int, snapshot: Dictionary) -> void:
	if snapshot_epoch != epoch or sequence < 1 or host_player_id.is_empty():
		return
	if multiplayer.get_remote_sender_id() != int(peer_ids.get(host_player_id, 0)):
		return
	if snapshot_epoch < latest_epoch or (snapshot_epoch == latest_epoch and sequence <= latest_sequence):
		return
	if snapshot.is_empty() or var_to_bytes(snapshot).size() > MAX_SNAPSHOT_BYTES:
		return
	latest_snapshot = snapshot.duplicate(true)
	latest_epoch = snapshot_epoch
	latest_sequence = sequence
	_save_recovery()
	snapshot_received.emit(latest_snapshot.duplicate(true))

# A bounded atomic checkpoint lets a reopened host resume its own in-progress
# run even when every other participant has also temporarily disconnected.
func _save_recovery() -> void:
	if run_id.is_empty() or latest_snapshot.is_empty() or str(latest_snapshot.get("run_id", "")) != run_id:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if last_recovery_save > 0.0 and now - last_recovery_save < RECOVERY_SAVE_INTERVAL:
		return
	var encoded := var_to_bytes({"run_id": run_id, "epoch": latest_epoch,
		"sequence": latest_sequence, "snapshot": latest_snapshot})
	if encoded.size() > MAX_SNAPSHOT_BYTES + 2048:
		return
	var temporary := RECOVERY_FILE + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return
	file.store_buffer(encoded)
	file.close()
	if DirAccess.rename_absolute(temporary, RECOVERY_FILE) == OK:
		last_recovery_save = now

func _load_recovery() -> void:
	var file := FileAccess.open(RECOVERY_FILE, FileAccess.READ)
	if file == null or file.get_length() > MAX_SNAPSHOT_BYTES + 2048:
		return
	var saved: Variant = bytes_to_var(file.get_buffer(file.get_length()))
	if not saved is Dictionary or str(saved.get("run_id", "")) != run_id:
		return
	var state: Variant = saved.get("snapshot")
	if not state is Dictionary or str(state.get("run_id", "")) != run_id or not state.get("campaign") is Dictionary or not state.get("heroes") is Dictionary:
		return
	var saved_epoch := int(saved.get("epoch", -1))
	var saved_sequence := int(saved.get("sequence", -1))
	if saved_epoch < 0 or saved_epoch > epoch or saved_sequence < 1:
		return
	latest_snapshot = state
	latest_epoch = saved_epoch
	latest_sequence = saved_sequence

func discard_recovery() -> void:
	if FileAccess.file_exists(RECOVERY_FILE):
		DirAccess.remove_absolute(RECOVERY_FILE)
