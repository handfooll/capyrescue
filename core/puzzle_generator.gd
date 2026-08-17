class_name PuzzleGenerator
extends RefCounted

## Generates playable puzzles: a random valid solution, then an irregular
## region layout grown outward from that solution, retried until
## PuzzleSolver confirms the layout admits exactly one solution.

class GeneratedPuzzle:
	var size: int
	var regions: Array
	var solution: Array # Array[Vector2i]

	func _init(p_size: int, p_regions: Array, p_solution: Array) -> void:
		size = p_size
		regions = p_regions
		solution = p_solution

## - `max_attempts`: each attempt generates a fresh random solution and region
##   layout; region growth is randomized, so a layout grown around a valid
##   solution can still end up admitting more than one, in which case we
##   discard it and retry. The odds of a random layout landing on a unique
##   solution collapse as `size` grows - measured empirically (30 seeds
##   each): size 6 is reliable at 500 attempts, size 7 needs ~10000 to be
##   reliable, and size 8 succeeds only ~15% of the time *even at 10000*
##   (worth knowing before offering size 8+ in any UI: raising this default
##   further won't fix it - that needs a smarter algorithm than pure random
##   region growth).
static func generate(size: int, max_attempts: int = 10000, rng: RandomNumberGenerator = null) -> GeneratedPuzzle:
	var use_rng := rng if rng != null else RandomNumberGenerator.new()
	for attempt in max_attempts:
		var solution = _generate_solution(size, use_rng)
		if solution == null:
			continue
		var regions := _grow_regions(size, solution, use_rng)
		if not PuzzleSolver.has_unique_solution(size, regions):
			continue
		return GeneratedPuzzle.new(size, regions, solution)
	return null

## One cat per row, satisfying the column and adjacency rules (region
## constraint is trivially satisfied once regions are grown one-per-solution-
## cell below). Returns null if no placement exists (true for size < 4 -
## exhaustively verified for 2x2 and 3x3: no arrangement can satisfy
## one-per-row/column plus non-adjacency at all).
static func _generate_solution(size: int, rng: RandomNumberGenerator) -> Variant:
	var placed: Array = []
	var used_columns := {}
	if _backtrack_solution(0, size, rng, placed, used_columns):
		return placed
	return null

# A plain recursive static func rather than a self-referencing lambda - see
# the note in puzzle_solver.gd's _backtrack for why.
static func _backtrack_solution(row: int, size: int, rng: RandomNumberGenerator, placed: Array, used_columns: Dictionary) -> bool:
	if row == size:
		return true
	for col in _shuffled(range(size), rng):
		if used_columns.has(col):
			continue
		var position := Vector2i(row, col)
		var conflicts := false
		for p in placed:
			if MoveValidator.is_adjacent(p, position):
				conflicts = true
				break
		if conflicts:
			continue
		placed.append(position)
		used_columns[col] = true
		if _backtrack_solution(row + 1, size, rng, placed, used_columns):
			return true
		placed.pop_back()
		used_columns.erase(col)
	return false

## Multi-source randomized flood fill: each solution cell seeds one region, and
## regions take turns claiming a random unclaimed orthogonal neighbor from their
## frontier until every cell on the board belongs to exactly one region.
static func _grow_regions(size: int, solution: Array, rng: RandomNumberGenerator) -> Array:
	var region_of: Array = []
	for row in size:
		var row_values: Array = []
		row_values.resize(size)
		row_values.fill(-1)
		region_of.append(row_values)

	var frontiers: Array = []
	for id in solution.size():
		var position: Vector2i = solution[id]
		region_of[position.x][position.y] = id
		frontiers.append([position])

	var remaining := size * size - solution.size()

	while remaining > 0:
		var growable: Array = []
		for i in frontiers.size():
			if not frontiers[i].is_empty():
				growable.append(i)
		if growable.is_empty():
			break
		var region_id: int = growable[rng.randi_range(0, growable.size() - 1)]
		var frontier: Array = frontiers[region_id]
		var index := rng.randi_range(0, frontier.size() - 1)
		var cell: Vector2i = frontier[index]
		frontier.remove_at(index)

		for neighbor in _orthogonal_neighbors(cell, size):
			if region_of[neighbor.x][neighbor.y] == -1:
				region_of[neighbor.x][neighbor.y] = region_id
				frontier.append(neighbor)
				remaining -= 1

	return region_of

static func _orthogonal_neighbors(position: Vector2i, size: int) -> Array:
	var candidates := [
		Vector2i(position.x - 1, position.y),
		Vector2i(position.x + 1, position.y),
		Vector2i(position.x, position.y - 1),
		Vector2i(position.x, position.y + 1),
	]
	var result: Array = []
	for c in candidates:
		if c.x >= 0 and c.x < size and c.y >= 0 and c.y < size:
			result.append(c)
	return result

## Fisher-Yates using the given RNG - Array.shuffle() always uses global
## random state, which would make this non-reproducible for seeded tests.
static func _shuffled(array: Array, rng: RandomNumberGenerator) -> Array:
	var result := array.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result
