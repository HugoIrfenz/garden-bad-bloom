extends Control

# Full-screen, touch-friendly multiplayer loadout sheet. No profile purchases or
# run rewards are made here; unlocked weapons mirror the solo preparation menu.
signal selection_changed(relic_id: String, weapon_id: String)
signal confirmed
signal closed

const Prep = preload("res://scripts/run_preparation_view.gd")
const Art = preload("res://scripts/garden_art.gd")
const Relics = preload("res://scripts/relic_effects.gd")
const RelicInfo = preload("res://scripts/relic_info_view.gd")
const Weapons = preload("res://scripts/weapon_catalog.gd")
const WeaponArt = preload("res://scripts/weapon_art.gd")
const Profile = preload("res://scripts/run_profile.gd")
const Roster = preload("res://scripts/guest_roster.gd")

class ItemIcon extends Node2D:
	var item_id := ""
	var is_relic := false
	func _draw() -> void:
		if item_id.is_empty():
			draw_arc(Vector2.ZERO, 14, 0, TAU, 20, Color("#c9ac94"), 1.0)
			draw_line(Vector2(-9, 9), Vector2(9, -9), Color("#c9ac94"), 2.0)
		elif is_relic:
			RelicInfo.draw_icon(self, item_id, Vector2.ZERO, 38)
		else:
			WeaponArt.draw_icon(self, item_id, Vector2.ZERO, 54)

var hero := 0
var profile
var codex
var selected_relic := ""
var selected_weapon := ""
var is_locked := false
var weapon_options: Array[String] = []
var relic_options: Array[String] = []
var title: Label
var weapon_name: Label
var weapon_detail: Label
var relic_detail: Label
var weapon_icon: ItemIcon
var cards: HBoxContainer
var previous_button: Button
var next_button: Button
var done_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var background := TextureRect.new()
	background.texture = Prep.BACKDROP
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var tint := ColorRect.new()
	tint.color = Color(0.10, 0.07, 0.14, 0.78)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)
	title = _label(self, Vector2(245, 12), Vector2(375, 32), "Run Preparation", 24, true)
	var weapon_heading := _label(self, Vector2(30, 61), Vector2(205, 24), "Starting Weapon", 18, true)
	weapon_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var weapon_box := Panel.new()
	weapon_box.position = Vector2(30, 89)
	weapon_box.size = Vector2(205, 198)
	weapon_box.add_theme_stylebox_override("panel", _frame(false))
	add_child(weapon_box)
	weapon_icon = ItemIcon.new()
	weapon_icon.position = Vector2(102, 45)
	weapon_box.add_child(weapon_icon)
	weapon_name = _label(weapon_box, Vector2(10, 82), Vector2(185, 32), "", 18, true)
	weapon_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_detail = _label(weapon_box, Vector2(13, 119), Vector2(179, 60), "", 12)
	weapon_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	previous_button = _button(weapon_box, Vector2(12, 163), Vector2(40, 28), "‹", _cycle_weapon.bind(-1))
	next_button = _button(weapon_box, Vector2(153, 163), Vector2(40, 28), "›", _cycle_weapon.bind(1))
	_label(self, Vector2(259, 61), Vector2(570, 24), "Choose a Starting Relic", 18, true)
	cards = HBoxContainer.new()
	cards.position = Vector2(259, 91)
	cards.size = Vector2(570, 128)
	cards.add_theme_constant_override("separation", 5)
	add_child(cards)
	var detail_box := Panel.new()
	detail_box.position = Vector2(259, 229)
	detail_box.size = Vector2(570, 84)
	detail_box.add_theme_stylebox_override("panel", _frame(false))
	add_child(detail_box)
	relic_detail = _label(detail_box, Vector2(12, 7), Vector2(546, 70), "", 13)
	relic_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(self, Vector2(30, 331), Vector2(130, 42), "Back", _close)
	done_button = _button(self, Vector2(657, 331), Vector2(173, 42), "Confirm", _confirm)
	_refresh()

func configure(hero_index: int, current_profile, current_codex = null) -> void:
	var new_hero := clampi(hero_index, 0, Roster.NAMES.size() - 1)
	if hero != new_hero or selected_weapon.is_empty():
		selected_relic = ""
		selected_weapon = Weapons.starter(new_hero)
	hero = new_hero
	profile = current_profile
	codex = current_codex
	if is_inside_tree():
		_refresh()

func set_selection(relic_id: String, weapon_id: String) -> void:
	selected_relic = relic_id
	selected_weapon = weapon_id
	if is_inside_tree():
		_refresh()

func set_locked(value: bool) -> void:
	is_locked = value
	if is_inside_tree():
		_refresh()

func _refresh() -> void:
	if title == null:
		return
	title.text = Roster.NAMES[hero] + " · Run Preparation"
	weapon_options.clear()
	weapon_options.append(Weapons.starter(hero))
	for weapon_id: String in Weapons.available(hero, ""):
		var discovered: bool = codex != null and codex.knows_weapon(weapon_id)
		var purchased: bool = profile != null and weapon_id in Profile.STARTING_WEAPONS and profile.has_unlock(weapon_id)
		if discovered or purchased:
			weapon_options.append(weapon_id)
	if selected_weapon not in weapon_options:
		selected_weapon = weapon_options[0]
	var weapon := Weapons.item(selected_weapon)
	weapon_name.text = str(weapon.get("name", "Weapon"))
	weapon_detail.text = str(weapon.get("effect", ""))
	weapon_icon.item_id = selected_weapon
	weapon_icon.queue_redraw()
	previous_button.disabled = is_locked or weapon_options.size() <= 1
	next_button.disabled = previous_button.disabled
	relic_options.clear()
	relic_options.append("")
	for id: String in Prep.relic_options(hero):
		relic_options.append(id)
	if selected_relic not in relic_options:
		selected_relic = ""
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	for id: String in relic_options:
		var selected := id == selected_relic
		var card := Button.new()
		card.custom_minimum_size = Vector2(109, 122)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.focus_mode = Control.FOCUS_NONE
		card.disabled = is_locked
		for key in ["normal", "hover", "pressed", "disabled", "focus"]:
			card.add_theme_stylebox_override(key, _frame(selected))
		card.pressed.connect(_choose_relic.bind(id))
		cards.add_child(card)
		var icon := ItemIcon.new()
		icon.item_id = id
		icon.is_relic = true
		icon.position = Vector2(54, 39)
		card.add_child(icon)
		var name := "No Relic" if id.is_empty() else str(Relics.definition(id).get("name", "Relic"))
		var caption := _label(card, Vector2(3, 75), Vector2(103, 40), name, 12, true)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var relic := Relics.definition(selected_relic)
	relic_detail.text = "No starting relic selected. Tap a card to inspect and equip it." if relic.is_empty() else str(relic.get("name", "Relic")) + "\n" + str(relic.get("detail", ""))
	done_button.text = "Done" if is_locked else "Confirm"

func _cycle_weapon(direction: int) -> void:
	if is_locked or weapon_options.is_empty():
		return
	var index := posmod(weapon_options.find(selected_weapon) + direction, weapon_options.size())
	selected_weapon = weapon_options[index]
	_refresh()
	selection_changed.emit(selected_relic, selected_weapon)

func _choose_relic(id: String) -> void:
	if is_locked or id not in relic_options:
		return
	selected_relic = id
	_refresh()
	selection_changed.emit(selected_relic, selected_weapon)

func _confirm() -> void:
	confirmed.emit()
	closed.emit()
	queue_free()

func _close() -> void:
	closed.emit()
	queue_free()

static func _frame(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#413044") if selected else Color(0.13, 0.09, 0.18, 0.94)
	style.border_color = Color("#f9d19a") if selected else Color("#c3a17b")
	style.set_border_width_all(2 if selected else 1)
	style.set_content_margin_all(4)
	return style

static func _label(parent: Node, point: Vector2, extent: Vector2, text_value: String, font_size: int, serif := false) -> Label:
	var label := Label.new()
	label.position = point
	label.size = extent
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#f6e2c2"))
	if serif:
		label.add_theme_font_override("font", Art.DISPLAY_FONT)
	parent.add_child(label)
	return label

static func _button(parent: Node, point: Vector2, extent: Vector2, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.position = point
	button.size = extent
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", Art.DISPLAY_FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("#f6e2c2"))
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(key, _frame(key == "pressed"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
