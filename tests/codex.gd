extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	if not require(not game.codex.entries(0)[0].discovered, "A fresh archive revealed an unknown enemy"):
		return
	game.tap(game.View.GARDEN_LINK.get_center())
	game.tap(game.Hub.CODEX.get_center())
	if not require(game.screen == "codex", "Garden Codex link did not open"):
		return
	game.tap(game.CodexView.BIOME_NEXT.get_center())
	game.tap(game.CodexView.entry_rect(3).get_center())
	if not require(game.codex_biome == 1 and game.codex_kind == 3, "Codex page or entry was not selected"):
		return
	game.tap(game.CodexView.BACK.get_center())
	if not require(game.screen == "garden_hub", "Codex Back did not return to the Garden"):
		return
	game.start_run(true)
	var reload = game.Codex.new()
	reload.load_local()
	if not require(reload.entries(0)[0].discovered and reload.entries(0)[1].discovered,
			"Encounter discoveries were not written locally"):
		return
	if not require(not reload.entries(0)[3].discovered and not reload.entries(1)[0].discovered,
			"Discovering early enemies revealed other entries"):
		return
	print("PASS: live Garden Codex navigation, hidden entries, and local discovery persistence.")
	quit()
