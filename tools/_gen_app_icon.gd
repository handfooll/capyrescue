extends Node

## Dev-only tool - regenerates the placeholder app icon (res://icon.png) from
## the same capybara piece art used for placed cats on the board (see
## AppTheme.ART_CAT_PIECE), on the game's grass green, matching the in-app
## branding (see ui/main_menu.gd's title).
## Run with: godot res://tools/_gen_app_icon.tscn (must NOT be --headless -
## same reason as tools/_screenshot_tour.gd: text rendering needs an actual
## rendered frame, not the dummy headless renderer).
##
## This is a placeholder, same as the rest of the "Meowdoku" branding (see
## the project notes - the name collides with a real App Store app and needs
## changing before ever actually shipping).

const OUT_PATH := "res://icon.png"
const SIZE := 1024

func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(SIZE, SIZE)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	# Sampled straight from the grass strip in art/menu/back.png so the icon
	# reads as the same world as the game itself.
	var bg := ColorRect.new()
	bg.color = Color("5c8f26")
	bg.size = Vector2(SIZE, SIZE)
	viewport.add_child(bg)

	var piece := TextureRect.new()
	piece.texture = load("res://art/menu/cat_piece.png")
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	piece.size = Vector2(SIZE, SIZE) * 0.8
	piece.position = (Vector2(SIZE, SIZE) - piece.size) / 2.0
	viewport.add_child(piece)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var image := viewport.get_texture().get_image()
	var err := image.save_png(OUT_PATH)
	if err != OK:
		push_error("failed to save icon: %s" % err)
	else:
		print("icon saved to ", OUT_PATH)
	get_tree().quit()
