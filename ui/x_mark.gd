extends Control

## Draws a thick X, independent of any font glyph - guarantees a visible,
## consistently-thick mark regardless of what glyphs the platform's font
## actually has (a real risk on iOS for even plain symbols, not just color
## emoji - see autoload/font_manager.gd). Sized to fill its parent cell.

const THICKNESS := 6.0
const INSET := 13.0

var mark_color: Color = Color(0.4, 0.4, 0.4)

func _draw() -> void:
	var a := Vector2(INSET, INSET)
	var b := size - Vector2(INSET, INSET)
	var c := Vector2(INSET, size.y - INSET)
	var d := Vector2(size.x - INSET, INSET)
	draw_line(a, b, mark_color, THICKNESS, true)
	draw_line(c, d, mark_color, THICKNESS, true)
