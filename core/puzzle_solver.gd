class_name PuzzleSolver
extends RefCounted

## Brute-force backtracking solver over a fixed region layout.
##
## This is intentionally independent of PuzzleGenerator's own placement
## logic: the generator uses it to confirm a layout has exactly one
## solution, and every candidate it finds is cross-checked against
## WinConditionChecker rather than trusted on the solver's own bookkeeping.

## Finds up to `limit` distinct solutions for the given region layout, placing
## one cat per row. Stops early once `limit` is reached.
static func find_solutions(size: int, regions: Array, limit: int = 2) -> Array:
	var board := Board.new(size, regions)
	var solutions: Array = []
	_backtrack(board, 0, size, limit, solutions)
	return solutions

# A plain recursive static func rather than a self-referencing lambda: GDScript
# lambdas capture local variables by value at creation time, not by live
# reference, so a `var f: Callable; f = func(): ... f.call(...)` pattern calls
# a still-null snapshot of `f` - this only surfaces at runtime, not at parse time.
static func _backtrack(board: Board, row: int, size: int, limit: int, solutions: Array) -> void:
	if solutions.size() >= limit:
		return
	if row == size:
		if WinConditionChecker.is_solved(board):
			solutions.append(board.cat_positions())
		return
	for col in size:
		if solutions.size() >= limit:
			return
		var position := Vector2i(row, col)
		if not MoveValidator.is_legal(position, board):
			continue
		board.place_cat(position)
		_backtrack(board, row + 1, size, limit, solutions)
		board.remove_cat(position)

static func has_unique_solution(size: int, regions: Array) -> bool:
	return find_solutions(size, regions, 2).size() == 1
