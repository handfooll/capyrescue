extends Node

## Registered as **Fonts**. Every screen's icons (🐱🐾🏆⚙💡🔊🎵📳🎉😿) are plain
## emoji glyphs, not custom art - see ui/theme.gd's rationale for leaning on
## the engine's built-in default font rather than bundling one. That font has
## no emoji glyphs of its own; on desktop the missing glyphs get silently
## patched in from the OS's system emoji font (Apple Color Emoji on macOS),
## which is why everything looked fine in every screenshot taken so far.
##
## iOS doesn't do that same automatic system-font-fallback lookup for
## Godot's text renderer - confirmed via godotengine/godot#77914 and #103363
## (same root cause on Android). The fix has to be a font file actually
## bundled into the app, not a lookup by name. Noto Color Emoji (CBDT/CBLC,
## Apache 2.0) is added here as a *fallback only* - the primary/default font
## is untouched, so regular text keeps its existing look everywhere.

func _ready() -> void:
	var emoji_font: Font = load("res://assets/fonts/NotoColorEmoji.ttf")
	var default_font: Font = ThemeDB.fallback_font.duplicate()
	default_font.fallbacks = [emoji_font]
	var theme := Theme.new()
	theme.default_font = default_font
	get_tree().root.theme = theme
