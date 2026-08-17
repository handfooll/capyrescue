class_name MoveValidator
extends RefCounted

## Checks whether placing a cat at a given position is legal against the
## cats already on the board - used for live feedback while the player
## plays, independent of whether the full board is solved.

## Positions of cats already on the board that would conflict with a cat
## placed at `position` (same row/column/region, or touching).
static func conflicts(position: Vector2i, board: Board) -> Array:
	var result: Array = []
	for existing in board.cat_positions():
		if existing == position:
			continue
		if existing.x == position.x \
				or existing.y == position.y \
				or board.region_id(existing) == board.region_id(position) \
				or is_adjacent(existing, position):
			result.append(existing)
	return result

static func is_legal(position: Vector2i, board: Board) -> bool:
	return conflicts(position, board).is_empty()

## Whether two cells touch horizontally, vertically, or diagonally.
static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return a != b and absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1
