extends Control

## App entry point: title, and navigation into the rest of the app. Built in
## code like every other screen here - see ui/theme.gd for the shared look.

func _ready() -> void:
	add_child(AppTheme.make_background())
	_add_decoration("🐾", -18, 0.12, Vector2(0.08, 0.14))
	_add_decoration("🐾", 24, 0.12, Vector2(0.86, 0.78))
	_add_decoration("🐾", -8, 0.1, Vector2(0.82, 0.12))
	_add_decoration("🐾", 16, 0.1, Vector2(0.1, 0.82))

	var safe_area := AppTheme.safe_area_root()
	add_child(safe_area)

	var root := CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe_area.add_child(root)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", AppTheme.SPACING_LG)
	column.custom_minimum_size.x = 340
	root.add_child(column)

	var title := AppTheme.heading("🐱 Meowdoku", 52, AppTheme.PRIMARY_DARK)
	column.add_child(title)

	var subtitle := AppTheme.body_label("one cat per row, column & territory", 16)
	column.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = AppTheme.SPACING_MD
	column.add_child(spacer)

	var play_button := AppTheme.primary_button("▶  Play", 24)
	play_button.pressed.connect(_on_play_pressed)
	column.add_child(play_button)

	var levels_button := AppTheme.secondary_button("🗺  Levels", 20)
	levels_button.pressed.connect(_go_to.bind("res://ui/level_select.tscn"))
	column.add_child(levels_button)

	var leaderboard_button := AppTheme.secondary_button("🏆  Leaderboard", 20)
	leaderboard_button.pressed.connect(_go_to.bind("res://ui/leaderboard.tscn"))
	column.add_child(leaderboard_button)

	var settings_button := AppTheme.secondary_button("⚙  Settings", 20)
	settings_button.pressed.connect(_go_to.bind("res://ui/settings.tscn"))
	column.add_child(settings_button)

	var quit_button := AppTheme.ghost_button("Quit", 16)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	column.add_child(quit_button)

func _on_play_pressed() -> void:
	Audio.play_ui_tap()
	get_tree().change_scene_to_file("res://ui/main.tscn")

func _go_to(path: String) -> void:
	Audio.play_ui_tap()
	get_tree().change_scene_to_file(path)

func _add_decoration(text: String, rotation_degrees_value: float, opacity: float, anchor: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 64)
	label.modulate = Color(1, 1, 1, opacity)
	label.rotation_degrees = rotation_degrees_value
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.anchor_left = anchor.x
	label.anchor_right = anchor.x
	label.anchor_top = anchor.y
	label.anchor_bottom = anchor.y
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
