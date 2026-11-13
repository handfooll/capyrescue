extends GutTest

const MainScene := preload("res://ui/main.tscn")

## A tap now marks immediately rather than waiting out a disambiguation
## timer, so the mark is observable the moment the press is handled.
func test_single_tap_marks_immediately() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	var position := Vector2i(0, 0)

	main._begin_press(position, Vector2.ZERO)

	assert_true(main.marked_cells.has(position))
	assert_false(main.board.has_cat(position))

func test_second_tap_on_same_cell_upgrades_the_mark_to_a_cat() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	var position := Vector2i(0, 0)

	main._begin_press(position, Vector2.ZERO)
	main._begin_press(position, Vector2.ZERO)

	assert_true(main.board.has_cat(position))
	assert_false(main.marked_cells.has(position))

## Regression: Godot sets InputEventMouseButton.double_click from the previous
## click anywhere on screen, so quickly marking two adjacent cells used to
## arrive as a "double click" on the second one and drop a cat there. Pairing
## is now by cell identity, so two different cells can never pair up no matter
## how fast they're tapped.
func test_fast_taps_on_different_cells_never_place_a_cat() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	var cells := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]

	for cell in cells:
		main._begin_press(cell, Vector2.ZERO)

	assert_eq(main.board.cat_positions().size(), 0, "no cat should be placed by fast marking")
	for cell in cells:
		assert_true(main.marked_cells.has(cell), "expected a mark at %s" % cell)

## A slow second tap on the same cell is a plain toggle, not a cat.
func test_slow_second_tap_clears_the_mark() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	var position := Vector2i(0, 0)

	main._begin_press(position, Vector2.ZERO)
	# Age the pairing window by rewinding the recorded stamp rather than by
	# actually waiting: _begin_press pairs taps off Time.get_ticks_msec()
	# (wall clock), while GUT's wait_seconds advances on the scene tree's
	# accumulated frame delta - under --headless those diverge badly (a real
	# wait_seconds(0.33) returned after ~0.18s of wall clock), so the second
	# press still landed inside the window and placed a cat.
	main._last_tap_msec -= int(main.DOUBLE_TAP_SECONDS * 1000.0) + 50
	main._begin_press(position, Vector2.ZERO)

	assert_false(main.marked_cells.has(position))
	assert_false(main.board.has_cat(position))

func _center_of(main, cell: Vector2i) -> Vector2:
	return main._cell_buttons[cell].get_global_rect().get_center()

## Dragging across the grid paints an X on every cell the finger enters.
func test_swipe_marks_every_cell_it_crosses() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	await wait_frames(2)

	var path := [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)]
	main._begin_press(path[0], _center_of(main, path[0]))
	for i in range(1, path.size()):
		main._continue_drag(_center_of(main, path[i]))

	for cell in path:
		assert_true(main.marked_cells.has(cell), "expected a mark at %s" % cell)
	assert_eq(main.board.cat_positions().size(), 0)

## Starting the drag on a cell that already has an X erases along the path
## instead, so the same gesture undoes a row you over-marked.
func test_swipe_from_a_marked_cell_erases() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	await wait_frames(2)

	var path := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
	for cell in path:
		main.marked_cells[cell] = true

	main._begin_press(path[0], _center_of(main, path[0]))
	for i in range(1, path.size()):
		main._continue_drag(_center_of(main, path[i]))

	for cell in path:
		assert_false(main.marked_cells.has(cell), "expected %s to be cleared" % cell)

## Swiping must never knock out a cat the player deliberately placed.
func test_swipe_leaves_placed_cats_alone() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	await wait_frames(2)

	var cat_cell: Vector2i = main.solution[0]
	main._handle_double_tap(cat_cell)
	assert_true(main.board.has_cat(cat_cell))

	# Drag along the cat's whole row, straight through it.
	var start := Vector2i(cat_cell.x, 0)
	main._begin_press(start, _center_of(main, start))
	for col in main.current_size:
		main._continue_drag(_center_of(main, Vector2i(cat_cell.x, col)))

	assert_true(main.board.has_cat(cat_cell), "swipe removed a placed cat")
	assert_false(main.marked_cells.has(cat_cell), "swipe marked over a placed cat")

## Tapping a placed capybara takes it off and leaves the cell empty. It used to
## leave an X behind, which reads as the tap doing something you didn't ask for
## - you wanted the piece gone, and got a mark to clear as well.
func test_tapping_a_placed_capybara_clears_the_cell() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	await wait_frames(2)

	var cell: Vector2i = main.solution[0]
	main._handle_double_tap(cell)
	assert_true(main.board.has_cat(cell), "setup: the capybara should be placed")

	main._handle_single_tap(cell)
	assert_false(main.board.has_cat(cell), "the tap should remove the capybara")
	assert_false(main.marked_cells.has(cell), "and must not leave a mark in its place")

## ...and a swipe carrying on from that tap keeps clearing, rather than laying
## down the marks the tap itself deliberately didn't.
func test_swiping_on_from_a_cleared_capybara_does_not_mark() -> void:
	var main = add_child_autofree(MainScene.instantiate())
	main.new_puzzle(4)
	await wait_frames(2)

	var cell: Vector2i = main.solution[0]
	main._handle_double_tap(cell)
	main._begin_press(cell, _center_of(main, cell))
	for col in main.current_size:
		main._continue_drag(_center_of(main, Vector2i(cell.x, col)))

	assert_true(main.marked_cells.is_empty(), "the swipe should not have marked anything")

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
