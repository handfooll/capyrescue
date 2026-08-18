extends Node

## Dev-only tool - regenerates the placeholder app icon (res://icon.png) from
## the 🐱 emoji, matching the in-app branding (see ui/main_menu.gd's title).
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

	var bg := ColorRect.new()
	bg.color = Color("ff8c5a")
	bg.size = Vector2(SIZE, SIZE)
	viewport.add_child(bg)

	var label := Label.new()
	label.text = "🐱"
	label.add_theme_font_size_override("font_size", 720)
	label.size = Vector2(SIZE, SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	viewport.add_child(label)

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
