extends RefCounted

const ENTER_DURATION = 0.32
const PRESS_DURATION = 0.36
const HOVER_DURATION = 0.15

var screen_age := 0.0
var hero_age := 0.0
var relic_age := 0.0
var previous_screen := ""
var press_point := Vector2.INF
var press_screen := ""
var garden_reaction_hero := -1
var garden_reaction_age := INF
var garden_reaction_kind := 0
var pause_panel := "relics"
var pause_upgrade := ""
var reward_relic_preview := ""
var _screen := ""
var _hero := -1
var _relic := ""
var _press_age := PRESS_DURATION
var _hover_rect := Rect2()
var _hover_age := 0.0

func advance(screen: String, hero: int, relic: String, pointer: Vector2, delta: float) -> void:
	if screen != "reward":
		reward_relic_preview = ""
	var entered := screen != _screen
	if entered:
		previous_screen = _screen
		_screen = screen
		screen_age = 0.0
	else:
		screen_age += delta

	if entered or hero != _hero:
		hero_age = 0.0
		_hero = hero
	else:
		hero_age += delta

	if entered or relic != _relic:
		relic_age = 0.0
		_relic = relic
	else:
		relic_age += delta

	_press_age += delta
	garden_reaction_age += delta
	if entered or not _hover_rect.has_point(pointer):
		_hover_rect = Rect2()
		_hover_age = 0.0
	else:
		_hover_age += delta

func record_press(screen: String, point: Vector2) -> void:
	press_screen = screen
	press_point = point
	_press_age = 0.0

func react_in_garden(index: int) -> void:
	garden_reaction_kind = posmod(garden_reaction_kind + 1, 4) if garden_reaction_hero == index else posmod(index, 4)
	garden_reaction_hero = index
	garden_reaction_age = 0.0

func press_amount(box: Rect2) -> float:
	if press_screen != _screen or not box.has_point(press_point):
		return 0.0
	return 1.0 - smoothstep(0.0, PRESS_DURATION, _press_age)

func hover_amount(box: Rect2, pointer: Vector2) -> float:
	if not box.has_point(pointer):
		return 0.0
	if _hover_rect != box:
		_hover_rect = box
		_hover_age = 0.0
	return smoothstep(0.0, HOVER_DURATION, _hover_age)

func entrance_amount() -> float:
	return 1.0 - smoothstep(0.0, ENTER_DURATION, screen_age)

func selection_amount(age: float) -> float:
	return 1.0 - smoothstep(0.0, 0.42, age)
