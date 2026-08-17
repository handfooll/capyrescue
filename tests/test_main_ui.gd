extends GutTest

const MainScene := preload("res://ui/main.tscn")

func test_single_tap_toggles_a_mark() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	var position := Vector2i(0, 0)

	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.double_click = false
	main._on_cell_gui_input(event, position)

	await wait_seconds(main.TAP_DISAMBIGUATION_SECONDS + 0.1)

	assert_true(main.marked_cells.has(position))
	assert_false(main.board.has_cat(position))

## Godot delivers a double-click as two separate press events: the first
## with double_click = false, the second with double_click = true - the
## handler has to cancel the pending single-tap timer on the second event,
## not just let it lose a race.
func test_double_click_sequence_places_a_cat_not_a_mark() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	var position := Vector2i(0, 0)

	var first := InputEventMouseButton.new()
	first.button_index = MOUSE_BUTTON_LEFT
	first.pressed = true
	first.double_click = false
	main._on_cell_gui_input(first, position)

	var second := InputEventMouseButton.new()
	second.button_index = MOUSE_BUTTON_LEFT
	second.pressed = true
	second.double_click = true
	main._on_cell_gui_input(second, position)

	await wait_seconds(main.TAP_DISAMBIGUATION_SECONDS + 0.1)

	assert_true(main.board.has_cat(position))
	assert_false(main.marked_cells.has(position))

func test_hint_places_one_correct_cat() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	assert_true(main.board.cat_positions().is_empty())

	main.request_hint()

	assert_eq(main.board.cat_positions().size(), 1)
	assert_false(main.is_solved)

func test_solving_locks_further_taps() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	for i in main.solution.size():
		main.request_hint()
	assert_true(main.is_solved)

	var cats_before: int = main.board.cat_positions().size()
	main._handle_double_tap(main.solution[0])
	assert_eq(main.board.cat_positions().size(), cats_before)

func test_new_puzzle_resets_and_unlocks() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	for i in main.solution.size():
		main.request_hint()
	assert_true(main.is_solved)

	main.new_puzzle(5)

	assert_false(main.is_solved)
	assert_eq(main.current_size, 5)
	assert_true(main.board.cat_positions().is_empty())
