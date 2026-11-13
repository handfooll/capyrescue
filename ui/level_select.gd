extends Control

## Difficulty picker: one card per board size, each showing that
## difficulty's local best time/score, and a Play button that hands the
## chosen size to the game screen via GameData.pending_size.
##
## Superseded and currently unreachable - nothing navigates here. The picker
## itself now lives in Settings and in the in-game pause card
## (AppTheme.difficulty_picker), which is where the choice is actually made;
## this screen is kept only because it also surfaces per-tier stats, and is
## safe to delete once nothing wants that view.

func _ready() -> void:
	add_child(AppTheme.art_background())

	var safe_area := AppTheme.safe_area_root()
	add_child(safe_area)

	var padded := AppTheme.screen_root(safe_area)
	safe_area.add_child(padded)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	padded.add_child(root)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	root.add_child(top_bar)
	var back_button := AppTheme.ghost_button("←  Back", 16)
	back_button.pressed.connect(_on_back_pressed)
	top_bar.add_child(back_button)
	var title := AppTheme.heading("Choose a Level", 30, AppTheme.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	scroll.add_child(list)

	for size in range(GameData.MIN_SIZE, GameData.MAX_SIZE + 1):
		list.add_child(_build_level_card(size))

func _build_level_card(size: int) -> Control:
	var card := AppTheme.card(AppTheme.SURFACE, 20)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_label := AppTheme.heading("%s  (%dx%d)" % [GameData.difficulty_name(size), size, size], 22, AppTheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(name_label)

	var best: Dictionary = GameData.get_best(size)
	var stats_text: String
	if best.games_played == 0:
		stats_text = "Not played yet"
	else:
		var best_time_text := AppTheme.format_time(best.best_time_seconds) if best.best_time_seconds >= 0.0 else "-"
		stats_text = "Best score %d   •   Best time %s   •   %d games" % [best.best_score, best_time_text, best.games_played]
	var stats_label := AppTheme.body_label(stats_text, 14)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(stats_label)

	var play_button := AppTheme.primary_button("Play", 18)
	play_button.custom_minimum_size.x = 90
	play_button.pressed.connect(_on_play_pressed.bind(size))
	row.add_child(play_button)

	return card

func _on_play_pressed(size: int) -> void:
	Audio.play_ui_tap()
	GameData.set_pending_size(size)
	get_tree().change_scene_to_file("res://ui/main.tscn")

func _on_back_pressed() -> void:
	Audio.play_ui_tap()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

