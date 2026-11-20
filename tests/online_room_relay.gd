extends SceneTree

const Peer = preload("res://scripts/online/peer_client.gd")
const ENDPOINT := "http://127.0.0.1:8788"

class NoDirectPeer extends "res://scripts/online/peer_client.gd":
	func send(payload: Dictionary) -> void:
		if payload.get("type") != "signal":
			super.send(payload)

func _initialize() -> void:
	call_deferred("verify")

func make_peer(branch_name: String) -> Node:
	var branch := Node.new()
	branch.name = branch_name
	root.add_child(branch)
	set_multiplayer(SceneMultiplayer.new(), branch.get_path())
	var peer := NoDirectPeer.new()
	peer.name = "OnlinePeer"
	branch.add_child(peer)
	return peer

func wait_until(check: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000)
	while not check.call() and Time.get_ticks_msec() < end:
		await process_frame
	return check.call()

func verify() -> void:
	var host := make_peer("RoomHost")
	var guest := make_peer("RoomGuest")
	host.connection_problem.connect(func(reason): print("Host: ", reason))
	guest.connection_problem.connect(func(reason): print("Guest: ", reason))
	var received := {"frame": {}}
	guest.session.frame_received.connect(func(frame: Dictionary): received.frame = frame)
	if host.host(ENDPOINT, "Test Host") != OK or not await wait_until(func(): return not host.room.is_empty(), 8.0):
		quit(1)
		return
	if guest.join(ENDPOINT, host.code, "Test Guest") != OK or not await wait_until(func(): return guest.room.get("players", []).size() == 2, 8.0):
		quit(2)
		return
	host.select_hero(0, true)
	guest.select_hero(4, true)
	if not await wait_until(func(): return host.room.players.all(func(player): return player.ready), 8.0):
		quit(3)
		return
	# Block direct signaling so the real timeout selects the room relay.
	host.start_run()
	if not await wait_until(func(): return host.transport_announced and guest.transport_announced, 8.0):
		quit(4)
		return
	if not await wait_until(func(): return guest.game_socket_peer != null and host.game_socket_peer != null, 20.0):
		quit(5)
		return
	if not await wait_until(func(): return not received.frame.is_empty() and not received.frame.get("party_starting", true), 8.0):
		push_error("Room relay did not deliver a ready campaign snapshot.")
		quit(6)
		return
	var before: Vector2 = received.frame.campaign.party.players[guest.player_id].position
	for step in range(48):
		guest.session.move(Vector2.RIGHT)
		await physics_frame
	guest.session.move(Vector2.ZERO)
	var after: Vector2 = received.frame.campaign.party.players[guest.player_id].position
	if after.x <= before.x:
		push_error("Guest motion did not round-trip through the room relay.")
		quit(7)
		return
	print("PASS: Worker WebSockets delivered party startup, Room 1 acknowledgment, and guest movement.")
	guest.leave()
	host.leave()
	await create_timer(0.2).timeout
	quit()
