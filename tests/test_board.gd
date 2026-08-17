extends GutTest

func _make_board() -> Board:
	# 3x3, three columns as regions.
	return Board.new(3, [[0, 1, 2], [0, 1, 2], [0, 1, 2]])

func test_contains_respects_bounds() -> void:
	var board := _make_board()
	assert_true(board.contains(Vector2i(0, 0)))
	assert_true(board.contains(Vector2i(2, 2)))
	assert_false(board.contains(Vector2i(3, 0)))
	assert_false(board.contains(Vector2i(0, -1)))

func test_region_id_looks_up_the_regions_grid() -> void:
	var board := _make_board()
	assert_eq(board.region_id(Vector2i(1, 2)), 2)

func test_place_and_remove_cat() -> void:
	var board := _make_board()
	var position := Vector2i(0, 1)
	board.place_cat(position)
	assert_true(board.has_cat(position))
	board.remove_cat(position)
	assert_false(board.has_cat(position))

func test_toggle_cat() -> void:
	var board := _make_board()
	var position := Vector2i(1, 1)
	board.toggle_cat(position)
	assert_true(board.has_cat(position))
	board.toggle_cat(position)
	assert_false(board.has_cat(position))
