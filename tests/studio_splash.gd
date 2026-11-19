extends SceneTree

const SplashScene = "res://studio_splash.tscn"
const PrologueScene = "res://prologue.tscn"
const TitleScene = "res://main.tscn"

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func wait_for_scene(path: String, seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if current_scene != null and current_scene.scene_file_path == path:
			return true
		await process_frame
	return false

func verify() -> void:
	var startup := str(ProjectSettings.get_setting("application/run/main_scene"))
	if not check(startup == SplashScene, "The actual project entry point bypasses the studio scene"):
		return
	change_scene_to_file(startup)
	if not await wait_for_scene(SplashScene, 2.0):
		check(false, "The studio scene did not open")
		return
	var first: Node = current_scene
	await create_timer(0.60).timeout
	if not check(is_instance_valid(first) and first.exit_started < 0.0, "The first splash ended before the three marks appeared"):
		return
	if not await wait_for_scene(PrologueScene, 7.0):
		check(false, "The automatic splash did not reach the prologue")
		return
	if not check(current_scene.page == 0, "The prologue did not start with the Creator"):
		return
	if not await wait_for_scene(TitleScene, 39.0):
		check(false, "The automatic prologue did not reach the title screen")
		return
	change_scene_to_file(startup)
	if not await wait_for_scene(SplashScene, 2.0):
		check(false, "Could not open the splash for a touch test")
		return
	var skip_touch := InputEventScreenTouch.new()
	skip_touch.pressed = true
	skip_touch.position = Vector2(385, 200)
	var second: Node = current_scene
	second._input(skip_touch)
	if not check(second.skip_requested and second.exit_started < 0.0, "A touch skipped the minimum display time"):
		return
	if not await wait_for_scene(PrologueScene, 1.8):
		check(false, "A tap did not shorten the splash")
		return
	if not check(current_scene.page == 0, "The splash tap advanced the prologue"):
		return
	skip_touch.position = Vector2(782, 45)
	current_scene._input(skip_touch)
	if not await wait_for_scene(TitleScene, 1.8):
		check(false, "Skip did not exit the prologue to the title screen")
		return
	if not check(current_scene.screen == "garden", "The skip press leaked into title navigation"):
		return
	print("PASS: studio and prologue startup, automatic title handoff, and input-safe skipping.")
	quit()
