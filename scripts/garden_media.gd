extends RefCounted

const ArcadeCatalog = preload("res://scripts/arcade_catalog.gd")
const CONSOLE := "petal_console"
const JUKEBOX := "garden_jukebox"
const CARTRIDGES := [
	"cart_petal_prix", "cart_cap_board", "cart_clockwork_encore", "cart_bramble_snake", "cart_teacup_catch",
]
const BOSS_ALBUM := 4
const HIDDEN_BOSS_ALBUM := 6
const FIRST_HIDDEN_TAPE := "vhs_queen_of_dandelions"
const ALBUMS := ["", "Storybook", "Home & Menus", "Dungeon Themes", "Boss Themes", "Garden Games", "Hidden Boss Themes"]
# Display title, album, and Garden Seed price.
const TAPE_TRACKS := {
	"vhs_title": ["Where the Garden Sleeps", 2, 32],
	"vhs_garden": ["A Place to Grow", 2, 29],
	"vhs_roster": ["The Garden Girls", 2, 26],
	"vhs_preparation": ["Before the Gate", 2, 25],
	"vhs_settings": ["Quiet Work", 2, 21],
	"vhs_archive": ["Pressed Pages", 2, 25],
	"vhs_shop": ["The Merchant's Waltz", 2, 28],
	"vhs_rest": ["Camp Lantern", 2, 23],
	"vhs_event": ["Something Rustles", 2, 23],
	"vhs_curse": ["Thorns at Noon", 2, 31],
	"vhs_reward": ["A Little Treasure", 2, 27],
	"vhs_victory": ["Garden Restored", 2, 41],
	"vhs_defeat": ["Petals in the Rain", 2, 30],
	"vhs_forgotten": ["Forgotten Garden", 3, 32],
	"vhs_mushroom": ["Mushroom Kingdom", 3, 34],
	"vhs_clockwork": ["Clockwork Conservatory", 3, 36],
	"vhs_bloodbloom": ["Bloodbloom Forest", 3, 38],
	"vhs_hollow": ["Hollow Palace", 3, 40],
	"vhs_astral": ["Astral Greenhouse", 3, 42],
	"vhs_bloomheart": ["Bloomheart Core", 3, 46],
	"vhs_forgotten_boss": ["The Gardener That Forgot", BOSS_ALBUM, 41],
	"vhs_mushroom_boss": ["His Moldy Majesty", BOSS_ALBUM, 45],
	"vhs_clockwork_boss": ["The Late Bell", BOSS_ALBUM, 49],
	"vhs_bloodbloom_boss": ["The Weeping Orchard", BOSS_ALBUM, 53],
	"vhs_hollow_boss": ["Duchess of the Last Tea", BOSS_ALBUM, 55],
	"vhs_astral_boss": ["The Starbound Florist", BOSS_ALBUM, 59],
	"vhs_bloomheart_boss": ["The Bloomheart, Unraveled", BOSS_ALBUM, 65],
	"vhs_arcade_prix": ["Petal Prix", 5, 32],
	"vhs_board": ["Three Caps in a Row", 5, 25],
	"vhs_arcade_encore": ["Clockwork Encore", 5, 29],
	"vhs_arcade_snake": ["Bramble Snake", 5, 28],
	"vhs_arcade_tea": ["Teacup Catch", 5, 29],
	"vhs_prologue_creator": ["The Creator", 1, 26],
	"vhs_prologue_bloom": ["The Bloom", 1, 28],
	"vhs_prologue_happiness": ["The Happiness", 1, 28],
	"vhs_prologue_corruption": ["The Corruption", 1, 34],
	"vhs_prologue_adventure": ["The Adventure", 1, 36],
	"vhs_queen_of_dandelions": ["Queen of Dandelions", HIDDEN_BOSS_ALBUM, 45],
	"vhs_first_scarecrow": ["The First Scarecrow", HIDDEN_BOSS_ALBUM, 47],
	"vhs_mother_of_spores": ["Mother of Spores", HIDDEN_BOSS_ALBUM, 49],
	"vhs_truffle_bandit": ["The Truffle Bandit", HIDDEN_BOSS_ALBUM, 51],
	"vhs_baroness_brasswing": ["Baroness Brasswing", HIDDEN_BOSS_ALBUM, 53],
	"vhs_unfinished_hour": ["The Unfinished Hour", HIDDEN_BOSS_ALBUM, 55],
	"vhs_bride_of_thorns": ["Bride of Thorns", HIDDEN_BOSS_ALBUM, 57],
	"vhs_antlered_choir": ["The Antlered Choir", HIDDEN_BOSS_ALBUM, 59],
	"vhs_crownless_prince": ["The Crownless Prince", HIDDEN_BOSS_ALBUM, 61],
	"vhs_madam_black_velvet": ["Madam Black Velvet", HIDDEN_BOSS_ALBUM, 63],
	"vhs_queen_of_two_moons": ["Queen of Two Moons", HIDDEN_BOSS_ALBUM, 65],
	"vhs_nebula_librarian": ["The Nebula Librarian", HIDDEN_BOSS_ALBUM, 67],
	"vhs_empty_sixth_chair": ["The Empty Sixth Chair", HIDDEN_BOSS_ALBUM, 72],
}
static var TAPES: Array = TAPE_TRACKS.keys()
static var PRICES: Dictionary = build_prices()
const ART = preload("res://assets/art/items/garden_media.png")
const REGIONS := [
	Rect2(22, 62, 402, 332), Rect2(468, 54, 410, 334), Rect2(911, 54, 411, 333), Rect2(1355, 54, 410, 332),
	Rect2(26, 493, 410, 351), Rect2(471, 499, 405, 329), Rect2(945, 493, 326, 328), Rect2(1360, 444, 381, 417),
]

static func build_prices() -> Dictionary:
	var prices := {
		CONSOLE: 58, JUKEBOX: 68,
		"cart_petal_prix": 46, "cart_cap_board": 30, "cart_clockwork_encore": 39, "cart_bramble_snake": 38, "cart_teacup_catch": 41,
	}
	for id: String in TAPE_TRACKS:
		prices[id] = TAPE_TRACKS[id][2]
	return prices


static func item(id: String) -> Dictionary:
	if id == CONSOLE:
		return {"name": "Petal Console", "effect": "Play owned game cartridges in the Garden", "kind": "Garden machine"}
	if id == JUKEBOX:
		return {"name": "Garden Jukebox", "effect": "Play any owned soundtrack VHS", "kind": "Garden machine"}
	if id in CARTRIDGES:
		var name := ArcadeCatalog.label(id.trim_prefix("cart_"), "title", "en")
		return {"name": name, "effect": "Replay this game on the Petal Console", "kind": "Game cartridge"}
	if TAPE_TRACKS.has(id):
		return {"name": TAPE_TRACKS[id][0], "effect": ALBUMS[int(TAPE_TRACKS[id][1])], "kind": "OST VHS"}
	return {}


static func cue(id: String) -> String:
	return id.trim_prefix("vhs_") if TAPE_TRACKS.has(id) else ""


static func cartridge(game_id: String) -> String:
	return "cart_" + game_id


static func can_replay(profile, game_id: String) -> bool:
	return ArcadeCatalog.DATA.has(game_id) and profile.has_unlock(CONSOLE) and profile.has_unlock(cartridge(game_id))


static func draw_icon(game, id: String, center: Vector2, size: float) -> void:
	if not PRICES.has(id):
		return
	var region: Rect2 = REGIONS[icon_slot(id)]
	var extent := (region.size * size / maxf(region.size.x, region.size.y)).round()
	game.draw_texture_rect_region(ART, Rect2((center - extent * 0.5).round(), extent), region)
	if id in CARTRIDGES:
		game.ArcadeView.draw_icon(game, id.trim_prefix("cart_"), center + Vector2(0, size * 0.07), size * 0.30)


static func icon_slot(id: String) -> int:
	if id == CONSOLE:
		return 0
	if id == JUKEBOX:
		return 7
	if id in CARTRIDGES:
		return 6
	var album := int(TAPE_TRACKS[id][1])
	return BOSS_ALBUM if album == HIDDEN_BOSS_ALBUM else album

