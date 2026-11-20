extends RefCounted

const GuestRoster = preload("res://scripts/guest_roster.gd")
const LUNA_ENCORE_PETALS := 10
const BOARD := "cap_board"
const PRIX := "petal_prix"
const ENCORE := "clockwork_encore"
const SNAKE := "bramble_snake"
const CATCH := "teacup_catch"
const GAMES := [PRIX, BOARD, ENCORE, SNAKE, CATCH]

const DATA := {
	PRIX: {
		"title": ["Petal Prix", "Grand Prix Kelopak"], "short": ["Petal Prix", "Prix Kelopak"],
		"tag": ["Tap-to-pedal racing", "Balap kayuh ketuk"], "cue": "arcade_prix",
		"prompt": ["Race the capkeeper in a flower-powered go-kart.",
			"Adu cepat dengan penjaga memakai gokart bertenaga bunga."],
		"prize": ["15 Petals", "15 Kelopak"], "stake": 6, "color": Color("#f7ac89"),
	},
	BOARD: {
		"title": ["Three Caps in a Row", "Tiga Tudung Berderet"], "short": ["Three Caps", "Tiga Tudung"],
		"tag": ["Tic-tac-toe", "Tiga segaris"], "cue": "board",
		"prompt": ["Win a Petal Bomb or +1 damage. A draw refunds the stake.",
			"Menang untuk Bom Kelopak atau +1 daya serang. Seri mengembalikan taruhan."],
		"prize": ["Petal Bomb or +1 damage", "Bom Kelopak atau +1 daya serang"], "stake": 6, "color": Color("#eccb90"),
	},
	ENCORE: {
		"title": ["Clockwork Encore", "Encore Roda Gigi"], "short": ["Clockwork Encore", "Encore Roda Gigi"],
		"tag": ["Repeat the melody", "Ulangi melodi"], "cue": "arcade_encore",
		"prompt": ["The organ plays a tune. Remember its keys and play it back.",
			"Organ memainkan lagu. Ingat tutsnya dan mainkan kembali."],
		"prize": ["8 Petals and up to 2 class pips", "8 Kelopak dan hingga 2 ruas energi"], "stake": 5, "color": Color("#ced3f3"),
	},
	SNAKE: {
		"title": ["Bramble Snake", "Ular Semak"], "short": ["Bramble Snake", "Ular Semak"],
		"tag": ["Steer and snack", "Belok dan makan"], "cue": "arcade_snake",
		"prompt": ["Feed a very hungry vine. Watch the hedge and its growing tail.",
			"Beri makan sulur lapar. Awas pagar dan ekornya yang makin panjang."],
		"prize": ["Petal Bomb or 8 Petals", "Bom Kelopak atau 8 Kelopak"], "stake": 5, "color": Color("#cbdc9c"),
	},
	CATCH: {
		"title": ["Teacup Catch", "Tangkap Cangkir"], "short": ["Teacup Catch", "Tangkap Cangkir"],
		"tag": ["Save the good china", "Selamatkan porselen"], "cue": "arcade_tea",
		"prompt": ["Catch the falling good china before the Duchess notices.",
			"Tangkap porselen sebelum sang Adipatni menyadarinya."],
		"prize": ["Clockwise Tonic or 9 Petals", "Tonik Jarum Jam atau 9 Kelopak"], "stake": 5, "color": Color("#efb5d6"),
	},
}

static func id_for_event(event_id: String) -> String:
	if event_id == "three_caps":
		return BOARD
	return event_id if DATA.has(event_id) else ""


static func event_for_floor(floor: int) -> String:
	if floor < 0 or floor >= GAMES.size():
		return ""
	return "three_caps" if GAMES[floor] == BOARD else GAMES[floor]


static func id_for_node(node: Dictionary) -> String:
	if node.get("kind", "") != "event":
		return ""
	# The board may also be rolled as a regular Mushroom event.
	return id_for_event(str(node.get("event_override", node.get("mushroom_event_id", ""))))


static func label(id: String, field: String, language: String) -> String:
	return str(DATA[id][field][1 if language == "id" else 0])

static func prize(game, id: String) -> String:
	if id == ENCORE and game.hero == GuestRoster.LUNA:
		return game.preferences.text("arcade.petals", {"amount": LUNA_ENCORE_PETALS})
	return label(id, "prize", game.preferences.language)


static func card(id: String) -> Dictionary:
	var data: Dictionary = DATA[id]
	return {"id": id, "title": data.title[0], "prompt": data.prompt[0], "leave": "Leave",
		"actions": [{"title": "Play", "petals": -int(data.stake), "minigame": id}]}
