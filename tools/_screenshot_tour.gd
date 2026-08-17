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

	print("Screenshots saved to: ", ProjectSettings.globalize_path(OUT_DIR))
	get_tree().quit()

func _shot(scene_path: String, name: String) -> void:
	var scene: PackedScene = load(scene_path)
	var instance: Control = scene.instantiate()
	add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	_save(name)
	instance.queue_free()
	await get_tree().process_frame

func _shot_game_states() -> void:
	var scene: PackedScene = load("res://ui/main.tscn")
	var instance = scene.instantiate()
	add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	instance.new_puzzle(6)
	await get_tree().process_frame
	_save("05_game_fresh")

	# Place one legal cat + one mark, then force a mistake so the HUD shows
	# lives/mistakes/conflict-highlight state, not just the empty board.
	var legal_pos: Vector2i = instance.solution[0]
	instance._handle_double_tap(legal_pos)
	var mark_pos := Vector2i(0, 0)
	if not instance.board.has_cat(mark_pos):
		instance._handle_single_tap(mark_pos)
	await get_tree().process_frame
	_save("06_game_in_progress")

	var conflict_pos := Vector2i(legal_pos.x, (legal_pos.y + 1) % instance.current_size)
	if conflict_pos == legal_pos:
		conflict_pos = Vector2i(legal_pos.x, (legal_pos.y + 2) % instance.current_size)
	instance._handle_double_tap(conflict_pos)
	await get_tree().process_frame
	_save("07_game_mistake")

	# Clear the illegal cat before solving, so the board doesn't have an
	# extra cat on top of the full solution (which WinConditionChecker
	# would then correctly refuse to call solved).
	instance._handle_double_tap(conflict_pos)
	for i in instance.solution.size():
		instance.request_hint()
	await get_tree().process_frame
	_save("08_game_solved")

	instance.queue_free()
	await get_tree().process_frame

func _save(name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, name])
