extends Control

## The whole game screen: owns the mutable board and translates player taps
## into calls against the plain-GDScript Core layer (res://core/). No rule
## logic lives here - this is presentation state only, same split as the
## Core-layer/UI-layer boundary in the archived Swift version.
##
## Public surface (new_puzzle, _on_cell_gui_input, _handle_double_tap,
## request_hint, board/solution/marked_cells/is_solved/current_size,
## TAP_DISAMBIGUATION_SECONDS) is exercised directly by tests/test_main_ui.gd
## - keep signatures stable when touching this file.

const DEFAULT_SIZE := 6
# A lone click and the first click of a double-click are indistinguishable
# until this much time has passed with no second click - Godot delivers
# double-clicks as two separate press events (the second flagged
# `double_click = true`), it does not suppress the first on its own.
const TAP_DISAMBIGUATION_SECONDS := 0.3

const REGION_COLORS: Array[Color] = [
	Color(0.97, 0.51, 0.51),
	Color(1.0, 0.7, 0.42),
	Color(0.98, 0.85, 0.4),
	Color(0.53, 0.85, 0.6),
	Color(0.4, 0.87, 0.76),
	Color(0.35, 0.78, 0.78),
	Color(0.42, 0.75, 0.95),
	Color(0.62, 0.55, 0.9),
	Color(0.75, 0.55, 0.9),
	Color(0.9, 0.55, 0.75),
]

var board: Board
var solution: Array = []
var marked_cells: Dictionary = {}
var is_solved: bool = false
var current_size: int = DEFAULT_SIZE

var mistakes: int = 0
var is_game_over: bool = false

var _cell_buttons: Dictionary = {} # Vector2i -> Button
var _single_tap_timer: Timer
var _pending_single_tap_position: Vector2i = Vector2i(-1, -1)

var _elapsed_seconds: float = 0.0
var _result_saved: bool = false

var _difficulty_label: Label
var _life_icons: Array = [] # Array[Label]
var _timer_label: Label
var _mistakes_label: Label
var _board_grid: GridContainer
var _hint_button: Button
var _restart_button: Button
var _new_puzzle_button: Button
var _overlay: Control
var _overlay_title: Label
var _overlay_stats: Label
var _overlay_buttons: HBoxContainer

func _ready() -> void:
	_build_chrome()
	_single_tap_timer = Timer.new()
	_single_tap_timer.wait_time = TAP_DISAMBIGUATION_SECONDS
	_single_tap_timer.one_shot = true
	_single_tap_timer.timeout.connect(_on_single_tap_timer_timeout)
	add_child(_single_tap_timer)
	new_puzzle(GameData.pending_size)

func _process(delta: float) -> void:
	if is_solved or is_game_over:
		return
	_elapsed_seconds += delta
	_timer_label.text = AppTheme.format_time(_elapsed_seconds)

func _build_chrome() -> void:
	add_child(AppTheme.make_background())

	var safe_area := AppTheme.safe_area_root()
	add_child(safe_area)

	var padded := AppTheme.padded_root(20)
	safe_area.add_child(padded)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	padded.add_child(root)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	root.add_child(top_bar)

	var back_button := AppTheme.ghost_button("←  Menu", 16)
	back_button.pressed.connect(_on_back_pressed)
	top_bar.add_child(back_button)

	_difficulty_label = AppTheme.heading("", 22, AppTheme.PRIMARY_DARK)
	_difficulty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_difficulty_label)

	var lives_row := HBoxContainer.new()
	lives_row.add_theme_constant_override("separation", 2)
	top_bar.add_child(lives_row)
	for i in GameData.STARTING_LIVES:
		var paw := Label.new()
		paw.text = "🐾"
		paw.add_theme_font_size_override("font_size", 24)
		lives_row.add_child(paw)
		_life_icons.append(paw)

	var stats_row := HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", AppTheme.SPACING_LG)
	root.add_child(stats_row)

	_timer_label = AppTheme.heading("0:00", 18, AppTheme.TEXT)
	stats_row.add_child(_timer_label)

	_mistakes_label = AppTheme.heading("", 18, AppTheme.TEXT_MUTED)
	stats_row.add_child(_mistakes_label)

	var grid_wrap := CenterContainer.new()
	grid_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(grid_wrap)
	var grid_card := AppTheme.card(AppTheme.SURFACE, 20)
	grid_wrap.add_child(grid_card)
	_board_grid = GridContainer.new()
	_board_grid.add_theme_constant_override("h_separation", 4)
	_board_grid.add_theme_constant_override("v_separation", 4)
	grid_card.add_child(_board_grid)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	root.add_child(button_row)
	_hint_button = AppTheme.secondary_button("💡 Hint", 16)
	_hint_button.pressed.connect(request_hint)
	button_row.add_child(_hint_button)
	_restart_button = AppTheme.ghost_button("↺ Restart", 16)
	_restart_button.pressed.connect(_on_restart_pressed)
	button_row.add_child(_restart_button)
	_new_puzzle_button = AppTheme.primary_button("New Puzzle", 16)
	_new_puzzle_button.pressed.connect(func() -> void: new_puzzle(current_size))
	button_row.add_child(_new_puzzle_button)

	root.add_child(AppTheme.ad_placeholder())

	_build_overlay()
	add_child(_overlay)

func _build_overlay() -> void:
	_overlay = CenterContainer.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.35)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(scrim)
	# CenterContainer only centers the *last* non-scrim child normally, but
	# since the scrim is full-rect it would otherwise get centered too -
	# put the actual card in its own full-rect wrapper on top instead.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var card := AppTheme.card(AppTheme.SURFACE, 28)
	card.custom_minimum_size = Vector2(280, 0)
	center.add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	card.add_child(column)

	_overlay_title = AppTheme.heading("", 28, AppTheme.TEXT)
	column.add_child(_overlay_title)

	_overlay_stats = AppTheme.body_label("", 16)
	column.add_child(_overlay_stats)

	_overlay_buttons = HBoxContainer.new()
	_overlay_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_overlay_buttons.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	column.add_child(_overlay_buttons)

func new_puzzle(size: int) -> void:
	var puzzle := PuzzleGenerator.generate(size)
	current_size = size
	board = Board.new(size, puzzle.regions)
	solution = puzzle.solution
	marked_cells.clear()
	is_solved = false
	is_game_over = false
	mistakes = 0
	_elapsed_seconds = 0.0
	_result_saved = false
	_difficulty_label.text = "%s  (%dx%d)" % [GameData.difficulty_name(size), size, size]
	_rebuild_grid()
	_refresh_all_cells()
	_refresh_lives()
	_refresh_mistakes_label()
	_hide_overlay()
	_hint_button.disabled = false

func _rebuild_grid() -> void:
	for child in _board_grid.get_children():
		child.queue_free()
	_cell_buttons.clear()
	_board_grid.columns = current_size
	for row in current_size:
		for col in current_size:
			var position := Vector2i(row, col)
			var button := Button.new()
			button.custom_minimum_size = Vector2(48, 48)
			button.focus_mode = Control.FOCUS_NONE
			button.gui_input.connect(_on_cell_gui_input.bind(position))
			_board_grid.add_child(button)
			_cell_buttons[position] = button

func _on_cell_gui_input(event: InputEvent, position: Vector2i) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.double_click:
		_single_tap_timer.stop()
		_handle_double_tap(position)
	else:
		_pending_single_tap_position = position
		_single_tap_timer.start()

func _on_single_tap_timer_timeout() -> void:
	_handle_single_tap(_pending_single_tap_position)

## Single tap: toggle an X mark. Tapping a cat marks it instead of clearing
## it outright, since a mark means "decided this isn't a cat".
func _handle_single_tap(position: Vector2i) -> void:
	if is_solved or is_game_over:
		return
	if board.has_cat(position):
		board.remove_cat(position)
		marked_cells[position] = true
	elif marked_cells.has(position):
		marked_cells.erase(position)
	else:
		marked_cells[position] = true
	Audio.play_mark()
	_on_board_changed()

## Double tap: toggle a cat directly, clearing any mark on the way in. A
## placement that conflicts with another cat (same row/column/region, or
## touching) costs one of the three lives - removing a cat never does.
func _handle_double_tap(position: Vector2i) -> void:
	if is_solved or is_game_over:
		return
	if board.has_cat(position):
		board.remove_cat(position)
		Audio.play_mark()
	else:
		marked_cells.erase(position)
		board.place_cat(position)
		if MoveValidator.is_legal(position, board):
			Audio.play_place()
			Audio.vibrate_if_enabled(15)
		else:
			mistakes += 1
			Audio.play_mistake()
			Audio.vibrate_if_enabled(35)
			_refresh_mistakes_label()
			_refresh_lives()
	_on_board_changed()
	if not is_solved and _lives_remaining() <= 0:
		_trigger_game_over()

## Reveals one correct cat placement the player hasn't found yet - the
## top-left-most missing solution cell, so the choice is deterministic
## rather than depending on Dictionary iteration order.
func request_hint() -> void:
	if is_solved or is_game_over:
		return
	var missing: Array = []
	for position in solution:
		if not board.has_cat(position):
			missing.append(position)
	if missing.is_empty():
		return
	missing.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x or (a.x == b.x and a.y < b.y))
	var position: Vector2i = missing[0]
	marked_cells.erase(position)
	board.place_cat(position)
	_on_board_changed()

func _lives_remaining() -> int:
	return maxi(0, GameData.STARTING_LIVES - mistakes)

func _on_board_changed() -> void:
	is_solved = WinConditionChecker.is_solved(board)
	_refresh_all_cells()
	if is_solved:
		_trigger_win()

func _trigger_win() -> void:
	Audio.play_win()
	Audio.vibrate_if_enabled(40)
	_hint_button.disabled = true
	var score := _compute_score()
	_save_result(score, true)
	_show_overlay(
		"🎉 Solved!",
		"Score %d   •   Time %s   •   %d mistake%s" % [score, AppTheme.format_time(_elapsed_seconds), mistakes, "" if mistakes == 1 else "s"],
		true
	)

func _trigger_game_over() -> void:
	is_game_over = true
	Audio.play_game_over()
	Audio.vibrate_if_enabled(60)
	_hint_button.disabled = true
	_save_result(0, false)
	_show_overlay(
		"😿 Out of Lives",
		"Time %s   •   Try again?" % AppTheme.format_time(_elapsed_seconds),
		false
	)

func _save_result(score: int, won: bool) -> void:
	if _result_saved:
		return
	_result_saved = true
	GameData.record_result(current_size, _elapsed_seconds, score, won)

func _compute_score() -> int:
	var base := 200 * current_size
	var time_penalty := int(_elapsed_seconds) * 2
	var mistake_penalty := mistakes * 100
	return maxi(0, base - time_penalty - mistake_penalty)

func _show_overlay(title: String, stats: String, won: bool) -> void:
	_overlay_title.text = title
	_overlay_title.add_theme_color_override("font_color", AppTheme.SUCCESS if won else AppTheme.DANGER)
	_overlay_stats.text = stats
	for child in _overlay_buttons.get_children():
		child.queue_free()

	var retry_button := AppTheme.primary_button("Retry" if not won else "New Puzzle", 16)
	retry_button.pressed.connect(_on_restart_pressed if not won else func() -> void: new_puzzle(current_size))
	_overlay_buttons.add_child(retry_button)

	var menu_button := AppTheme.ghost_button("Menu", 16)
	menu_button.pressed.connect(_on_back_pressed)
	_overlay_buttons.add_child(menu_button)

	_overlay.visible = true

func _hide_overlay() -> void:
	if _overlay != null:
		_overlay.visible = false

func _on_restart_pressed() -> void:
	Audio.play_ui_tap()
	board = Board.new(current_size, board.regions)
	marked_cells.clear()
	is_solved = false
	is_game_over = false
	mistakes = 0
	_elapsed_seconds = 0.0
	_result_saved = false
	_refresh_all_cells()
	_refresh_lives()
	_refresh_mistakes_label()
	_hide_overlay()
	_hint_button.disabled = false

func _on_back_pressed() -> void:
	Audio.play_ui_tap()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _refresh_lives() -> void:
	var remaining := _lives_remaining()
	for i in _life_icons.size():
		var paw: Label = _life_icons[i]
		paw.modulate = Color(1, 1, 1, 1) if i < remaining else Color(0, 0, 0, 0.15)

func _refresh_mistakes_label() -> void:
	_mistakes_label.text = "Mistakes: %d/%d" % [mistakes, GameData.STARTING_LIVES]

func _refresh_all_cells() -> void:
	for position in _cell_buttons:
		_refresh_cell(position)

func _refresh_cell(position: Vector2i) -> void:
	var button: Button = _cell_buttons.get(position)
	if button == null:
		return
	var region := board.region_id(position)
	var color := REGION_COLORS[region % REGION_COLORS.size()]
	var conflicted := board.has_cat(position) and not MoveValidator.is_legal(position, board)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	# A conflicting cat is flagged via the border, not font_color: the cat
	# glyph is a full-color emoji, and color-emoji glyphs ignore font_color
	# overrides entirely (they're COLR/bitmap layers, not tinted outlines) -
	# caught by the viewport-screenshot check, not by reading the code.
	style.border_color = AppTheme.DANGER if conflicted else Color(0, 0, 0, 0.25)
	style.set_border_width_all(4 if conflicted else 1)
	style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

	if board.has_cat(position):
		button.text = "🐱"
	elif marked_cells.has(position):
		button.text = "✕" # ✕
		button.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	else:
		button.text = ""
