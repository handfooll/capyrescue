extends Control

## Local personal-bests board, one row per difficulty. There's no online
## backend yet (see the project notes "Backend (Future Phase)") - this reads
## on-device GameData only, and says so, rather than pretending to be a real
## leaderboard.

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
	var title := AppTheme.heading("🏆  Leaderboard", 30, AppTheme.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)

	# TEXT, not the default muted tan - this line sits on the painted sky now.
	var subtitle := AppTheme.body_label("your personal bests, saved on this device", 14, AppTheme.TEXT)
	root.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	scroll.add_child(list)

	for size in range(GameData.MIN_SIZE, GameData.MAX_SIZE + 1):
		list.add_child(_build_row(size))

func _build_row(size: int) -> Control:
	var card := AppTheme.card(AppTheme.SURFACE, 20)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	card.add_child(row)

	var name_label := AppTheme.heading("%s" % GameData.difficulty_name(size), 20, AppTheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.custom_minimum_size.x = 110
	row.add_child(name_label)

	var best: Dictionary = GameData.get_best(size)
	if best.games_played == 0:
		var empty_label := AppTheme.body_label("no runs yet", 16)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(empty_label)
		return card

	var stats := VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stats)

	var score_label := AppTheme.heading("Best score: %d" % best.best_score, 18, AppTheme.ACCENT)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stats.add_child(score_label)

	var best_time_text := AppTheme.format_time(best.best_time_seconds) if best.best_time_seconds >= 0.0 else "-"
	var win_rate := int(round(100.0 * best.wins / best.games_played))
	var detail_label := AppTheme.body_label("Best time %s   •   %d/%d wins (%d%%)" % [best_time_text, best.wins, best.games_played, win_rate], 14)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(detail_label)

	return card

func _on_back_pressed() -> void:
	Audio.play_ui_tap()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
