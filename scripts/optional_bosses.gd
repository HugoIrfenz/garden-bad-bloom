extends RefCounted

const Geometry = preload("res://scripts/forgotten_encounters.gd")
const Relics = preload("res://scripts/relic_effects.gd")
const QUEEN = "queen_of_dandelions"
const MOTHER = "mother_of_spores"
const SCARECROW = "first_scarecrow"
const BANDIT = "truffle_bandit"
const BRASSWING = "baroness_brasswing"
const HOUR = "unfinished_hour"
const BRIDE = "bride_of_thorns"
const CHOIR = "antlered_choir"
const PRINCE = "crownless_prince"
const VELVET = "madam_black_velvet"
const MOONS = "queen_of_two_moons"
const LIBRARIAN = "nebula_librarian"
const CHAIR = "empty_sixth_chair"
const CHAIR_POSTS = [Vector2(254, 199), Vector2(610, 199)]
const MOON_ALTARS = [Vector2(235, 226), Vector2(629, 226)]
const VELVET_PUPPETS = [Vector2(277, 220), Vector2(587, 220)]
const PRINCE_MIRRORS = [Vector2(228, 202), Vector2(636, 202)]
const CHOIR_BELLS = [Vector2(217, 212), Vector2(432, 155), Vector2(647, 212)]
const NAMES = {QUEEN: "Queen of Dandelions", MOTHER: "Mother of Spores", SCARECROW: "The First Scarecrow", BANDIT: "The Truffle Bandit", BRASSWING: "Baroness Brasswing", HOUR: "The Unfinished Hour", BRIDE: "Bride of Thorns", CHOIR: "The Antlered Choir", PRINCE: "The Crownless Prince", VELVET: "Madam Black Velvet", MOONS: "Queen of Two Moons", LIBRARIAN: "The Nebula Librarian", CHAIR: "The Empty Sixth Chair"}
const REWARDS = {QUEEN: Relics.FEATHER_CROWN, MOTHER: Relics.MOTHERCAP_VEIL, SCARECROW: Relics.HONEST_EYES, BANDIT: Relics.TRUFFLE_SATCHEL, BRASSWING: Relics.BRASSWING_PIN, HOUR: Relics.SECOND_CHANCE_DIAL, BRIDE: Relics.THORN_VEIL, CHOIR: Relics.CHOIR_ANTLER, PRINCE: Relics.PRINCES_PIN, VELVET: Relics.VELVET_RIBBON, MOONS: Relics.TWIN_MOON_PENDANT, LIBRARIAN: Relics.NEBULA_INDEX, CHAIR: Relics.SIXTH_SEAT_TRINKET}
const MUSHROOMS = [Vector2(274, 243), Vector2(432, 282), Vector2(590, 243)]
const HAY_POSTS = [Vector2(300, 219), Vector2(564, 234)]
const RAIL_Y = [181.0, 232.0, 288.0]
const HOUR_ANCHORS = [Vector2(308, 227), Vector2(560, 227)]
const WINDUP = 0.85
# Each approach foe rehearses one attack using the arena's own telegraph.
const APPROACHES = {
	QUEEN: [["Seed Drift", 0], ["Airborne Nursery", 2]],
	SCARECROW: [["Needle Patch", 0], ["Straw Crossing", 1]],
	MOTHER: [["Spore Nursery", 0], ["Stepping Caps", 1]],
	BANDIT: [["Smuggler's Trail", 0], ["Truffle Run", 2]],
	BRASSWING: [["Needle Gallery", 0], ["Rotor Workshop", 1]],
	HOUR: [["Echo Antechamber", 0], ["Rewound Passage", 2]],
	BRIDE: [["Bouquet Path", 0], ["Ribbon Arbor", 1]],
	CHOIR: [["Antler Run", 0], ["Spirit Clearing", 1]],
	PRINCE: [["Fencing Gallery", 0], ["Chandelier Walk", 2]],
	VELVET: [["Spotlight Rehearsal", 0], ["Ribbon Wings", 1]],
	MOONS: [["Moonbeam Walk", 0], ["Gravity Court", 1]],
	LIBRARIAN: [["Letter Gallery", 0], ["Loose Pages", 2]],
	CHAIR: [["Banquet Procession", 0], ["Invitations Hall", 2]],
}
const SPRITES = {
	QUEEN: "res://assets/art/optional_bosses/queen_of_dandelions.png",
	MOTHER: "res://assets/art/optional_bosses/mother_of_spores.png",
	SCARECROW: "res://assets/art/optional_bosses/first_scarecrow.png",
	BANDIT: "res://assets/art/optional_bosses/truffle_bandit.png",
	BRASSWING: "res://assets/art/optional_bosses/baroness_brasswing.png",
	HOUR: "res://assets/art/optional_bosses/unfinished_hour.png",
	BRIDE: "res://assets/art/optional_bosses/bride_of_thorns.png",
	CHOIR: "res://assets/art/optional_bosses/antlered_choir.png",
	PRINCE: "res://assets/art/optional_bosses/crownless_prince.png",
	VELVET: "res://assets/art/optional_bosses/madam_black_velvet.png",
	MOONS: "res://assets/art/optional_bosses/queen_of_two_moons.png",
	LIBRARIAN: "res://assets/art/optional_bosses/nebula_librarian.png",
	CHAIR: "res://assets/art/optional_bosses/empty_sixth_chair.png",
}
const ARENAS = {
	QUEEN: "res://assets/art/optional_bosses/queen_arena.png",
	MOTHER: "res://assets/art/optional_bosses/mother_arena.png",
	SCARECROW: "res://assets/art/optional_bosses/scarecrow_arena.png",
	BANDIT: "res://assets/art/optional_bosses/bandit_arena.png",
	BRASSWING: "res://assets/art/optional_bosses/brasswing_arena.png",
	HOUR: "res://assets/art/optional_bosses/hour_arena.png",
	BRIDE: "res://assets/art/optional_bosses/bride_arena.png",
	CHOIR: "res://assets/art/optional_bosses/choir_arena.png",
	PRINCE: "res://assets/art/optional_bosses/prince_arena.png",
	VELVET: "res://assets/art/optional_bosses/velvet_arena.png",
	MOONS: "res://assets/art/optional_bosses/moons_arena.png",
	LIBRARIAN: "res://assets/art/optional_bosses/library_arena.png",
	CHAIR: "res://assets/art/optional_bosses/chair_arena.png",
}

static var loaded_encounter := ""
static var loaded_arena: Texture2D
static var loaded_sheets: Dictionary = {}

static func arena_texture(id: String) -> Texture2D:
	if id != loaded_encounter:
		loaded_encounter = id
		loaded_arena = load(ARENAS[id]) as Texture2D if ARENAS.has(id) else null
	return loaded_arena

static func draw_pose(canvas: Node2D, id: String, frame: int, feet: Vector2, alpha := 1.0, height := 92.0) -> bool:
	if not SPRITES.has(id):
		return false
	if not loaded_sheets.has(id):
		# A Codex page can show both bosses from its biome in one draw.
		if loaded_sheets.size() >= 2:
			loaded_sheets.erase(loaded_sheets.keys().front())
		loaded_sheets[id] = load(SPRITES[id]) as Texture2D
	var sheet: Texture2D = loaded_sheets[id]
	if sheet == null:
		return false
	var cell := sheet.get_size() / Vector2(4.0, 2.0)
	var source := Rect2(cell * Vector2(frame % 4, floorf(float(frame) / 4.0)), cell)
	var size := (cell * (height / cell.y)).round()
	canvas.draw_texture_rect_region(sheet, Rect2((feet - Vector2(size.x * 0.5, size.y * 0.91)).round(), size),
		source, Color(1.0, 1.0, 1.0, alpha))
	return true

static func pose(foe: Dictionary, time: float) -> int:
	if foe.get("optional_boss") == CHAIR and foe.get("optional_second", false):
		if foe.phase == Geometry.WINDUP or float(foe.clock) > 1.2:
			return 5
		return 6
	match int(foe.phase):
		Geometry.WINDUP: return 2
		Geometry.RECOVERY:
			if foe.get("optional_second", false) and float(foe.clock) > 1.2:
				return 5
			return 3 if float(foe.clock) > (0.76 if foe.get("optional_second", false) else 1.03) else 4
	return int(floorf(time * 3.0)) % 2

static func advance(game, foe: Dictionary, delta := 0.0) -> void:
	if foe.get("chair_post", false):
		return
	if foe.optional_boss in [HOUR, PRINCE, LIBRARIAN]:
		tick_hour_echoes(game, foe, delta)
	if foe.get("brasswing_drone", false):
		var origin: Vector2 = game.target(foe)
		for lane in range(RAIL_Y.size()):
			if cart_rect(game.room_clock, lane).has_point(origin):
				foe.hp = 0
				game.sound.play("boss_break")
				return
		var gap: Vector2 = game.player - origin
		if gap.length() > 104.0:
			var moved: Vector2 = game.slide_with_cover(origin, gap.normalized() * 69.0 * delta)
			foe.x = moved.x
			foe.y = moved.y
		if foe.clock <= 0.0:
			projectile(game, origin, gap.normalized(), 178.0, 1.3, 7)
			foe.clock = 1.8
		return
	if foe.clock > 0.0:
		return
	if foe.phase == Geometry.WINDUP:
		release(game, foe)
		return
	var threshold := 0.4 if foe.optional_boss in [BANDIT, CHOIR, LIBRARIAN, CHAIR] else 0.5
	if foe.optional_boss == HOUR:
		threshold = 0.6
	elif foe.optional_boss == VELVET:
		threshold = 0.45
	var second := not foe.has("optional_lesson") and float(foe.hp) <= float(foe.max) * threshold
	if second and not foe.get("optional_second", false):
		foe.optional_second = true
		foe.phase = Geometry.RECOVERY
		foe.clock = 1.35
		if foe.optional_boss == BRASSWING:
			for flank: float in [-1.0, 1.0]:
				var center: Vector2 = game.target(foe)
				var point: Vector2 = Geometry.clear_endpoint(game, center, Vector2(flank, 0), 95.0, game.BARREL_CLEARANCE)
				game.foes.append({"x": point.x, "y": point.y, "hp": 46, "max": 46, "clock": 1.8,
					"phase": 0, "boss": false, "kind": 0, "biome": 2, "optional_boss": BRASSWING,
					"brasswing_drone": true})
		if foe.optional_boss == CHAIR:
			for point: Vector2 in CHAIR_POSTS:
				game.foes.append({"x": point.x, "y": point.y, "hp": 45, "max": 45, "clock": 0.0,
					"phase": 0, "boss": false, "kind": 0, "biome": 6, "optional_boss": CHAIR, "chair_post": true})
		game.sound.play("boss_star" if foe.optional_boss == MOONS else "warning_boss")
		return
	var direction: Vector2 = game.target(foe).direction_to(game.player)
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	var attack := int(foe.get("optional_lesson", posmod(int(foe.get("optional_cycle", 0)), 3)))
	var duration := WINDUP if attack == 0 else 1.05
	if foe.optional_boss == MOTHER and attack == 1:
		var nearest := INF
		for point: Vector2 in MUSHROOMS:
			if on_safe_mushroom(point, second):
				nearest = minf(nearest, game.player.distance_to(point))
		duration = maxf(duration, (nearest - 28.0) / 95.0 + 0.22)
	foe.merge({"phase": Geometry.WINDUP, "clock": duration, "duration": duration,
		"dx": direction.x, "dy": direction.y, "tx": game.player.x, "ty": game.player.y,
		"optional_attack": attack}, true)

static func release(game, foe: Dictionary) -> void:
	var origin: Vector2 = game.target(foe)
	var direction := Vector2(foe.dx, foe.dy)
	var second := bool(foe.get("optional_second", false))
	var queen: bool = foe.optional_boss == QUEEN
	if foe.optional_boss == SCARECROW:
		release_scarecrow(game, foe, origin, direction, second)
		finish_attack(foe, second)
		return
	if foe.optional_boss == BANDIT:
		release_bandit(game, foe, origin, direction, second)
		finish_attack(foe, second)
		return
	if foe.optional_boss == BRASSWING:
		release_brasswing(game, foe, origin, direction)
		finish_attack(foe, second)
		return
	if foe.optional_boss == HOUR:
		release_hour(game, foe, origin, direction, second)
		finish_attack(foe, second)
		return
	if foe.optional_boss == BRIDE:
		release_bride(game, foe, origin, direction, second)
		finish_attack(foe, second)
		if int(foe.optional_attack) == 2:
			foe.clock = 1.62
		return
	if foe.optional_boss == CHOIR:
		release_choir(game, foe, origin, direction, second)
		finish_attack(foe, second)
		return
	if foe.optional_boss == PRINCE:
		release_prince(game, foe, origin, direction, second)
		finish_attack(foe, second)
		return
	if foe.optional_boss == VELVET:
		release_velvet(game, foe, origin, direction, second)
		finish_attack(foe, second)
		return
	if foe.optional_boss == MOONS:
		release_moons(game, foe, origin, direction, second)
		finish_attack(foe, second)
		return
	if foe.optional_boss == CHAIR:
		release_chair(game, foe, origin, direction)
		finish_attack(foe, second)
		return
	if foe.optional_boss == LIBRARIAN:
		release_librarian(game, foe, origin, direction)
		finish_attack(foe, second)
		return
	match int(foe.optional_attack):
		0:
			for index in range(-3, 4):
				var ray := direction.rotated(index * 0.17)
				if queen and second:
					var edge: Vector2 = Geometry.clear_endpoint(game, origin, ray, 270.0, 14.0)
					projectile(game, edge, -ray, 225.0, 1.4, 12)
				else:
					projectile(game, origin, ray, 205.0, 1.7, 11)
		1:
			if queen:
				var offset: Vector2 = game.player - origin
				if offset.length() <= 260.0 and offset.normalized().dot(direction) > 0.74 and not Geometry.blocked(game, origin, game.player, 14.0):
					game.player = game.slide_with_cover(game.player, direction * (-64.0 if second else 64.0))
					game.damage_hero(10, origin)
			elif not on_safe_mushroom(game.player, second):
				var hp_before: int = game.hp
				game.damage_hero(14, origin)
				if game.hp < hp_before and game.hp > 0:
					game.combat_status.apply_hero("poison", 3.0, 1.0, MOTHER)
		2:
			for point: Vector2 in bomb_points(foe):
				if queen:
					if game.player.distance_to(point) <= 30.0:
						game.damage_hero(14)
				else:
					projectile(game, game.clamp_position(point), Vector2.LEFT if second else Vector2.RIGHT, 70.0, 2.5, 12)
	finish_attack(foe, second)

static func finish_attack(foe: Dictionary, second: bool) -> void:
	foe.optional_cycle = int(foe.get("optional_cycle", 0)) + 1
	foe.phase = Geometry.RECOVERY
	foe.clock = 1.8 if foe.has("optional_lesson") else (0.95 if second else 1.22)
	if foe.get("optional_hay_stagger", false):
		foe.clock = 2.1
		foe.erase("optional_hay_stagger")

static func chair_attack_end(game, origin: Vector2, direction: Vector2, attack: int) -> Vector2:
	return Geometry.clear_endpoint(game, origin, direction, 226.0 if attack == 0 else 560.0, game.BARREL_CLEARANCE)

static func chair_posts_active(foes: Array) -> bool:
	for foe: Dictionary in foes:
		if foe.get("chair_post", false) and int(foe.hp) > 0:
			return true
	return false

static func release_chair(game, foe: Dictionary, origin: Vector2, direction: Vector2) -> void:
	var attack := int(foe.optional_attack)
	if attack == 2:
		var invitation := Vector2(foe.tx, foe.ty)
		if game.player.distance_to(invitation) <= 43.0:
			var before: int = game.hp
			game.damage_hero(13, origin)
			if game.hp < before and game.hp > 0:
				game.combat_status.apply_hero("root", 1.9, 1.0, CHAIR)
		return
	var endpoint := chair_attack_end(game, origin, direction, attack)
	if attack == 0:
		foe.x = endpoint.x
		foe.y = endpoint.y
		game.sound.play("enemy_crash")
	else:
		game.sound.play("enemy_arcane")
	if Geometry.segment_gap(game.player, origin, endpoint) <= (26.0 if attack == 0 else 18.0):
		game.damage_hero(19 if attack == 0 else 23, origin)

static func library_patterns(game, foe: Dictionary, origin: Vector2, direction: Vector2) -> Array:
	var strikes: Array = []
	var target := Vector2(foe.tx, foe.ty)
	if int(foe.optional_attack) == 2:
		for index in range(-1, 2):
			var point: Vector2 = game.clamp_position(target + Vector2(index * 76, abs(index) * -26))
			strikes.append(hour_echo(0.55 + abs(index) * 0.36, point, point, 35.0))
	elif int(foe.optional_attack) == 1:
		var angle: float = direction.angle()
		var stage_count := 3 if foe.get("optional_second", false) else 1
		for stage in range(stage_count):
			var axis := Vector2.from_angle(angle + stage * 0.42)
			var left: Vector2 = Geometry.clear_endpoint(game, origin, -axis, 320.0, 14.0)
			var right: Vector2 = Geometry.clear_endpoint(game, origin, axis, 320.0, 14.0)
			if left.distance_to(origin) > 68.0:
				strikes.append(hour_echo(0.48 + stage * 0.43, left, origin - axis * 68.0, 17.0))
			if right.distance_to(origin) > 68.0:
				strikes.append(hour_echo(0.48 + stage * 0.43, origin + axis * 68.0, right, 17.0))
	return strikes

static func release_librarian(game, foe: Dictionary, origin: Vector2, direction: Vector2) -> void:
	if int(foe.optional_attack) == 0:
		for angle: float in [-0.49, -0.33, 0.0, 0.33, 0.49]:
			projectile(game, origin, direction.rotated(angle), 262.0, 1.5, 13)
	else:
		foe.hour_echoes = library_patterns(game, foe, origin, direction)

static func release_moons(game, foe: Dictionary, origin: Vector2, direction: Vector2, swapped: bool) -> void:
	var bright: Vector2 = MOON_ALTARS[1 if swapped else 0]
	var dark: Vector2 = MOON_ALTARS[0 if swapped else 1]
	var target := Vector2(foe.tx, foe.ty)
	match int(foe.optional_attack):
		0:
			var end: Vector2 = Geometry.clear_endpoint(game, bright, bright.direction_to(target), 550.0, 14.0)
			if Geometry.segment_gap(game.player, bright, end) <= 18.0:
				game.damage_hero(18, bright)
		1:
			var in_dark_half: bool = game.player.x < 387.0 if swapped else game.player.x > 477.0
			if in_dark_half and game.player.distance_to(dark) <= 245.0 and not Geometry.blocked(game, game.player, dark, 14.0):
				game.player = game.slide_with_cover(game.player, (dark - game.player).limit_length(88.0))
				game.damage_hero(13, dark)
		2:
			var gap: Vector2 = game.player - origin
			if gap.length() <= 164.0 and absf(direction.angle_to(gap)) <= 0.82 and not Geometry.blocked(game, origin, game.player, 14.0):
				game.damage_hero(20, origin)

static func velvet_spot(foe: Dictionary) -> Vector2:
	var index := posmod(int(foe.get("optional_cycle", 0)) / 3, VELVET_PUPPETS.size())
	var target := Vector2(foe.tx, foe.ty)
	return VELVET_PUPPETS[index] if foe.get("optional_second", false) else target

static func release_velvet(game, foe: Dictionary, origin: Vector2, direction: Vector2, second: bool) -> void:
	var target := Vector2(foe.tx, foe.ty)
	match int(foe.optional_attack):
		0:
			var spot := velvet_spot(foe)
			if second:
				foe.velvet_revealed = int(foe.get("velvet_revealed", 0)) | (1 << VELVET_PUPPETS.find(spot))
			if game.player.distance_to(spot) <= 52.0:
				game.damage_hero(17 if second else 10, origin)
		1:
			var end: Vector2 = Geometry.clear_endpoint(game, origin, direction, 260.0, 14.0)
			if Geometry.segment_gap(game.player, origin, end) <= 23.0:
				game.player = game.slide_with_cover(game.player, (origin - game.player).limit_length(72.0))
				game.damage_hero(13, origin)
		2:
			for index in range(VELVET_PUPPETS.size()):
				if int(foe.get("velvet_severed", 0)) & (1 << index):
					continue
				var puppet: Vector2 = VELVET_PUPPETS[index]
				var aim := puppet.direction_to(target)
				for angle: float in [-0.22, 0.0, 0.22]:
					projectile(game, puppet, aim.rotated(angle), 220.0, 1.6, 12)

static func sever_velvet_string(game, tap := Vector2.INF) -> bool:
	for foe: Dictionary in game.foes:
		if foe.get("optional_boss") != VELVET or int(foe.hp) <= 0:
			continue
		var visible := int(foe.get("velvet_revealed", 0))
		var severed := int(foe.get("velvet_severed", 0))
		for index in range(VELVET_PUPPETS.size()):
			var point: Vector2 = VELVET_PUPPETS[index]
			var bit := 1 << index
			if (visible & bit) and not (severed & bit) and game.player.distance_to(point) <= 36.0 \
					and (not tap.is_finite() or tap.distance_to(point) <= 28.0):
				foe.velvet_severed = severed | bit
				game.sound.play("boss_break")
				game.checkpoint()
				return true
	return false

static func prince_patterns(game, foe: Dictionary, origin: Vector2, direction: Vector2) -> Array:
	var strikes: Array = []
	var aim := Vector2(foe.tx, foe.ty)
	match int(foe.optional_attack):
		0:
			for angle: float in [0.0, -0.22, 0.22]:
				var end: Vector2 = Geometry.clear_endpoint(game, origin, direction.rotated(angle), 148.0, 14.0)
				strikes.append(hour_echo(0.2 + absf(angle) * 2.7 + (0.25 if angle > 0.0 else 0.0), origin, end, 16.0))
		1:
			for mirror: Vector2 in PRINCE_MIRRORS:
				if int(foe.get("prince_broken", 0)) & (1 << PRINCE_MIRRORS.find(mirror)):
					continue
				var end: Vector2 = Geometry.clear_endpoint(game, mirror, mirror.direction_to(aim), 210.0, 14.0)
				strikes.append(hour_echo(0.54, mirror, end, 19.0))
		2:
			var drop: Vector2 = PRINCE_MIRRORS[0] if aim.distance_to(PRINCE_MIRRORS[0]) < aim.distance_to(PRINCE_MIRRORS[1]) else PRINCE_MIRRORS[1]
			if aim.distance_to(drop) > 68.0:
				drop = aim
			strikes.append(hour_echo(0.45, drop, drop, 50.0))
	return strikes

static func release_prince(game, foe: Dictionary, origin: Vector2, direction: Vector2, second: bool) -> void:
	var strikes := prince_patterns(game, foe, origin, direction)
	if int(foe.optional_attack) == 2:
		var drop: Dictionary = strikes[0]
		drop.mirror = PRINCE_MIRRORS.find(Vector2(drop.x, drop.y))
	if second and int(foe.optional_attack) == 1:
		for hit: Dictionary in strikes:
			hit.left = 0.42 if float(hit.x) < 432.0 else 0.72
	foe.hour_echoes = strikes

static func choir_charge(game, foe: Dictionary, origin: Vector2, direction: Vector2) -> Vector2:
	var bells := 3
	var muted := int(foe.get("choir_muted", 0))
	for index in range(CHOIR_BELLS.size()):
		if muted & (1 << index):
			bells -= 1
	var distance := 155.0 + 42.0 * bells if foe.get("optional_second", false) else 190.0
	return Geometry.clear_endpoint(game, origin, direction, distance, game.BARREL_CLEARANCE)

static func choir_flowers(foe: Dictionary) -> Array[Vector2]:
	var target := Vector2(foe.tx, foe.ty)
	return [target, target + Vector2(-72, 24), target + Vector2(72, 24)]

static func release_choir(game, foe: Dictionary, origin: Vector2, direction: Vector2, second: bool) -> void:
	match int(foe.optional_attack):
		0:
			var end := choir_charge(game, foe, origin, direction)
			if Geometry.segment_gap(game.player, origin, end) <= 23.0:
				game.damage_hero(20, origin)
			foe.x = end.x
			foe.y = end.y
		1:
			var spread := 3 if second else 2
			for index in range(-spread, spread + 1):
				projectile(game, origin, direction.rotated(index * 0.24), 235.0, 1.65, 12)
		2:
			for point in choir_flowers(foe):
				if game.player.distance_to(point) <= 34.0:
					game.damage_hero(17)
					break

static func mute_choir_bell(game, tap := Vector2.INF) -> bool:
	for foe: Dictionary in game.foes:
		if foe.get("optional_boss") != CHOIR or int(foe.hp) <= 0:
			continue
		var mask := int(foe.get("choir_muted", 0))
		for index in range(CHOIR_BELLS.size()):
			var point: Vector2 = CHOIR_BELLS[index]
			if (mask & (1 << index)) == 0 and game.player.distance_to(point) <= 32.0 \
					and (not tap.is_finite() or tap.distance_to(point) <= 25.0):
				foe.choir_muted = mask | (1 << index)
				game.sound.play("confirm")
				game.checkpoint()
				return true
	return false

static func bride_lanes(game, origin: Vector2, direction: Vector2, second: bool) -> Array[PackedVector2Array]:
	var lanes: Array[PackedVector2Array] = []
	var angles: Array = [-0.54, 0.54] if second else [0.0]
	for angle: float in angles:
		var middle: Vector2 = Geometry.clear_endpoint(game, origin, direction.rotated(angle), 103.0, 14.0)
		var end: Vector2 = Geometry.clear_endpoint(game, middle, direction.rotated(-angle), 110.0, 14.0)
		lanes.append(PackedVector2Array([origin, middle, end]))
	return lanes

static func release_bride(game, foe: Dictionary, origin: Vector2, direction: Vector2, second: bool) -> void:
	match int(foe.optional_attack):
		0:
			for index in range(-2, 3):
				projectile(game, origin, direction.rotated(index * 0.22), 232.0, 1.45, 13)
		1:
			var knot := Vector2(foe.tx, foe.ty)
			if game.player.distance_to(knot) < 42.0:
				var before: int = game.hp
				game.damage_hero(10, origin)
				if game.hp < before and game.hp > 0:
					game.combat_status.apply_hero("root", 1.65, 1.0, BRIDE)
		2:
			for lane in bride_lanes(game, origin, direction, second):
				for index in range(1, lane.size()):
					if Geometry.segment_gap(game.player, lane[index - 1], lane[index]) <= 23.0:
						game.damage_hero(19, origin)
						return

static func release_hour(game, foe: Dictionary, origin: Vector2, direction: Vector2, second: bool) -> void:
	var target := Vector2(foe.tx, foe.ty)
	var attack := int(foe.optional_attack)
	var echoes: Array = foe.get("hour_echoes", [])
	match attack:
		0:
			echoes.append(hour_echo(0.72, target, target, 38.0))
		1:
			var end: Vector2 = Geometry.clear_endpoint(game, origin, direction, 460.0, 14.0)
			if Geometry.segment_gap(game.player, origin, end) <= 17.0:
				game.damage_hero(16, origin)
			echoes.append(hour_echo(0.58, origin, end, 17.0))
		2:
			var old := Vector2(float(foe.get("hour_old_x", target.x)), float(foe.get("hour_old_y", target.y)))
			echoes.append(hour_echo(0.52, old, old, 45.0))
	if second:
		for index in range(HOUR_ANCHORS.size()):
			var anchor: Vector2 = HOUR_ANCHORS[index]
			var side := -1.0 if index == 0 else 1.0
			var mirrored := Vector2(864.0 - target.x, target.y)
			var delay := 0.95 if side < 0.0 else 1.22
			if attack == 1:
				var end: Vector2 = Geometry.clear_endpoint(game, anchor, anchor.direction_to(mirrored), 360.0, 14.0)
				echoes.append(hour_echo(delay, anchor, end, 13.0))
			else:
				var offset := target - origin
				offset.x *= -side
				var footprint: Vector2 = game.clamp_position(anchor + offset.limit_length(115.0))
				echoes.append(hour_echo(delay, footprint, footprint, 32.0 if attack == 0 else 39.0))
	foe.hour_echoes = echoes
	foe.hour_old_x = target.x
	foe.hour_old_y = target.y

static func hour_echo(left: float, start: Vector2, end: Vector2, radius: float) -> Dictionary:
	return {"left": left, "x": start.x, "y": start.y, "ex": end.x, "ey": end.y, "radius": radius}

static func tick_hour_echoes(game, foe: Dictionary, delta: float) -> void:
	var echoes: Array = foe.get("hour_echoes", [])
	for index in range(echoes.size() - 1, -1, -1):
		var echo: Dictionary = echoes[index]
		echo.left = float(echo.left) - delta
		if echo.left > 0.0:
			continue
		var origin := Vector2(echo.x, echo.y)
		var end := Vector2(echo.ex, echo.ey)
		var gap: float = game.player.distance_to(origin) if origin == end else Geometry.segment_gap(game.player, origin, end)
		if gap <= float(echo.radius):
			game.damage_hero(14, origin)
		if int(echo.get("mirror", -1)) >= 0:
			foe.prince_broken = int(foe.get("prince_broken", 0)) | (1 << int(echo.mirror))
			game.sound.play("boss_break")
		echoes.remove_at(index)

static func release_brasswing(game, foe: Dictionary, origin: Vector2, direction: Vector2) -> void:
	match int(foe.optional_attack):
		0:
			var end: Vector2 = Geometry.clear_endpoint(game, origin, direction, 245.0, game.BARREL_CLEARANCE)
			if Geometry.segment_gap(game.player, origin, end) <= 16.0:
				game.damage_hero(19, origin)
			foe.x = end.x
			foe.y = end.y
		1:
			var gap: Vector2 = game.player - origin
			if gap.length() <= 116.0 and not Geometry.blocked(game, origin, game.player, 14.0):
				game.player = game.slide_with_cover(game.player, gap.normalized() * 76.0)
				game.damage_hero(12, origin)
		2:
			for angle: float in [-0.62, -0.37, -0.12, 0.12, 0.37, 0.62]:
				projectile(game, origin, direction.rotated(angle), 295.0, 1.55, 13)

static func bandit_dash(game, origin: Vector2, direction: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array([origin])
	for turn: float in [0.36, -0.36, 0.36]:
		points.append(Geometry.clear_endpoint(game, points[-1], direction.rotated(turn), 66.0, game.BARREL_CLEARANCE))
	return points

static func release_bandit(game, foe: Dictionary, origin: Vector2, direction: Vector2, second: bool) -> void:
	match int(foe.optional_attack):
		0:
			var path := bandit_dash(game, origin, direction)
			for index in range(1, path.size()):
				if Geometry.segment_gap(game.player, path[index - 1], path[index]) <= 22.0:
					game.damage_hero(16, path[index - 1])
					break
			foe.x = path[-1].x
			foe.y = path[-1].y
		1:
			for index in range(-2, 3):
				projectile(game, origin, direction.rotated(index * 0.23), 285.0, 1.55, 11)
		2:
			var target := Vector2(foe.tx, foe.ty)
			if second and game.player.distance_to(target) < 110.0 and not Geometry.blocked(game, game.player, target, 14.0):
				var pull: Vector2 = (target - game.player).limit_length(58.0)
				game.player = game.slide_with_cover(game.player, pull)
			var before: int = game.bolts.size()
			projectile(game, origin, direction, 165.0, 2.55, 18)
			game.bolts[before].radius = 29.0

static func scarecrow_decoys(origin: Vector2, direction: Vector2) -> Array[Vector2]:
	var flank := direction.orthogonal() * 82.0
	return [origin - flank, origin + flank]

static func release_scarecrow(game, foe: Dictionary, origin: Vector2, direction: Vector2, second: bool) -> void:
	match int(foe.optional_attack):
		0:
			var needles := 2 if second else 1
			for index in range(-needles, needles + 1):
				projectile(game, origin, direction.rotated(index * 0.11), 360.0, 1.2, 12)
		1:
			var end := Geometry.clear_endpoint(game, origin, direction, 195.0, game.BARREL_CLEARANCE)
			if Geometry.segment_gap(game.player, origin, end) <= 19.0:
				game.damage_hero(17, origin)
			foe.x = end.x
			foe.y = end.y
			for index in range(HAY_POSTS.size()):
				var post: Vector2 = HAY_POSTS[index]
				if post in game.barrels and end.distance_to(post) < game.BARREL_CLEARANCE + 8.0 \
						and (post - end).dot(direction) > 0.0:
					var node: Dictionary = game.floor_manifest.nodes[game.room_id]
					node.broken_hay = int(node.get("broken_hay", 0)) | (1 << index)
					game.barrels.erase(post)
					foe.optional_hay_stagger = true
					game.sound.play("boss_break")
					break
		2:
			for point: Vector2 in scarecrow_decoys(origin, direction):
				if game.ARENA.has_point(point):
					var aim := point.direction_to(Vector2(foe.tx, foe.ty))
					projectile(game, point, aim, 245.0, 1.3, 10)

static func bomb_points(foe: Dictionary) -> Array[Vector2]:
	var aim := Vector2(foe.tx, foe.ty)
	return [aim + Vector2(-65, -18), aim, aim + Vector2(65, 18)]

static func on_safe_mushroom(point: Vector2, second: bool) -> bool:
	for index in range(MUSHROOMS.size()):
		if (index % 2 == 1) == second and point.distance_to(MUSHROOMS[index]) <= 32.0:
			return true
	return false

static func draw_arena_props(game, foe: Dictionary) -> void:
	var canvas: Node2D = game.world_canvas
	if foe.get("brasswing_drone", false):
		return
	var second := bool(foe.get("optional_second", false))
	if foe.optional_boss == CHAIR and second:
		var shoulder: Vector2 = game.target(foe) - Vector2(0, 66)
		for post: Dictionary in game.foes:
			if post.get("chair_post", false) and int(post.hp) > 0:
				var tip: Vector2 = game.target(post) - Vector2(0, 21)
				canvas.draw_line(tip, shoulder, Color("#f1a5c3"), 2.0, true)
	elif foe.optional_boss == MOONS:
		for index in range(MOON_ALTARS.size()):
			var center: Vector2 = MOON_ALTARS[index]
			var ink := Color("#ffe4b7") if (index == 1) == second else Color("#9e81d0")
			canvas.draw_circle(center, 21.0, Color(ink, 0.18))
			canvas.draw_arc(center, 21.0, 0.0, TAU, 36, ink, 2.0, true)
		for x: float in [387.0, 477.0]:
			canvas.draw_dashed_line(Vector2(x, 112), Vector2(x, 345), Color("#a0c4d9"), 1.0, 6.0)
	elif foe.optional_boss == VELVET:
		for index in range(VELVET_PUPPETS.size()):
			var bit := 1 << index
			if (int(foe.get("velvet_revealed", 0)) & bit) and not (int(foe.get("velvet_severed", 0)) & bit):
				var point: Vector2 = VELVET_PUPPETS[index]
				canvas.draw_line(point - Vector2(0, 58), point, Color("#efb2c9"), 2.0, true)
				canvas.draw_circle(point, 12.0, Color("#bd7d9e"))
				canvas.draw_arc(point, 18.0, 0.0, TAU, 24, Color("#efb2c9"), 1.5, true)
	elif foe.optional_boss == CHOIR:
		var mask := int(foe.get("choir_muted", 0))
		for index in range(CHOIR_BELLS.size()):
			var point: Vector2 = CHOIR_BELLS[index]
			var muted := (mask & (1 << index)) != 0
			var ink := Color("#796879") if muted else Color("#e3b28f")
			canvas.draw_circle(point, 14.0, Color("#422534"))
			canvas.draw_arc(point, 11.0, PI, TAU, 18, ink, 3.0, true)
			canvas.draw_line(point + Vector2(-11, 0), point + Vector2(11, 0), ink, 2.0, true)
			if not muted and game.player.distance_to(point) <= 32.0:
				canvas.draw_arc(point, 20.0, 0.0, TAU, 24, ink, 1.5, true)
	elif foe.optional_boss == HOUR:
		for index in range(HOUR_ANCHORS.size()):
			var anchor: Vector2 = HOUR_ANCHORS[index]
			var angle: float = game.room_clock * (0.7 if index == 0 else -0.7)
			var ink := Color("#e0aaed") if second else Color("#d2b69d")
			for offset: float in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
				canvas.draw_arc(anchor, 78.0, angle + offset, angle + offset + 0.9, 16, Color(ink, 0.64), 2.0, true)
	elif foe.optional_boss == PRINCE:
		for index in range(PRINCE_MIRRORS.size()):
			var mirror: Vector2 = PRINCE_MIRRORS[index]
			if int(foe.get("prince_broken", 0)) & (1 << index):
				canvas.draw_line(mirror - Vector2(13, 4), mirror + Vector2(15, 5), Color("#ac8fae"), 3.0, true)
			else:
				canvas.draw_rect(Rect2(mirror - Vector2(12, 35), Vector2(24, 38)), Color("#bec6ee"))
				canvas.draw_rect(Rect2(mirror - Vector2(12, 35), Vector2(24, 38)), Color("#c99d70"), false, 3.0)
		if second:
			var shadow: Vector2 = game.target(foe) + Vector2(0, 12)
			canvas.draw_line(shadow - Vector2(18, 0), shadow + Vector2(18, 0), Color("#432b51"), 7.0, true)
	if foe.optional_boss in [HOUR, PRINCE, LIBRARIAN]:
		draw_echo_warnings(canvas, foe.get("hour_echoes", []))
	if foe.optional_boss == LIBRARIAN and second:
		var center: Vector2 = game.target(foe)
		for index in range(4):
			var point := center + Vector2.from_angle(game.room_clock * 1.1 + index * PI * 0.5) * 48.0
			canvas.draw_rect(Rect2(point - Vector2(6, 8), Vector2(12, 16)), Color("#635587"))
			canvas.draw_line(point + Vector2(-4, -5), point + Vector2(4, -5), Color("#f2d79e"), 1.5)
	if foe.optional_boss == MOTHER:
		for point: Vector2 in MUSHROOMS:
			var safe := on_safe_mushroom(point, second)
			var ink := Color("#b8efab") if safe else Color("#95799e")
			canvas.draw_circle(point, 32.0, Color(ink, 0.16), true, -1.0, true)
			canvas.draw_arc(point, 32.0, 0.0, TAU, 36, Color(ink, 0.85), 2.0, true)
			for offset: Vector2 in [Vector2(-11, -7), Vector2(9, -10), Vector2(4, 10)]:
				canvas.draw_circle(point + offset, 3.0, ink, true)
	elif foe.optional_boss == BRASSWING:
		for lane in range(RAIL_Y.size()):
			var cart := cart_rect(game.room_clock, lane)
			canvas.draw_rect(cart.grow(2), Color("#26232b"))
			canvas.draw_rect(cart, Color("#a47546"))
			canvas.draw_rect(cart.grow(-4), Color("#577975"))
			canvas.draw_line(cart.position + Vector2(3, 3), Vector2(cart.end.x - 3, cart.position.y + 3), Color("#f5d597"), 2.0)
			for shift: float in [10.0, 31.0]:
				canvas.draw_circle(Vector2(cart.position.x + shift, cart.end.y), 3.0, Color("#242130"))
	elif second and foe.optional_boss == QUEEN:
		var crown: Vector2 = game.target(foe) + Vector2(0, -55.0 + sin(game.visual_clock * 4.0) * 5.0)
		canvas.draw_colored_polygon(PackedVector2Array([
			crown + Vector2(-13, -6), crown + Vector2(-6, 0), crown + Vector2(0, -12),
			crown + Vector2(6, 0), crown + Vector2(13, -6), crown + Vector2(9, 7),
			crown + Vector2(-9, 7),
		]), Color("#f9d37a"))

static func draw_echo_warnings(canvas: Node2D, echoes: Array) -> void:
	for echo: Dictionary in echoes:
		var origin := Vector2(echo.x, echo.y)
		var end := Vector2(echo.ex, echo.ey)
		if origin == end:
			canvas.draw_circle(origin, echo.radius, Geometry.WARNING_FILL)
			canvas.draw_arc(origin, echo.radius, 0.0, TAU, 34, Color("#f3cc91"), 2.0, true)
		else:
			canvas.draw_line(origin, end, Geometry.WARNING_FILL, float(echo.radius) * 2.0, true)
			canvas.draw_line(origin, end, Color("#f3cc91"), 2.0, true)

static func cart_rect(time: float, lane: int) -> Rect2:
	var progress := pingpong(time * (0.24 + float(lane) * 0.025) + float(lane) * 0.59, 1.0)
	var center := Vector2(82.0 + progress * 700.0, RAIL_Y[lane])
	return Rect2(center - Vector2(21, 9), Vector2(42, 18))

static func tick_rails(game) -> void:
	for lane in range(RAIL_Y.size()):
		var cart := cart_rect(game.room_clock, lane)
		if cart.has_point(game.player):
			game.damage_hero(9, cart.get_center())
			return

static func projectile(game, origin: Vector2, direction: Vector2, speed: float, lifetime: float, damage: int) -> void:
	game.bolts.append({"x": origin.x, "y": origin.y, "dx": direction.x, "dy": direction.y,
		"life": lifetime, "speed": speed, "damage": damage})

static func warning(game, foe: Dictionary) -> void:
	if foe.phase != Geometry.WINDUP:
		return
	var canvas: Node2D = game.world_canvas
	var origin: Vector2 = game.target(foe)
	var direction := Vector2(foe.dx, foe.dy)
	var queen: bool = foe.optional_boss == QUEEN
	if foe.optional_boss == CHAIR:
		var attack := int(foe.optional_attack)
		var tint := Color("#ffc0e0")
		if attack == 2:
			var point := Vector2(foe.tx, foe.ty)
			canvas.draw_circle(point, 43.0, Color(tint, 0.18))
			canvas.draw_arc(point, 43.0, 0, TAU, 36, tint, 2.0, true)
			canvas.draw_rect(Rect2(point - Vector2(10, 7), Vector2(20, 14)), tint, false, 2.0)
		else:
			var end := chair_attack_end(game, origin, direction, attack)
			canvas.draw_line(origin, end, Color(tint, 0.2), 52.0 if attack == 0 else 36.0, true)
			canvas.draw_line(origin, end, tint, 2.0, true)
		return
	if foe.optional_boss == LIBRARIAN:
		if int(foe.optional_attack) == 0:
			for angle: float in [-0.49, -0.33, 0.0, 0.33, 0.49]:
				var end: Vector2 = Geometry.clear_endpoint(game, origin, direction.rotated(angle), 393.0, 14.0)
				canvas.draw_line(origin, end, Color("#c7a9f4"), 1.8, true)
		else:
			draw_echo_warnings(canvas, library_patterns(game, foe, origin, direction))
		return
	if foe.optional_boss == SCARECROW:
		warn_scarecrow(game, foe, canvas, origin, direction)
		return
	if foe.optional_boss == BANDIT:
		warn_bandit(game, foe, canvas, origin, direction)
		return
	if foe.optional_boss == BRIDE:
		warn_bride(game, foe, canvas, origin, direction)
		return
	if foe.optional_boss == PRINCE:
		draw_echo_warnings(canvas, prince_patterns(game, foe, origin, direction))
		if int(foe.optional_attack) == 1:
			for index in range(PRINCE_MIRRORS.size()):
				if (int(foe.get("prince_broken", 0)) & (1 << index)) == 0:
					draw_pose(canvas, PRINCE, 2, PRINCE_MIRRORS[index] + Vector2(0, 13), 0.47)
		return
	if foe.optional_boss == MOONS:
		var swapped := bool(foe.get("optional_second", false))
		var bright: Vector2 = MOON_ALTARS[1 if swapped else 0]
		var dark: Vector2 = MOON_ALTARS[0 if swapped else 1]
		match int(foe.optional_attack):
			0:
				var aim := Vector2(foe.tx, foe.ty)
				var end: Vector2 = Geometry.clear_endpoint(game, bright, bright.direction_to(aim), 550.0, 14.0)
				canvas.draw_line(bright, end, Geometry.WARNING_FILL, 36.0, true)
				canvas.draw_line(bright, end, Color("#ffe4b7"), 2.0, true)
			1:
				var danger := game.ARENA as Rect2
				if swapped:
					danger.size.x = 387.0 - danger.position.x
				else:
					var right := danger.end.x
					danger.position.x = 477.0
					danger.size.x = right - 477.0
				canvas.draw_rect(danger, Geometry.WARNING_FILL)
				canvas.draw_arc(dark, 245.0, 0.0, TAU, 54, Color("#bda1ec"), 2.0, true)
			2:
				canvas.draw_arc(origin, 164.0, direction.angle() - 0.82, direction.angle() + 0.82, 32, Color("#ffe4b7"), 4.0, true)
				for offset: float in [-0.82, 0.82]:
					canvas.draw_line(origin, origin + direction.rotated(offset) * 164.0, Geometry.WARNING_EDGE, 2.0, true)
		return
	if foe.optional_boss == VELVET:
		match int(foe.optional_attack):
			0:
				var spot := velvet_spot(foe)
				canvas.draw_circle(spot, 52.0, Geometry.WARNING_FILL)
				canvas.draw_arc(spot, 52.0, 0.0, TAU, 42, Color("#ffd7e4"), 2.0, true)
			1:
				var end: Vector2 = Geometry.clear_endpoint(game, origin, direction, 260.0, 14.0)
				canvas.draw_line(origin, end, Geometry.WARNING_FILL, 46.0, true)
				canvas.draw_line(origin, end, Color("#efb2c9"), 2.0, true)
			2:
				for index in range(VELVET_PUPPETS.size()):
					if int(foe.get("velvet_severed", 0)) & (1 << index):
						continue
					var point: Vector2 = VELVET_PUPPETS[index]
					var aim := point.direction_to(Vector2(foe.tx, foe.ty))
					for angle: float in [-0.22, 0.0, 0.22]:
						var end: Vector2 = Geometry.clear_endpoint(game, point, aim.rotated(angle), 352.0, 14.0)
						canvas.draw_line(point, end, Color("#efb2c9"), 1.5, true)
		return
	if foe.optional_boss == CHOIR:
		match int(foe.optional_attack):
			0:
				var end := choir_charge(game, foe, origin, direction)
				canvas.draw_line(origin, end, Geometry.WARNING_FILL, 46.0, true)
				canvas.draw_line(origin, end, Geometry.WARNING_EDGE, 2.0, true)
			1:
				var spread := 3 if foe.get("optional_second", false) else 2
				for index in range(-spread, spread + 1):
					var end: Vector2 = Geometry.clear_endpoint(game, origin, direction.rotated(index * 0.24), 388.0, 14.0)
					canvas.draw_line(origin, end, Geometry.WARNING_EDGE, 1.5, true)
			2:
				for point in choir_flowers(foe):
					canvas.draw_circle(point, 34.0, Geometry.WARNING_FILL)
					canvas.draw_arc(point, 34.0, 0.0, TAU, 36, Geometry.WARNING_EDGE, 2.0, true)
		return
	if foe.optional_boss == BRASSWING:
		warn_brasswing(game, foe, canvas, origin, direction)
		return
	if foe.optional_boss == HOUR:
		var gold := Color("#f3cc91")
		var target := Vector2(foe.tx, foe.ty)
		if int(foe.optional_attack) == 1:
			var end: Vector2 = Geometry.clear_endpoint(game, origin, direction, 460.0, 14.0)
			canvas.draw_line(origin, end, Geometry.WARNING_FILL, 34.0, true)
			canvas.draw_line(origin, end, gold, 2.0, true)
		elif int(foe.optional_attack) == 2:
			var old := Vector2(float(foe.get("hour_old_x", target.x)), float(foe.get("hour_old_y", target.y)))
			canvas.draw_arc(old, 45.0, 0.0, TAU, 36, gold, 2.0, true)
		else:
			canvas.draw_arc(target, 38.0, 0.0, TAU, 36, gold, 2.0, true)
		return
	match int(foe.optional_attack):
		0:
			for index in range(-3, 4):
				var ray := direction.rotated(index * 0.17)
				var endpoint: Vector2 = Geometry.clear_endpoint(game, origin, ray, 270.0, 14.0)
				canvas.draw_line(origin, endpoint, Geometry.WARNING_EDGE, 1.5, true)
		1:
			if queen:
				canvas.draw_arc(origin, 260.0, direction.angle() - acos(0.74), direction.angle() + acos(0.74),
					32, Geometry.WARNING_EDGE, 3.0, true)
				for angle: float in [-acos(0.74), acos(0.74)]:
					canvas.draw_line(origin, origin + direction.rotated(angle) * 260.0, Geometry.WARNING_EDGE, 2.0, true)
			else:
				canvas.draw_rect(game.ARENA, Geometry.WARNING_FILL)
				for point: Vector2 in MUSHROOMS:
					if on_safe_mushroom(point, bool(foe.get("optional_second", false))):
						canvas.draw_circle(point, 32.0, Color("#9debba"), false, 3.0, true)
		2:
			for point: Vector2 in bomb_points(foe):
				canvas.draw_circle(point, 30.0, Geometry.WARNING_FILL)
				canvas.draw_circle(point, 30.0, Geometry.WARNING_EDGE, false, 2.0, true)

static func warn_bride(game, foe: Dictionary, canvas: Node2D, origin: Vector2, direction: Vector2) -> void:
	var pink := Color("#ffb8c8")
	match int(foe.optional_attack):
		0:
			for index in range(-2, 3):
				var end: Vector2 = Geometry.clear_endpoint(game, origin, direction.rotated(index * 0.22), 336.0, 14.0)
				canvas.draw_line(origin, end, pink, 1.5, true)
		1:
			var knot := Vector2(foe.tx, foe.ty)
			canvas.draw_circle(knot, 42.0, Geometry.WARNING_FILL)
			canvas.draw_arc(knot, 42.0, 0.0, TAU, 48, pink, 2.0, true)
			canvas.draw_arc(knot, 42.0 * clampf(float(foe.clock) / float(foe.duration), 0.0, 1.0), 0.0, TAU, 32, pink, 1.5, true)
		2:
			for lane in bride_lanes(game, origin, direction, bool(foe.get("optional_second", false))):
				canvas.draw_polyline(lane, Geometry.WARNING_FILL, 46.0, true)
				canvas.draw_polyline(lane, pink, 2.0, true)

static func warn_brasswing(game, foe: Dictionary, canvas: Node2D, origin: Vector2, direction: Vector2) -> void:
	match int(foe.optional_attack):
		0:
			var end: Vector2 = Geometry.clear_endpoint(game, origin, direction, 245.0, game.BARREL_CLEARANCE)
			canvas.draw_line(origin, end, Geometry.WARNING_FILL, 32.0, true)
			canvas.draw_line(origin, end, Geometry.WARNING_EDGE, 2.0, true)
		1:
			canvas.draw_circle(origin, 116.0, Geometry.WARNING_FILL)
			canvas.draw_arc(origin, 116.0, 0.0, TAU, 54, Geometry.WARNING_EDGE, 2.0, true)
		2:
			for angle: float in [-0.62, -0.37, -0.12, 0.12, 0.37, 0.62]:
				var end: Vector2 = Geometry.clear_endpoint(game, origin, direction.rotated(angle), 457.0, 14.0)
				canvas.draw_line(origin, end, Geometry.WARNING_EDGE, 1.5, true)

static func warn_bandit(game, foe: Dictionary, canvas: Node2D, origin: Vector2, direction: Vector2) -> void:
	var gold := Color("#f6cc81")
	match int(foe.optional_attack):
		0:
			var path := bandit_dash(game, origin, direction)
			canvas.draw_polyline(path, Geometry.WARNING_FILL, 44.0, true)
			canvas.draw_polyline(path, gold, 2.0, true)
		1:
			for index in range(-2, 3):
				var end := Geometry.clear_endpoint(game, origin, direction.rotated(index * 0.23), 440.0, 14.0)
				canvas.draw_line(origin, end, gold, 1.5, true)
		2:
			var end := Geometry.clear_endpoint(game, origin, direction, 420.0, 14.0)
			canvas.draw_line(origin, end, Geometry.WARNING_FILL, 58.0, true)
			canvas.draw_line(origin, end, gold, 2.0, true)
			if foe.get("optional_second", false):
				var target := Vector2(foe.tx, foe.ty)
				canvas.draw_arc(target, 110.0, 0.0, TAU, 52, gold, 2.0, true)
				canvas.draw_circle(target, 7.0, gold, true)

static func warn_scarecrow(game, foe: Dictionary, canvas: Node2D, origin: Vector2, direction: Vector2) -> void:
	var second := bool(foe.get("optional_second", false))
	match int(foe.optional_attack):
		0:
			var needles := 2 if second else 1
			for index in range(-needles, needles + 1):
				var end := Geometry.clear_endpoint(game, origin, direction.rotated(index * 0.11), 430.0, 14.0)
				canvas.draw_line(origin, end, Geometry.WARNING_EDGE, 1.4, true)
		1:
			var end := Geometry.clear_endpoint(game, origin, direction, 195.0, game.BARREL_CLEARANCE)
			canvas.draw_line(origin, end, Geometry.WARNING_FILL, 38.0, true)
			canvas.draw_line(origin, end, Geometry.WARNING_EDGE, 2.0, true)
		2:
			for point: Vector2 in scarecrow_decoys(origin, direction):
				if game.ARENA.has_point(point):
					var aim := point.direction_to(Vector2(foe.tx, foe.ty))
					var end := Geometry.clear_endpoint(game, point, aim, 318.0, 14.0)
					canvas.draw_line(point, end, Geometry.WARNING_EDGE, 1.5, true)
					draw_pose(canvas, SCARECROW, 0, point + Vector2(0, 13), 0.58)
			if second:
				var twitch := Vector2(sin(float(foe.clock) * 35.0) * 6.0, 12.0)
				canvas.draw_line(origin + twitch - Vector2(17, 0), origin + twitch + Vector2(17, 0), Color("#5b3851"), 5.0, true)

static func draw_hay(canvas: Node2D, center: Vector2) -> void:
	canvas.draw_circle(center + Vector2(2, 5), 20.0, Color("#533632"), true)
	canvas.draw_rect(Rect2(center - Vector2(18, 20), Vector2(36, 28)), Color("#9a623c"))
	for row in range(5):
		var y := -19.0 + row * 5.0
		canvas.draw_line(center + Vector2(-16, y), center + Vector2(17, y + 2), Color("#d8ae66"), 2.0)
	for x: float in [-7, 8]:
		canvas.draw_line(center + Vector2(x, -21), center + Vector2(x, 8), Color("#704943"), 3.0)
