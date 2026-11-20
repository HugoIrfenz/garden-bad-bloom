extends RefCounted

const Dungeon = preload("res://scripts/dungeon_generation.gd")
const OptionalBosses = preload("res://scripts/optional_bosses.gd")
const ForgottenEncounters = preload("res://scripts/forgotten_encounters.gd")
const BiomeEncounters = preload("res://scripts/biome_encounters.gd")
const ForestPalace = preload("res://scripts/bloodbloom_palace_encounters.gd")
const AstralCore = preload("res://scripts/astral_core_encounters.gd")
const ELITE_CHANCE = 0.12
const ELITE_HEAL_CHANCE = 0.30
const BOSS_HEALTH_MULTIPLIER = 5

static func spawn(room: Dictionary, floor_manifest: Dictionary, room_id: String, floor_index: int, depth: int, route: int, endless) -> Array[Dictionary]:
	var foes: Array[Dictionary] = []
	var room_kind: String = room.kind
	var room_template: String = room.template_id
	var active_biome: int = room.biome
	var node: Dictionary = floor_manifest.get("nodes", {}).get(room_id, {})
	var side_boss := str(node.get("optional_boss", "")) if int(node.get("optional_stage", -1)) == 2 else ""
	var stage := int(node.get("optional_stage", -1))
	var lessons: Array = OptionalBosses.APPROACHES.get(node.get("optional_boss", ""), [])
	var approach: Array = lessons[stage] if stage >= 0 and stage < lessons.size() else []
	var boss = room_kind == "boss" or not side_boss.is_empty()
	var encounter_depth = depth if floor_index < 0 else floor_index * 4 + int(floor_manifest.nodes[room_id].layer / 2)
	var count = 1 if boss else mini(2 + encounter_depth / 3 + route, room.spawns.size())
	if not approach.is_empty():
		count = mini(count, 2)
	count = endless.encounter_count(count, room_kind)
	var rng = Dungeon.seeded(room.encounter_seed)
	var elite_rng = Dungeon.seeded(int(room.encounter_seed) ^ 0x5e17e)
	for index in range(count):
		var pos: Vector2 = room.spawns[index]
		if not side_boss.is_empty():
			pos = Vector2(clampf(pos.x, 300.0, 564.0), maxf(169.0, pos.y))
		var elite: bool = not boss and (room_kind == "elite" or (room_kind in ["combat", "challenge"] and elite_rng.randf() < ELITE_CHANCE))
		# The first encounter introduces the two melee enemies.
		var kind = 3 if boss else (index if encounter_depth == 0 else rng.randi_range(0, 2))
		if floor_index >= 0 and not boss and index == 0 and room_template in ["hedge_maze", "flowerbed_siege"]:
			kind = ForgottenEncounters.HEDGE_KNIGHT
		elif floor_index >= 0 and not boss and index == 0 and room_template in ["fungal_crossroad", "glowpool"]:
			kind = BiomeEncounters.MYCELIUM_LEAPER
		elif floor_index >= 0 and not boss and index == 0 and room_template in ["widow_crossing", "poppy_cathedral"]:
			kind = ForestPalace.THORN_WIDOW
		elif floor_index >= 0 and not boss and index == 0 and active_biome == ForestPalace.PALACE and room_template in ["broken_ballroom", "chandelier_hall"]:
			kind = ForestPalace.PORCELAIN_HOUND
		var life := boss_health(encounter_depth) if boss else enemy_health(encounter_depth, active_biome, kind, elite)
		var foe = {"x": pos.x, "y": pos.y, "hp": life, "max": life,
			"boss": boss, "clock": 0.8 + index * 0.28, "phase": 0, "tx": 0.0, "ty": 0.0,
			"kind": kind, "biome": active_biome, "enemy_power": enemy_power(encounter_depth, boss, elite),
			"elite": elite, "elite_heal_drop": elite and elite_rng.randf() < ELITE_HEAL_CHANCE}
		if boss:
			foe.boss_health_multiplier = BOSS_HEALTH_MULTIPLIER
		if not side_boss.is_empty():
			foe.optional_boss = side_boss
		elif index == 0 and not approach.is_empty():
			foe.optional_boss = floor_manifest.nodes[room_id].optional_boss
			foe.optional_lesson = approach[1]
			foe.elite = false
			foe.elite_heal_drop = false
		if boss and active_biome == AstralCore.CORE and floor_index < Dungeon.BIOME_COUNT:
			AstralCore.configure_capstone(foe)
		if active_biome == ForestPalace.PALACE and kind == ForestPalace.PORCELAIN_HOUND:
			foe.hound_side = 1 if int(room.encounter_seed) % 2 == 0 else -1
		endless.mark_foe(foe, index, room_kind)
		foes.append(foe)
	return foes

static func boss_health(encounter_depth: int) -> int:
	var rank := clampi(encounter_depth, 0, 80)
	return BOSS_HEALTH_MULTIPLIER * (222 + 9 * rank + roundi(0.055 * rank * rank))

static func enemy_health(encounter_depth: int, biome: int, kind: int, elite: bool) -> int:
	const SPECIES_HEALTH = [
		[1.00, 1.13, 0.88, 1.00, 1.23], [1.00, 0.85, 1.09, 1.00, 1.12],
		[0.88, 1.06, 1.15], [0.88, 1.19, 0.90, 1.00, 1.22],
		[0.93, 0.88, 1.22, 1.00, 1.12], [0.85, 1.15, 0.95], [1.03, 0.91, 1.14],
	]
	var rank := clampi(encounter_depth, 0, 66)
	var species: Array = SPECIES_HEALTH[clampi(biome, 0, SPECIES_HEALTH.size() - 1)]
	var scale := float(species[kind]) if kind >= 0 and kind < species.size() else 1.0
	return roundi((34 + 2 * rank + 0.036 * rank * rank) * scale * (1.55 if elite else 1.0))

static func enemy_power(encounter_depth: int, boss: bool, elite: bool) -> float:
	var later := clampf(float(encounter_depth - 2) * 0.017, 0.0, 0.54)
	return 1.0 + later + (0.09 * smoothstep(0.0, 24.0, float(encounter_depth)) if boss else 0.0) + (0.10 if elite else 0.0)

