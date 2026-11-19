extends RefCounted

const Catalog = preload("res://scripts/arcade_catalog.gd")
const PetalPrix = preload("res://scripts/arcade_petal_prix.gd")
const ClockworkEncore = preload("res://scripts/arcade_clockwork_encore.gd")
const BrambleSnake = preload("res://scripts/arcade_bramble_snake.gd")
const TeacupCatch = preload("res://scripts/arcade_teacup_catch.gd")
const CONSTRUCTORS := {
	Catalog.PRIX: PetalPrix, Catalog.ENCORE: ClockworkEncore,
	Catalog.SNAKE: BrambleSnake, Catalog.CATCH: TeacupCatch,
}
const PLAYING := "playing"

var id := ""
var round: RefCounted
var practice := false
var save_age := 0.0
var outcome := ""


func reset() -> void:
	id = ""
	round = null
	practice = false
	outcome = ""
	save_age = 0.0


func begin(game_id: String, seed_value: int, hero: int, board: RefCounted, free_round: bool) -> void:
	select_game(game_id, board)
	practice = free_round
	if game_id == Catalog.BOARD:
		round.begin(seed_value)
	else:
		round.begin(seed_value, hero)
	outcome = str(round.state)


func select_game(game_id: String, board: RefCounted) -> void:
	reset()
	if game_id == Catalog.BOARD:
		round = board
	elif CONSTRUCTORS.has(game_id):
		round = CONSTRUCTORS[game_id].new()
	else:
		return
	id = game_id


func snapshot() -> Dictionary:
	if id.is_empty() or practice:
		return {}
	return {"id": id, "round": round.snapshot()}


func restore(saved: Variant, old_board: Variant, board: RefCounted) -> void:
	reset()
	if saved is Dictionary and not saved.is_empty():
		select_game(str(saved.get("id", "")), board)
		if not id.is_empty():
			round.restore(saved.get("round"))
	elif old_board is Dictionary:
		select_game(Catalog.BOARD, board)
		round.restore(old_board)
	if round == null or str(round.state) not in [PLAYING, "win", "draw", "loss"]:
		reset()
	else:
		outcome = str(round.state)


func tick(game, delta: float) -> void:
	if round == null or outcome != PLAYING:
		return
	round.tick(game, minf(delta, 0.10))
	sync_outcome(game)
	if not practice and outcome == PLAYING:
		save_age += delta
		if save_age >= 0.45:
			save_age = 0.0
			game.checkpoint()


func tap(game, point: Vector2) -> void:
	if round == null:
		return
	round.tap(game, point)
	sync_outcome(game)


func key(game, keycode: int) -> void:
	if round == null or outcome != PLAYING or not round.has_method("key"):
		return
	round.key(game, keycode)
	sync_outcome(game)


func sync_outcome(game) -> void:
	if round == null or outcome == str(round.state):
		return
	outcome = str(round.state)
	# Three Caps already plays its original result cue.
	if id != Catalog.BOARD:
		match outcome:
			"win": game.sound.play("board_win")
			"loss": game.sound.play("board_loss")
			"draw": game.sound.play("board_move")
	if not practice:
		game.checkpoint()


func settle(game) -> void:
	if round == null:
		return
	var was_practice := practice
	if not was_practice:
		match str(round.state):
			"win":
				award_win(game)
			"draw":
				game.petals += int(Catalog.DATA[id].stake)
	reset()
	if was_practice:
		game.screen = "garden_arcade"
	else:
		game.complete_room()


func award_win(game) -> void:
	match id:
		Catalog.PRIX:
			game.petals += 15
		Catalog.BOARD:
			if not game.pocket.take("petal_bomb"):
				game.bonus += 1
		Catalog.ENCORE:
			game.petals += 8
			game.resource = mini(game.HeroUltimates.CHARGE, game.resource + 2)
		Catalog.SNAKE:
			if not game.pocket.take("petal_bomb"):
				game.petals += 8
		Catalog.CATCH:
			if not game.pocket.take("clockwise_tonic"):
				game.petals += 9
