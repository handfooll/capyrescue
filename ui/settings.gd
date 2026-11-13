extends Control

## Difficulty, music/SFX volume, haptics toggle, and a reset-progress action -
## all reading and writing through the Settings/GameData autoloads so every
## screen (and the next app launch) sees the same values.
##
## The difficulty picker lives here because the main menu's Play goes straight
## into a game: res://ui/level_select.tscn was the only thing that ever set the
## tier, and nothing navigated to it, so the choice was unreachable.

var _reset_confirm: ConfirmationDialog
var _difficulty_picker: GridContainer

func _ready() -> void:
	add_child(AppTheme.art_background())

	var safe_area := AppTheme.safe_area_root()
	add_child(safe_area)

	var padded := AppTheme.screen_root(safe_area)
	safe_area.add_child(padded)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", AppTheme.SPACING_LG)
	padded.add_child(root)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	root.add_child(top_bar)
	var back_button := AppTheme.ghost_button("←  Back", 16)
	back_button.pressed.connect(_on_back_pressed)
	top_bar.add_child(back_button)
	var title := AppTheme.heading("⚙  Settings", 30, AppTheme.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)

	var difficulty_card := AppTheme.card(AppTheme.SURFACE, 20)
	root.add_child(difficulty_card)
	var difficulty_section := VBoxContainer.new()
	difficulty_section.add_theme_constant_override("separation", AppTheme.SPACING_SM)
	difficulty_card.add_child(difficulty_section)

	var difficulty_label := AppTheme.body_label("Difficulty", 18, AppTheme.TEXT)
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	difficulty_section.add_child(difficulty_label)

	var difficulty_hint := AppTheme.body_label("bigger board, bigger score", 14)
	difficulty_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	difficulty_section.add_child(difficulty_hint)

	_difficulty_picker = AppTheme.difficulty_picker(GameData.pending_size, _on_difficulty_picked)
	difficulty_section.add_child(_difficulty_picker)

	var card := AppTheme.card(AppTheme.SURFACE, 20)
	root.add_child(card)
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", AppTheme.SPACING_LG)
	card.add_child(section)

	section.add_child(_build_slider_row("🎵  Music Volume", Settings.music_volume, _on_music_volume_changed))
	section.add_child(_build_slider_row("🔊  SFX Volume", Settings.sfx_volume, _on_sfx_volume_changed))
	section.add_child(_build_haptics_row())

	var reset_button := AppTheme.danger_button("Reset All Progress", 18)
	reset_button.pressed.connect(_on_reset_pressed)
	root.add_child(reset_button)

	_reset_confirm = ConfirmationDialog.new()
	_reset_confirm.title = "Reset progress?"
	_reset_confirm.dialog_text = "This clears every difficulty's best score and time. This can't be undone."
	_reset_confirm.confirmed.connect(_on_reset_confirmed)
	add_child(_reset_confirm)

func _build_slider_row(label_text: String, initial_value: float, on_changed: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", AppTheme.SPACING_SM)

	var label := AppTheme.body_label(label_text, 18, AppTheme.TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial_value
	slider.custom_minimum_size.y = 28
	AppTheme.style_slider(slider)
	slider.value_changed.connect(on_changed)
	row.add_child(slider)

	return row

func _build_haptics_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", AppTheme.SPACING_MD)

	var label := AppTheme.body_label("📳  Haptic Feedback", 18, AppTheme.TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var toggle := CheckButton.new()
	toggle.button_pressed = Settings.haptics_enabled
	toggle.toggled.connect(_on_haptics_toggled)
	row.add_child(toggle)

	return row

func _on_difficulty_picked(size: int) -> void:
	Audio.play_ui_tap()
	GameData.set_pending_size(size)
	AppTheme.refresh_difficulty_picker(_difficulty_picker, size)

func _on_music_volume_changed(value: float) -> void:
	Settings.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	Settings.set_sfx_volume(value)
	Audio.play_ui_tap()

func _on_haptics_toggled(pressed: bool) -> void:
	Settings.set_haptics_enabled(pressed)
	if pressed:
		Audio.vibrate_if_enabled(20)

func _on_reset_pressed() -> void:
	Audio.play_ui_tap()
	_reset_confirm.popup_centered()

func _on_reset_confirmed() -> void:
	GameData.reset_progress()
	Audio.play_ui_tap()

func _on_back_pressed() -> void:
	Audio.play_ui_tap()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
