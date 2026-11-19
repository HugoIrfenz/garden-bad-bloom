extends RefCounted

const ArcadeCatalog = preload("res://scripts/arcade_catalog.gd")
const CONSOLE := "petal_console"
const JUKEBOX := "garden_jukebox"
const CARTRIDGES := [
	"cart_petal_prix", "cart_cap_board", "cart_clockwork_encore", "cart_bramble_snake", "cart_teacup_catch",
]
const TAPES := [
	"vhs_title", "vhs_garden", "vhs_roster", "vhs_preparation",
	"vhs_settings", "vhs_archive", "vhs_shop", "vhs_rest",
	"vhs_event", "vhs_curse", "vhs_reward", "vhs_victory",
	"vhs_defeat", "vhs_forgotten", "vhs_mushroom", "vhs_clockwork",
	"vhs_bloodbloom", "vhs_hollow", "vhs_astral", "vhs_bloomheart",
	"vhs_forgotten_boss", "vhs_mushroom_boss", "vhs_clockwork_boss", "vhs_bloodbloom_boss",
	"vhs_hollow_boss", "vhs_astral_boss", "vhs_bloomheart_boss", "vhs_arcade_prix",
	"vhs_board", "vhs_arcade_encore", "vhs_arcade_snake", "vhs_arcade_tea",
	"vhs_prologue_creator", "vhs_prologue_bloom", "vhs_prologue_happiness", "vhs_prologue_corruption",
	"vhs_prologue_adventure",
]
const ALBUMS := ["", "Storybook", "Home & Menus", "Dungeon Themes", "Boss Themes", "Garden Games"]
const TAPE_TRACKS := {
	"vhs_title": ["Where the Garden Sleeps", 2],
	"vhs_garden": ["A Place to Grow", 2],
	"vhs_roster": ["The Garden Girls", 2],
	"vhs_preparation": ["Before the Gate", 2],
	"vhs_settings": ["Quiet Work", 2],
	"vhs_archive": ["Pressed Pages", 2],
	"vhs_shop": ["The Merchant's Waltz", 2],
	"vhs_rest": ["Camp Lantern", 2],
	"vhs_event": ["Something Rustles", 2],
	"vhs_curse": ["Thorns at Noon", 2],
	"vhs_reward": ["A Little Treasure", 2],
	"vhs_victory": ["Garden Restored", 2],
	"vhs_defeat": ["Petals in the Rain", 2],
	"vhs_forgotten": ["Forgotten Garden", 3],
	"vhs_mushroom": ["Mushroom Kingdom", 3],
	"vhs_clockwork": ["Clockwork Conservatory", 3],
	"vhs_bloodbloom": ["Bloodbloom Forest", 3],
	"vhs_hollow": ["Hollow Palace", 3],
	"vhs_astral": ["Astral Greenhouse", 3],
	"vhs_bloomheart": ["Bloomheart Core", 3],
	"vhs_forgotten_boss": ["The Gardener That Forgot", 4],
	"vhs_mushroom_boss": ["His Moldy Majesty", 4],
	"vhs_clockwork_boss": ["The Late Bell", 4],
	"vhs_bloodbloom_boss": ["The Weeping Orchard", 4],
	"vhs_hollow_boss": ["Duchess of the Last Tea", 4],
	"vhs_astral_boss": ["The Starbound Florist", 4],
	"vhs_bloomheart_boss": ["The Bloomheart, Unraveled", 4],
	"vhs_arcade_prix": ["Petal Prix", 5],
	"vhs_board": ["Three Caps in a Row", 5],
	"vhs_arcade_encore": ["Clockwork Encore", 5],
	"vhs_arcade_snake": ["Bramble Snake", 5],
	"vhs_arcade_tea": ["Teacup Catch", 5],
	"vhs_prologue_creator": ["The Creator", 1],
	"vhs_prologue_bloom": ["The Bloom", 1],
	"vhs_prologue_happiness": ["The Happiness", 1],
	"vhs_prologue_corruption": ["The Corruption", 1],
	"vhs_prologue_adventure": ["The Adventure", 1],
}
const PRICES := {
	CONSOLE: 58, JUKEBOX: 68,
	"cart_petal_prix": 46, "cart_cap_board": 30, "cart_clockwork_encore": 39, "cart_bramble_snake": 38, "cart_teacup_catch": 41,
	"vhs_title": 32,
	"vhs_garden": 29,
	"vhs_roster": 26,
	"vhs_preparation": 25,
	"vhs_settings": 21,
	"vhs_archive": 25,
	"vhs_shop": 28,
	"vhs_rest": 23,
	"vhs_event": 23,
	"vhs_curse": 31,
	"vhs_reward": 27,
	"vhs_victory": 41,
	"vhs_defeat": 30,
	"vhs_forgotten": 32,
	"vhs_mushroom": 34,
	"vhs_clockwork": 36,
	"vhs_bloodbloom": 38,
	"vhs_hollow": 40,
	"vhs_astral": 42,
	"vhs_bloomheart": 46,
	"vhs_forgotten_boss": 41,
	"vhs_mushroom_boss": 45,
	"vhs_clockwork_boss": 49,
	"vhs_bloodbloom_boss": 53,
	"vhs_hollow_boss": 55,
	"vhs_astral_boss": 59,
	"vhs_bloomheart_boss": 65,
	"vhs_arcade_prix": 32,
	"vhs_board": 25,
	"vhs_arcade_encore": 29,
	"vhs_arcade_snake": 28,
	"vhs_arcade_tea": 29,
	"vhs_prologue_creator": 26,
	"vhs_prologue_bloom": 28,
	"vhs_prologue_happiness": 28,
	"vhs_prologue_corruption": 34,
	"vhs_prologue_adventure": 36,
}
const ART = preload("res://assets/art/items/garden_media.png")
const REGIONS := [
	Rect2(22, 62, 402, 332), Rect2(468, 54, 410, 334), Rect2(911, 54, 411, 333), Rect2(1355, 54, 410, 332),
	Rect2(26, 493, 410, 351), Rect2(471, 499, 405, 329), Rect2(945, 493, 326, 328), Rect2(1360, 444, 381, 417),
]

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
	return int(TAPE_TRACKS[id][1])

