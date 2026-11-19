extends RefCounted

const IDS = ["royal_teacup", "clockwise_tonic", "petal_bomb"]
const ICONS = preload("res://assets/art/items/pocket_items.png")
const ICON_REGIONS = [Rect2(50, 138, 644, 515), Rect2(876, 22, 421, 664), Rect2(1491, 37, 630, 649)]
const ITEMS = {
	"royal_teacup": {"name": "Royal Teacup", "rarity": "uncommon", "effect": "Refill to 3 resource pips", "short": "Teacup", "accent": Color("#a5d5eb")},
	"clockwise_tonic": {"name": "Clockwise Tonic", "rarity": "uncommon", "effect": "Move and recover faster for 6s", "short": "Tonic", "accent": Color("#f2c778")},
	"petal_bomb": {"name": "Petal Bomb", "rarity": "uncommon", "effect": "Blast 38 damage near a foe", "short": "Bomb", "accent": Color("#f48db1")},
}
const TONIC_TIME = 6.0
const TONIC_RECOVERY = 1.40
const TONIC_MOVEMENT = 1.24
const BOMB_RADIUS = 72.0
const BOMB_RANGE = 175.0
const FLASH_TIME = 0.42

var held := ""
var haste := 0.0
var flash := 0.0
var last := ""
var center := Vector2.ZERO

static func card(item: String) -> Dictionary:
	var data: Dictionary = ITEMS[item].duplicate()
	data.texture = ICONS
	data.icon = ICON_REGIONS[IDS.find(item)]
	data.kind = "Consumable"
	data.action = "Pack for later"
	return data

static func draw_icon(canvas: Node2D, item: String, point: Vector2, extent: float, tint: Color) -> void:
	var source: Rect2 = ICON_REGIONS[IDS.find(item)]
	var size := (source.size * extent / maxf(source.size.x, source.size.y)).round()
	canvas.draw_texture_rect_region(ICONS, Rect2((point - size / 2.0).round(), size), source, tint)

func restore(item: String = "", remaining: float = 0.0) -> void:
	held = item if ITEMS.has(item) else ""
	haste = clampf(remaining, 0.0, TONIC_TIME)
	flash = 0.0
	last = ""

func offer(game) -> String:
	if game.floor_index < 0 or not held.is_empty() or not game.reward_relic_id.is_empty():
		return ""
	var seed_value := int(game.current_room().reward_seed)
	return IDS[posmod(posmod(seed_value, IDS.size()) + int(game.depth), IDS.size())]

func remaining_cooldown(clock: float) -> float:
	return clock - minf(clock / TONIC_RECOVERY, haste) * (TONIC_RECOVERY - 1.0)

func take(item: String) -> bool:
	if not held.is_empty() or not ITEMS.has(item):
		return false
	held = item
	return true

func usable(game) -> bool:
	match held:
		"royal_teacup":
			return game.resource < 3
		"clockwise_tonic":
			return haste <= 0.0
		"petal_bomb":
			return game.assisted_aim(BOMB_RANGE).is_finite()
	return false

func consume(game) -> void:
	if not usable(game):
		return
	last = held
	held = ""
	center = game.player
	flash = FLASH_TIME
	match last:
		"royal_teacup":
			game.resource = 3
			game.sound.play("reward")
		"clockwise_tonic":
			haste = TONIC_TIME
			game.sound.play("reward")
		"petal_bomb":
			center = game.assisted_aim(BOMB_RANGE)
			for foe: Dictionary in game.foes:
				if int(foe.hp) <= 0 or center.distance_squared_to(game.target(foe)) > BOMB_RADIUS * BOMB_RADIUS:
					continue
				var damage: int = game.defend_foe(foe, game.player_hit_amount(38))
				foe.hp -= damage
				if damage > 0:
					foe.flash = 0.14
			game.sound.play("hit")
	game.checkpoint()

func tick(delta: float) -> void:
	haste = maxf(0.0, haste - delta)
	flash = maxf(0.0, flash - delta)

func draw(game) -> void:
	var canvas: Node2D = game.world_canvas
	if haste > 0.0:
		for index in range(3):
			var phase := fposmod(game.visual_clock * 1.24 + float(index) / 3.0, 1.0)
			var point: Vector2 = game.player + Vector2.from_angle(phase * TAU) * Vector2(22.0, 8.0) + Vector2(0, 8.0 - phase * 26.0)
			game.View.diamond(canvas, point.round(), 2.1, Color(ITEMS.clockwise_tonic.accent, 1.0 - phase))
	if flash <= 0.0 or not ITEMS.has(last):
		return
	var progress := 1.0 - flash / FLASH_TIME
	var tint: Color = ITEMS[last].accent
	var limit := BOMB_RADIUS if last == "petal_bomb" else 29.0
	var radius := lerpf(10.0, limit, 1.0 - pow(1.0 - progress, 3.0))
	canvas.draw_arc(center, radius, 0, TAU, 42, Color(tint, 1.0 - progress), 2.2, true)
	for index in range(12):
		var axis := Vector2.from_angle(index * TAU / 12.0 + 0.22 * progress)
		var point := center + axis * radius * (0.73 + (index % 3) * 0.12)
		game.View.diamond(canvas, point.round(), 2.9 * (1.0 - progress), Color(tint, 1.0 - progress))
