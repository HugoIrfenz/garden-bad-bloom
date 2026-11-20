extends MultiplayerPeerExtension

# Room-service fallback for networks where a WebRTC data channel cannot open.
# The Worker authenticates the socket and replaces the sender in each header.
const HEADER_BYTES := 6
const MAX_PACKET_BYTES := 1024 * 1024
const MAX_QUEUED_PACKETS := 128

var socket: WebSocketPeer
var local_id := 0
var remote_peers: Dictionary = {}
var incoming: Array[PackedByteArray] = []
var target_peer := 0
var _channel := 0
var _mode := MultiplayerPeer.TRANSFER_MODE_RELIABLE
var refusing := false

func configure(room_socket: WebSocketPeer, id: int) -> void:
	socket = room_socket
	local_id = id

func sync_peers(next: Dictionary) -> void:
	for id: int in remote_peers.keys():
		if not next.has(id):
			_disconnect_peer(id, true)
	for id: int in next:
		if not remote_peers.has(id):
			remote_peers[id] = true
			peer_connected.emit(id)

func receive_packet(packet: PackedByteArray) -> void:
	if packet.size() <= HEADER_BYTES or packet.size() > MAX_PACKET_BYTES + HEADER_BYTES:
		return
	if not remote_peers.has(packet.decode_s32(0)) or packet[4] > MultiplayerPeer.TRANSFER_MODE_RELIABLE:
		return
	if incoming.size() >= MAX_QUEUED_PACKETS:
		return
	incoming.append(packet)

func _put_packet_script(buffer: PackedByteArray) -> Error:
	if _get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return ERR_UNCONFIGURED
	if buffer.is_empty() or buffer.size() > MAX_PACKET_BYTES:
		return ERR_INVALID_DATA
	var packet := PackedByteArray()
	packet.resize(HEADER_BYTES)
	packet.encode_s32(0, target_peer)
	packet[4] = _mode
	packet[5] = _channel
	packet.append_array(buffer)
	return socket.put_packet(packet)

func _get_packet_script() -> PackedByteArray:
	if incoming.is_empty():
		return PackedByteArray()
	return incoming.pop_front().slice(HEADER_BYTES)

func _get_available_packet_count() -> int:
	return incoming.size()

func _get_packet_peer() -> int:
	return 0 if incoming.is_empty() else incoming.front().decode_s32(0)

func _get_packet_channel() -> int:
	return 0 if incoming.is_empty() else int(incoming.front()[5])

func _get_packet_mode() -> MultiplayerPeer.TransferMode:
	return MultiplayerPeer.TRANSFER_MODE_RELIABLE if incoming.is_empty() else int(incoming.front()[4]) as MultiplayerPeer.TransferMode

func _get_max_packet_size() -> int:
	return MAX_PACKET_BYTES

func _set_target_peer(id: int) -> void:
	target_peer = id

func _set_transfer_channel(channel: int) -> void:
	_channel = clampi(channel, 0, 255)

func _get_transfer_channel() -> int:
	return _channel

func _set_transfer_mode(mode: MultiplayerPeer.TransferMode) -> void:
	_mode = mode

func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
	return _mode

func _get_unique_id() -> int:
	return local_id

func _is_server() -> bool:
	return false

func _is_server_relay_supported() -> bool:
	return false

func _set_refuse_new_connections(enabled: bool) -> void:
	refusing = enabled

func _is_refusing_new_connections() -> bool:
	return refusing

func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		return MultiplayerPeer.CONNECTION_CONNECTED
	return MultiplayerPeer.CONNECTION_DISCONNECTED

func _poll() -> void:
	# PeerClient owns polling because the socket also carries room messages.
	pass

func _disconnect_peer(id: int, _force: bool) -> void:
	if remote_peers.erase(id):
		peer_disconnected.emit(id)

func _close() -> void:
	sync_peers({})
	incoming.clear()
	socket = null
