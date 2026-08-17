extends GutTest

func _make_board() -> Board:
	# 4x4, each column its own region.
	return Board.new(4, [
		[0, 1, 2, 3],
		[0, 1, 2, 3],
		[0, 1, 2, 3],
		[0, 1, 2, 3],
	])

func test_is_adjacent_covers_all_eight_directions() -> void:
	var center := Vector2i(1, 1)
	var neighbors := [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 0), Vector2i(1, 2),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2),
	]
	for neighbor in neighbors:
		assert_true(MoveValidator.is_adjacent(center, neighbor))
	assert_false(MoveValidator.is_adjacent(center, Vector2i(3, 3)))
	assert_false(MoveValidator.is_adjacent(center, center))

func test_detects_row_conflict() -> void:
	var board := _make_board()
	board.place_cat(Vector2i(0, 0))
	assert_false(MoveValidator.is_legal(Vector2i(0, 3), board))

func test_detects_column_conflict() -> void:
	var board := _make_board()
	board.place_cat(Vector2i(0, 0))
	assert_false(MoveValidator.is_legal(Vector2i(3, 0), board))

func test_detects_region_conflict() -> void:
	var board := _make_board()
	board.place_cat(Vector2i(0, 0))
	# Same region (column 0), far enough away to rule out row/column/adjacency.
	assert_false(MoveValidator.is_legal(Vector2i(2, 0), board))

func test_detects_adjacency_conflict() -> void:
	var board := _make_board()
	board.place_cat(Vector2i(1, 1))
	assert_false(MoveValidator.is_legal(Vector2i(2, 2), board))

func test_allows_non_conflicting_placement() -> void:
	var board := _make_board()
	board.place_cat(Vector2i(0, 0))
	assert_true(MoveValidator.is_legal(Vector2i(2, 3), board))

func test_ignores_the_cat_being_moved() -> void:
	var board := _make_board()
	var position := Vector2i(0, 0)
	board.place_cat(position)
	# A cat shouldn't conflict with itself when re-checking its own square.
	assert_true(MoveValidator.is_legal(position, board))
