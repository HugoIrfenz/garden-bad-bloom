extends SceneTree

const Relics = preload("res://scripts/relic_effects.gd")

func _initialize() -> void:
	call_deferred("run")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func run() -> void:
	var relics = Relics.new()
	if not require(relics.equip(Relics.WEDDING_RING) and not relics.equip(Relics.WEDDING_RING)
			and not relics.equip("missing"), "Relic ownership accepted a duplicate or invalid ID"):
		return
	var nonlethal = relics.resolve_damage(13, 12, 0)
	if not require(nonlethal.hp == 1 and not nonlethal.prevented and relics.ring_available(0),
			"Nonlethal damage consumed the Wedding Ring"):
		return
	var lethal = relics.resolve_damage(12, 12, 0)
	if not require(lethal.hp == 1 and lethal.grace > 0.0 and lethal.prevented,
			"The Wedding Ring did not prevent a lethal attack"):
		return
	var restored = Relics.new()
	var serialized = JSON.stringify(relics.snapshot())
	if not require(restored.restore(JSON.parse_string(serialized)), "Wedding Ring state did not deserialize"):
		return
	var floor_repeat = restored.resolve_damage(1, 4, 0)
	var new_floor = restored.resolve_damage(1, 4, 1)
	if not require(floor_repeat.hp <= 0 and not floor_repeat.prevented and new_floor.prevented,
			"Wedding Ring floor usage did not persist or reset correctly"):
		return

	relics.equip(Relics.GLASS_EYELASH)
	relics.equip(Relics.LAST_TEASPOON)
	relics.on_perfect_dodge()
	relics.on_perfect_dodge()
	serialized = JSON.stringify(relics.snapshot())
	restored.restore(JSON.parse_string(serialized))
	var first = restored.on_basic_attack(20)
	var near_death = restored.on_basic_attack(1)
	if not require(first.pierce and not first.wide_cone and not near_death.pierce and near_death.wide_cone,
			"Dodge charge or one-HP attack was lost, stacked, or consumed early"):
		return
	serialized = JSON.stringify(restored.snapshot())
	relics.restore(JSON.parse_string(serialized))
	if not require(not relics.on_basic_attack(1).wide_cone, "Last Teaspoon usage did not persist"):
		return
	relics.reset()
	relics.on_perfect_dodge()
	if not require(not relics.on_basic_attack(1).pierce and not relics.ring_available(2),
			"Previous relic effects survived a new run"):
		return
	print("PASS: relic slots, Wedding Ring floor guard, one piercing attack, Last Teaspoon, and JSON save round trips.")
	quit()
