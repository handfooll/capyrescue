extends Node

## Dev-only visual verification tool - not part of the shipped game. Loads
## each screen in turn, lets it render a couple of frames, and saves a PNG.
## Run with: godot res://tools/_screenshot_tour.tscn (must NOT be --headless -
## get_viewport().get_texture() needs an actual rendered frame).
##
## Output goes under the project's own user:// data dir rather than any
## session-specific scratch path, so this keeps working unedited in future
## sessions/machines. Print the resolved path below to find the PNGs.

const OUT_DIR := "user://screenshots"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await get_tree().process_frame
	await get_tree().process_frame

	await _shot("res://ui/main_menu.tscn", "01_main_menu")
	await _shot("res://ui/level_select.tscn", "02_level_select")
	await _shot("res://ui/leaderboard.tscn", "03_leaderboard")
	await _shot("res://ui/settings.tscn", "04_settings")
	await _shot_game_states()
	await _shot_game_over()
	await _shot_daily()

	print("Screenshots saved to: ", ProjectSettings.globalize_path(OUT_DIR))
	get_tree().quit()

## Placements pop in via a 0.2s tween (ui/main.gd::_pop_animate), so a capture
## two frames after the change catches every piece mid-scale - which reads as
## "the art is too small / off-center" when it's only partway through its
## animation. Every state therefore settles first.
const SETTLE_FRAMES := 30

func _settle() -> void:
	for i in SETTLE_FRAMES:
		await get_tree().process_frame

func _shot(scene_path: String, name: String) -> void:
	var scene: PackedScene = load(scene_path)
	var instance: Control = scene.instantiate()
	add_child(instance)
	await _settle()
	_save(name)
	instance.queue_free()
	await get_tree().process_frame

func _shot_game_states() -> void:
	var scene: PackedScene = load("res://ui/main.tscn")
	var instance = scene.instantiate()
	add_child(instance)
	await _settle()
	instance.new_puzzle(6)
	await _settle()
	_save("05_game_fresh")

	# Place one legal cat + one mark, then force a mistake so the HUD shows
	# lives/mistakes/conflict-highlight state, not just the empty board.
	var legal_pos: Vector2i = instance.solution[0]
	instance._handle_double_tap(legal_pos)
	var mark_pos := Vector2i(0, 0)
	if not instance.board.has_cat(mark_pos):
		instance._handle_single_tap(mark_pos)
	await _settle()
	_save("06_game_in_progress")

	var conflict_pos := Vector2i(legal_pos.x, (legal_pos.y + 1) % instance.current_size)
	if conflict_pos == legal_pos:
		conflict_pos = Vector2i(legal_pos.x, (legal_pos.y + 2) % instance.current_size)
	instance._handle_double_tap(conflict_pos)
	await _settle()
	_save("07_game_mistake")

	# Clear the illegal cat before solving, so the board doesn't have an
	# extra cat on top of the full solution (which WinConditionChecker
	# would then correctly refuse to call solved).
	instance._handle_double_tap(conflict_pos)
	for i in instance.solution.size():
		instance.request_hint()
	await _settle()
	_save("08_game_solved")

	instance._on_settings_pressed()
	await _settle()
	_save("09_game_paused")

	instance.queue_free()
	await get_tree().process_frame

## Out of lives. Driven by spending the lives directly rather than by placing
## three genuinely illegal cats, which would depend on the generated layout.
func _shot_game_over() -> void:
	var instance = load("res://ui/main.tscn").instantiate()
	add_child(instance)
	await _settle()
	instance.new_puzzle(6)
	await _settle()
	instance.mistakes = GameData.STARTING_LIVES
	instance._refresh_lives()
	instance._refresh_mistakes_label()
	instance._trigger_game_over()
	await _settle()
	_save("10_game_over")
	instance.queue_free()
	await get_tree().process_frame

## Today's board - hides New Puzzle and the difficulty picker, and shows the
## Today badge, so it's worth its own capture.
func _shot_daily() -> void:
	var instance = load("res://ui/main.tscn").instantiate()
	add_child(instance)
	await _settle()
	instance.new_daily_puzzle()
	await _settle()
	_save("11_daily")
	instance._on_settings_pressed()
	await _settle()
	_save("12_daily_paused")
	instance.queue_free()
	await get_tree().process_frame

func _save(name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, name])
