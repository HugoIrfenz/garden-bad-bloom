extends Node2D

const View = preload("res://scripts/garden_view.gd")
const Art = preload("res://scripts/garden_art.gd")
const HeroAbilities = preload("res://scripts/hero_abilities.gd")
const ElegyMagic = preload("res://scripts/elegy_magic.gd")
const SnareThread = preload("res://scripts/snare_thread.gd")
const HeroUltimates = preload("res://scripts/hero_ultimates.gd")
const HeroCombatVisuals = preload("res://scripts/hero_combat_visuals.gd")
const BossCombatVisuals = preload("res://scripts/boss_combat_visuals.gd")
const BossVictory = preload("res://scripts/boss_victory.gd")
const CombatStatuses = preload("res://scripts/combat_statuses.gd")
const RunTalents = preload("res://scripts/run_talents.gd")
const RunUpgrades = preload("res://scripts/run_upgrades.gd")
const EnemyCombatVisuals = preload("res://scripts/enemy_combat_visuals.gd")
const EnemyAttackArt = preload("res://scripts/enemy_attack_art.gd")
const Relics = preload("res://scripts/relic_effects.gd")
const Hub = preload("res://scripts/garden_hub.gd")
const SeedShop = preload("res://scripts/seed_shop_view.gd")
const HistoryView = preload("res://scripts/run_history_view.gd")
const Prep = preload("res://scripts/run_preparation_view.gd")
const SettingsView = preload("res://scripts/garden_settings_view.gd")
const PauseView = preload("res://scripts/pause_view.gd")
const Preferences = preload("res://scripts/garden_preferences.gd")
const MenuMotion = preload("res://scripts/menu_motion.gd")
const RunProfile = preload("res://scripts/run_profile.gd")
const Dungeon = preload("res://scripts/dungeon_generation.gd")
const EndlessRules = preload("res://scripts/endless_mutators.gd")
const GardenSoundstage = preload("res://scripts/garden_soundstage.gd")
const Codex = preload("res://scripts/codex.gd")
const CodexView = preload("res://scripts/codex_view.gd")
const RelicLedger = preload("res://scripts/relic_ledger_view.gd")
const RelicSources = preload("res://scripts/relic_sources.gd")
const RouteView = preload("res://scripts/dungeon_route_view.gd")
const RoomEvents = preload("res://scripts/room_events.gd")
const RunCurses = preload("res://scripts/run_curses.gd")
const OptionalBosses = preload("res://scripts/optional_bosses.gd")
const RunEconomy = preload("res://scripts/run_economy.gd")
const CapBoard = preload("res://scripts/cap_board.gd")
const ArcadeCatalog = preload("res://scripts/arcade_catalog.gd")
const ArcadeSession = preload("res://scripts/arcade_session.gd")
const ArcadeView = preload("res://scripts/arcade_view.gd")
const GardenMedia = preload("res://scripts/garden_media.gd")
const GardenJukebox = preload("res://scripts/garden_jukebox.gd")
const GardenMerchant = preload("res://scripts/garden_merchant.gd")
const Weapons = preload("res://scripts/weapon_catalog.gd")
const WeaponArt = preload("res://scripts/weapon_art.gd")
const WeaponEvolutions = preload("res://scripts/weapon_evolutions.gd")
const UpgradeArt = preload("res://scripts/upgrade_art.gd")
const PaintedEvolution = preload("res://scripts/painted_evolution.gd")
const ForgeView = preload("res://scripts/forge_view.gd")
const ArmoryView = preload("res://scripts/armory_view.gd")
const TalentView = preload("res://scripts/talent_view.gd")
const RunArmory = preload("res://scripts/run_armory.gd")
const RunItems = preload("res://scripts/run_items.gd")
const GardenGroundHazards = preload("res://scripts/garden_ground_hazards.gd")
const ClockworkFloor = preload("res://scripts/clockwork_floor.gd")
const ForgottenEncounters = preload("res://scripts/forgotten_encounters.gd")
const BiomeEncounters = preload("res://scripts/biome_encounters.gd")
const ForestPalace = preload("res://scripts/bloodbloom_palace_encounters.gd")
const AstralCore = preload("res://scripts/astral_core_encounters.gd")
const ENCOUNTERS_BY_BIOME = [
	ForgottenEncounters, BiomeEncounters, BiomeEncounters, ForestPalace, ForestPalace,
	AstralCore, AstralCore,
]
const BIOME_BACKDROPS = [
	preload("res://assets/art/forgotten_garden.png"),
	preload("res://assets/art/mushroom_kingdom.png"),
	preload("res://assets/art/clockwork_conservatory.png"),
	preload("res://assets/art/bloodbloom_forest.png"),
	preload("res://assets/art/hollow_palace.png"),
	preload("res://assets/art/astral_greenhouse.png"),
	preload("res://assets/art/bloomheart_core.png"),
]
const ROOM_VARIANT_ART = [
	preload("res://assets/art/forgotten_variants.png"),
	preload("res://assets/art/fungal_variants.png"),
	preload("res://assets/art/clockwork_variants.png"),
	preload("res://assets/art/hollow_palace_variants.png"),
]
const ROOM_VARIANT_CELLS = {
	"petal_courtyard": [0, 0, 0],
	"broken_fountain": [0, 1, 0],
	"hedge_maze": [0, 0, 1],
	"sunken_greenhouse": [0, 1, 1],
	"spore_nursery": [1, 0, 0],
	"knife_orchard": [1, 1, 0],
	"glowpool": [1, 0, 1],
	"royal_audience": [1, 1, 1],
	"clockface_atrium": [2, 0, 0],
	"gear_orchard": [2, 1, 0],
	"greenhouse_rails": [2, 0, 1],
	"ticking_nursery": [2, 1, 1],
	"chandelier_hall": [3, 0, 0],
	"broken_ballroom": [3, 1, 0],
	"royal_kitchen": [3, 0, 1],
	"final_tea_table": [3, 1, 1],
}

const NAMES = ["Angela", "Vivianne", "Nixia", "Virelia", "Zaria"]
const RESOURCES = ["Resolve", "Ink", "Momentum", "Focus", "Spark"]
const COLORS = [Color.SKY_BLUE, Color.LAVENDER, Color.MEDIUM_PURPLE, Color.LIGHT_PINK, Color.TURQUOISE]
const HEALTH = [125, 80, 100, 95, 90]
const BIOMES = ["Forgotten Garden", "Mushroom Kingdom", "Clockwork Conservatory", "Bloodbloom Forest", "Hollow Palace", "Astral Greenhouse", "Bloomheart Core", "Garden Without End"]
const SAVE = "user://run.json"
const ARENA = Rect2(31, 78, 802, 286)
const ENTRY = Vector2(432, 305)
const CHEST = Vector2(553, 222)
const CHEST_OPEN_DURATION = 0.34
const BARREL_CLEARANCE = 26.0
const ATTACK = Vector2(780, 326)
const DODGE = Vector2(710, 335)
const SKILL = Vector2(784, 254)
const ULTIMATE = Vector2(714, 254)
const POCKET = Vector2(651, 335)
const JOYSTICK = Vector2(84, 323)
const JOYSTICK_TRAVEL = 58.0
const JOYSTICK_DEADZONE = 8.0
const ELITE_CHANCE = 0.12
const ELITE_HEAL_CHANCE = 0.30
const ELITE_HEAL_AMOUNT = 8
const ELITE_WINDUP_FACTOR = 0.80
const ACTIVE_RUN_SCREENS = ["fight", "reward", "clear", "room_choice", "talent", "forge", "minigame"]
const SWING_DURATION = 0.24
const LILY_REPEAT_DELAY = 0.13
const DASH_DISTANCES = [82.0, 64.0, 54.0, 93.0, 110.0]
const DASH_DURATIONS = [0.18, 0.25, 0.11, 0.14, 0.14]
const DASH_RECHARGE = [1.0, 1.28, 0.83, 0.96, 0.77]
const BASIC_INTERVALS = Weapons.STARTER_INTERVAL
const BASIC_POWER = Weapons.STARTER_DAMAGE
const CURRENT_LAYOUT = 2
const BOSS_HEALTH_MULTIPLIER := 5
const NEXT_FLOOR = "next_floor"
const HUNT_TIME = 20.0

var screen = "garden"
var preferences = Preferences.new()
var menu_motion = MenuMotion.new()
var hero = 0
var run_seed = 0
var run_id = ""
var profile = RunProfile.new()
var pending_result: Dictionary = {}
var last_result: Dictionary = {}
var depth = 0
var hp = 0
var resource = 0
var petals = 0
var bonus = 0
var route = 0
var player = ENTRY
var facing = Vector2.UP
var foes: Array = []
var bolts: Array = []
var attack_time = 0.0
var dodge_time = 0.0
var mercy = 0.0
var skill_time = 0.0
var abilities = HeroAbilities.new()
var ultimates = HeroUltimates.new()
var combat_status = CombatStatuses.new()
var talents := RunTalents.new()
var upgrades := RunUpgrades.new()
var acquired_upgrade_id := ""
var snare_thread := SnareThread.new()
var relics = Relics.new()
var curses := RunCurses.new()
var cap_board := CapBoard.new()
var arcade := ArcadeSession.new()
var arcade_backgrounded := false
var endless = EndlessRules.new()
var sound = GardenSoundstage.new()
var jukebox := GardenJukebox.new()
var boss_victory := BossVictory.new()
var selected_relic = ""
var selected_starting_item := ""
var seed_shop_feedback := ""
var seed_shop_shelf := SeedShop.Shelf.ITEMS
var seed_shop_page := 0
var seed_shop_focus := ""
var seed_shop_return_screen := "garden_hub"
var run_history: Array = []
var history_page := 0
var history_selected := 0
var relic_foe_serial = 0
var dash_evaded = false
var flash = 0.0
var attack_visual_facing := Vector2.DOWN
var lily_repeat_visual := false
var lily_repeat: Dictionary = {}
var _encounter_damage_scale := 1.0
var save_time = 0.0
var joystick_id = -1
var joystick_origin: Vector2 = Vector2.ZERO
var elite_heal_drops: Array[Dictionary] = []
var stick = Vector2.ZERO
var aim_touch_id := -1
var aim_action := ""
var aim_started := 0.0
var aim_mouse := false
var run_paused: bool = false
var confirm_end_run: bool = false
var garden_seeds = 0
var run_time = 0.0
var last_outcome = ""
var visual_clock = 0.0
var visual_velocity = Vector2.ZERO
var walk_distance = 0.0
var dash_vector = Vector2.ZERO
var dash_remaining = 0.0
var damage_flash = 0.0
var barrels: Array[Vector2] = []
var active_biome = 0
var room_generation = 0
var room_title = ""
var room_template = ""
var ground_hazards = GardenGroundHazards.new()
var clockwork_floor = ClockworkFloor.new()
var lily_combo = 0
var lily_combo_time = 0.0
var lily_finisher_flash = false
var floor_index = -1
var floor_manifest: Dictionary = {}
var room_id = ""
var room_kind = "combat"
var room_exits: Dictionary = {}
var room_complete = false
var room_clock = 0.0
const ROOM_ARRIVAL = 0.62
var room_arrival = 0.0
var pocket := RunItems.new()
var merchant := GardenMerchant.new()
var armory := RunArmory.new()
var painted_evolution := PaintedEvolution.new()
var armory_hero := 0
var armory_entry := 0
var selected_weapon := ""
var reward_weapon_id := ""
var route_history: Array[String] = []
var chest_position = CHEST
var pending_chest = false
var reward_relic_id = ""
var feather_crown_left := 0.0
var honest_eyes_ready := false
var brasswing_pin_left := 0.0
var second_chance_used := false
var princes_pin_used := false
var velvet_ribbon_used := false
var velvet_ribbon_left := 0.0
var twin_moon_hits := 0
var twin_moon_sequences: Array[int] = []
var chest_open_time = 0.0
var world_image: TextureRect
var world_canvas: Node2D
var codex = Codex.new()
var codex_biome = 0
var codex_kind = 0
var relic_ledger_return := "codex"
var relic_ledger_carried: Array[String] = []
var relic_ledger_page := 0
var relic_ledger_entry := 0
var relic_ledger_tab := 0

func _ready() -> void:
	combat_status.bind(self)
	ground_hazards.bind_combat_status(combat_status)
	preferences.load_local()
	codex.load_local()
	setup_world_canvas()
	add_child(sound)
	add_child(jukebox)
	get_tree().set_auto_accept_quit(false)
	apply_audio_preferences()
	var profile_error = profile.load_local()
	if profile_error != OK:
		push_warning("Could not load the Garden profile: " + error_string(profile_error))
	garden_seeds = profile.garden_seeds
	recover_terminal_result(RunProfile.read_json(SAVE))
	var past_relics: Array = []
	for record: Variant in profile.history():
		if record is Dictionary and record.get("relics") is Array:
			past_relics.append_array(record.relics)
	codex.observe_relics(past_relics)

func apply_audio_preferences() -> void:
	sound.music_enabled = preferences.music_enabled
	sound.effects_enabled = preferences.effects_enabled

func setup_world_canvas() -> void:
	var viewport = SubViewport.new()
	viewport.size = Vector2i(View.CANVAS.size)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	viewport.name = "Battlefield"
	add_child(viewport)
	world_canvas = Node2D.new()
	world_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(world_canvas)
	world_canvas.draw.connect(draw_world)

	world_image = TextureRect.new()
	world_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_image.size = View.CANVAS.size
	world_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_image.texture = viewport.get_texture()
	world_image.z_index = -1
	world_image.hide()
	add_child(world_image)

func start_run(legacy := false) -> void:
	if not pending_result.is_empty() and not flush_finalization():
		return
	reset_run_input()
	var weapon := "" if legacy else prepared_weapon()
	armory.reset(hero, weapon)
	selected_weapon = ""
	run_id = RunProfile.fresh_run_id()
	relics.reset()
	twin_moon_hits = 0
	feather_crown_left = 0.0
	honest_eyes_ready = false
	brasswing_pin_left = 0.0
	curses.restore()
	combat_status.reset()
	talents.reset()
	upgrades.reset()
	var starting_item := selected_starting_item if not legacy and profile.has_unlock(selected_starting_item) else ""
	pocket.restore(starting_item)
	selected_starting_item = ""
	if not legacy and selected_relic in Prep.relic_options(hero):
		relics.equip(selected_relic)
	selected_relic = ""
	run_seed = randi()
	depth = 0
	hp = HEALTH[hero]
	resource = 0
	skill_time = 0.0
	petals = 0
	bonus = 0
	route = 0
	run_time = 0.0
	floor_index = -1 if legacy else 0
	floor_manifest.clear()
	route_history.clear()
	room_id = ""
	if floor_index >= 0:
		load_floor()
	enter_room()

func load_floor() -> void:
	floor_manifest = Dungeon.generate_floor(run_seed, floor_index)
	Dungeon.add_optional_boss_route(floor_manifest, run_seed, OptionalBosses.NAMES.keys())
	room_id = floor_manifest.entrance_id
	route = 0

func enter_room() -> void:
	twin_moon_sequences.clear()
	second_chance_used = false
	princes_pin_used = false
	velvet_ribbon_used = false
	velvet_ribbon_left = 0.0
	var room = current_room()
	acquired_upgrade_id = ""
	boss_victory.reset()
	merchant.reset()
	armory.enter_room()
	painted_evolution.reset()
	talents.enter_room()
	snare_thread.reset()
	reset_aim_preview()
	room_generation = room.version
	set_room_props(room)
	RoomEvents.bind_card(self)
	cap_board.reset()
	arcade.reset()
	curses.bind_altar(self)
	lily_combo = 0
	lily_combo_time = 0.0
	lily_finisher_flash = false
	lily_repeat.clear()
	lily_repeat_visual = false
	flash = 0.0
	abilities.reset()
	ultimates.reset()
	player = room.entry
	room_complete = floor_index >= 0 and room_kind == "transition"
	room_clock = 0.0
	pending_chest = floor_index >= 0 and room_kind == "treasure"
	reward_relic_id = RelicSources.treasure_offer(floor_index, hero, relics.owned) if pending_chest else ""
	reward_weapon_id = reward_weapon_offer() if pending_chest and reward_relic_id.is_empty() else ""
	chest_open_time = 0.0
	foes.clear()
	bolts.clear()
	elite_heal_drops.clear()
	mercy = 0.7
	dash_remaining = 0.0
	dash_evaded = false
	relic_foe_serial = 0
	visual_velocity = Vector2.ZERO
	var side_boss := optional_arena_boss()
	var approach := optional_approach()
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
		if active_biome == ForestPalace.PALACE and kind == ForestPalace.PORCELAIN_HOUND:
			foe.hound_side = 1 if int(room.encounter_seed) % 2 == 0 else -1
		endless.mark_foe(foe, index, room_kind)
		foes.append(foe)
	room_arrival = ROOM_ARRIVAL if not foes.is_empty() else 0.0
	resource = mini(HeroUltimates.CHARGE, resource + upgrades.enter_room(not foes.is_empty()))
	curses.enter_hostile_room(self)
	codex.observe(foes)
	if boss:
		sound.play("boss_enter")
	screen = "fight"
	if floor_index >= 0:
		route_history.append(room_id)
	checkpoint()

func current_room() -> Dictionary:
	if floor_index < 0:
		return Dungeon.legacy_room(run_seed, depth, route)
	return Dungeon.generate_room(run_seed, floor_manifest, room_id)

func optional_arena_boss() -> String:
	var node: Dictionary = floor_manifest.get("nodes", {}).get(room_id, {})
	return str(node.get("optional_boss", "")) if int(node.get("optional_stage", -1)) == 2 else ""

func optional_approach() -> Array:
	var node: Dictionary = floor_manifest.get("nodes", {}).get(room_id, {})
	var stage := int(node.get("optional_stage", -1))
	var lessons: Array = OptionalBosses.APPROACHES.get(node.get("optional_boss", ""), [])
	return lessons[stage] if stage >= 0 and stage < lessons.size() else []

func set_room_props(room: Dictionary) -> void:
	active_biome = int(room.biome)
	room_title = room.display_name
	var side_boss := optional_arena_boss()
	if OptionalBosses.NAMES.has(side_boss):
		room_title = OptionalBosses.NAMES[side_boss]
	var approach := optional_approach()
	if not approach.is_empty():
		room_title = approach[0]
	room_template = room.template_id
	ground_hazards.setup(room)
	clockwork_floor.setup(room)
	if floor_index < 0 or not side_boss.is_empty():
		ground_hazards.patches.clear()
		clockwork_floor.mode = ""
	room_kind = room.kind
	room_exits = room.exit_positions.duplicate()
	if floor_index >= 0 and room_kind == "boss":
		room_exits[NEXT_FLOOR] = Vector2(432, Dungeon.EXIT_Y)
	chest_position = room.reward
	barrels.assign(room.cover)
	if not approach.is_empty() or side_boss in [OptionalBosses.MOTHER, OptionalBosses.BRASSWING]:
		barrels.clear()
	elif side_boss == OptionalBosses.SCARECROW:
		barrels.clear()
		var broken := int(floor_manifest.nodes[room_id].get("broken_hay", 0))
		for index in range(OptionalBosses.HAY_POSTS.size()):
			if (broken & (1 << index)) == 0:
				barrels.append(OptionalBosses.HAY_POSTS[index])
	EndlessRules.configure_floor(floor_manifest, run_seed)
	endless.begin_room(floor_manifest, int(room.encounter_seed))

func restore_early_room() -> void:
	endless.begin_room({}, 0)
	barrels.clear()
	chest_position = CHEST
	active_biome = mini(int(depth / 4), 7)
	room_title = ""
	room_template = ""
	room_kind = "boss" if depth % 4 == 3 else "combat"
	room_exits.clear()
	if depth < 4:
		barrels.append(Vector2(127, 161 + 18 * (depth % 2)))
		barrels.append(Vector2(654 - 28 * (depth % 3), 283))
		if route == 1:
			barrels.append(Vector2(264, 231))

func checkpoint() -> void:
	if not pending_result.is_empty():
		flush_finalization()
		return
	if screen not in ACTIVE_RUN_SCREENS:
		return
	if run_id.is_empty():
		run_id = RunProfile.legacy_run_id(run_seed, hero)
	var snapshot = {"layout": CURRENT_LAYOUT, "room_generation": room_generation, "screen": screen, "hero": hero,
		"run_id": run_id, "seed": run_seed, "depth": depth, "hp": hp,
		"resource": resource, "petals": petals, "bonus": bonus, "route": route, "x": player.x, "y": player.y, "foes": foes, "bolts": bolts,
		"elite_heal_drops": elite_heal_drops,
		"feather_crown_left": feather_crown_left,
		"honest_eyes_ready": honest_eyes_ready,
		"brasswing_pin_left": brasswing_pin_left,
		"second_chance_used": second_chance_used,
		"princes_pin_used": princes_pin_used,
		"velvet_ribbon_used": velvet_ribbon_used, "velvet_ribbon_left": velvet_ribbon_left,
		"twin_moon_hits": twin_moon_hits, "twin_moon_sequences": twin_moon_sequences,
		"attack_time": attack_time, "dodge_time": dodge_time, "mercy": mercy,
		"pending_chest": pending_chest, "chest_open_time": chest_open_time, "reward_relic_id": reward_relic_id,
		"floor_index": floor_index, "floor_manifest": floor_manifest, "room_id": room_id,
		"room_complete": room_complete, "room_clock": room_clock, "room_arrival": room_arrival, "route_history": route_history,
		"boss_victory": boss_victory.snapshot(),
		"pocket_item": pocket.held, "pocket_haste": pocket.haste,
		"armory": armory.snapshot(), "reward_weapon_id": reward_weapon_id,
		"painted_evolution": painted_evolution.snapshot(),
		"merchant": merchant.snapshot(),
		"curses": curses.snapshot(),
		"endless_state": endless.snapshot(),
		"ground_hazards": ground_hazards.patches, "ground_snare": ground_hazards.snare_time,
		"combat_status": combat_status.snapshot(),
		"talents": talents.snapshot(),
		"run_upgrades": upgrades.snapshot(),
		"arcade": arcade.snapshot(),
		"snare_thread": snare_thread.snapshot(),
		"clockwork_floor": clockwork_floor.snapshot(),
		"lily_combo": lily_combo, "lily_combo_time": lily_combo_time,
		"lily_repeat": lily_repeat.duplicate(),
		"relics": relics.snapshot(), "relic_foe_serial": relic_foe_serial, "dash_evaded": dash_evaded,
		"facing": [facing.x, facing.y], "dash": [dash_vector.x, dash_vector.y, dash_remaining],
		"skill_time": skill_time, "abilities": abilities.snapshot(), "ultimates": ultimates.snapshot(), "run_time": run_time}
	if RunProfile.write_json(SAVE, snapshot) == OK:
		codex.observe_weapon(armory.for_hero(hero))
		codex.observe_relics(relics.owned)

func resume_run() -> void:
	if not pending_result.is_empty():
		flush_finalization()
		return
	var state = RunProfile.read_json(SAVE)
	if not state.has("screen") or recover_terminal_result(state):
		return
	var saved_floor_index = int(state.get("floor_index", -1))
	var saved_manifest: Variant = state.get("floor_manifest", {})
	var saved_room_id = str(state.get("room_id", ""))
	if saved_floor_index >= 0 and (
			not saved_manifest is Dictionary or not saved_manifest.has("nodes")
			or not saved_manifest.nodes.has(saved_room_id)):
		push_warning("Cannot resume: the active dungeon route is missing from the save.")
		return
	reset_run_input()
	floor_index = saved_floor_index
	floor_manifest = saved_manifest if floor_index >= 0 else {}
	room_id = saved_room_id if floor_index >= 0 else ""
	route_history.assign(state.get("route_history", []))
	room_complete = bool(state.get("room_complete", false))
	room_clock = float(state.get("room_clock", 0.0))
	room_arrival = clampf(float(state.get("room_arrival", 0.0)), 0.0, ROOM_ARRIVAL)
	elite_heal_drops.clear()
	var saved_drops: Variant = state.get("elite_heal_drops", [])
	if saved_drops is Array:
		for drop in saved_drops:
			if drop is Dictionary and drop.has_all(["x", "y"]):
				elite_heal_drops.append({"x": float(drop.x), "y": float(drop.y)})
	boss_victory.restore(state.get("boss_victory"))
	pocket.restore(str(state.get("pocket_item", "")), float(state.get("pocket_haste", 0.0)))
	merchant.restore(state.get("merchant"))
	curses.restore(state.get("curses"))
	screen = state.screen
	hero = int(state.hero)
	acquired_upgrade_id = ""
	upgrades.restore(state.get("run_upgrades"), hero)
	restore_lily_repeat(state.get("lily_repeat"))
	talents.restore(hero, state.get("talents"))
	arcade.reset()
	if screen == "minigame":
		arcade.restore(state.get("arcade"), state.get("cap_board"), cap_board)
		if arcade.id.is_empty():
			# A damaged minigame state returns to the paid encounter without a second stake.
			room_complete = true
			screen = "fight"
	snare_thread.restore(state.get("snare_thread"))
	armory.restore(hero, state.get("armory"))
	painted_evolution.restore(state.get("painted_evolution"))
	codex.observe_weapon(armory.for_hero(hero))
	reward_weapon_id = str(state.get("reward_weapon_id", ""))
	if not Weapons.DEFINITIONS.has(reward_weapon_id) or not Weapons.usable_by(reward_weapon_id, hero) \
			or reward_weapon_id == armory.for_hero(hero):
		reward_weapon_id = ""
	run_seed = int(state.seed)
	run_id = str(state.get("run_id", ""))
	if run_id.is_empty():
		run_id = RunProfile.legacy_run_id(run_seed, hero)
	depth = int(state.depth)
	hp = int(state.hp)
	resource = int(state.resource)
	petals = int(state.petals)
	bonus = int(state.bonus)
	route = int(state.get("route", 0))
	player = Vector2(state.x, state.y)
	room_generation = int(state.get("room_generation", 0))
	if room_generation > 0:
		set_room_props(current_room())
	else:
		restore_early_room()
	endless.restore(state.get("endless_state", {}))
	ground_hazards.restore(state.get("ground_hazards", state.get("thorn_patches")), float(state.get("ground_snare", 0.0)))
	clockwork_floor.restore(state.get("clockwork_floor"), barrels)
	lily_combo = clampi(int(state.get("lily_combo", 0)), 0, 2)
	lily_combo_time = maxf(0.0, float(state.get("lily_combo_time", 0.0)))
	pending_chest = bool(state.get("pending_chest", false))
	chest_open_time = float(state.get("chest_open_time", 0.0))
	foes = state.foes
	for foe: Dictionary in foes:
		if foe.get("boss", false):
			restore_boss_health(foe)
	combat_status.restore(state.get("combat_status"))
	combat_status.restore_foes(foes)
	bolts = state.get("bolts", [])
	for bolt: Dictionary in bolts:
		if bolt.has("hit_foes"):
			bolt.hit_foes = bolt.hit_foes.map(func(id): return int(id))
	attack_time = state.get("attack_time", 0.0)
	dodge_time = state.get("dodge_time", 0.0)
	mercy = state.get("mercy", 0.0)
	skill_time = state.get("skill_time", 0.0)
	feather_crown_left = clampf(float(state.get("feather_crown_left", 0.0)), 0.0, 1.0)
	honest_eyes_ready = bool(state.get("honest_eyes_ready", false))
	brasswing_pin_left = clampf(float(state.get("brasswing_pin_left", 0.0)), 0.0, 2.0)
	second_chance_used = bool(state.get("second_chance_used", false))
	princes_pin_used = bool(state.get("princes_pin_used", false))
	velvet_ribbon_used = bool(state.get("velvet_ribbon_used", false))
	velvet_ribbon_left = clampf(float(state.get("velvet_ribbon_left", 0.0)), 0.0, 2.0)
	twin_moon_hits = posmod(int(state.get("twin_moon_hits", 0)), 4)
	twin_moon_sequences.clear()
	var saved_sequences: Variant = state.get("twin_moon_sequences", [])
	if saved_sequences is Array:
		for saved_sequence in saved_sequences:
			twin_moon_sequences.append(int(saved_sequence))
	if not relics.restore(state.get("relics", {})):
		relics.reset()
	codex.observe_relics(relics.owned)
	reward_relic_id = str(state.get("reward_relic_id", ""))
	if not state.has("reward_relic_id") and floor_index >= 0 and room_kind == "boss" and (pending_chest or screen == "reward"):
		reward_relic_id = boss_relic_offer()
	if not RelicSources.can_offer(reward_relic_id, hero) or relics.has_relic(reward_relic_id):
		reward_relic_id = ""
	if screen == "reward" or chest_open_time > 0.0:
		prepare_reward_upgrades(not state.has("run_upgrades"))
	relic_foe_serial = int(state.get("relic_foe_serial", 0))
	dash_evaded = bool(state.get("dash_evaded", false))
	var saved_abilities: Variant = state.get("abilities", {})
	abilities.restore(saved_abilities if saved_abilities is Dictionary else {})
	ultimates.restore(state.get("ultimates", {}))
	run_time = state.get("run_time", 0.0)
	var direction = state.get("facing", [0.0, -1.0])
	facing = Vector2(direction[0], direction[1])
	var dash = state.get("dash", [0.0, 0.0, 0.0])
	dash_vector = Vector2(dash[0], dash[1])
	dash_remaining = float(dash[2])
	if int(state.get("layout", 1)) < CURRENT_LAYOUT:
		player = migrate_position(player)
		for i in range(foes.size()):
			var foe: Dictionary = foes[i]
			var spot = migrate_position(target(foe))
			var warned = migrate_position(Vector2(foe.tx, foe.ty))
			foe.merge({"x": spot.x, "y": spot.y, "tx": warned.x, "ty": warned.y,
				"kind": 3 if foe.boss else (i + depth) % 3}, true)
		for bolt in bolts:
			var spot = migrate_position(target(bolt))
			bolt.x = spot.x
			bolt.y = spot.y

func migrate_position(old: Vector2) -> Vector2:
	var u = clampf(inverse_lerp(40, 350, old.x), 0.0, 1.0)
	var v = clampf(inverse_lerp(184, 624, old.y), 0.0, 1.0)
	return clamp_position(ARENA.position + Vector2(u, v) * ARENA.size)

func finish_run(outcome: String, result := "defeat") -> void:
	if screen == "summary" and pending_result.is_empty():
		return
	if pending_result.is_empty():
		if run_id.is_empty():
			run_id = RunProfile.legacy_run_id(run_seed, hero)
		var reached_endless = floor_index >= Dungeon.BIOME_COUNT if floor_index >= 0 else depth >= 28
		pending_result = {
			"run_id": run_id, "seed": run_seed, "result": result, "outcome": outcome,
			"cause": {"defeat": "hp_depleted", "ended": "player_ended"}.get(result, ""), "hero": hero,
			"hero_name": NAMES[hero], "room": room_id, "room_title": room_title,
			"depth": depth, "floor_index": floor_index if floor_index >= 0 else depth >> 2,
			"biome": active_biome, "reached_endless": reached_endless,
			"campaign_cleared": result == "clear" or reached_endless,
			"elapsed_seconds": run_time, "finished_at": int(Time.get_unix_time_from_system()),
			"petals": petals, "damage_bonus": bonus, "relics": relics.owned.duplicate(), "pocket_item": pocket.held,
			"curses": curses.snapshot(),
			"weapon_id": armory.for_hero(hero),
			"seeds_earned": 1 + depth,
		}
	flush_finalization()

func recover_terminal_result(state: Dictionary) -> bool:
	if state.get("screen", "") != RunProfile.FINALIZING:
		return false
	var result: Variant = state.get("summary")
	if result is Dictionary and RunProfile.valid_summary(result) and state.get("run_id", "") == result.run_id:
		pending_result = result
		flush_finalization()
	else:
		push_warning("The saved Garden run result is incomplete.")
	return true

func flush_finalization() -> bool:
	if pending_result.is_empty():
		return true
	sound.summary_clear = pending_result.get("result", "") == "clear"
	if screen != "summary" and pending_result.get("result", "") == "defeat":
		sound.play("fall")
	reset_run_input()
	screen = "summary"
	var error = RunProfile.stage_result(SAVE, pending_result)
	if error == OK:
		error = profile.finish_staged(SAVE)
	garden_seeds = profile.garden_seeds
	if error != OK:
		last_outcome = "Run result awaiting save"
		push_warning("Could not finalize the Garden run: " + error_string(error))
		return false
	last_outcome = str(pending_result.get("outcome", "Run finished"))
	hero = int(pending_result.get("hero", hero))
	run_id = str(pending_result.run_id)
	depth = int(pending_result.get("depth", depth))
	run_time = float(pending_result.get("elapsed_seconds", run_time))
	last_result = pending_result.duplicate(true)
	pending_result.clear()
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		arcade_backgrounded = true
		reset_joystick()
		checkpoint()
	if what == NOTIFICATION_APPLICATION_RESUMED:
		arcade_backgrounded = false
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset_joystick()
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not sound.shutting_down:
		checkpoint()
		jukebox.stop()
		sound.shutdown()
		# Godot's audio server retires stopped streams on the mix thread.
		get_tree().create_timer(0.15).timeout.connect(func(): get_tree().quit())

func touch_position(default_position: Vector2) -> Vector2:
	return preferences.touch_point(default_position, View.CANVAS.size.x)

func update_stick(point: Vector2) -> void:
	var offset := point - joystick_origin
	var length := offset.length()
	var strength := clampf(inverse_lerp(JOYSTICK_DEADZONE, JOYSTICK_TRAVEL, length), 0.0, 1.0)
	strength = pow(strength, 0.85)
	stick = offset.normalized() * strength

func reset_joystick() -> void:
	joystick_id = -1
	joystick_origin = Vector2.ZERO
	stick = Vector2.ZERO

func reset_run_input() -> void:
	reset_joystick()
	reset_aim_preview()
	run_paused = false
	confirm_end_run = false

func in_movement_region(point: Vector2) -> bool:
	var center_x := View.CANVAS.get_center().x
	return View.CANVAS.has_point(point) and point.y >= View.ROOM_ART.position.y + 2.0 \
		and (point.x >= center_x if preferences.left_handed else point.x < center_x)

func press_screen_touch(index: int, point: Vector2) -> void:
	aim_mouse = false
	var action := preview_button_at(point)
	if not action.is_empty():
		if aim_touch_id < 0:
			aim_touch_id = index
			aim_action = action
			aim_started = visual_clock
		return
	var can_capture: bool = screen == "fight" and not run_paused and joystick_id < 0 and in_movement_region(point)
	var old_depth := int(depth)
	var old_chest_time := float(chest_open_time)
	tap(point)
	# A nearby interactable or door can use a press anywhere in its visible hitbox.
	if can_capture and screen == "fight" and not run_paused and depth == old_depth and chest_open_time == old_chest_time:
		joystick_id = index
		joystick_origin = point
		stick = Vector2.ZERO

func preview_button_at(point: Vector2, radius := 27.0) -> String:
	if hero not in [1, 3] or screen != "fight" or run_paused or room_complete or pending_chest or ultimates.locks_movement():
		return ""
	if hero == 1 and skill_time <= 0.0 and dash_remaining <= 0.0 and not abilities.locks_movement() and point.distance_to(touch_position(SKILL)) < radius:
		return "skill"
	if ultimate_ready() and point.distance_to(touch_position(ULTIMATE)) < radius:
		return "ultimate"
	return ""

func reset_aim_preview() -> void:
	aim_touch_id = -1
	aim_action = ""
	aim_mouse = false

func release_aim_touch(point: Vector2, canceled: bool) -> void:
	var requested := aim_action
	reset_aim_preview()
	if not canceled and preview_button_at(point, 34.0) == requested:
		act(requested)

func preview_action() -> String:
	if aim_touch_id >= 0 and visual_clock - aim_started >= 0.14:
		var control := SKILL if aim_action == "skill" else ULTIMATE
		return preview_button_at(touch_position(control))
	return preview_button_at(get_local_mouse_position()) if aim_mouse else ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			press_screen_touch(event.index, event.position)
		elif event.index == aim_touch_id:
			release_aim_touch(event.position, event.canceled)
		elif event.index == joystick_id:
			reset_joystick()
	elif event is InputEventScreenDrag and event.index == joystick_id:
		update_stick(event.position)
	elif event is InputEventMouseMotion:
		aim_mouse = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if screen == "arcade_practice" and event.keycode == KEY_ESCAPE:
			arcade.settle(self)
			return
		if screen in ["minigame", "arcade_practice"] and not run_paused and event.keycode != KEY_ESCAPE:
			if event.keycode in [KEY_ENTER, KEY_KP_ENTER] and arcade.outcome != ArcadeSession.PLAYING:
				arcade.settle(self)
			else:
				arcade.key(self, event.keycode)
			return
		match event.keycode:
			KEY_J: act("attack")
			KEY_K: act("dodge")
			KEY_L: act("skill")
			KEY_U: act("ultimate")
			KEY_I: use_pocket()
			KEY_E: interact()
			KEY_ESCAPE:
				if confirm_end_run:
					cancel_end_run()
				elif run_paused:
					unpause_run()
				elif screen == "reward" and View.Reward.relic_preview_open(self):
					menu_motion.reward_relic_preview = ""
					sound.play("cancel")
				elif screen in ACTIVE_RUN_SCREENS:
					suspend_run()
				elif screen == "armory":
					screen = "codex"
				elif screen == "relic_ledger":
					screen = relic_ledger_return
					sound.play("cancel")
				elif screen == "settings":
					screen = "garden"
				elif screen == "seed_shop":
					screen = seed_shop_return_screen
				elif screen in ["run_history", "garden_arcade", "jukebox"]:
					screen = "garden_hub"

func tap(pos: Vector2) -> void:
	var previous_screen = screen
	var previous_hero = hero
	var previous_relic = selected_relic
	var previous_item = selected_starting_item
	var previous_biome = codex_biome
	var previous_entry = codex_kind
	handle_tap(pos)
	if previous_screen != screen and previous_screen not in ["fight", "reward"]:
		sound.play("confirm")
	elif (previous_hero != hero or previous_relic != selected_relic or previous_item != selected_starting_item
		or previous_biome != codex_biome or previous_entry != codex_kind):
		sound.play("ui")

func handle_tap(pos: Vector2) -> void:
	if run_paused:
		menu_motion.record_press(pause_menu_screen(), pos)
		PauseView.activate(self, pos)
		return
	if screen in ACTIVE_RUN_SCREENS and View.PAUSE.has_point(pos):
		suspend_run()
		return
	if screen != "fight":
		menu_motion.record_press(screen, pos)
	match screen:
		"garden":
			if View.CONTINUE.has_point(pos):
				if FileAccess.file_exists(SAVE):
					resume_run()
				else:
					screen = "roster"
			elif View.GARDEN_LINK.has_point(pos):
				screen = "garden_hub"
			elif View.SETTINGS_LINK.has_point(pos):
				screen = "settings"
		"settings":
			if SettingsView.activate(self, pos):
				screen = "garden"
		"garden_hub":
			match Hub.action_at(pos):
				"title":
					screen = "garden"
				"roster":
					if FileAccess.file_exists(SAVE):
						resume_run()
					else:
						screen = "roster"
				"codex":
					screen = "codex"
				"seeds":
					open_seed_shop()
				"games":
					screen = "garden_arcade"
				"jukebox":
					screen = "jukebox"
				"history":
					run_history = profile.history().filter(func(record):
						return record is Dictionary and RunProfile.valid_summary(record))
					history_page = 0
					history_selected = 0
					screen = "run_history"
				_:
					Hub.react_at(self, pos)
		"seed_shop":
			if SeedShop.activate(self, pos):
				screen = seed_shop_return_screen
		"run_history":
			if HistoryView.activate(self, pos):
				screen = "garden_hub"
		"garden_arcade":
			ArcadeView.select(self, pos)
		"jukebox":
			jukebox.tap(self, pos)
		"codex":
			if CodexView.BACK.has_point(pos):
				screen = "garden_hub"
			elif CodexView.RELICS.has_point(pos):
				open_relic_ledger()
			elif CodexView.WEAPONS.has_point(pos):
				armory_hero = hero
				armory_entry = 0
				screen = "armory"
			elif CodexView.BIOME_PREV.has_point(pos) and codex_biome > 0:
				codex_biome -= 1
				codex_kind = 0
			elif CodexView.BIOME_NEXT.has_point(pos) and codex_biome < Dungeon.BIOME_COUNT - 1:
				codex_biome += 1
				codex_kind = 0
			else:
				var entry = CodexView.entry_at(pos, codex.entries(codex_biome).size())
				if entry >= 0 and entry < codex.entries(codex_biome).size():
					codex_kind = entry
		"armory":
			ArmoryView.tap(self, pos)
		"relic_ledger":
			RelicLedger.tap(self, pos)
		"roster":
			if FileAccess.file_exists(SAVE):
				if View.ROSTER_BACK.has_point(pos):
					screen = "garden"
				else:
					resume_run()
				return
			for i in range(NAMES.size()):
				if View.roster_hit(i).has_point(pos):
					if hero != i:
						selected_weapon = ""
					hero = i
					return
			if View.ROSTER_BACK.has_point(pos):
				screen = "garden"
			elif View.DESCEND.has_point(pos):
				screen = "preparation"
		"preparation":
			if Prep.BACK.has_point(pos):
				screen = "roster"
			elif Prep.RELIC_LEDGER.has_point(pos):
				open_relic_ledger()
			elif FileAccess.file_exists(SAVE):
				resume_run()
			elif Prep.ENTER.has_point(pos):
				start_run()
			elif Prep.WEAPON_NEXT.has_point(pos):
				var options := starting_weapon_options()
				selected_weapon = options[(options.find(prepared_weapon()) + 1) % options.size()]
			elif Prep.CLEAR.has_point(pos) and not selected_relic.is_empty():
				selected_relic = ""
			elif Prep.STARTING_POCKET.has_point(pos):
				selected_starting_item = Prep.next_starting_item(self)
			else:
				var relic_id := Prep.relic_at(pos, hero)
				if not relic_id.is_empty():
					selected_relic = relic_id
		"fight":
			if optional_arena_boss() == OptionalBosses.CHOIR and OptionalBosses.mute_choir_bell(self, pos):
				return
			elif optional_arena_boss() == OptionalBosses.VELVET and OptionalBosses.sever_velvet_string(self, pos):
				return
			elif (pending_chest or uses_room_choice()) and Rect2(chest_position + Vector2(-39, -69), Vector2(78, 89)).has_point(pos):
				interact()
			elif click_room_exit(pos):
				return
			elif pos.distance_to(touch_position(ATTACK)) < 32:
				act("attack")
			elif pos.distance_to(touch_position(DODGE)) < 25:
				act("dodge")
			elif pos.distance_to(touch_position(SKILL)) < 27:
				act("skill")
			elif pos.distance_to(touch_position(ULTIMATE)) < 27:
				act("ultimate")
			elif pos.distance_to(touch_position(POCKET)) < 25:
				use_pocket()
		"reward":
			if View.Reward.relic_preview_open(self):
				if View.Reward.RELIC_BACK.has_point(pos):
					menu_motion.reward_relic_preview = ""
					sound.play("cancel")
				elif View.Reward.RELIC_EQUIP.has_point(pos) and relics.equip(reward_relic_id):
					finish_reward(route)
				return
			var offers_relic = not reward_relic_id.is_empty()
			var offers_weapon = not reward_weapon_id.is_empty()
			var consumable = pocket.offer(self)
			var offered := reward_upgrade_offers()
			var third = offers_relic or offers_weapon or not consumable.is_empty() or offered.size() > 1
			if View.Reward.tea_rect(third).has_point(pos):
				if reward_has_tea():
					var heal := reward_healing()
					if heal <= 0:
						return
					hp += heal
				else:
					var charge := reward_resource_gain()
					if charge <= 0:
						return
					resource += charge
				finish_reward(0)
			else:
				for index in range(offered.size()):
					if View.Reward.upgrade_rect(index, third).has_point(pos):
						take_reward_upgrade(offered[index])
						return
				if View.Reward.RELIC_RECT.has_point(pos):
					if offers_relic:
						menu_motion.reward_relic_preview = reward_relic_id
						sound.play("ui")
					elif offers_weapon and equip_weapon(reward_weapon_id):
						finish_reward(route)
					elif not consumable.is_empty() and pocket.take(consumable):
						finish_reward(route)
		"room_choice":
			resolve_room_choice(pos)
		"minigame", "arcade_practice":
			ArcadeView.tap_round(self, pos)
		"talent":
			TalentView.tap(self, pos)
		"forge":
			ForgeView.tap(self, pos)
		"clear":
			if View.FIRST_OPTION.has_point(pos):
				if floor_index < 0:
					advance()
				else:
					next_floor()
			elif View.SECOND_OPTION.has_point(pos):
				suspend_run()
				request_end_run()
		"summary":
			if View.SECOND_OPTION.has_point(pos) and flush_finalization():
				screen = "garden_hub"

func open_seed_shop(shelf: int = SeedShop.Shelf.ITEMS, focus_offer: String = "") -> void:
	if screen != "seed_shop":
		seed_shop_return_screen = screen
	var profile_error: Error = profile.load_local()
	garden_seeds = profile.garden_seeds
	seed_shop_feedback = "" if profile_error == OK else "seed_shop.profile_error"
	seed_shop_shelf = clampi(shelf, SeedShop.Shelf.ITEMS, SeedShop.Shelf.MEDIA)
	seed_shop_page = SeedShop.page_of(seed_shop_shelf, focus_offer)
	seed_shop_focus = focus_offer
	screen = "seed_shop"

func purchase_seed_offer(unlock_id: String) -> void:
	if unlock_id.is_empty():
		return
	if unlock_id in RunProfile.STARTING_WEAPONS and codex.knows_weapon(unlock_id):
		seed_shop_feedback = "seed_shop.already_owned"
		return
	var purchase: Error = profile.purchase_unlock(unlock_id)
	garden_seeds = profile.garden_seeds
	match purchase:
		OK:
			seed_shop_feedback = "seed_shop.item_success"
			if unlock_id == RunProfile.FOUNTAIN_LANTERNS:
				seed_shop_feedback = "seed_shop.lantern_success"
			elif unlock_id in RunProfile.GARDEN_DECORATIONS:
				seed_shop_feedback = "seed_shop.decoration_success"
			elif unlock_id in RunProfile.STARTING_WEAPONS:
				seed_shop_feedback = "seed_shop.weapon_success"
			elif unlock_id == GardenMedia.CONSOLE:
				seed_shop_feedback = "seed_shop.console_success"
			elif unlock_id == GardenMedia.JUKEBOX:
				seed_shop_feedback = "seed_shop.jukebox_success"
			elif unlock_id in GardenMedia.CARTRIDGES:
				seed_shop_feedback = "seed_shop.cartridge_success"
			elif unlock_id in GardenMedia.TAPES:
				seed_shop_feedback = "seed_shop.vhs_success"
			sound.play("reward")
		ERR_ALREADY_EXISTS:
			seed_shop_feedback = "seed_shop.already_owned"
		ERR_CANT_ACQUIRE_RESOURCE:
			seed_shop_feedback = "seed_shop.need_seeds"
		_:
			seed_shop_feedback = "seed_shop.save_error"

func suspend_run() -> void:
	if run_paused or screen not in ACTIVE_RUN_SCREENS:
		return
	sound.play("cancel")
	reset_joystick()
	reset_aim_preview()
	run_paused = true
	checkpoint()

func unpause_run() -> void:
	reset_run_input()
	sound.play("confirm")

func pause_menu_screen() -> String:
	return "end_run_confirm" if confirm_end_run else "pause"

func request_end_run() -> void:
	if run_paused:
		confirm_end_run = true
		sound.play("ui")

func cancel_end_run() -> void:
	confirm_end_run = false
	sound.play("cancel")

func end_paused_run() -> void:
	if not run_paused or not confirm_end_run:
		return
	if screen == "clear":
		finish_run("Garden restored", "clear")
	else:
		finish_run("Run ended", "ended")

func uses_room_choice() -> bool:
	return floor_index >= 0 and not room_complete and room_kind in ["shop", "rest", "event", "curse"]

func interact() -> void:
	if screen != "fight" or run_paused:
		return
	if optional_arena_boss() == OptionalBosses.CHOIR and OptionalBosses.mute_choir_bell(self):
		return
	if optional_arena_boss() == OptionalBosses.VELVET and OptionalBosses.sever_velvet_string(self):
		return
	if pending_chest:
		open_chest()
	elif uses_room_choice() and player.distance_to(chest_position) < RouteView.INTERACTION_RANGE:
		sound.play("ui")
		screen = "room_choice"
		checkpoint()
	else:
		var exit_id = nearest_open_exit()
		if not exit_id.is_empty():
			take_exit(exit_id)

func open_chest() -> void:
	if screen == "fight" and pending_chest and chest_open_time <= 0.0 and player.distance_to(chest_position) < RouteView.INTERACTION_RANGE:
		menu_motion.reward_relic_preview = ""
		acquired_upgrade_id = ""
		prepare_reward_upgrades()
		sound.play("chest")
		chest_open_time = CHEST_OPEN_DURATION
		checkpoint()

func use_pocket() -> void:
	if screen == "fight" and not run_paused and boss_victory.left <= 0.0 \
			and chest_open_time <= 0.0 and not ultimates.locks_movement():
		pocket.consume(self)

func finish_reward(legacy_route: int, cue := "reward") -> void:
	sound.play(cue)
	upgrades.clear_offers()
	menu_motion.reward_relic_preview = ""
	reward_relic_id = ""
	reward_weapon_id = ""
	if floor_index < 0:
		route = legacy_route
		advance()
	else:
		complete_room()

func resolve_room_choice(pos: Vector2) -> void:
	if room_kind == "shop":
		RouteView.ShopView.tap(self, pos)
		return
	if room_kind == "rest" and RouteView.FORGE_ACTION.has_point(pos) and not WeaponEvolutions.recipe_for(hero).is_empty():
		screen = "forge"
		checkpoint()
		return
	if RouteView.LEAVE_ACTION.has_point(pos):
		complete_room()
		return
	if room_kind == "event":
		var choice_index = RouteView.event_choice_at(pos)
		if RoomEvents.apply(self, choice_index) and room_kind == "event" and screen == "room_choice":
			complete_room()
		return
	if room_kind == "curse":
		if curses.take(self, RouteView.event_choice_at(pos)):
			sound.play("reward")
			complete_room()
		return
	if room_kind == "rest" and RouteView.SECOND_ACTION.has_point(pos):
		bonus += 1
		sound.play("reward")
		complete_room()
		return
	if not RouteView.FIRST_ACTION.has_point(pos):
		return
	if room_kind == "rest":
		var healing := healing_amount(RunEconomy.CAMP_HEAL, "rest")
		if healing <= 0:
			return
		hp += healing
	complete_room()

func open_arcade_round(game_id: String) -> void:
	var stream := "cap-board:v1" if game_id == ArcadeCatalog.BOARD else "garden-game:%s:v1" % game_id
	arcade.begin(game_id, Dungeon.stream_seed(run_seed, floor_index, room_id, stream), hero, cap_board, false)
	screen = "minigame"
	checkpoint()

func practice_arcade_round(game_id: String) -> void:
	if not ArcadeCatalog.DATA.has(game_id):
		return
	if not GardenMedia.can_replay(profile, game_id):
		var unlock := GardenMedia.cartridge(game_id) if profile.has_unlock(GardenMedia.CONSOLE) else GardenMedia.CONSOLE
		open_seed_shop(SeedShop.Shelf.MEDIA, unlock)
		return
	arcade.begin(game_id, randi(), hero, cap_board, true)
	screen = "arcade_practice"

func evolution_offer() -> Dictionary:
	return WeaponEvolutions.offer(self)

func leave_forge() -> void:
	if screen == "forge" and not run_paused:
		screen = "room_choice"
		checkpoint()

func forge_weapon() -> bool:
	if screen != "forge" or room_kind != "rest" or room_complete or run_paused:
		return false
	var forge := evolution_offer()
	if not bool(forge.get("can_evolve", false)) or not equip_weapon(str(forge.get("id", ""))):
		return false
	sound.play("reward")
	complete_room()
	return true

func complete_room() -> void:
	pending_chest = false
	room_complete = true
	screen = "fight"
	checkpoint()

func nearest_open_exit() -> String:
	if floor_index < 0 or not room_complete:
		return ""
	for exit_id: String in room_exits:
		if player.distance_to(room_exits[exit_id]) < RouteView.INTERACTION_RANGE:
			return exit_id
	return ""

func click_room_exit(pos: Vector2) -> bool:
	if floor_index < 0 or not room_complete:
		return false
	for exit_id: String in room_exits:
		var point: Vector2 = room_exits[exit_id]
		var label_area = RouteView.exit_label(point)
		if (label_area.has_point(pos) or pos.distance_to(point) < 27.0) and player.distance_to(point) < RouteView.INTERACTION_RANGE:
			take_exit(exit_id)
			return true
	return false

func take_exit(exit_id: String) -> void:
	if not room_complete or not room_exits.has(exit_id):
		return
	if exit_id == NEXT_FLOOR:
		next_floor()
		return
	var next: Dictionary = floor_manifest.nodes[exit_id]
	room_id = exit_id
	route = int(next.branch)
	advance()

func next_floor() -> void:
	if room_kind == "boss" and floor_index in [0, 1] and not talents.offer(hero, chapter_talent_milestone()).is_empty():
		screen = "talent"
		checkpoint()
		return
	floor_index += 1
	load_floor()
	advance()

func chapter_talent_milestone() -> String:
	return RunTalents.SECOND_MILESTONE if floor_index == 1 else RunTalents.FIRST_MILESTONE

func advance() -> void:
	depth += 1
	enter_room()

func ultimate_ready() -> bool:
	return screen == "fight" and boss_victory.left <= 0.0 and not foes.is_empty() \
		and chest_open_time <= 0.0 and ultimates.can_cast(self)

static func boss_health(encounter_depth: int) -> int:
	var rank := clampi(encounter_depth, 0, 80)
	return BOSS_HEALTH_MULTIPLIER * (222 + 9 * rank + roundi(0.055 * rank * rank))

static func restore_boss_health(foe: Dictionary) -> void:
	var saved_multiplier := maxi(1, int(foe.get("boss_health_multiplier", 1)))
	if saved_multiplier >= BOSS_HEALTH_MULTIPLIER:
		return
	var scale := float(BOSS_HEALTH_MULTIPLIER) / saved_multiplier
	foe.max = roundi(float(foe.max) * scale)
	foe.hp = clampi(roundi(float(foe.hp) * scale), 0, int(foe.max))
	foe.boss_health_multiplier = BOSS_HEALTH_MULTIPLIER

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

func dodge_cooldown() -> float:
	return float(DASH_RECHARGE[hero]) * upgrades.dodge_factor() * curses.dodge_factor()

func basic_attack_interval() -> float:
	return float(Weapons.item(armory.for_hero(hero)).interval) * upgrades.attack_factor() * curses.attack_interval_factor()

func skill_cooldown() -> float:
	return HeroAbilities.cooldown_for_game(self) * upgrades.skill_factor(hero) * relics.skill_cooldown_factor()

func assisted_aim(maximum: float, prefers_marks := false) -> Vector2:
	var best_point := Vector2.INF
	var best_score := INF
	var desired := facing.normalized()
	for foe: Dictionary in foes:
		if int(foe.hp) <= 0:
			continue
		var point := target(foe)
		var offset: Vector2 = point - player
		var length: float = offset.length()
		if length <= 1.0 or length > maximum or ForgottenEncounters.blocked(self, player, point, 14.0):
			continue
		var score: float = length * (1.0 + (1.0 - desired.dot(offset / length)) * 0.14)
		if prefers_marks and float(foe.get("camellia_mark", 0.0)) > 0.0:
			score *= 0.75
		if score < best_score:
			best_point = point
			best_score = score
	return best_point

func assisted_direction(maximum: float, prefers_marks := false) -> Vector2:
	var point := assisted_aim(maximum, prefers_marks)
	if point.is_finite():
		return player.direction_to(point)
	return facing.normalized() if not facing.is_zero_approx() else Vector2.UP

func prepared_weapon() -> String:
	if starting_weapon_options().has(selected_weapon):
		return selected_weapon
	return Weapons.starter(hero)

func reward_has_tea() -> bool:
	return floor_index < 0 or RunEconomy.chest_has_tea(room_kind, Dungeon.stream_seed(run_seed, floor_index, room_id, "reward"))

func reward_healing() -> int:
	return healing_amount(20 if floor_index < 0 else RunEconomy.LOOT_HEAL, "reward")

func reward_resource_gain() -> int:
	return mini(RunEconomy.LOOT_RESOURCE, maxi(0, HeroUltimates.CHARGE - resource))

func reward_upgrade_offers() -> Array[String]:
	return upgrades.offers()

func prepare_reward_upgrades(old_open_chest := false) -> void:
	var room: Dictionary = current_room()
	var key := str(room.get("id", room_id))
	var seed_value := Dungeon.stream_seed(run_seed, floor_index, key, "run_upgrade")
	var equipment: bool = not reward_relic_id.is_empty() or not reward_weapon_id.is_empty() or not pocket.offer(self).is_empty()
	upgrades.prepare_offers(seed_value, hero, 1 if equipment else 2, depth, floor_index < 0, old_open_chest)

func take_reward_upgrade(id: String) -> bool:
	if screen != "reward" or run_paused or not upgrades.take(id, hero):
		return false
	if id == RunUpgrades.THORN_EDGE:
		bonus += 2
	elif id == RunUpgrades.VELVET_PURSE:
		petals += RunUpgrades.PETAL_PAYOUT
	acquired_upgrade_id = id
	finish_reward(1, "upgrade_pick")
	return true

func healing_amount(amount: int, source := "standard") -> int:
	if not curses.healing_block(source).is_empty():
		return 0
	return clampi(curses.healing(combat_status.hero_healing(amount)), 0, maxi(0, HEALTH[hero] - hp))

func shop_price(amount: int, healing_item := false) -> int:
	return curses.shop_price(amount, healing_item)

func player_hit_amount(amount: int) -> int:
	var result := curses.attack_damage(amount, hp, HEALTH[hero])
	if result <= 0:
		return 0
	if hero == 3:
		result = maxi(1, roundi(result * 0.9))
	elif hero == 4 and relics.has_relic(Relics.IRIS_DICE) and randf() < 0.15:
		result *= 2
	return result

func starting_weapon_options() -> Array[String]:
	var result: Array[String] = [Weapons.starter(hero)]
	for id in Weapons.available(hero, ""):
		if knows_weapon(id):
			result.append(id)
	return result

func knows_weapon(id: String) -> bool:
	return codex.knows_weapon(id) or (id in RunProfile.STARTING_WEAPONS and profile.has_unlock(id))

func open_relic_ledger() -> void:
	relic_ledger_return = screen
	relic_ledger_carried.clear()
	var active := RunProfile.read_json(SAVE)
	var stored: Variant = active.get("relics")
	if active.get("screen", "") in ACTIVE_RUN_SCREENS and stored is Dictionary and stored.get("owned") is Array:
		for id: Variant in stored.owned:
			if id is String and Relics.DEFINITIONS.has(id) and id not in relic_ledger_carried:
				relic_ledger_carried.append(id)
	codex.observe_relics(relic_ledger_carried)
	relic_ledger_entry = maxi(0, RelicSources.LEDGER_IDS.find(selected_relic)) if screen == "preparation" else 0
	relic_ledger_page = floori(float(relic_ledger_entry) / RelicLedger.ROWS)
	relic_ledger_tab = 0
	screen = "relic_ledger"

func equip_weapon(id: String) -> bool:
	return armory.equip(id, hero)

func reward_weapon_offer() -> String:
	if floor_index < 0 or room_kind not in ["treasure", "secret", "elite"]:
		return ""
	var chapter_weapon := WeaponEvolutions.chapter_weapon(hero, floor_index)
	if room_kind == "treasure" and not chapter_weapon.is_empty() and armory.for_hero(hero) != chapter_weapon:
		return chapter_weapon
	return armory.offer(hero, int(current_room().reward_seed))

func act(action: String) -> void:
	if boss_victory.left > 0.0:
		return
	if screen != "fight" or run_paused or chest_open_time > 0.0 or abilities.locks_movement() or ultimates.locks_movement():
		return
	if action == "dodge" and dodge_time <= 0:
		talents.start_dodge()
		honest_eyes_ready = relics.has_relic(Relics.HONEST_EYES)
		if relics.has_relic(Relics.FEATHER_CROWN):
			feather_crown_left = 1.0
		var snare_scale: float = ground_hazards.break_snare()
		var dodge_distance := float(DASH_DISTANCES[hero]) * snare_scale
		var direction: Vector2 = facing
		var recall := painted_evolution.take_return(self) if is_equal_approx(snare_scale, 1.0) else Vector2.INF
		if recall.is_finite():
			dodge_distance = player.distance_to(recall)
			direction = player.direction_to(recall)
		dash_remaining = float(DASH_DURATIONS[hero])
		dash_vector = direction * dodge_distance / dash_remaining
		dash_evaded = false
		dodge_time = dodge_cooldown()
		mercy = dash_remaining + 0.045
		sound.play("dodge")
		if recall.is_finite():
			checkpoint.call_deferred()
	elif action == "skill":
		var origin: Vector2 = player
		if abilities.cast(self):
			if relics.has_relic(Relics.BRASSWING_PIN):
				brasswing_pin_left = 2.0
			skill_time = float(skill_time) * upgrades.skill_factor(hero) * relics.skill_cooldown_factor()
			painted_evolution.mark_exit(self, origin)
			sound.hero_attack(hero, true)
	elif action == "ultimate":
		if ultimate_ready() and ultimates.cast(self):
			checkpoint.call_deferred()
	elif action == "attack" and attack_time <= 0 and lily_repeat.is_empty():
		sound.hero_attack(hero)
		var id := armory.for_hero(hero)
		var weapon := Weapons.item(id)
		attack_time = basic_attack_interval()
		var manual_aim: Vector2 = stick + Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if SnareThread.can_pin(id) and manual_aim.length_squared() > 0.04:
			facing = manual_aim.normalized()
		else:
			facing = assisted_direction(weapon.aim, hero == 3)
		attack_visual_facing = facing
		lily_repeat_visual = false
		var effect = relics.on_basic_attack(hp, id == Relics.ROSEWALL_EXECUTION)
		effect.weapon_id = id
		effect.weapon_attack = armory.begin_attack(self, id)
		talents.begin_basic(effect.weapon_attack)
		var guard_charge_used := false
		if hero in [1, 3]:
			fire_basic_shot(effect)
		else:
			lily_finisher_flash = id == "lilyblade" and advance_lily_combo()
			guard_charge_used = basic_slash(effect, lily_finisher_flash)
		if curses.has_curse(RunCurses.LILY):
			lily_repeat = {"left": LILY_REPEAT_DELAY, "weapon_id": id, "dx": facing.x, "dy": facing.y,
				"weapon_attack": int(effect.weapon_attack), "finisher": lily_finisher_flash and hero == 0}
		if effect.pierce or effect.wide_cone or guard_charge_used or not lily_repeat.is_empty():
			checkpoint.call_deferred()
		flash = SWING_DURATION

func restore_lily_repeat(saved: Variant) -> void:
	lily_repeat.clear()
	lily_repeat_visual = false
	flash = 0.0
	if not saved is Dictionary or not curses.has_curse(RunCurses.LILY):
		return
	var id := str(saved.get("weapon_id", ""))
	var direction := Vector2(float(saved.get("dx", 0.0)), float(saved.get("dy", 0.0)))
	if not Weapons.usable_by(id, hero) or not direction.is_finite() or direction.is_zero_approx():
		return
	lily_repeat = {"left": clampf(float(saved.get("left", 0.0)), 0.0, LILY_REPEAT_DELAY),
		"weapon_id": id, "dx": direction.x, "dy": direction.y,
		"weapon_attack": int(saved.get("weapon_attack", -1)), "finisher": bool(saved.get("finisher", false))}

func tick_lily_repeat(delta: float) -> void:
	if lily_repeat.is_empty():
		return
	lily_repeat.left = float(lily_repeat.left) - delta
	if float(lily_repeat.left) > 0.0:
		return
	var repeat := lily_repeat
	lily_repeat = {}
	var original_facing: Vector2 = facing
	facing = Vector2(repeat.dx, repeat.dy).normalized()
	attack_visual_facing = facing
	lily_repeat_visual = true
	lily_finisher_flash = bool(repeat.finisher)
	var effect := {"pierce": false, "wide_cone": false, "weapon_id": repeat.weapon_id,
		"weapon_attack": int(repeat.weapon_attack), "lily_repeat": true}
	if hero in [1, 3]:
		fire_basic_shot(effect)
	else:
		basic_slash(effect, lily_finisher_flash)
	facing = original_facing
	flash = SWING_DURATION
	sound.play(GardenSoundstage.HERO_EFFECTS[hero], 0.90)
	checkpoint.call_deferred()

func fire_basic_shot(effect: Dictionary) -> void:
	var id := str(effect.get("weapon_id", armory.for_hero(hero)))
	var weapon := Weapons.item(id)
	var speed := maxf(1.0, float(weapon.get("speed", 0.0)))
	var reach := float(weapon.reach)
	var lifetime := (0.47 if hero == 1 else 0.89) if id == Weapons.starter(hero) else reach / speed
	if hero == 1:
		lifetime *= 0.9 * (1.2 if relics.has_relic(Relics.ROSE_LENS) else 1.0)
	var bolt = {"x": player.x, "y": player.y, "dx": facing.x, "dy": facing.y, "hero_projectile": hero,
		"life": lifetime, "speed": speed, "weapon_id": id, "weapon_attack": int(effect.get("weapon_attack", -1))}
	if bool(effect.get("lily_repeat", false)):
		bolt.lily_repeat = true
	if effect.pierce or id == "hollowglass_bow":
		bolt.remaining_hits = 2
		bolt.hit_foes = []
	if effect.wide_cone:
		bolt.spread_x = player.x
		bolt.spread_y = player.y
	if id == ElegyMagic.WEAPON:
		ElegyMagic.prepare_bolt(bolt)
	var angles: Array = [-0.18, 0.0, 0.18] if hero == 1 and int(effect.get("weapon_attack", -1)) > 0 and int(effect.weapon_attack) % 3 == 0 else [0.0]
	for angle: float in angles:
		var shot := bolt.duplicate(true)
		var direction := facing.rotated(angle)
		shot.dx = direction.x
		shot.dy = direction.y
		bolts.append(shot)

func advance_lily_combo() -> bool:
	if hero != 0:
		return false
	lily_combo = (lily_combo + 1) % 3
	lily_combo_time = 0.92
	return lily_combo == 0

func basic_slash(effect: Dictionary, finisher := false) -> bool:
	var id := str(effect.get("weapon_id", armory.for_hero(hero)))
	var sequence := int(effect.get("weapon_attack", -1))
	var weapon := Weapons.item(id)
	var reach := 83.0 if finisher else float(weapon.reach)
	var repeat := bool(effect.get("lily_repeat", false))
	ground_hazards.sever_melee(self, player, facing, reach)
	if finisher:
		ground_hazards.trim(self, player, facing, reach)
	var min_alignment = -0.40 if effect.wide_cone else 0.15
	var rosewall := bool(effect.get("rosewall", false))
	var followthrough := rosewall or bool(effect.get("ledger", false))
	var struck := PackedInt32Array()
	var anchor := Vector2.INF
	var pierced_front = false
	var beyond := -1
	var nearest_distance = reach + 32.0
	for index in range(foes.size()):
		var foe: Dictionary = foes[index]
		if int(foe.hp) <= 0:
			continue
		var point := target(foe)
		var offset = point - player
		var distance = offset.length()
		var alignment = offset.normalized().dot(facing)
		var in_pierce_lane = effect.pierce and alignment > 0.90 and absf(offset.cross(facing)) < 13.0
		if distance < reach and alignment > min_alignment:
			if repeat and ForgottenEncounters.blocked(self, player, point, 15.0):
				continue
			if in_pierce_lane and not ForgottenEncounters.blocked(self, player, point, 15.0):
				pierced_front = true
			var previous_hp := int(foe.hp)
			strike(foe, finisher, id, sequence, 1.0, repeat)
			if followthrough:
				struck.append(index)
				if int(foe.hp) < previous_hp and distance < player.distance_to(anchor):
					anchor = point
		elif distance < nearest_distance and in_pierce_lane and not ForgottenEncounters.blocked(self, player, point, 15.0):
			nearest_distance = distance
			beyond = index
	if pierced_front and beyond >= 0:
		var foe: Dictionary = foes[beyond]
		var point := target(foe)
		var previous_hp := int(foe.hp)
		strike(foe, finisher, id, sequence)
		if followthrough:
			struck.append(beyond)
			if not anchor.is_finite() and int(foe.hp) < previous_hp:
				anchor = point
	if followthrough and anchor.is_finite():
		relics.spend_guard_followthrough(rosewall)
		abilities.resolve_guard_followthrough(self, anchor, struck, int(weapon.damage) + bonus, rosewall)
		return true
	return false

func strike(foe: Dictionary, finisher := false, weapon_id := "", sequence := -1, damage_scale := 1.0,
		repeat := false) -> void:
	if int(foe.hp) <= 0:
		return
	foe.flash = 0.14
	var close_bonus = 3 if hero == 2 and player.distance_squared_to(target(foe)) <= 40.0 * 40.0 else 0
	var id := weapon_id if Weapons.usable_by(weapon_id, hero) else armory.for_hero(hero)
	var guard_counter := abilities.counter_bonus(self, foe) if not repeat else 0
	var rose_counter := id == "royal_cleaver" and guard_counter > 0 and relics.rose_counter_ready(depth)
	var rose_power := Relics.ROSE_COUNTER_BONUS if rose_counter else 0
	var raw: int = int(Weapons.item(id).damage) + close_bonus + bonus + guard_counter + rose_power \
		+ (ultimates.counter_bonus() if not repeat else 0)
	if honest_eyes_ready:
		raw += 3
	var prince_bonus := not princes_pin_used and relics.has_relic(Relics.PRINCES_PIN)
	if prince_bonus:
		raw += 8
	var count_moon_hit := sequence >= 0 and not repeat and relics.has_relic(Relics.TWIN_MOON_PENDANT) and sequence not in twin_moon_sequences
	if count_moon_hit and twin_moon_hits == 3:
		raw += 5
	var painted_flank := PaintedEvolution.flank(self, foe)
	var pin_scale := 1.1 if brasswing_pin_left > 0.0 else 1.0
	var amount := player_hit_amount(maxi(1, roundi(raw * damage_scale * pin_scale * (1.30 if painted_flank else 1.0))))
	var was_marked := float(foe.get("camellia_mark", 0.0)) > 0.0 or CombatStatuses.has_foe(foe, "marked")
	var loss = defend_foe(foe, amount)
	foe.hp -= loss
	if loss > 0:
		honest_eyes_ready = false
		if count_moon_hit:
			twin_moon_sequences.append(sequence)
			twin_moon_hits = (twin_moon_hits + 1) % 4
		if prince_bonus:
			princes_pin_used = true
		sound.play("hit")
		if repeat:
			return
		resource = mini(5, resource + 1)
		if rose_counter:
			relics.spend_rose_counter()
			armory.add_trace("bloom", target(foe), target(foe), Color("#f0bbbd"))
		armory.after_hit(self, foe, id, sequence, was_marked)
		painted_evolution.after_basic(self, foe, sequence, painted_flank)
		talents.after_basic_hit(self, foe, sequence)
		if hero == 3 and int(foe.hp) > 0:
			HeroUltimates.mark_foe(foe, 1.8)
	if loss < amount or foe.phase == ForgottenEncounters.LUNGE:
		return
	if id != "ribbon_string" or not was_marked:
		armory.knockback(self, foe, 22.0 if finisher else (17.0 if hero == 2 else 8.0), id)

func defend_foe(foe: Dictionary, amount: int) -> int:
	if ultimates.cue_time > 0.0 or endless.protected_at(target(foe)):
		return 0
	if relics.has_relic(Relics.CHOIR_ANTLER) and (int(foe.get("phase", 0)) == ForgottenEncounters.RECOVERY or float(foe.get("hero_stun", 0.0)) > 0.0):
		amount = roundi(amount * 1.1)
	if foe.has("optional_boss"):
		if foe.optional_boss == OptionalBosses.CHAIR and foe.boss:
			if not foe.get("optional_second", false):
				return mini(amount, maxi(0, int(foe.hp) - floori(float(foe.max) * 0.4)))
			if OptionalBosses.chair_posts_active(foes):
				return 0
		if foe.optional_boss == OptionalBosses.BRASSWING and foe.boss and foe.get("optional_second", false):
			for drone: Dictionary in foes:
				if drone.get("brasswing_drone", false) and int(drone.hp) > 0:
					return 0
		return amount
	if active_biome < ENCOUNTERS_BY_BIOME.size():
		return ENCOUNTERS_BY_BIOME[active_biome].defend(self, foe, amount)
	return amount

func target(foe: Dictionary) -> Vector2:
	return Vector2(foe.x, foe.y)

func slide_with_cover(start: Vector2, step: Vector2) -> Vector2:
	var moved = clamp_position(start + step)
	for barrel in barrels:
		var offset = moved - barrel
		if offset.length_squared() < BARREL_CLEARANCE * BARREL_CLEARANCE:
			var normal = offset.normalized() if offset != Vector2.ZERO else Vector2.UP
			moved = clamp_position(barrel + normal * BARREL_CLEARANCE)
	return moved

func clamp_position(pos: Vector2) -> Vector2:
	return pos.clamp(ARENA.position + Vector2(16, 16), ARENA.end - Vector2(16, 16))

func _process(delta: float) -> void:
	visual_clock += delta
	var browsing_jukebox: bool = screen == "jukebox"
	sound.music_suppressed = browsing_jukebox and profile.has_unlock(GardenMedia.JUKEBOX)
	if not browsing_jukebox and jukebox.player.stream != null:
		jukebox.stop()
	var boss_active = room_kind == "boss" and (boss_victory.left > 0.0 \
		or foes.any(func(foe): return foe.get("boss", false) and int(foe.hp) > 0))
	var optional_cue := optional_arena_boss() if screen == "fight" and not room_complete and not pending_chest else ""
	if screen in ["minigame", "arcade_practice"] and not arcade.id.is_empty():
		sound.request(ArcadeCatalog.DATA[arcade.id].cue)
	elif not optional_cue.is_empty():
		sound.request(optional_cue)
	else:
		sound.sync("garden_hub" if browsing_jukebox else screen, active_biome, room_kind, boss_active)
	menu_motion.advance(pause_menu_screen() if run_paused else screen, hero, selected_relic, get_local_mouse_position(), delta)
	if screen != "fight" and joystick_id >= 0:
		reset_joystick()
	if screen in ["minigame", "arcade_practice"] and not run_paused and not arcade_backgrounded:
		arcade.tick(self, delta)
	world_image.visible = screen in ["fight", "room_choice", "talent", "forge"] \
		or (screen == "minigame" and arcade.id == ArcadeCatalog.BOARD)
	if world_image.visible and not run_paused:
		world_canvas.queue_redraw()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if screen != "fight" or run_paused:
		return
	if boss_victory.left > 0.0:
		boss_victory.tick(self, delta)
		if boss_victory.left <= 0.0 or save_time + delta >= 0.5:
			save_time = 0.0
			checkpoint()
		else:
			save_time += delta
		return
	if ultimates.tick_cutin(self, delta):
		return
	if chest_open_time > 0.0:
		chest_open_time = maxf(0.0, chest_open_time - delta)
		if chest_open_time <= 0.0:
			prepare_reward_upgrades()
			screen = "reward"
			checkpoint()
		return
	run_time += delta
	pocket.tick(delta)
	armory.tick(self, delta)
	upgrades.tick(delta)
	var recovery_delta = delta * (RunItems.TONIC_RECOVERY if pocket.haste > 0.0 else 1.0)
	attack_time -= recovery_delta
	lily_combo_time = maxf(0.0, lily_combo_time - delta)
	if lily_combo_time <= 0.0:
		lily_combo = 0
	dodge_time -= recovery_delta
	feather_crown_left = maxf(0.0, feather_crown_left - delta)
	brasswing_pin_left = maxf(0.0, brasswing_pin_left - delta)
	velvet_ribbon_left = maxf(0.0, velvet_ribbon_left - delta)
	skill_time -= recovery_delta
	mercy -= delta
	flash -= delta
	var move = (stick + Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")).limit_length()
	var before = player
	var dodging: bool = dash_remaining > 0.0
	if dodging:
		player = slide_with_cover(player, dash_vector * minf(delta, dash_remaining))
		talents.add_dash_step(self, before, player)
		dash_remaining = maxf(0.0, dash_remaining - delta)
	elif move.length() > 0.1 and not abilities.locks_movement() and not ultimates.locks_movement():
		facing = move.normalized()
		var haste_scale = RunItems.TONIC_MOVEMENT if pocket.haste > 0.0 else 1.0
		var movement_scale := minf(ground_hazards.movement_scale(), combat_status.hero_movement_scale())
		var walk_speed := float([143.0, 151.0, 167.0, 151.0, 175.0][hero]) * upgrades.movement_factor() * curses.movement_factor()
		if feather_crown_left > 0.0:
			walk_speed *= 1.15
		if velvet_ribbon_left > 0.0:
			walk_speed *= 1.15
		if hero == 3:
			walk_speed *= 1.05 * (1.1 if relics.has_relic(Relics.CAMELLIA_RIBBON) else 1.0)
		player = slide_with_cover(player, move * walk_speed * haste_scale * movement_scale * delta)
	painted_evolution.tick(self, before, delta)
	abilities.tick(self, delta)
	ultimates.tick(self, delta)
	walk_distance = fposmod(walk_distance + player.distance_to(before), 64.0)
	tick_lily_repeat(delta)
	visual_velocity = visual_velocity.lerp((player - before) / maxf(delta, 0.001), minf(12.0 * delta, 1.0))
	damage_flash = maxf(0.0, damage_flash - delta)
	room_arrival = maxf(0.0, room_arrival - delta)
	if room_arrival <= 0.0:
		endless.tick(self, delta)
		update_bolts(delta)
	var thread_samples := snare_thread.sample_foes(self)
	update_foes(delta, room_arrival > 0.0)
	collect_elite_heals()
	if boss_victory.left > 0.0:
		if hp <= 0:
			finish_run("The Garden claims another")
		else:
			checkpoint()
		return
	snare_thread.tick(self, thread_samples, delta)
	if room_arrival <= 0.0 and not room_complete and not pending_chest and not foes.is_empty():
		ground_hazards.tick(self, before, delta)
		clockwork_floor.tick(self, delta)
	var active_stride: bool = player.distance_to(before) > 78.0 * delta
	combat_status.tick_hero(self, delta, active_stride or flash > 0.0)
	talents.tick(self, delta, player.distance_to(before) > 3.0 * delta, dodging)
	if hp <= 0:
		finish_run("The Garden claims another")
		return
	if floor_index >= 0:
		if step_dungeon_room(delta, move):
			return
	elif foes.is_empty() and not pending_chest:
		petals += 8 + depth
		if depth < 4:
			pending_chest = true
		else:
			screen = "clear" if depth == 27 else "reward"
			if screen == "reward":
				prepare_reward_upgrades()
		checkpoint()
		return
	save_time += delta
	if save_time >= 0.5:
		save_time = 0
		checkpoint()

func step_dungeon_room(delta: float, move: Vector2) -> bool:
	if room_complete:
		if move.y < -0.12:
			for exit_id: String in room_exits:
				var point: Vector2 = room_exits[exit_id]
				if absf(player.x - point.x) <= 24.0 and player.y <= point.y + 10.0:
					take_exit(exit_id)
					return true
		return false
	if uses_room_choice() or pending_chest:
		return false
	if room_arrival <= 0.0:
		room_clock += delta
	if not foes.is_empty() or endless.holds_room():
		return false

	ground_hazards.disarm()
	clockwork_floor.disarm()
	petals += curses.room_reward(RunEconomy.room_petals(room_kind, floor_index, room_clock <= HUNT_TIME))
	if relics.has_relic(Relics.TRUFFLE_SATCHEL) and room_kind not in Dungeon.FRIENDLY_KINDS:
		petals += 2
	bolts.clear()
	if room_kind == "boss" and floor_index == Dungeon.BIOME_COUNT - 1:
		screen = "clear"
		sound.play("clear")
	else:
		pending_chest = true
		if room_kind == "boss":
			reward_relic_id = boss_relic_offer()
		elif not optional_arena_boss().is_empty():
			var relic_id: String = OptionalBosses.REWARDS.get(optional_arena_boss(), "")
			reward_relic_id = relic_id if not relics.has_relic(relic_id) else ""
		else:
			reward_weapon_id = reward_weapon_offer()
	checkpoint()
	return true

func boss_relic_offer() -> String:
	if floor_index == Dungeon.BIOME_COUNT - 1:
		return ""
	var preferred := RelicSources.boss_preference(floor_index, hero, relics.owned)
	if not preferred.is_empty():
		return preferred
	return relics.boss_offer(int(current_room().reward_seed), hero)

func update_bolts(delta: float) -> void:
	for i in range(bolts.size() - 1, -1, -1):
		var bolt = bolts[i]
		var start = target(bolt)
		if int(bolt.get("hero_projectile", -1)) == 3 and SnareThread.can_pin(str(bolt.get("weapon_id", ""))):
			if step_pin_arrow(bolt, start, delta):
				bolts.remove_at(i)
			continue
		if bolt.has("ultimate"):
			ultimates.steer_bolt(self, bolt, delta)
		elif bolt.get("weapon_id", "") == ElegyMagic.WEAPON:
			ElegyMagic.steer_bolt(bolt, delta)
		var pos = start + Vector2(bolt.dx, bolt.dy) * float(bolt.get("speed", 408.0)) * delta
		bolt.x = pos.x
		bolt.y = pos.y
		bolt.life -= delta
		var blocked := not ARENA.has_point(pos) or ForgottenEncounters.blocked(self, start, pos, 16.0)
		if float(bolt.life) <= 0.0 or blocked:
			if not blocked and bolt.get("weapon_id", "") == "moonquill_staff" and not bolt.get("lily_repeat", false):
				armory.lunar_bloom(self, pos)
			bolts.remove_at(i)
			continue
		if bolt.has("damage"):
			var radius = float(bolt.get("radius", 12.0))
			if ForgottenEncounters.segment_gap(player, start, pos) <= radius:
				var direction := Vector2(bolt.dx, bolt.dy).normalized()
				var is_directional: bool = direction != Vector2.ZERO and not bolt.get("terrain", false)
				var source: Vector2 = player - direction * 32.0 if is_directional else Vector2.INF
				var power := clampf(float(bolt.get("enemy_power", 1.0)), 1.0, 1.65)
				damage_hero(roundi(int(bolt.damage) * power), source, bolt if is_directional else {})
				if not bolt.get("terrain", false):
					bolts.remove_at(i)
			continue
		if bolt.has("ultimate"):
			if ultimates.resolve_bolt(self, bolt, start, pos):
				bolts.remove_at(i)
		elif ground_hazards.sever_bolt(self, start, pos):
			bolts.remove_at(i)
		elif resolve_hero_bolt(bolt, start, pos):
			bolts.remove_at(i)

func step_pin_arrow(bolt: Dictionary, start: Vector2, delta: float) -> bool:
	var step := clampf(float(bolt.life), 0.0, delta)
	if step <= 0.0:
		return true
	var pos := start + Vector2(bolt.dx, bolt.dy) * float(bolt.get("speed", 408.0)) * step
	var contact := SnareThread.wall_contact(ARENA, start, pos)
	if not contact.is_empty():
		pos = contact.tip
	elif not ARENA.has_point(pos):
		return true
	if ForgottenEncounters.blocked(self, start, pos, 16.0):
		return true
	bolt.x = pos.x
	bolt.y = pos.y
	bolt.life = float(bolt.life) - step
	if ground_hazards.sever_bolt(self, start, pos) or resolve_hero_bolt(bolt, start, pos):
		return true
	if not contact.is_empty():
		if not bolt.get("lily_repeat", false):
			snare_thread.pin_wall(self, contact, str(bolt.weapon_id))
		return true
	return float(bolt.life) <= 0.0

func resolve_hero_bolt(bolt: Dictionary, start: Vector2, finish: Vector2) -> bool:
	var remaining = int(bolt.get("remaining_hits", 1))
	var hit_foes: Array = bolt.get("hit_foes", [])
	if bolt.has("remaining_hits"):
		for foe: Dictionary in foes:
			if not foe.has("relic_target_id"):
				relic_foe_serial += 1
				foe.relic_target_id = relic_foe_serial
	for hit_index in range(remaining):
		var hit = closest_bolt_target(bolt, start, finish, hit_foes)
		if hit.is_empty():
			break
		var id := str(bolt.get("weapon_id", ""))
		var reduced := id == "hollowglass_bow" and remaining == 1
		strike(hit, false, id, int(bolt.get("weapon_attack", -1)), 0.65 if reduced else 1.0,
			bool(bolt.get("lily_repeat", false)))
		if reduced:
			armory.add_trace("spark", target(hit), target(hit), Color("#cdbaf7"))
		remaining -= 1
		if remaining == 0:
			return true
		hit_foes.append(int(hit.relic_target_id))
	if bolt.has("remaining_hits"):
		bolt.remaining_hits = remaining
		bolt.hit_foes = hit_foes
	return false

func closest_bolt_target(bolt: Dictionary, start: Vector2, finish: Vector2, hit_foes: Array) -> Dictionary:
	var closest: Dictionary = {}
	var nearest = INF
	var direction = start.direction_to(finish)
	var spread = 0.0
	if bolt.has("spread_x"):
		var launch = Vector2(bolt.spread_x, bolt.spread_y)
		spread = minf(finish.distance_to(launch) * 0.22, 27.0)
	for foe: Dictionary in foes:
		if int(foe.hp) <= 0 or int(foe.get("relic_target_id", 0)) in hit_foes:
			continue
		var point = target(foe)
		var reach = (28.0 if foe.boss else 18.0) + spread
		if ForgottenEncounters.segment_gap(point, start, finish) > reach:
			continue
		var distance = (point - start).dot(direction)
		if distance < nearest:
			nearest = distance
			closest = foe
	return closest

func damage_hero(amount: int, source: Vector2 = Vector2.INF, projectile: Dictionary = {}) -> void:
	if amount <= 0 or hp <= 0 or ultimates.cue_time > 0.0 or endless.protected_at(player):
		return
	if mercy > 0.0:
		if dash_remaining > 0.0 and not dash_evaded and relics.has_relic(Relics.GLASS_EYELASH):
			dash_evaded = true
			relics.on_perfect_dodge()
			checkpoint.call_deferred()
		return
	amount = maxi(1, roundi(amount * _encounter_damage_scale))
	amount = curses.incoming_damage(amount)
	var damage = abilities.damage_after_guard(self, amount, source, projectile)
	if damage < amount:
		sound.play("guard")
	damage = ultimates.damage_after_aura(damage)
	damage = armory.reduce_hit(damage)
	if damage <= 0:
		return
	var adjusted := upgrades.absorb_first_hit(int(damage))
	var aegis_used: bool = adjusted < int(damage)
	var relic_floor = floor_index if floor_index >= 0 else depth >> 2
	var before := int(hp)
	var hit = relics.resolve_damage(hp, adjusted, relic_floor)
	hp = hit.hp
	if int(hp) < before:
		apply_damage_relics()
	if int(hp) < before and projectile.get("glass_shard", false):
		combat_status.apply_hero(CombatStatuses.CHILL, 3.2, 1.0, "glass_shard", "hazard")
	sound.play("upgrade_guard" if aegis_used else "hurt")
	damage_flash = 0.20
	mercy = maxf(0.48, hit.grace)
	if hit.prevented or aegis_used:
		checkpoint.call_deferred()
	if hero == 2:
		resource = maxi(0, resource - 2)

func apply_damage_relics() -> void:
	if not second_chance_used and relics.has_relic(Relics.SECOND_CHANCE_DIAL):
		second_chance_used = true
		dodge_time = maxf(0.0, float(dodge_time) - 0.6)
	if not velvet_ribbon_used and relics.has_relic(Relics.VELVET_RIBBON) and not foes.is_empty():
		velvet_ribbon_used = true
		velvet_ribbon_left = 2.0

func damage_hero_from_status(amount: int) -> void:
	if amount <= 0 or hp <= 0 or mercy > 0.0 or room_arrival > 0.0 or room_complete \
			or pending_chest or foes.is_empty() or ultimates.cue_time > 0.0 or endless.protected_at(player):
		return
	amount = curses.incoming_damage(amount)
	if abilities.damage_after_guard(self, amount, Vector2.INF) == 0:
		sound.play("guard")
		return
	var relic_floor = floor_index if floor_index >= 0 else depth >> 2
	var result = relics.resolve_damage(hp, amount, relic_floor)
	var before := int(hp)
	hp = result.hp
	if int(hp) < before:
		apply_damage_relics()
	damage_flash = maxf(damage_flash, 0.09)
	sound.play("hurt", 0.84)
	if result.prevented:
		mercy = maxf(mercy, result.grace)
		checkpoint.call_deferred()

func update_foes(delta: float, arriving := false) -> void:
	if not arriving and optional_arena_boss() == OptionalBosses.BRASSWING and not foes.is_empty():
		OptionalBosses.tick_rails(self)
	for i in range(foes.size() - 1, -1, -1):
		var foe = foes[i]
		if foe.hp <= 0:
			if bool(foe.get("elite", false)) and bool(foe.get("elite_heal_drop", false)):
				elite_heal_drops.append({"x": float(foe.x), "y": float(foe.y)})
			if not foe.get("web_anchor", false):
				endless.defeat(self, foe)
			if foe.boss and active_biome < Art.ENEMY_ATLASES.size():
				boss_victory.begin(target(foe), -1.0 if player.x > float(foe.x) else 1.0)
				sound.play("boss_break")
			foes.remove_at(i)
			continue
		if arriving:
			continue
		var pos = target(foe)
		foe.flash = maxf(0.0, float(foe.get("flash", 0.0)) - delta)
		if HeroAbilities.consume_stun(foe, delta):
			combat_status.tick_foe(self, foe, delta, false)
			continue
		var previous_phase := int(foe.phase)
		var foot_scale := 1.0
		if previous_phase == ForgottenEncounters.APPROACH:
			foot_scale = minf(CombatStatuses.foe_movement_scale(foe), talents.foe_movement_scale(self, foe))
		if foot_scale <= 0.0:
			combat_status.tick_foe(self, foe, delta, false)
			continue
		foe.clock -= delta
		if active_biome < ENCOUNTERS_BY_BIOME.size() and foe.has("kind"):
			if not foe.has("biome"):
				foe.biome = active_biome
			var projectile_start := bolts.size()
			_encounter_damage_scale = clampf(float(foe.get("enemy_power", 1.0)), 1.0, 1.65)
			if foe.has("optional_boss"):
				OptionalBosses.advance(self, foe, delta)
			else:
				ENCOUNTERS_BY_BIOME[active_biome].advance(self, foe, endless.move_delta(foe, delta) * foot_scale)
			pace_elite_windup(foe, previous_phase)
			if not foe.has("optional_boss"):
				pace_boss_phase(foe, previous_phase)
			for projectile_index in range(projectile_start, bolts.size()):
				if bolts[projectile_index].has("damage"):
					bolts[projectile_index].enemy_power = _encounter_damage_scale
			_encounter_damage_scale = 1.0
			if previous_phase != ForgottenEncounters.WINDUP and int(foe.phase) == ForgottenEncounters.WINDUP:
				sound.play("warning_boss" if bool(foe.boss) else "warning")
			elif previous_phase == ForgottenEncounters.WINDUP and int(foe.phase) >= ForgottenEncounters.LUNGE:
				sound.enemy_release(str(foe.get("move", "")))
			tick_foe_status(foe, pos, previous_phase, delta)
			continue
		var radius = danger_radius(foe)
		if foe.phase == 0:
			if pos.distance_to(player) > radius * 0.7:
				var step = (player - pos).normalized() * (46 + mini(depth, 25)) * delta * foot_scale
				var moved = slide_with_cover(pos, step)
				if moved.distance_to(pos) < step.length() * 0.35:
					moved = slide_with_cover(pos, step.rotated(PI * 0.5))
				pos = moved
				foe.x = pos.x
				foe.y = pos.y
			elif foe.clock <= 0:
				foe.phase = 1
				foe.clock = 0.72
				foe.tx = player.x
				foe.ty = player.y
		elif foe.phase == 1 and foe.clock <= 0:
			if player.distance_to(Vector2(foe.tx, foe.ty)) <= radius:
				damage_hero((14 if foe.boss else 8) + mini(depth / 4, 8), pos)
			foe.phase = 0
			foe.clock = 0.85
			if foe.boss:
				foe.clock = boss_recovery(foe, float(foe.clock))
		pace_elite_windup(foe, previous_phase)
		pace_boss_phase(foe, previous_phase)
		tick_foe_status(foe, pos, previous_phase, delta)

func collect_elite_heals() -> void:
	for index in range(elite_heal_drops.size() - 1, -1, -1):
		var drop: Dictionary = elite_heal_drops[index]
		if player.distance_to(Vector2(drop.x, drop.y)) > 20.0:
			continue
		var amount := healing_amount(ELITE_HEAL_AMOUNT, "standard")
		if amount <= 0:
			continue
		hp += amount
		elite_heal_drops.remove_at(index)
		sound.play("reward")
		checkpoint.call_deferred()

static func pace_elite_windup(foe: Dictionary, previous_phase: int) -> void:
	if not bool(foe.get("elite", false)) or previous_phase == ForgottenEncounters.WINDUP or int(foe.phase) != ForgottenEncounters.WINDUP:
		return
	foe.clock = maxf(0.30, float(foe.clock) * ELITE_WINDUP_FACTOR)
	foe.duration = foe.clock

static func pace_boss_phase(foe: Dictionary, previous_phase: int) -> void:
	var phase := int(foe.phase)
	if not foe.boss or previous_phase == phase:
		return
	var authored := float(foe.clock)
	var move := str(foe.get("move", ""))
	if phase == ForgottenEncounters.WINDUP:
		var warning_minimum := 0.66
		match move:
			"petal_gates": warning_minimum = 1.02
			"sequence", "gravity", "constellation": warning_minimum = 0.85
			"echo", "curtain", "falling_stars", "steam": warning_minimum = 0.78
		foe.clock = maxf(minf(authored, warning_minimum), authored * (1.0 - 0.21 * boss_haste(foe)))
		foe.duration = foe.clock
	elif phase == ForgottenEncounters.RECOVERY:
		# A missed charge into cover grants its authored counterattack opening.
		if move != "antlers" or not foe.get("collided", false):
			foe.clock = boss_recovery(foe, authored)

static func boss_recovery(foe: Dictionary, authored: float) -> float:
	return maxf(minf(authored, 0.58), authored * (1.0 - 0.38 * boss_haste(foe)))

static func boss_haste(foe: Dictionary) -> float:
	var missing_hp := 1.0 - float(foe.hp) / maxf(1.0, float(foe.max))
	return smoothstep(0.0, 0.9, missing_hp)

func tick_foe_status(foe: Dictionary, before: Vector2, previous_phase: int, delta: float) -> void:
	if not foe.has(CombatStatuses.FOE_STATE):
		return
	var moving := before.distance_to(target(foe)) > 76.0 * delta
	var attacking := int(foe.phase) in [ForgottenEncounters.WINDUP, ForgottenEncounters.LUNGE] \
		or previous_phase in [ForgottenEncounters.WINDUP, ForgottenEncounters.LUNGE]
	combat_status.tick_foe(self, foe, delta, moving or attacking)

func danger_radius(foe: Dictionary) -> float:
	if not foe.boss:
		return 34.0
	return 76.0 if foe.hp * 2 < foe.max else 54.0

func _draw() -> void:
	if screen in ["fight", "room_choice"]:
		var in_endless = floor_index >= Dungeon.BIOME_COUNT if floor_index >= 0 else depth >= 28
		View.hud(self, 7 if in_endless else active_biome)
		RouteView.draw_world_ui(self)
		endless.draw_hud(self)
		View.boss_health_bar(self)
		if boss_victory.left > 0.0:
			boss_victory.draw_stamp(self, active_biome)
		View.controls(self)
		View.Reward.draw_confirmation(self)
		RouteView.draw_choice(self)
		if screen == "fight":
			View.ultimate_cutin(self)
	elif screen == "garden_hub":
		Hub.draw(self)
	elif screen == "seed_shop":
		SeedShop.draw(self)
	elif screen == "run_history":
		HistoryView.draw(self)
	elif screen == "preparation":
		Prep.draw(self)
	elif screen == "settings":
		SettingsView.draw(self)
	elif screen == "codex":
		CodexView.draw(self)
	elif screen == "armory":
		ArmoryView.draw(self)
	elif screen == "relic_ledger":
		RelicLedger.draw(self)
	elif screen == "garden_arcade":
		ArcadeView.gallery(self)
	elif screen == "jukebox":
		jukebox.draw(self)
	elif screen in ["minigame", "arcade_practice"]:
		ArcadeView.round(self)
	elif screen == "talent":
		TalentView.draw(self)
	elif screen == "forge":
		ForgeView.draw(self)
	else:
		View.menu(self)
	if screen in ["reward", "clear", "talent", "forge", "minigame"]:
		View.button(self, View.PAUSE, "Ⅱ")
	if run_paused:
		PauseView.draw(self)
	elif screen not in ["fight", "room_choice", "reward"]:
		View.entrance(self)

func draw_world() -> void:
	var biome = active_biome
	var arena_art := OptionalBosses.arena_texture(optional_arena_boss())
	if arena_art != null:
		world_canvas.draw_texture_rect(arena_art, View.ROOM_ART, false)
	elif ROOM_VARIANT_CELLS.has(room_template):
		var cell: Array = ROOM_VARIANT_CELLS[room_template]
		var atlas: Texture2D = ROOM_VARIANT_ART[cell[0]]
		var size = (atlas.get_size() * 0.5).floor()
		var region = Rect2(Vector2(cell[1], cell[2]) * size, size)
		world_canvas.draw_texture_rect_region(atlas, View.ROOM_ART, region)
	elif biome < BIOME_BACKDROPS.size():
		world_canvas.draw_texture_rect(BIOME_BACKDROPS[biome], View.ROOM_ART, false)
	else:
		var tones = ["#273c33", "#38304c", "#3c3831", "#442b3e", "#473c49", "#263651", "#3c3053", "#302748"]
		world_canvas.draw_rect(View.ROOM_ART, Color(tones[biome]))
		for x in range(30, 850, 24):
			for y in range(54, 382, 24):
				world_canvas.draw_rect(Rect2(x, y, 22, 22), Color(1, 1, 1, 0.045))
	View.petals(world_canvas, visual_clock, true)
	endless.draw_field(self)
	ground_hazards.draw(self)
	for drop: Dictionary in elite_heal_drops:
		var point := Vector2(drop.x, drop.y)
		world_canvas.draw_circle(point, 9.0, Color("#bcf4bd"), true, -1.0, true)
		world_canvas.draw_line(point + Vector2(-5, 0), point + Vector2(5, 0), Color("#305d43"), 2.5, true)
		world_canvas.draw_line(point + Vector2(0, -5), point + Vector2(0, 5), Color("#305d43"), 2.5, true)
	clockwork_floor.draw(self)
	pocket.draw(self)
	armory.draw(self)
	snare_thread.draw(self)
	painted_evolution.draw(self)
	View.draw_aim_preview(self)
	abilities.draw_effects(self)
	ultimates.draw_effects(self)
	combat_status.draw(self)
	talents.draw(self)
	for foe in foes:
		if foe.has("optional_boss"):
			OptionalBosses.draw_arena_props(self, foe)
			OptionalBosses.warning(self, foe)
			continue
		if foe.phase == 1:
			draw_warning(foe)
		if biome < ENCOUNTERS_BY_BIOME.size() and foe.has("biome"):
			ENCOUNTERS_BY_BIOME[biome].attack_effect(self, foe)
	var actors: Array = foes.duplicate()
	actors.append({"y": player.y, "hero_actor": true})
	if boss_victory.left > 0.0:
		actors.append({"y": boss_victory.spot.y, "falling_boss": true})
	for index in range(barrels.size()):
		var barrel: Vector2 = barrels[index]
		actors.append({"y": barrel.y, "barrel": barrel, "cover_index": index})
	if pending_chest:
		actors.append({"y": chest_position.y, "chest": true})
	elif uses_room_choice():
		actors.append({"y": chest_position.y, "encounter_prop": true})
	actors.sort_custom(func(a, b): return a.y < b.y)
	for actor in actors:
		if actor.has("hero_actor"):
			draw_hero()
		elif actor.has("falling_boss"):
			var defeat_pose := 6 if boss_victory.left > BossVictory.LANDING else 7
			if not OptionalBosses.draw_pose(world_canvas, optional_arena_boss(), defeat_pose, boss_victory.spot + Vector2(0, 13)):
				boss_victory.draw_actor(world_canvas, biome)
		elif actor.has("barrel"):
			if optional_arena_boss() == OptionalBosses.SCARECROW:
				OptionalBosses.draw_hay(world_canvas, actor.barrel)
			else:
				Art.room_cover(world_canvas, biome, depth, actor.cover_index, actor.barrel + Vector2(0, 9), room_kind == "boss")
		elif actor.has("chest"):
			draw_chest()
		elif actor.has("encounter_prop"):
			RouteView.draw_interaction_prop(self)
		else:
			draw_foe(actor, biome)
	for bolt in bolts:
		var direction = Vector2(bolt.dx, bolt.dy)
		var pos = target(bolt)
		if bolt.has("ultimate"):
			HeroUltimates.draw_bolt(world_canvas, bolt, pos, direction)
		elif bolt.get("weapon_id", "") == ElegyMagic.WEAPON:
			ElegyMagic.draw_bolt(world_canvas, pos, direction, visual_clock)
		elif bolt.has("hero_projectile"):
			if not WeaponArt.draw_projectile(world_canvas, str(bolt.get("weapon_id", "")), pos, direction, visual_clock):
				HeroCombatVisuals.projectile(world_canvas, int(bolt.hero_projectile), pos, direction, visual_clock)
		elif bolt.get("glass_shard", false):
			world_canvas.draw_line(pos - direction * 9.0, pos, Color("#78ceeb"), 2.0, true)
			View.diamond(world_canvas, pos.round(), 3.0, Color("#d6ffff"))
		elif bolt.has("damage"):
			EnemyAttackArt.bolt(world_canvas, bolt, pos, direction, active_biome, visual_clock)
		if bolt.get("lily_repeat", false):
			HeroCombatVisuals.repeat_projectile(world_canvas, pos, direction)
		else:
			var tint: Color = COLORS[hero].lightened(0.22)
			world_canvas.draw_line(pos - direction * 13.0, pos, Color(tint, 0.46), 4, true)
			world_canvas.draw_circle(pos, 3.8, tint, true, -1.0, true)

func draw_chest() -> void:
	var feet = chest_position + Vector2(0, 12)
	var opening = chest_open_time > 0.0
	var progress = 1.0 - chest_open_time / CHEST_OPEN_DURATION
	var pulse = 0.5 + sin(visual_clock * 5.0) * 0.18
	world_canvas.draw_circle(chest_position - Vector2(0, 4), 29.0, Color(1.0, 0.67, 0.23, 0.19 * pulse), true, -1.0, true)
	Art.prop(world_canvas, 2 if opening else 1, feet, 50.0 if opening else 36.0)
	for i in range(6):
		var angle = i * TAU / 6.0 + visual_clock * 0.6
		var rise = fposmod(visual_clock * 23.0 + i * 8.0, 38.0)
		var offset = Vector2.from_angle(angle) * (18.0 + (progress * 15.0 if opening else 0.0))
		var point = chest_position + Vector2(offset.x, offset.y * 0.45 - rise)
		View.diamond(world_canvas, point, 2.2, Color(1, 0.85, 0.48, 1.0 - rise / 38.0))

func draw_hero() -> void:
	var ground = player + Vector2(0, 11)
	var elevation = abilities.elevation()
	Art.shadow(world_canvas, ground, 15.0 - elevation * 0.16)
	var feet = ground - Vector2(0.0, elevation)
	var attack_phase = clampf(1.0 - flash / SWING_DURATION, 0.0, 1.0)
	var skill_pose: Dictionary = abilities.action_pose()
	if dash_remaining > 0:
		HeroCombatVisuals.step_sweep(world_canvas, player, dash_vector.normalized(), COLORS[hero],
			clampf(dash_remaining / float(DASH_DURATIONS[hero]), 0.0, 1.0))
		for i in range(2, 0, -1):
			var trail = feet - dash_vector.normalized() * i * 16.0
			Art.heroine(world_canvas, hero, trail, 53, visual_clock, visual_velocity, 0.3, Color(COLORS[hero], 0.18))
	var tint = Color.WHITE.lerp(Color(1.25, 0.43, 0.50), damage_flash / 0.2)
	var height = 50.0 if hero == 2 else 56.0
	var moving = visual_velocity.length_squared() > 144.0
	if dash_remaining <= 0.0 and flash > 0.0 and attack_phase < 0.85:
		HeroCombatVisuals.action_body(world_canvas, hero, feet, height, attack_visual_facing,
			attack_phase, false, tint, 0.0, lily_repeat_visual)
	elif dash_remaining <= 0.0 and not skill_pose.is_empty():
		HeroCombatVisuals.action_body(world_canvas, hero, feet, height, skill_pose.direction,
			skill_pose.phase, skill_pose.skill, tint, skill_pose.impact)
	elif moving or facing.y < -0.50 or absf(facing.x) > 0.65:
		Art.walk(world_canvas, hero, feet, height, walk_distance, facing, moving, tint)
	else:
		Art.heroine(world_canvas, hero, feet, height, visual_clock, visual_velocity,
			maxf(0.0, flash / SWING_DURATION), tint)
	if flash > 0:
		HeroCombatVisuals.basic(world_canvas, hero, player, attack_visual_facing, attack_phase,
			lily_finisher_flash, lily_repeat_visual)
		WeaponArt.draw_swing(world_canvas, armory.for_hero(hero), player, attack_visual_facing, attack_phase)
	UpgradeArt.draw_guard(world_canvas, player, upgrades.aegis_flash)

func draw_warning(foe: Dictionary) -> void:
	if active_biome < ENCOUNTERS_BY_BIOME.size() and foe.has("move"):
		ENCOUNTERS_BY_BIOME[active_biome].warning(self, foe)
		return
	var point = Vector2(foe.tx, foe.ty)
	var radius = danger_radius(foe)
	var progress = clampf(1.0 - float(foe.clock) / float(foe.get("duration", 0.72)), 0.0, 1.0)
	world_canvas.draw_circle(point, radius, Color(1.0, 0.25, 0.35, 0.13 + 0.18 * progress), true, -1.0, true)
	world_canvas.draw_arc(point, radius, 0, TAU, 44, Color("#ffad9d"), 2.0, true)
	world_canvas.draw_arc(point, radius - 4.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 44, Color("#ffe3b3"), 3.0, true)

func draw_foe(foe: Dictionary, biome: int) -> void:
	if foe.get("chair_post", false):
		var center := target(foe)
		world_canvas.draw_circle(center, 15.0, Color("#472f55"))
		world_canvas.draw_rect(Rect2(center - Vector2(5, 21), Vector2(10, 25)), Color("#bc798f"))
		world_canvas.draw_arc(center - Vector2(0, 20), 7.0, 0, TAU, 16, Color("#ffe2c3"), 2.0, true)
		return
	if foe.get("brasswing_drone", false):
		var center := target(foe)
		world_canvas.draw_circle(center, 11.0, Color("#c68b51"), true)
		world_canvas.draw_arc(center, 14.0, visual_clock * 13.0, visual_clock * 13.0 + PI, 14, Color("#f4d191"), 2.0, true)
		world_canvas.draw_rect(Rect2(center + Vector2(-2, -2), Vector2(4, 4)), Color("#92ded2"))
		return
	if foe.get("web_anchor", false):
		ForestPalace.draw_web_anchor(self, foe)
		return
	if foe.get("flower_node", false):
		AstralCore.draw_node(self, foe)
		return
	var pos = target(foe)
	var radius = 26.0 if foe.boss else (18.0 if foe.get("elite", false) else 14.0)
	var feet = pos + Vector2(0, radius * 0.51)
	var visible := smoothstep(0.06, 0.90, 1.0 - room_arrival / ROOM_ARRIVAL)
	if room_arrival > 0.0:
		var bloom := clampf(1.0 - room_arrival / ROOM_ARRIVAL, 0.0, 1.0)
		var tint := Color("#f2adbe") if foe.boss else Color("#d6c4db")
		world_canvas.draw_arc(feet, radius * (0.77 + 0.4 * bloom), 0, TAU, 28,
			Color(tint, sin(PI * bloom) * 0.85), 1.5, true)
		feet.y += (1.0 - visible) * 8.0
	Art.shadow(world_canvas, feet, radius * 0.95 * visible)
	if foe.has("optional_boss") and not foe.has("optional_lesson") and OptionalBosses.draw_pose(world_canvas, foe.optional_boss, OptionalBosses.pose(foe, visual_clock), feet, visible):
		return
	if biome < Art.ENEMY_ATLASES.size():
		var kind = int(foe.get("kind", 3 if foe.boss else 0))
		var height = [42.0, 30.0, 44.0, 86.0, 55.0][kind]
		if foe.get("elite", false):
			height *= 1.3
		if biome == 1 and kind == BiomeEncounters.MYCELIUM_LEAPER:
			if foe.phase == ForgottenEncounters.LUNGE:
				var peak = sin(ForgottenEncounters.progress(foe) * PI) * 47.0
				feet.y -= minf(peak, maxf(0.0, feet.y - height - View.ROOM_ART.position.y - 3.0))
			elif foe.phase == ForgottenEncounters.RECOVERY:
				height = 42.0
		if biome == 0 and kind == ForgottenEncounters.SLUG and foe.phase == ForgottenEncounters.RECOVERY:
			world_canvas.draw_arc(feet - Vector2(0, 8), 22.0, visual_clock * 0.4, visual_clock * 0.4 + TAU * 0.72, 34, Color("#d9d999"), 1.7, true)
		if biome == 0 and kind == ForgottenEncounters.HEDGE_KNIGHT and foe.phase != ForgottenEncounters.RECOVERY and foe.has("dx"):
			var angle = ForgottenEncounters.direction(foe).angle()
			world_canvas.draw_arc(pos, 20.0, angle - 0.65, angle + 0.65, 14, Color("#d7dba0"), 2.0, true)
		if biome == 0 and kind == ForgottenEncounters.GARDENER and ForgottenEncounters.phase_two(foe):
			world_canvas.draw_arc(feet, 29.0 + sin(visual_clock * 4.0) * 2.0, 0.0, TAU, 44, Color("#e3a784"), 1.8, true)
		var hit := clampf(float(foe.get("flash", 0.0)) / 0.14, 0.0, 1.0)
		var actor_clock: float = visual_clock + float(pos.x) * 0.014
		if foe.boss:
			BossCombatVisuals.draw(world_canvas, biome, foe, feet, height, actor_clock, hit, visible)
		else:
			EnemyCombatVisuals.draw(world_canvas, biome, kind, foe, feet, height, actor_clock, hit, visible)
	else:
		world_canvas.draw_circle(pos, radius, Color("#cf608d", visible), true, -1.0, true)
	if visible < 0.96:
		return
	var top = pos.y - (81.0 if foe.boss and biome < Art.ENEMY_ATLASES.size() else (52.0 if foe.get("elite", false) else 40.0))
	var left = Vector2(pos.x - radius, top)
	endless.draw_foe_badge(world_canvas, foe, Vector2(pos.x + radius + 9.0, top + 7.0))
	if foe.get("elite", false):
		var badge := Vector2(pos.x + radius + 7.0, top + 7.0)
		world_canvas.draw_colored_polygon(PackedVector2Array([badge + Vector2(-7, 4), badge + Vector2(-8, -4), badge + Vector2(-3, -1), badge + Vector2(0, -8), badge + Vector2(3, -1), badge + Vector2(8, -4), badge + Vector2(7, 4)]), Color("#f0c279"))
	if foe.boss:
		return
	world_canvas.draw_line(left, left + Vector2(radius * 2.0, 0), Color("#3a1d37"), 3)
	world_canvas.draw_line(left, left + Vector2(radius * 2.0 * maxf(0.0, float(foe.hp) / foe.max), 0), Color("#f78e9f"), 2)
