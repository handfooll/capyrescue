extends GutTest

func test_single_cell_board_has_one_trivial_solution() -> void:
	var solutions := PuzzleSolver.find_solutions(1, [[0]])
	assert_eq(solutions.size(), 1)
	assert_eq(solutions[0], [Vector2i(0, 0)])
	assert_true(PuzzleSolver.has_unique_solution(1, [[0]]))

func test_three_by_three_column_regions_have_no_solution() -> void:
	# One cat per row/column/region with the adjacency rule leaves no
	# legal permutation on a 3x3 board - verified by hand.
	var regions := [[0, 1, 2], [0, 1, 2], [0, 1, 2]]
	var solutions := PuzzleSolver.find_solutions(3, regions, 10)
	assert_true(solutions.is_empty())
	assert_false(PuzzleSolver.has_unique_solution(3, regions))

func test_four_by_four_row_regions_have_exactly_two_solutions() -> void:
	# Each row is its own region, so this reduces to a plain column
	# permutation under the adjacency rule - verified by hand to have
	# exactly two solutions: (1,3,0,2) and (2,0,3,1).
	var regions := [[0, 0, 0, 0], [1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]
	var solutions := PuzzleSolver.find_solutions(4, regions, 10)

	var expected_a := [Vector2i(0, 1), Vector2i(1, 3), Vector2i(2, 0), Vector2i(3, 2)]
	var expected_b := [Vector2i(0, 2), Vector2i(1, 0), Vector2i(2, 3), Vector2i(3, 1)]
	assert_eq(solutions.size(), 2)
	assert_has(solutions, expected_a)
	assert_has(solutions, expected_b)
	assert_false(PuzzleSolver.has_unique_solution(4, regions))

func test_solver_stops_at_limit() -> void:
	var regions := [[0, 0, 0, 0], [1, 1, 1, 1], [2, 2, 2, 2], [3, 3, 3, 3]]
	var solutions := PuzzleSolver.find_solutions(4, regions, 1)
	assert_eq(solutions.size(), 1)
