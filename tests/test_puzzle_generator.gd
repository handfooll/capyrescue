extends GutTest

## Brute-force cross-check per the project's testing approach: don't just
## trust the generator's own solution, verify the emitted board against the
## actual win-condition validator and re-derive uniqueness with an
## independent solver.
func test_generated_puzzle_is_valid_and_unique() -> void:
	for size in [4, 5, 6, 7]:
		for seed_value in [1, 2, 3]:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var puzzle := PuzzleGenerator.generate(size, 10000, rng)
			assert_ne(puzzle, null, "generator failed to produce a puzzle for size %d, seed %d" % [size, seed_value])
			if puzzle == null:
				continue

			assert_eq(puzzle.size, size)
			assert_eq(puzzle.regions.size(), size)
			for row_values in puzzle.regions:
				assert_eq(row_values.size(), size)

			var board := Board.new(size, puzzle.regions)
			for position in puzzle.solution:
				board.place_cat(position)
			assert_true(WinConditionChecker.is_solved(board))

			var solutions := PuzzleSolver.find_solutions(size, puzzle.regions, 2)
			assert_eq(solutions.size(), 1)
			assert_eq(solutions[0], puzzle.solution)

func test_regions_partition_the_board_into_exactly_size_connected_territories() -> void:
	for size in [4, 5, 6, 7]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		var puzzle := PuzzleGenerator.generate(size, 10000, rng)
		assert_ne(puzzle, null)
		if puzzle == null:
			continue

		var cells_by_region := {}
		for row in size:
			for col in size:
				var region: int = puzzle.regions[row][col]
				if not cells_by_region.has(region):
					cells_by_region[region] = []
				cells_by_region[region].append(Vector2i(row, col))

		assert_eq(cells_by_region.keys().size(), size)
		var total := 0
		for cells in cells_by_region.values():
			total += cells.size()
		assert_eq(total, size * size)

		for cells in cells_by_region.values():
			assert_true(_cells_connected(cells, size))

## Orthogonal-adjacency BFS connectivity check, independent of the generator's own growth logic.
func _cells_connected(cells: Array, size: int) -> bool:
	if cells.is_empty():
		return true
	var cell_set := {}
	for c in cells:
		cell_set[c] = true
	var start: Vector2i = cells[0]
	var visited := {start: true}
	var queue := [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_back()
		var neighbors := [
			Vector2i(current.x - 1, current.y),
			Vector2i(current.x + 1, current.y),
			Vector2i(current.x, current.y - 1),
			Vector2i(current.x, current.y + 1),
		]
		for neighbor in neighbors:
			if cell_set.has(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	return visited.size() == cell_set.size()
