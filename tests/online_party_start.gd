extends SceneTree

class LocalPeer extends "res://scripts/online/peer_client.gd":
	var other: LocalPeer
	func send(payload: Dictionary) -> void:
		if payload.get("type") == "signal":
			var forwarded := payload.duplicate(true)
			forwarded["from"] = player_id
			other.receive.call_deferred(forwarded)

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var host_root := Node.new()
	host_root.name = "HostFixture"
	var guest_root := Node.new()
	guest_root.name = "GuestFixture"
	root.add_child(host_root)
	root.add_child(guest_root)
	set_multiplayer(SceneMultiplayer.new(), host_root.get_path())
	set_multiplayer(SceneMultiplayer.new(), guest_root.get_path())
	var host := LocalPeer.new()
	var guest := LocalPeer.new()
	host.name = "OnlinePeer"
	guest.name = "OnlinePeer"
	host_root.add_child(host)
	guest_root.add_child(guest)
	host.other = guest
	guest.other = host
	host.player_id = "host"
	guest.player_id = "guest"
	host.ice_servers = [{"urls": []}]
	guest.ice_servers = [{"urls": []}]
	var received := {"frame": {}, "saw_waiting": false}
	guest.session.frame_received.connect(func(frame: Dictionary):
		received.saw_waiting = received.saw_waiting or bool(frame.get("party_starting", false))
		received.frame = frame)
	var state := {"type": "room", "phase": "playing", "host": "host", "epoch": 0, "runId": "local-rtc-test",
		"runSeed": 12345, "players": [
			{"id": "host", "peerId": 2, "connected": true, "hero": 0, "username": "Angela"},
			{"id": "guest", "peerId": 3, "connected": true, "hero": 4, "username": "Zaria"}]}
	var lobby_state := state.duplicate(true)
	lobby_state.phase = "lobby"
	lobby_state.runId = ""
	host.receive(lobby_state.duplicate(true))
	guest.receive(lobby_state.duplicate(true))
	host.receive(state.duplicate(true))
	guest.receive(state.duplicate(true))
	var deadline := Time.get_ticks_msec() + 8000
	if not host.session.initial_party_pending.has("guest"):
		push_error("Host started the campaign before the guest acknowledged Room 1.")
		quit(4)
		return
	host.session.move(Vector2.RIGHT)
	if host.session.campaign.motion.controls.has("host"):
		push_error("Room 1 accepted movement while the party was still connecting.")
		quit(5)
		return
	while (received.frame.is_empty() or received.frame.get("party_starting", false)) and Time.get_ticks_msec() < deadline:
		await process_frame
	if received.frame.is_empty() or received.frame.get("party_starting", false) or not received.saw_waiting:
		print("host generation ", host.replica.next_sequence, " guest latest ", guest.replica.latest_sequence,
			" active ", host.session.active_run, "/", guest.session.active_run,
			" host peers ", host.multiplayer.get_peers(), " guest peers ", guest.multiplayer.get_peers(),
			" host recovery ", host.session.host_waiting_snapshot, " campaign ", host.session.campaign)
		push_error("Guest did not receive Room 1. Host %s, guest %s" % [host.connection_progress(), guest.connection_progress()])
		quit(1)
		return
	if not host.session.initial_party_pending.is_empty():
		quit(6)
		return
	var member: Dictionary = received.frame.campaign.party.players.guest
	if int(member.hero) != 4 or int(received.frame.campaign.party.players.host.hero) != 0:
		quit(2)
		return
	var before: Vector2 = member.position
	for index in range(24):
		guest.session.move(Vector2.RIGHT)
		await physics_frame
	var after: Vector2 = received.frame.campaign.party.players.guest.position
	if after.x <= before.x:
		push_error("Guest movement did not reach the host.")
		quit(3)
		return
	print("PASS: co-op waits for the guest's Room 1 acknowledgment, then delivers guest movement and the correct heroine identities.")
	host.reset_session()
	guest.reset_session()
	quit()
