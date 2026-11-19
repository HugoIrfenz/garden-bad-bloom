extends SceneTree

const Encounter = preload("res://scripts/bloodbloom_palace_encounters.gd")
const Geometry = preload("res://scripts/forgotten_encounters.gd")

func _initialize() -> void:
	call_deferred("verify")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func widow_at(point: Vector2) -> Dictionary:
	return {"kind": Encounter.THORN_WIDOW, "biome": Encounter.BLOODBLOOM, "phase": Geometry.APPROACH,
		"boss": false, "hp": 45, "max": 45, "x": point.x, "y": point.y, "clock": 0.0}

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_run(true)
	game.depth = 12
	game.enter_room()
	game.barrels.clear()
	game.player = Vector2(415, 211)
	game.mercy = 0.0
	var widow = widow_at(Vector2(329, 211))
	game.foes = [widow]
	game.update_foes(0.016)
	if not require(widow.move == "thorn_web" and widow.phase == Geometry.WINDUP and game.foes.size() == 3,
			"Widow must show both anchor lines before activating"):
		return

	game.checkpoint()
	game.resume_run()
	widow = game.foes[0]
	if not require(Encounter.intact_lanes(game, widow).size() == 2 and widow.phase == Geometry.WINDUP,
			"Resuming erased the locked web and corner anchors"):
		return

	var anchor: Dictionary = game.foes[1]
	var cut_lane: int = anchor.web_lane
	var cut_points: Array = widow.web_lanes[cut_lane]
	var cut_start = Vector2(cut_points[0], cut_points[1])
	var cut_end = Vector2(cut_points[2], cut_points[3])
	game.player = cut_start + Vector2(0, 15.0)
	game.strike(anchor)
	if not require(Encounter.intact_lanes(game, widow).size() == 1, "Striking a corner did not sever its strand"):
		return

	game.player = cut_start.lerp(cut_end, 0.22)
	game.update_foes(0.96)
	var hp: int = game.hp
	game.update_foes(0.60)
	if not require(game.hp == hp, "The cut lane remained dangerous during its first pulse"):
		return
	var remaining = Encounter.intact_lanes(game, widow)[0]
	game.player = remaining[0].lerp(remaining[1], 0.25)
	game.update_foes(0.11)
	if not require(game.hp < hp, "The remaining web line did not damage the player"):
		return

	widow.hp = 0
	game.update_foes(0.016)
	game.update_foes(0.016)
	if not require(game.foes.is_empty(), "Defeating the Widow left orphan anchors in the arena"):
		return

	var left = widow_at(Vector2(353, 194))
	var right = widow_at(Vector2(490, 225))
	game.player = Vector2(420, 207)
	game.foes = [left, right]
	game.update_foes(0.016)
	if not require(left.web_id != right.web_id and Encounter.intact_lanes(game, left).size() == 2
			and Encounter.intact_lanes(game, right).size() == 2, "Two Widow attacks shared anchor ownership"):
		return
	game.foes.clear()
	print("PASS: Thorn Widow warning, anchor persistence, actual strike counterplay, active damage, cleanup, and group isolation.")
	quit(0)
