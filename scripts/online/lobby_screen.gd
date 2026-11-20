extends Control

signal closed

const GardenHub = preload("res://scripts/garden_hub.gd")
const GardenView = preload("res://scripts/garden_view.gd")
const GardenArt = preload("res://scripts/garden_art.gd")
const LobbyHeroines = preload("res://scripts/online/lobby_heroines.gd")
const Client = preload("res://scripts/online/peer_client.gd")
const PreparationPanel = preload("res://scripts/online/preparation_panel.gd")
const Roster = preload("res://scripts/guest_roster.gd")
const SETTINGS := "user://online.cfg"
const SIGNALING_ENDPOINT := "https://garden-bad-bloom-signaling.online-signaling.workers.dev"
const CREAM := Color("#f6e2c2")
const GOLD := Color("#bda07a")
const PLUM := Color("#281f34")
const MUTED := Color("#b9a8b7")
const RETRY_INTERVAL := 2.0
const RETRY_WINDOW := 60.0

var game: Node
var client: Node
var username: LineEdit
var address: LineEdit
var code: LineEdit
var status: Label
var players: VBoxContainer
var heroines: Node2D
var hero_buttons: GridContainer
var host_button: Button
var join_button: Button
var rejoin_button: Button
var start_button: Button
var prepare_button: Button
var ready_button: Button
var copy_button: Button
var pending := ""
var room_code := ""
var token := ""
var local_player_id := ""
var selected := -1
var locked := false
var state: Dictionary = {}
var retry_until := 0.0
var next_retry := 0.0
var retrying := false
var closing := false
var finalizing := false
var leave_requested := false
var leave_deadline := 0.0
var previous_touch_emulation := false

func _ready() -> void:
	# The lobby uses Godot controls. The battle handles raw screen touches.
	previous_touch_emulation = Input.emulate_mouse_from_touch
	visibility_changed.connect(_update_touch_emulation)
	_update_touch_emulation()
	# The parent is a Node2D, so the lobby needs its own layout size.
	size = GardenView.CANVAS.size
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var artwork := TextureRect.new()
	artwork.texture = GardenHub.COURTYARD
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(artwork)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.10, 0.07, 0.14, 0.34)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	margin.add_child(columns)
	var left := lobby_panel(columns, 274)
	add_label(left, "The Garden", 30)
	add_label(left, "Multiplayer", 17).modulate = GOLD
	username = make_entry(left, "Your name", 24)
	address = make_entry(left, "Room service", 255)
	address.text = SIGNALING_ENDPOINT
	address.visible = false
	code = make_entry(left, "Room code", 6)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	left.add_child(actions)
	host_button = make_button(actions, "Host", _host, true)
	join_button = make_button(actions, "Join", _join)
	rejoin_button = make_button(actions, "Rejoin", _rejoin)
	status = add_label(left, "Enter your name to host or join.", 16)
	status.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	make_button(left, "Back", _close)
	var right := lobby_panel(columns, 0)
	add_label(right, "Waiting Garden", 24)
	var stage := Control.new()
	stage.custom_minimum_size.y = 92
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(stage)
	var stage_frame := Panel.new()
	stage.add_child(stage_frame)
	stage_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_frame.add_theme_stylebox_override("panel", frame(Color("#21192d"), Color("#755c76")))
	heroines = LobbyHeroines.new()
	stage.add_child(heroines)
	stage.resized.connect(func(): heroines.width = stage.size.x)
	add_label(right, "Choose a heroine", 16).modulate = GOLD
	players = VBoxContainer.new()
	players.visible = false
	right.add_child(players)
	hero_buttons = GridContainer.new()
	hero_buttons.columns = 4
	hero_buttons.add_theme_constant_override("h_separation", 5)
	hero_buttons.add_theme_constant_override("v_separation", 5)
	right.add_child(hero_buttons)
	for hero in Roster.NAMES.size():
		var button := make_button(hero_buttons, Roster.NAMES[hero], _choose.bind(hero))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(105, 42)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = Roster.NAMES[hero]
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	right.add_child(controls)
	copy_button = make_button(controls, "Copy code", _copy_code)
	prepare_button = make_button(controls, "Prepare", _open_preparation)
	ready_button = make_button(controls, "Lock in", _ready_toggle)
	start_button = make_button(controls, "Start run", _start, true)
	client = Client.new()
	client.name = "OnlinePeer"
	add_child(client)
	client.session_joined.connect(_session_joined)
	client.room_changed.connect(_room_changed)
	client.connection_problem.connect(_failed)
	client.reconnecting.connect(_reconnecting)
	client.session_left.connect(_finish_close)
	load_settings()
	update_controls()

func _update_touch_emulation() -> void:
	Input.emulate_mouse_from_touch = is_visible_in_tree() or previous_touch_emulation

func _exit_tree() -> void:
	Input.emulate_mouse_from_touch = previous_touch_emulation

func frame(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style

func lobby_panel(parent: HBoxContainer, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	if width == 0:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := frame(Color("#281f34f5"), GOLD)
	style.set_content_margin_all(14)
	style.shadow_color = Color("#160f2099")
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	return content

func add_label(parent: Node, value: String, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", GardenArt.DISPLAY_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#f6e2c2"))
	parent.add_child(label)
	return label

func make_entry(parent: Node, hint: String, limit: int) -> LineEdit:
	var entry := LineEdit.new()
	entry.placeholder_text = hint
	entry.max_length = limit
	entry.custom_minimum_size.y = 42
	entry.add_theme_font_override("font", GardenArt.DISPLAY_FONT)
	entry.add_theme_font_size_override("font_size", 17)
	entry.add_theme_color_override("font_color", CREAM)
	entry.add_theme_color_override("font_placeholder_color", MUTED)
	var field := frame(Color("#21192d"), Color("#806983"))
	field.set_content_margin_all(8)
	entry.add_theme_stylebox_override("normal", field)
	var focus := frame(Color.TRANSPARENT, CREAM)
	focus.draw_center = false
	entry.add_theme_stylebox_override("focus", focus)
	parent.add_child(entry)
	return entry

func make_button(parent: Node, title: String, action: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 42
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", GardenArt.DISPLAY_FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", frame(CREAM if primary else Color("#44334f"), GOLD))
	button.add_theme_stylebox_override("hover", frame(Color("#fff1d6") if primary else Color("#604666"), CREAM))
	button.add_theme_stylebox_override("pressed", frame(Color("#d5b78a") if primary else Color("#312438"), CREAM))
	button.add_theme_stylebox_override("disabled", frame(PLUM, Color("#655367")))
	var focus := frame(Color.TRANSPARENT, CREAM)
	focus.draw_center = false
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	for state_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state_name, PLUM if primary else CREAM)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS) == OK:
		username.text = str(config.get_value("player", "name", ""))
		address.text = SIGNALING_ENDPOINT
		room_code = str(config.get_value("run", "code", ""))
		token = str(config.get_value("run", "token", ""))

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "name", username.text.strip_edges())
	config.set_value("server", "address", address.text.strip_edges())
	config.set_value("run", "code", room_code)
	config.set_value("run", "token", token)
	var temporary := SETTINGS + ".tmp"
	if config.save(temporary) == OK:
		DirAccess.rename_absolute(temporary, SETTINGS)

func now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0

func _process(_delta: float) -> void:
	if closing and leave_deadline > 0.0 and now_seconds() >= leave_deadline:
		_finish_close()

func connect_for(action: String) -> void:
	if username.text.strip_edges().is_empty() or address.text.strip_edges().is_empty():
		status.text = "Enter your name to host or join."
		return
	if action == "join" and code.text.strip_edges().length() != 6:
		status.text = "Enter the six-character room code."
		return
	retrying = false
	pending = action
	save_settings()
	var error: Error = OK
	match action:
		"host": error = client.host(address.text, username.text)
		"join": error = client.join(address.text, code.text, username.text)
		"rejoin": error = client.rejoin(address.text, room_code, token)
	if error != OK:
		status.text = "Could not start connection: " + error_string(error)
		pending = ""
	else:
		status.text = "Connecting to the Garden…"
	update_controls()

func _host() -> void:
	connect_for("host")

func _join() -> void:
	connect_for("join")

func _rejoin() -> void:
	if room_code.is_empty() or token.is_empty():
		return
	connect_for("rejoin")

func _session_joined(joined_code: String, joined_token: String, player_id: String) -> void:
	room_code = joined_code
	token = joined_token
	local_player_id = player_id
	retrying = false
	save_settings()
	status.text = "Room code  ·  " + room_code
	update_controls()

func _room_changed(payload: Dictionary) -> void:
	pending = ""
	state = payload
	room_code = str(payload.get("code", room_code))
	draw_roster()
	update_controls()
	if str(state.get("phase", "")) == "playing" and not is_instance_valid(game.online_peer):
		game.begin_online(client)
		hide()

func _failed(reason: String) -> void:
	pending = ""
	retrying = false
	status.text = reason
	update_controls()

func _reconnecting(seconds_left: float) -> void:
	retrying = true
	status.text = "Reconnecting… %ds" % ceili(seconds_left)
	update_controls()

func draw_roster() -> void:
	heroines.roster = state.get("players", []).duplicate(true)
	for child in players.get_children():
		child.queue_free()
	for row: Dictionary in state.get("players", []):
		if row.id == local_player_id:
			selected = int(row.hero)
			locked = bool(row.ready)
		var hero := int(row.hero)
		var name: String = Roster.NAMES[hero] if hero >= 0 and hero < Roster.NAMES.size() else "Choosing"
		var suffix := " · Ready" if row.ready else ""
		if not row.connected:
			suffix = " · Reconnecting"
		add_label(players, "%s  ·  %s%s" % [row.username, name, suffix], 14)
	if state.get("phase", "") != "lobby":
		status.text = "Room " + room_code + " · campaign starting"
	else:
		status.text = "Room code  ·  " + room_code
	for index in hero_buttons.get_child_count():
		var button: Button = hero_buttons.get_child(index)
		button.disabled = locked
		for row: Dictionary in state.get("players", []):
			if int(row.hero) == index and row.id != local_player_id:
				button.disabled = true
				button.tooltip_text = "Selected by " + str(row.username)

func update_controls() -> void:
	var in_room := not state.is_empty()
	host_button.disabled = in_room or retrying or not pending.is_empty()
	join_button.disabled = in_room or retrying or not pending.is_empty()
	rejoin_button.disabled = in_room or retrying or not pending.is_empty() or room_code.is_empty() or token.is_empty()
	prepare_button.disabled = not in_room or selected < 0 or state.get("phase", "") != "lobby"
	ready_button.disabled = not in_room or selected < 0 or state.get("phase", "") != "lobby"
	ready_button.text = "Unlock" if locked else "Lock in"
	var all_ready: bool = in_room and state.get("players", []).size() >= 2
	for row: Dictionary in state.get("players", []):
		if not row.ready or not row.connected:
			all_ready = false
	start_button.disabled = not all_ready or state.get("host", "") != local_player_id or state.get("phase", "") != "lobby"
	copy_button.disabled = not in_room or room_code.is_empty()
	for index in hero_buttons.get_child_count():
		var button: Button = hero_buttons.get_child(index)
		var unlocked := game != null and Roster.is_unlocked(game.profile, index)
		button.disabled = not in_room or locked or not unlocked
		button.text = Roster.NAMES[index] if unlocked else Roster.NAMES[index] + " · Locked"
		button.tooltip_text = Roster.NAMES[index] if unlocked else Roster.NAMES[index] + " · Unlock in the Seed Shop"
		if index == selected:
			button.text += " · Yours"
		var selected_fill := Color("#594455") if index == selected else Color("#44334f")
		button.add_theme_stylebox_override("normal", frame(selected_fill, CREAM if index == selected else GOLD))
		button.add_theme_stylebox_override("disabled", frame(selected_fill if index == selected else PLUM, GOLD if index == selected else Color("#655367")))
		for row: Dictionary in state.get("players", []):
			if int(row.hero) == index and row.id != local_player_id:
				button.disabled = true
				button.text = Roster.NAMES[index] + " · Taken"
				button.tooltip_text = "Selected by " + str(row.username)

func _open_preparation() -> void:
	if selected < 0 or game == null:
		return
	var panel = PreparationPanel.new()
	add_child(panel)
	panel.configure(selected, game.profile, game.codex)
	for row: Dictionary in state.get("players", []):
		if str(row.get("id", "")) == local_player_id:
			panel.set_selection(str(row.get("relic", "")), str(row.get("weapon", "")))
			break
	panel.set_locked(locked)
	panel.selection_changed.connect(func(relic: String, weapon: String):
		client.send({"type": "prepare", "relic": relic, "weapon": weapon}))
	panel.confirmed.connect(func():
		if not locked:
			client.send({"type": "prepare", "relic": panel.selected_relic, "weapon": panel.selected_weapon}))

func _copy_code() -> void:
	DisplayServer.clipboard_set(room_code)
	status.text = "Room code copied."

func _choose(hero: int) -> void:
	if locked or game == null or not Roster.is_unlocked(game.profile, hero):
		return
	selected = hero
	client.select_hero(hero, false)
	update_controls()

func _ready_toggle() -> void:
	if selected < 0:
		return
	locked = not locked
	client.select_hero(selected, locked)
	update_controls()

func _start() -> void:
	client.start_run()

func _close() -> void:
	if closing:
		return
	closing = true
	retrying = false
	leave_requested = not state.is_empty()
	if leave_requested:
		status.text = "Leaving the Garden…"
		leave_deadline = now_seconds() + 2.0
		client.leave()
		return
	_finish_close()

func _finish_close() -> void:
	if finalizing:
		return
	finalizing = true
	leave_deadline = 0.0
	if leave_requested:
		room_code = ""
		token = ""
		save_settings()
	client.reset_session()
	closed.emit()
	queue_free()
