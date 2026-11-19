extends RefCounted

const LEARN = Rect2(420, 265, 269, 40)
const PASS = Rect2(420, 312, 269, 49)
const PROCEED = Rect2(420, 310, 269, 44)
const PANEL = Rect2(374, 46, 377, 328)

static func draw(game) -> void:
	var view = game.View
	var hero: int = game.hero
	var milestone: String = game.chapter_talent_milestone()
	var offer: Dictionary = game.talents.offer(hero, milestone)
	var outcome: String = game.talents.outcome(milestone)
	var accent: Color = game.COLORS[hero]
	game.draw_rect(view.CANVAS, Color(0.10, 0.063, 0.15, 0.73))
	view.petals(game, game.visual_clock)
	var entrance: float = game.menu_motion.entrance_amount()
	var portrait := Rect2(72, 43, 265, 325)
	portrait.position.x += roundf(-18.0 * (1.0 - entrance))
	view.draw_portrait_stage(game, hero, portrait, false, false, accent, entrance)
	view.frame(game, PANEL, Color("#282035"), accent)

	var seal := Vector2(558, 133)
	game.draw_circle(seal, 29.0, Color(accent, 0.11), true, -1.0, true)
	game.draw_arc(seal, 28.0, 0, TAU, 44, Color(accent, 0.62), 1.5, true)
	view.ability_icon(game, hero, false, seal, 43.0)
	if not outcome.is_empty():
		draw_outcome(game, outcome)
		return
	if offer.is_empty():
		view.centered(game, Rect2(409, 183, 300, 35), "Choice already complete", 24, view.CREAM, true)
		view.button(game, PROCEED, "Enter next chapter", true)
		return

	view.centered(game, Rect2(408, 59, 300, 35), "Choose Your Path", 27, view.CREAM, true)
	view.centered(game, Rect2(409, 163, 300, 32), offer.name, 24, view.CREAM, true)
	var line_y := 199.0
	for line: String in game.CodexView.wrap_text(offer.detail, ThemeDB.fallback_font, 295.0, 13):
		view.centered(game, Rect2(409, line_y, 298, 18), line, 13, view.DIM)
		line_y += 18.0
	view.button(game, LEARN, "Learn Talent for This Run", true)
	view.frame(game, PASS, Color("#3d3045"), view.BRASS)
	view.centered(game, Rect2(PASS.position + Vector2(0, 3), Vector2(PASS.size.x, 20)),
		"Take Camp Blessing Instead", 15, view.CREAM, true)
	view.centered(game, Rect2(PASS.position + Vector2(0, 25), Vector2(PASS.size.x, 17)),
		"+1 damage this run  ·  Full class meter", 11, view.DIM)

static func draw_outcome(game, choice: String) -> void:
	var view = game.View
	var is_blessing: bool = choice == game.RunTalents.CAMP_BLESSING
	var outcome := "Camp Blessing Taken" if is_blessing else "Talent Learned"
	view.centered(game, Rect2(405, 61, 306, 36), outcome, 26, view.CREAM, true)
	var talent: Dictionary = game.RunTalents.definition(choice)
	var caption := "+1 damage for this run" if is_blessing else str(talent.get("name", "Talent"))
	var detail := "Class meter filled. Talent skipped." if is_blessing else "Active for the rest of this run."
	view.centered(game, Rect2(406, 180, 304, 40), caption, 25, view.CREAM, true)
	view.centered(game, Rect2(410, 230, 296, 31), detail, 13, view.DIM)
	view.button(game, PROCEED, "Enter next chapter", true)

static func tap(game, point: Vector2) -> void:
	var milestone: String = game.chapter_talent_milestone()
	if game.talents.milestone_resolved(milestone):
		if PROCEED.has_point(point):
			game.next_floor()
		return
	if LEARN.has_point(point):
		var offer: Dictionary = game.talents.offer(game.hero, milestone)
		if offer.is_empty() or not game.talents.choose(offer.id, game.hero, milestone):
			return
	elif PASS.has_point(point):
		if not game.talents.decline(milestone):
			return
		game.bonus += game.RunTalents.CAMP_DAMAGE
		game.resource = game.HeroUltimates.CHARGE
	else:
		return
	game.sound.play("reward")
	game.checkpoint()
