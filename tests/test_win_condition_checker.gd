extends GutTest

# 4x4, each column its own region, so a valid solve is any non-adjacent
# column permutation.
func _make_board() -> Board:
	return Board.new(4, [
		[0, 1, 2, 3],
		[0, 1, 2, 3],
		[0, 1, 2, 3],
		[0, 1, 2, 3],
	])

func test_valid_solution_is_solved() -> void:
	var board := _make_board()
	for pair in [[0, 1], [1, 3], [2, 0], [3, 2]]:
		board.place_cat(Vector2i(pair[0], pair[1]))
	assert_true(WinConditionChecker.is_solved(board))

func test_too_few_cats_is_not_solved() -> void:
	var board := _make_board()
	board.place_cat(Vector2i(0, 1))
	assert_false(WinConditionChecker.is_solved(board))

func test_duplicate_row_is_not_solved() -> void:
	var board := _make_board()
	for pair in [[0, 0], [0, 2], [2, 1], [3, 3]]:
		board.place_cat(Vector2i(pair[0], pair[1]))
	assert_false(WinConditionChecker.is_solved(board))

func test_duplicate_column_is_not_solved() -> void:
	var board := _make_board()
	for pair in [[0, 0], [1, 2], [2, 0], [3, 3]]:
		board.place_cat(Vector2i(pair[0], pair[1]))
	assert_false(WinConditionChecker.is_solved(board))

func test_adjacent_cats_are_not_solved() -> void:
	# One region per row, so row/column/region coverage all pass and only
	# the adjacency rule is left to fail: (0,0) and (1,1) touch diagonally.
	var board := Board.new(4, [
		[0, 0, 0, 0],
		[1, 1, 1, 1],
		[2, 2, 2, 2],
		[3, 3, 3, 3],
	])
	for pair in [[0, 0], [1, 1], [2, 3], [3, 2]]:
		board.place_cat(Vector2i(pair[0], pair[1]))
	assert_false(WinConditionChecker.is_solved(board))

func test_missing_region_coverage_is_not_solved() -> void:
	# All four cats land in only two of the four regions.
	var board := Board.new(4, [
		[0, 0, 1, 1],
		[0, 0, 1, 1],
		[0, 0, 1, 1],
		[0, 0, 1, 1],
	])
	for pair in [[0, 1], [1, 3], [2, 0], [3, 2]]:
		board.place_cat(Vector2i(pair[0], pair[1]))
	assert_false(WinConditionChecker.is_solved(board))
