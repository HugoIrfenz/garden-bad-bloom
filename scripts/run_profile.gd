extends RefCounted

const Decorations = preload("res://scripts/garden_decorations.gd")
const Media = preload("res://scripts/garden_media.gd")
const VERSION = 1
const HISTORY_LIMIT = 60
const FINALIZING = "finalizing"
const FOUNTAIN_LANTERNS = "fountain_lanterns"
const PORCELAIN_PLANTERS = "porcelain_planters"
const FIREFLY_GROVE = "firefly_grove"
const ROSE_TEA_CORNER = "rose_tea_corner"
const BASE_DECORATIONS = [FOUNTAIN_LANTERNS, PORCELAIN_PLANTERS, FIREFLY_GROVE, ROSE_TEA_CORNER]
const STARTING_ITEMS = ["royal_teacup", "clockwise_tonic", "petal_bomb"]
const STARTING_WEAPONS = ["morning_promise", "black_margin", "pocket_thunder", "ribbon_string", "palette_knives",
	"clockface_shank", "royal_cleaver", "moonquill_staff", "tiny_hammerfists", "hollowglass_bow", "snarewood_bow"]
const BASE_SEED_OFFERS = {
	"royal_teacup": 7,
	"clockwise_tonic": 10,
	"petal_bomb": 13,
	FOUNTAIN_LANTERNS: 9,
	PORCELAIN_PLANTERS: 6,
	FIREFLY_GROVE: 8,
	ROSE_TEA_CORNER: 12,
	"morning_promise": 13,
	"black_margin": 13,
	"pocket_thunder": 14,
	"ribbon_string": 12,
	"palette_knives": 13,
	"clockface_shank": 30,
	"royal_cleaver": 31,
	"moonquill_staff": 32,
	"tiny_hammerfists": 33,
	"hollowglass_bow": 34,
	"snarewood_bow": 36,
}

static var GARDEN_DECORATIONS: Array = BASE_DECORATIONS + Decorations.PRICES.keys()
static var SEED_OFFERS: Dictionary = BASE_SEED_OFFERS.merged(Decorations.PRICES).merged(Media.PRICES)

var garden_seeds = 0
var _profile_path: String
var _backup_path: String
var _legacy_path: String
var _data: Dictionary = {}

func _init(directory := "user://") -> void:
	_profile_path = directory.path_join("profile.json")
	_backup_path = directory.path_join("profile.json.bak")
	_legacy_path = directory.path_join("profile.txt")

static func fresh_run_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

static func legacy_run_id(seed_value: int, hero_index: int) -> String:
	return "legacy_" + ("%d|%d" % [seed_value, hero_index]).sha256_text().substr(0, 32)

func load_local() -> Error:
	var primary = read_json(_profile_path)
	var backup = read_json(_backup_path)
	if valid_profile(primary):
		set_data(primary)
		return OK
	if valid_profile(backup):
		set_data(backup)
		return write_json(_profile_path, backup)
	if FileAccess.file_exists(_profile_path) or FileAccess.file_exists(_backup_path):
		return ERR_FILE_CORRUPT

	var legacy = FileAccess.open(_legacy_path, FileAccess.READ)
	var legacy_seeds = 0
	if legacy != null:
		var digits = legacy.get_as_text().strip_edges()
		legacy.close()
		if not digits.is_valid_int():
			return ERR_FILE_CORRUPT
		legacy_seeds = maxi(0, digits.to_int())
	set_data({"version": VERSION, "garden_seeds": legacy_seeds, "history": [], "finalized_runs": {}})
	if legacy == null:
		return OK

	# Leave the original profile.txt available as a migration source. Once the
	# JSON profile exists, its balance becomes the sole source of truth.
	var error = write_json(_profile_path, _data)
	return write_json(_backup_path, _data) if error == OK else error

func history() -> Array:
	return _data.get("history", []).duplicate(true)

func has_result(run_id: String) -> bool:
	return _data.get("finalized_runs", {}).has(run_id)

func has_unlock(unlock_id: String) -> bool:
	var unlocks: Variant = _data.get("unlocks", [])
	return unlocks is Array and unlock_id in unlocks

func purchase_unlock(unlock_id: String) -> Error:
	if not SEED_OFFERS.has(unlock_id):
		return ERR_DOES_NOT_EXIST
	var error := load_local()
	if error != OK:
		return error
	if has_unlock(unlock_id):
		return ERR_ALREADY_EXISTS
	var cost: int = SEED_OFFERS[unlock_id]
	if garden_seeds < cost:
		return ERR_CANT_ACQUIRE_RESOURCE
	var next := _data.duplicate(true)
	var existing: Variant = next.get("unlocks", [])
	var unlocks: Array = existing if existing is Array else []
	unlocks.append(unlock_id)
	next.unlocks = unlocks
	next.garden_seeds = garden_seeds - cost
	error = write_json(_profile_path, next)
	if error != OK:
		return error
	set_data(next)
	# The primary already owns this unlock. A mirror failure must not turn a
	# committed purchase into a retryable charge.
	var mirror_error := write_json(_backup_path, _data)
	if mirror_error != OK:
		push_warning("Could not mirror the Garden unlock: " + error_string(mirror_error))
	return OK

static func stage_result(active_path: String, summary: Dictionary) -> Error:
	if not valid_summary(summary):
		return ERR_INVALID_DATA
	var current = read_json(active_path)
	if current.get("screen", "") == FINALIZING:
		return OK if current.get("run_id", "") == summary.run_id else ERR_BUSY
	var active_id = str(current.get("run_id", ""))
	if not active_id.is_empty() and active_id != summary.run_id:
		return ERR_BUSY
	return write_json(active_path, {"version": VERSION, "screen": FINALIZING,
		"run_id": summary.run_id, "summary": summary})

func finish_staged(active_path: String) -> Error:
	var terminal = read_json(active_path)
	if terminal.get("screen", "") != FINALIZING:
		return ERR_INVALID_DATA
	var summary: Variant = terminal.get("summary")
	if not summary is Dictionary or not valid_summary(summary) or terminal.get("run_id", "") != summary.run_id:
		return ERR_INVALID_DATA

	var error = load_local()
	if error != OK:
		return error
	if not has_result(str(summary.run_id)):
		var next = _data.duplicate(true)
		next.garden_seeds = garden_seeds + int(summary.seeds_earned)
		next.finalized_runs[summary.run_id] = true
		next.history.push_front(summary.duplicate(true))
		if next.history.size() > HISTORY_LIMIT:
			next.history.resize(HISTORY_LIMIT)
		error = write_json(_profile_path, next)
		if error != OK:
			return error
		set_data(next)

	# Mirror the committed balance before deleting the terminal marker. A
	# process interrupted between these writes can safely replay the marker.
	error = write_json(_backup_path, _data)
	if error != OK:
		return error
	var current = read_json(active_path)
	if current.get("screen", "") == FINALIZING and current.get("run_id", "") == summary.run_id:
		return DirAccess.remove_absolute(active_path)
	return OK

func set_data(data: Dictionary) -> void:
	_data = data
	garden_seeds = maxi(0, int(_data.garden_seeds))

static func valid_profile(data: Dictionary) -> bool:
	return int(data.get("version", 0)) == VERSION and data.has("garden_seeds") 		and data.get("history") is Array and data.get("finalized_runs") is Dictionary

static func valid_summary(summary: Dictionary) -> bool:
	return not str(summary.get("run_id", "")).is_empty() \
		and str(summary.get("result", "")) in ["defeat", "clear", "ended"] \
		and int(summary.get("seeds_earned", -1)) >= 0

static func read_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return value if value is Dictionary else {}

static func write_json(path: String, data: Dictionary) -> Error:
	var temporary = path + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var error = file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		DirAccess.remove_absolute(temporary)
	return error
