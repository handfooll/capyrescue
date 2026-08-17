class_name WinConditionChecker
extends RefCounted

## Checks whether a board, as currently filled in, satisfies every win
## condition: exactly one cat per row, column, and region, with no two cats
## touching (including diagonally).
static func is_solved(board: Board) -> bool:
	var cats: Array = board.cat_positions()
	if cats.size() != board.size:
		return false
	for cat in cats:
		if not board.contains(cat):
			return false

	var rows := {}
	var cols := {}
	var region_ids := {}
	for cat in cats:
		rows[cat.x] = true
		cols[cat.y] = true
		region_ids[board.region_id(cat)] = true
	if rows.size() != board.size or cols.size() != board.size or region_ids.size() != board.size:
		return false

	for i in cats.size():
		for j in range(i + 1, cats.size()):
			if MoveValidator.is_adjacent(cats[i], cats[j]):
				return false
	return true
