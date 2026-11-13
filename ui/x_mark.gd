extends Control

## Draws a thick X, independent of any font glyph - guarantees a visible,
## consistently-thick mark regardless of what glyphs the platform's font
## actually has (a real risk on iOS for even plain symbols, not just color
## emoji - see autoload/font_manager.gd). Sized to fill its parent cell.
##
## Proportions rather than fixed pixels, because the cell isn't a fixed size
## any more: ui/main.gd fits the grid to the screen, so a 4x4 board's tiles are
## half again as wide as a 7x7's and a hardcoded inset/thickness would read as
## a different mark on each.
const INSET_RATIO := 0.27
const THICKNESS_RATIO := 0.125

## The lettering brown from the art set (AppTheme.TEXT), not a neutral gray -
## a gray X on the region fills reads as a different design language than the
## drawn pieces sitting next to it.
var mark_color: Color = Color(AppTheme.TEXT, 0.8)

func _draw() -> void:
	var span := minf(size.x, size.y)
	var inset := span * INSET_RATIO
	var thickness := span * THICKNESS_RATIO
	var a := Vector2(inset, inset)
	var b := size - Vector2(inset, inset)
	var c := Vector2(inset, size.y - inset)
	var d := Vector2(size.x - inset, inset)
	draw_line(a, b, mark_color, thickness, true)
	draw_line(c, d, mark_color, thickness, true)
