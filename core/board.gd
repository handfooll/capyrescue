class_name Board
extends RefCounted

## The NxN grid, its region layout, and the cats currently placed on it.
##
## This type owns no rule logic beyond bounds/region lookups - validation and
## win checking live in MoveValidator and WinConditionChecker so the rules
## stay independently testable.
##
## Grid positions are Vector2i(row, col) throughout this codebase.

var size: int
var regions: Array # regions[row][col] is an int region id
var cats: Dictionary = {} # Set of Vector2i, keyed by position

func _init(p_size: int, p_regions: Array, p_cats: Dictionary = {}) -> void:
	assert(p_regions.size() == p_size, "regions must have `size` rows")
	for row_values in p_regions:
		assert(row_values.size() == p_size, "regions must have `size` columns")
	size = p_size
	regions = p_regions
	cats = p_cats.duplicate()

func contains(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < size and position.y >= 0 and position.y < size

func region_id(position: Vector2i) -> int:
	return regions[position.x][position.y]

func place_cat(position: Vector2i) -> void:
	cats[position] = true

func remove_cat(position: Vector2i) -> void:
	cats.erase(position)

func has_cat(position: Vector2i) -> bool:
	return cats.has(position)

func toggle_cat(position: Vector2i) -> void:
	if cats.has(position):
		cats.erase(position)
	else:
		cats[position] = true

func cat_positions() -> Array:
	return cats.keys()
