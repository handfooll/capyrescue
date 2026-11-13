extends Control

## The whole game screen: owns the mutable board and translates player taps
## into calls against the plain-GDScript Core layer (res://core/). No rule
## logic lives here - this is presentation state only, same split as the
## Core-layer/UI-layer boundary in the archived Swift version.
##
## Public surface (new_puzzle, _handle_single_tap, _handle_double_tap,
## _begin_press/_continue_drag, request_hint,
## board/solution/marked_cells/is_solved/current_size, DOUBLE_TAP_SECONDS)
## is exercised directly by tests/test_main_ui.gd - keep signatures stable
## when touching this file.

const DEFAULT_SIZE := 6

const INVALID_CELL := Vector2i(-1, -1)

## Two presses on the *same* cell within this window place a cat.
##
## Deliberately measured from our own press timestamps rather than read off
## `InputEventMouseButton.double_click`: Godot sets that flag in the viewport
## from the previous click *anywhere on screen*, not per-Button. Two quick
## taps on two different (but nearby) cells therefore arrive with the second
## flagged `double_click = true`, which used to drop a cat on the second cell
## while the player was only trying to mark Xs quickly. Comparing cells
## ourselves makes a double-tap mean the same thing on every platform.
const DOUBLE_TAP_SECONDS := 0.28

## A press that travels at least this far before release is a swipe, not a
## tap, so it must not arm the double-tap window.
const DRAG_SLOP_PIXELS := 8.0

## Screen edge padding for the flowed content, and where that content starts.
##
## The Menu button and settings glyph are pixel-positioned in absolute screen
## space (see _build_top_row) rather than flowed from the safe-area inset, so
## they line up with the same glyph on the main menu - which never applies that
## inset at all, because the artist's canvas bakes its own top margin in. Under
## the old flowed layout the two screens' top rows sat at different heights on
## any device with a notch, since only this one got pushed down by it.
const SCREEN_MARGIN := 20
## Where the backdrop's capybara ends, in points - the bottom of its drawn
## bounds in art/menu/back_game.png (source pixels / ART_SCALE, same
## convention as AppTheme's art regions). The flowed content starts below it
## rather than right under the top row: a stats pill at the top row's own
## height sits across the animal's middle and crops it out of the scene.
const BACKDROP_CAPY_BOTTOM := 527.0 / AppTheme.ART_SCALE
const CONTENT_TOP := BACKDROP_CAPY_BOTTOM + AppTheme.SPACING_SM

## Cells are sized to the board, not fixed: a flat 48pt tile made the 7x7 grid
## 392pt wide inside 318pt of usable width, so the card ran off both edges of
## the screen. _cell_size_for() divides the width that's actually there, capped
## so a 4x4 doesn't balloon.
const CELL_SEPARATION := 4
const CELL_MAX_SIZE := 64.0
## AppTheme.card()'s content margin, which the board card spends on each side
## before the grid gets any room.
const CARD_PADDING := AppTheme.SPACING_MD

## Fraction of the cell the capybara piece occupies - it renders smaller than
## the tile so the tile's border stays visible as a placement frame around it.
const PIECE_SCALE := 0.75
const LIFE_ICON_SIZE := Vector2(18, 18)
## The capybara in the "found" counter on the stats row. Even, so the
## CenterContainer art_piece_rect() wraps it in can split the remainder
## exactly (see AppTheme.art_piece_rect).
const COUNTER_ICON_SIZE := Vector2(20, 20)
## The same piece again, drained of colour, at the top of the out-of-lives card.
const GAME_OVER_PIECE_SIZE := Vector2(76, 76)

## Region fills, derived from the drawn art's own palette (see AppTheme) rather
## than a generic pastel ramp - ordered so that consecutive region ids, which
## do end up adjacent on the board, land on clearly different hues.
const REGION_COLORS: Array[Color] = [
	Color("e4736a"), # champ-board red, softened toward the soil
	Color("f1d073"), # champ-board sand
	Color("7fc05e"), # grass, lightened
	Color("6ec8ea"), # sky
	Color("dbadc6"), # daily-card pink
	Color("fba561"), # play-sign orange
	Color("bcd05e"), # grass/sand blend
	Color("a7dcf2"), # pale sky
	Color("e8909f"), # deeper daily pink
	Color("c58564"), # soil highlight
]

var board: Board
var solution: Array = []
var marked_cells: Dictionary = {}
var is_solved: bool = false
var current_size: int = DEFAULT_SIZE
## True while this run is today's daily board rather than a free-play one.
var is_daily: bool = false

var mistakes: int = 0
var is_game_over: bool = false

var _cell_buttons: Dictionary = {} # Vector2i -> Button
var _cell_cats: Dictionary = {} # Vector2i -> Control (CenterContainer wrapper)
var _cell_marks: Dictionary = {} # Vector2i -> Control (ui/x_mark.gd)
var _last_tap_cell: Vector2i = INVALID_CELL
var _last_tap_msec: int = -1000000

# Swipe-to-mark state. A press opens a drag; every new cell the finger enters
# gets painted with the same operation the press itself performed, so a swipe
# reads as "keep doing what that first tap did" rather than toggling each cell
# it crosses (which would make dragging back over your own trail undo it).
var _drag_active: bool = false
var _drag_erasing: bool = false
var _drag_visited: Dictionary = {} # Set of Vector2i painted during this drag
var _drag_press_global: Vector2 = Vector2.ZERO
var _drag_moved: bool = false

# region id -> [normal StyleBoxFlat, conflicted StyleBoxFlat]. Cells only ever
# use one of two looks per region, so they're built once instead of allocating
# N² fresh styleboxes (plus 4N² theme overrides) on every single board change.
var _style_cache: Dictionary = {}

## Recomputed per board in _rebuild_grid(); see _cell_size_for().
var _cell_size: float = 48.0

var _elapsed_seconds: float = 0.0
var _result_saved: bool = false

var _life_icons: Array = [] # Array[Control] (CenterContainer wrappers)
var _timer_label: Label
var _mistakes_label: Label
var _found_label: Label
var _board_grid: GridContainer
var _hint_button: Button
var _restart_button: Button
var _new_puzzle_button: Button
var _overlay: Control
var _overlay_piece: TextureRect
var _overlay_title: Label
var _overlay_stats: Label
var _overlay_buttons: HBoxContainer
var _settings_overlay: Control
var _difficulty_picker: GridContainer
var _difficulty_label: Label
var _daily_badge: Control

func _ready() -> void:
	_build_chrome()
	if GameData.pending_daily:
		# One-shot handoff from the menu's Today button - cleared so that
		# Restart, Menu-and-back, or a relaunch don't silently stay on it.
		GameData.pending_daily = false
		new_daily_puzzle()
	else:
		new_puzzle(GameData.pending_size)

func _process(delta: float) -> void:
	if is_solved or is_game_over or _is_paused():
		return
	_elapsed_seconds += delta
	_timer_label.text = AppTheme.format_time(_elapsed_seconds)

func _build_chrome() -> void:
	# The game screen's own backdrop - distinct from the one every other
	# screen uses, see AppTheme.art_background().
	add_child(AppTheme.art_background(AppTheme.ART_BACK_GAME))

	var safe_area := AppTheme.safe_area_root()
	add_child(safe_area)

	var padded := MarginContainer.new()
	padded.set_anchors_preset(Control.PRESET_FULL_RECT)
	padded.add_theme_constant_override("margin_left", SCREEN_MARGIN)
	padded.add_theme_constant_override("margin_right", SCREEN_MARGIN)
	padded.add_theme_constant_override("margin_bottom", SCREEN_MARGIN)
	# Measured from the top of the *screen*, not the top of the safe area: the
	# top row below is positioned in absolute screen space, so subtracting the
	# notch inset here is what keeps the gap under it the same on a notched
	# device as on one without. Never smaller than SPACING_MD, in case a device
	# ever reports an inset deeper than the row itself.
	padded.add_theme_constant_override(
		"margin_top",
		maxi(AppTheme.SPACING_MD, int(CONTENT_TOP) - safe_area.current_offsets[1])
	)
	safe_area.add_child(padded)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	padded.add_child(root)

	_build_top_row()

	# Lives live on the stats row (with timer/mistakes), not the top bar. The
	# row sits on open sky, so it gets a pill behind it - bare labels there
	# wash out against the backdrop and its capybara silhouette.
	var stats_pill := AppTheme.pill(AppTheme.SURFACE, 18, AppTheme.SPACING_MD, AppTheme.SPACING_SM)
	root.add_child(stats_pill)

	var stats_row := HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	# Tighter than SPACING_MD: with the found counter on it the row carries
	# five items, and at the wider gap the daily board (which also shows the
	# Today badge) pushed the lives off the right edge of the pill.
	stats_row.add_theme_constant_override("separation", AppTheme.SPACING_SM)
	stats_pill.add_child(stats_row)

	# Only shown on the daily board, where "which puzzle is this" is the one
	# thing the player can't tell from the grid itself.
	_daily_badge = AppTheme.heading("Today", 18, AppTheme.ACCENT)
	_daily_badge.visible = false
	stats_row.add_child(_daily_badge)

	_timer_label = AppTheme.heading("0:00", 18, AppTheme.TEXT)
	stats_row.add_child(_timer_label)

	# How many capybaras are placed out of how many the board needs. The
	# target is just the board size (one per row), and it's the one number a
	# new player can't read off the grid itself - "how many am I looking for"
	# was otherwise only inferable from the rules.
	var found_row := HBoxContainer.new()
	found_row.add_theme_constant_override("separation", 4)
	stats_row.add_child(found_row)
	found_row.add_child(AppTheme.art_piece_rect(AppTheme.ART_CAT_PIECE, COUNTER_ICON_SIZE))
	_found_label = AppTheme.heading("", 18, AppTheme.TEXT)
	found_row.add_child(_found_label)

	_mistakes_label = AppTheme.heading("", 18, AppTheme.TEXT)
	stats_row.add_child(_mistakes_label)

	var lives_row := HBoxContainer.new()
	lives_row.add_theme_constant_override("separation", 2)
	stats_row.add_child(lives_row)
	for i in GameData.STARTING_LIVES:
		var life_icon := _build_life_icon()
		lives_row.add_child(life_icon.wrapper)
		_life_icons.append(life_icon)

	var grid_wrap := CenterContainer.new()
	grid_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(grid_wrap)
	var grid_card := AppTheme.card(AppTheme.SURFACE, 20)
	grid_wrap.add_child(grid_card)
	_board_grid = GridContainer.new()
	_board_grid.add_theme_constant_override("h_separation", CELL_SEPARATION)
	_board_grid.add_theme_constant_override("v_separation", CELL_SEPARATION)
	grid_card.add_child(_board_grid)

	# Restart isn't here any more - it moved into the pause card alongside the
	# difficulty picker, which leaves the two things you reach for mid-puzzle
	# (a hint, a fresh board) on their own instead of three-abreast.
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	root.add_child(button_row)
	_hint_button = AppTheme.secondary_button("💡 Hint", 16)
	_hint_button.pressed.connect(request_hint)
	button_row.add_child(_hint_button)
	_new_puzzle_button = AppTheme.primary_button("New Puzzle", 16)
	_new_puzzle_button.pressed.connect(func() -> void: new_puzzle(current_size))
	button_row.add_child(_new_puzzle_button)

	root.add_child(AppTheme.ad_placeholder())

	_build_overlay()
	add_child(_overlay)

	_build_settings_overlay()
	add_child(_settings_overlay)

## Menu button and settings glyph, both centred on AppTheme.TOP_ROW_CENTER_Y so
## they sit exactly where the main menu's own top row does. Added straight to
## the screen rather than into the safe-area content, for the reason spelled
## out on CONTENT_TOP; the row is well clear of the deepest notch inset either
## way, so nothing lands under it.
func _build_top_row() -> void:
	var back_button := AppTheme.ghost_button("←  Menu", 16)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)
	back_button.reset_size()
	back_button.position = Vector2(SCREEN_MARGIN, AppTheme.TOP_ROW_CENTER_Y - AppTheme.TOP_ROW_HEIGHT / 2.0)

	# Opens the pause overlay rather than navigating to res://ui/settings.tscn
	# like the menu's copy of this glyph does: that screen's own Back goes to
	# the main menu, so from mid-game it would be a one-way trip that quietly
	# throws the run away.
	var settings_button := AppTheme.art_tap_button(AppTheme.ART_SETTINGS, AppTheme.REGION_SETTINGS)
	settings_button.pressed.connect(_on_settings_pressed)
	add_child(settings_button)

func _build_overlay() -> void:
	_overlay = CenterContainer.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false

	var scrim := ColorRect.new()
	scrim.color = AppTheme.SCRIM
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

	# The out-of-lives card leads with the board's own capybara, drained of
	# colour, instead of the 😿 it used to - the game hasn't had cats in it
	# since the art landed, and the piece the player was placing all run reads
	# as "your capybara is done" far more directly than a borrowed emoji.
	# Hidden on a win, where the title carries it.
	# Built here rather than through AppTheme.art_piece_rect(): that wraps the
	# texture in a CenterContainer, and a CanvasItem's material applies only to
	# the node it's set on - children don't inherit it, so the shader has to go
	# on the TextureRect itself.
	_overlay_piece = TextureRect.new()
	_overlay_piece.texture = load(AppTheme.ART_CAT_PIECE)
	_overlay_piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay_piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_overlay_piece.custom_minimum_size = GAME_OVER_PIECE_SIZE
	_overlay_piece.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_overlay_piece.material = AppTheme.grayscale_material()
	_overlay_piece.modulate = Color(1, 1, 1, 0.8)
	column.add_child(_overlay_piece)

	_overlay_title = AppTheme.heading("", 28, AppTheme.TEXT)
	column.add_child(_overlay_title)

	_overlay_stats = AppTheme.body_label("", 16)
	column.add_child(_overlay_stats)

	_overlay_buttons = HBoxContainer.new()
	_overlay_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_overlay_buttons.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	column.add_child(_overlay_buttons)

## The in-game settings/pause card behind the top bar's settings glyph. Carries
## the audio/haptics controls from res://ui/settings.tscn, plus the two things
## that only make sense with a run in progress: the difficulty picker (this is
## where the old standalone level-select screen's job lives now) and Restart.
## Reset All Progress deliberately isn't repeated here - wiping the leaderboard
## is not something to offer one tap away from a live game.
func _build_settings_overlay() -> void:
	_settings_overlay = Control.new()
	_settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.visible = false

	var scrim := ColorRect.new()
	scrim.color = AppTheme.SCRIM
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_overlay.add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.add_child(center)

	var card := AppTheme.card(AppTheme.SURFACE, 28)
	card.custom_minimum_size = Vector2(300, 0)
	center.add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	card.add_child(column)

	column.add_child(AppTheme.heading("⚙  Paused", 26, AppTheme.TEXT))

	_difficulty_label = AppTheme.body_label("Difficulty", 15, AppTheme.TEXT_MUTED)
	_difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(_difficulty_label)

	_difficulty_picker = AppTheme.difficulty_picker(current_size, _on_difficulty_picked)
	column.add_child(_difficulty_picker)

	column.add_child(_build_volume_row("🎵  Music", Settings.music_volume, func(value: float) -> void:
		Settings.set_music_volume(value)))
	column.add_child(_build_volume_row("🔊  SFX", Settings.sfx_volume, func(value: float) -> void:
		Settings.set_sfx_volume(value)
		Audio.play_ui_tap()))

	var haptics_row := HBoxContainer.new()
	haptics_row.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	var haptics_label := AppTheme.body_label("📳  Haptics", 16, AppTheme.TEXT)
	haptics_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	haptics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	haptics_row.add_child(haptics_label)
	var haptics_toggle := CheckButton.new()
	haptics_toggle.button_pressed = Settings.haptics_enabled
	haptics_toggle.toggled.connect(func(pressed: bool) -> void:
		Settings.set_haptics_enabled(pressed)
		if pressed:
			Audio.vibrate_if_enabled(20))
	haptics_row.add_child(haptics_toggle)
	column.add_child(haptics_row)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", AppTheme.SPACING_MD)
	column.add_child(actions)

	_restart_button = AppTheme.ghost_button("↺  Restart", 16)
	_restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_restart_button.pressed.connect(func() -> void:
		_close_settings_overlay()
		_on_restart_pressed())
	actions.add_child(_restart_button)

	var resume_button := AppTheme.primary_button("Resume", 18)
	resume_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume_button.pressed.connect(_hide_settings_overlay)
	actions.add_child(resume_button)

## Switching tier mid-run abandons the current board for a fresh one at the new
## size, and remembers the choice - the same puzzle can't be rescaled, and
## leaving the player on the old board after they picked a new difficulty would
## just look broken.
func _on_difficulty_picked(size: int) -> void:
	Audio.play_ui_tap()
	GameData.set_pending_size(size)
	_close_settings_overlay()
	new_puzzle(size)

func _build_volume_row(label_text: String, initial_value: float, on_changed: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", AppTheme.SPACING_SM)

	var label := AppTheme.body_label(label_text, 16, AppTheme.TEXT)
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

## True while the game is showing the pause card - the run's clock stops, so
## fiddling with the volume mid-puzzle can't cost the player score.
func _is_paused() -> bool:
	return _settings_overlay != null and _settings_overlay.visible

func _on_settings_pressed() -> void:
	Audio.play_ui_tap()
	_reset_input_state()
	_settings_overlay.visible = true

## Resume: the only path that closes the card as an end in itself, so it's the
## one that gets the tap sound. Restart and the difficulty chips close it as a
## side effect of doing something else and use _close_settings_overlay(), which
## keeps them from double-beeping over their own sound.
func _hide_settings_overlay() -> void:
	Audio.play_ui_tap()
	_close_settings_overlay()

func _close_settings_overlay() -> void:
	if _settings_overlay != null:
		_settings_overlay.visible = false

## Today's puzzle: same board for everyone, because the seed is the date rather
## than anything a server handed out (GameData.daily_seed). Anything that would
## deal a *different* board - New Puzzle, the difficulty chips - is hidden for
## the run, since the whole point is that there's one of these a day.
func new_daily_puzzle() -> void:
	is_daily = true
	var rng := RandomNumberGenerator.new()
	rng.seed = GameData.daily_seed()
	new_puzzle(GameData.DAILY_SIZE, rng)

func new_puzzle(size: int, rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		is_daily = false
	var puzzle := PuzzleGenerator.generate(size, 10000, rng)
	current_size = size
	board = Board.new(size, puzzle.regions)
	solution = puzzle.solution
	marked_cells.clear()
	is_solved = false
	is_game_over = false
	mistakes = 0
	_elapsed_seconds = 0.0
	_result_saved = false
	_reset_input_state()
	_rebuild_grid()
	_refresh_all_cells()
	_refresh_lives()
	_refresh_mistakes_label()
	_refresh_found_counter()
	_hide_overlay()
	_hint_button.disabled = false
	if _difficulty_picker != null:
		AppTheme.refresh_difficulty_picker(_difficulty_picker, current_size)
	_refresh_daily_chrome()

## Shows/hides the parts of the screen that only make sense in one mode.
func _refresh_daily_chrome() -> void:
	_new_puzzle_button.visible = not is_daily
	_daily_badge.visible = is_daily
	_difficulty_picker.visible = not is_daily
	_difficulty_label.visible = not is_daily

func _reset_input_state() -> void:
	_last_tap_cell = INVALID_CELL
	_last_tap_msec = -1000000
	_drag_active = false
	_drag_erasing = false
	_drag_visited.clear()
	_drag_moved = false

## The widest a cell can be and still leave the whole grid inside the screen.
## Kept even, because the piece inside it is centred by a CenterContainer that
## lays its child out at integer pixels - an odd cell can't have an evenly
## split remainder, and the art ends up half a pixel off (see AppTheme
## .art_piece_rect). Same reason the piece itself is rounded down to even.
func _cell_size_for(size: int) -> float:
	var usable := get_viewport_rect().size.x - 2.0 * SCREEN_MARGIN - 2.0 * CARD_PADDING
	var fitted := (usable - (size - 1) * CELL_SEPARATION) / size
	return float(_floor_even(minf(CELL_MAX_SIZE, fitted)))

static func _floor_even(value: float) -> int:
	var whole := int(value)
	return whole - (whole % 2)

func _rebuild_grid() -> void:
	for child in _board_grid.get_children():
		child.queue_free()
	_cell_buttons.clear()
	_cell_cats.clear()
	_cell_marks.clear()
	_style_cache.clear()
	_cell_size = _cell_size_for(current_size)
	var piece_size := Vector2.ONE * _floor_even(_cell_size * PIECE_SCALE)
	_board_grid.columns = current_size
	for row in current_size:
		for col in current_size:
			var position := Vector2i(row, col)
			var button := Button.new()
			button.custom_minimum_size = Vector2(_cell_size, _cell_size)
			button.focus_mode = Control.FOCUS_NONE
			button.gui_input.connect(_on_cell_gui_input.bind(position))
			_board_grid.add_child(button)
			_cell_buttons[position] = button

			# Cat glyph and X mark are separate overlay nodes (not the
			# button's own .text) so a placement can be pop-animated without
			# scaling the tile's background/border along with it.
			var cat_piece := AppTheme.art_piece_rect(AppTheme.ART_CAT_PIECE, piece_size)
			cat_piece.visible = false
			button.add_child(cat_piece)
			_cell_cats[position] = cat_piece

			var mark := Control.new()
			mark.set_script(load("res://ui/x_mark.gd"))
			mark.set_anchors_preset(Control.PRESET_FULL_RECT)
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.visible = false
			button.add_child(mark)
			_cell_marks[position] = mark

## Cell input. Godot keeps routing motion and the release to whichever control
## received the press, so `position` is only trustworthy for the press itself -
## a drag reports the cell under the finger via hit-testing instead.
func _on_cell_gui_input(event: InputEvent, position: Vector2i) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_press(position, event.global_position)
		else:
			_drag_active = false
	elif event is InputEventMouseMotion and _drag_active:
		_continue_drag(event.global_position)

func _begin_press(cell: Vector2i, global_point: Vector2) -> void:
	if is_solved or is_game_over:
		return

	var now := Time.get_ticks_msec()
	if cell == _last_tap_cell and now - _last_tap_msec <= int(DOUBLE_TAP_SECONDS * 1000.0):
		# Second tap on the same cell - upgrade the X it just received into a
		# cat. Disarmed immediately so a third tap starts a fresh pair rather
		# than re-triggering off the same timestamp.
		_last_tap_cell = INVALID_CELL
		_drag_active = false
		_handle_double_tap(cell)
		return

	# Act on the first tap right away. The previous build deferred every single
	# tap behind a 0.18s timer purely to see whether a second one was coming,
	# which made marking an X feel late on every tap. Marking now and letting a
	# genuine second tap replace the X with a cat costs nothing and reads as an
	# upgrade rather than a correction.
	var placed_mark := _handle_single_tap(cell)
	_last_tap_cell = cell
	_last_tap_msec = now

	_drag_active = true
	# A swipe continues whatever the opening tap did, so this is taken from the
	# tap's actual outcome rather than from the cell's prior state: a tap that
	# lifted a capybara off the board is clearing, not marking, and dragging on
	# from it should keep clearing.
	_drag_erasing = not placed_mark
	_drag_visited = {cell: true}
	_drag_press_global = global_point
	_drag_moved = false

func _continue_drag(global_point: Vector2) -> void:
	if is_solved or is_game_over:
		_drag_active = false
		return

	if not _drag_moved and global_point.distance_to(_drag_press_global) >= DRAG_SLOP_PIXELS:
		_drag_moved = true
		# Committed to a swipe: don't let the press that started it pair up
		# with the player's next tap into an accidental double-tap.
		_last_tap_cell = INVALID_CELL

	var cell := _cell_at_global(global_point)
	if cell == INVALID_CELL or _drag_visited.has(cell):
		return
	_drag_visited[cell] = true
	_paint_cell(cell)

## Applies the drag's operation to one newly-entered cell.
func _paint_cell(cell: Vector2i) -> void:
	# A swipe never disturbs a placed cat: dragging across the board to clear
	# space shouldn't be able to undo deliberate work. Only a tap removes one.
	if board.has_cat(cell):
		return
	if _drag_erasing:
		if not marked_cells.has(cell):
			return
		marked_cells.erase(cell)
	else:
		if marked_cells.has(cell):
			return
		marked_cells[cell] = true
	Audio.play_mark()
	_refresh_mark_visual(cell)
	if not _drag_erasing:
		_pop_animate(_cell_marks[cell])

func _cell_at_global(global_point: Vector2) -> Vector2i:
	for cell in _cell_buttons:
		var button: Button = _cell_buttons[cell]
		if button.get_global_rect().has_point(global_point):
			return cell
	return INVALID_CELL

## Pops a newly-placed cat/mark in from nothing - only called for an actual
## new placement, not for removals or unrelated refreshes, so already-placed
## glyphs don't keep re-animating every time some other cell changes.
func _pop_animate(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(0.2, 0.2)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.2)

## Single tap: toggle an X mark. Tapping a cell that already holds a capybara
## clears it outright and leaves the cell *empty* - it used to drop an X in its
## place on the theory that removing a cat means "decided this isn't one", but
## in the hand that reads as the tap doing the wrong thing: you asked to take
## the piece off and got a mark you then have to tap twice more to be rid of.
## Tap again if you actually want the X.
## Returns true when the tap left a mark behind (see _begin_press).
func _handle_single_tap(position: Vector2i) -> bool:
	if is_solved or is_game_over:
		return false
	var placed_mark := false
	var removed_cat := false
	if board.has_cat(position):
		board.remove_cat(position)
		removed_cat = true
	elif marked_cells.has(position):
		marked_cells.erase(position)
	else:
		marked_cells[position] = true
		placed_mark = true
	Audio.play_mark()
	# A mark changes neither the win condition nor any other cell's conflict
	# state, so it repaints exactly one cell. Only removing a cat can change
	# what the rest of the board looks like, and only that needs the full pass.
	if removed_cat:
		_on_board_changed()
	else:
		_refresh_mark_visual(position)
	if placed_mark:
		_pop_animate(_cell_marks[position])
	return placed_mark

## Double tap: toggle a cat directly, clearing any mark on the way in. A
## placement that conflicts with another cat (same row/column/region, or
## touching) costs one of the three lives - removing a cat never does.
func _handle_double_tap(position: Vector2i) -> void:
	if is_solved or is_game_over:
		return
	var placed_cat := false
	if board.has_cat(position):
		board.remove_cat(position)
		Audio.play_mark()
	else:
		marked_cells.erase(position)
		board.place_cat(position)
		placed_cat = true
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
	if placed_cat:
		_pop_animate(_cell_cats[position])
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
	_pop_animate(_cell_cats[position])

func _lives_remaining() -> int:
	return maxi(0, GameData.STARTING_LIVES - mistakes)

func _on_board_changed() -> void:
	is_solved = WinConditionChecker.is_solved(board)
	_refresh_all_cells()
	_refresh_found_counter()
	if is_solved:
		_trigger_win()

func _trigger_win() -> void:
	Audio.play_win()
	Audio.vibrate_if_enabled(40)
	_hint_button.disabled = true
	var score := _compute_score()
	_save_result(score, true)
	var stats := "Score %d   •   Time %s   •   %d mistake%s" % [
		score, AppTheme.format_time(_elapsed_seconds), mistakes, "" if mistakes == 1 else "s"
	]
	if is_daily:
		GameData.record_daily_win()
		stats += "\n%d day streak" % GameData.daily_streak()
	_show_overlay("🎉 Solved!", stats, true)

func _trigger_game_over() -> void:
	is_game_over = true
	Audio.play_game_over()
	Audio.vibrate_if_enabled(60)
	_hint_button.disabled = true
	_save_result(0, false)
	_show_overlay(
		"Out of Lives",
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
	_overlay_piece.visible = not won
	_overlay_title.text = title
	_overlay_title.add_theme_color_override("font_color", AppTheme.SUCCESS if won else AppTheme.DANGER)
	_overlay_stats.text = stats
	for child in _overlay_buttons.get_children():
		child.queue_free()

	# After a solved daily there's no second daily to deal, so the forward
	# action drops the player into free play at their own tier instead.
	var retry_button: Button
	if not won:
		retry_button = AppTheme.primary_button("Retry", 16)
		retry_button.pressed.connect(_on_restart_pressed)
	elif is_daily:
		retry_button = AppTheme.primary_button("Keep Playing", 16)
		retry_button.pressed.connect(func() -> void: new_puzzle(GameData.pending_size))
	else:
		retry_button = AppTheme.primary_button("New Puzzle", 16)
		retry_button.pressed.connect(func() -> void: new_puzzle(current_size))
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
	_reset_input_state()
	_refresh_all_cells()
	_refresh_lives()
	_refresh_mistakes_label()
	_refresh_found_counter()
	_hide_overlay()
	_hint_button.disabled = false

func _on_back_pressed() -> void:
	Audio.play_ui_tap()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

## Both textures are pre-built and swapped by visibility rather than loaded
## on demand, matching the cat-glyph/X-mark pattern elsewhere on this screen.
func _build_life_icon() -> Dictionary:
	var wrapper := CenterContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var full := AppTheme.art_piece_rect(AppTheme.ART_LIFE_ICON, LIFE_ICON_SIZE)
	wrapper.add_child(full)
	var used := AppTheme.art_piece_rect(AppTheme.ART_LIFE_ICON_USED, LIFE_ICON_SIZE)
	used.visible = false
	wrapper.add_child(used)

	return {"wrapper": wrapper, "full": full, "used": used}

func _refresh_lives() -> void:
	var remaining := _lives_remaining()
	for i in _life_icons.size():
		var life_icon: Dictionary = _life_icons[i]
		var has_life: bool = i < remaining
		life_icon.full.visible = has_life
		life_icon.used.visible = not has_life

func _refresh_mistakes_label() -> void:
	_mistakes_label.text = "Mistakes: %d/%d" % [mistakes, GameData.STARTING_LIVES]

## Placed-vs-needed capybaras. Read off the board rather than tracked in a
## counter of our own, so it can't drift out of sync with what's on the grid.
func _refresh_found_counter() -> void:
	_found_label.text = "%d/%d" % [board.cat_positions().size(), current_size]

func _refresh_all_cells() -> void:
	for position in _cell_buttons:
		_refresh_cell(position)

func _refresh_cell(position: Vector2i) -> void:
	var button: Button = _cell_buttons.get(position)
	if button == null:
		return
	var conflicted := board.has_cat(position) and not MoveValidator.is_legal(position, board)
	var style := _cell_style(board.region_id(position), conflicted)
	if button.get_theme_stylebox("normal") != style:
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_stylebox_override("focus", style)
	_refresh_mark_visual(position)

## Updates only what's drawn *on* a cell - cheap enough to call per cell while
## a swipe is in flight.
func _refresh_mark_visual(position: Vector2i) -> void:
	var cat_piece: Control = _cell_cats.get(position)
	var mark: Control = _cell_marks.get(position)
	if cat_piece == null or mark == null:
		return
	if board.has_cat(position):
		cat_piece.visible = true
		mark.visible = false
	elif marked_cells.has(position):
		cat_piece.visible = false
		mark.visible = true
		mark.queue_redraw()
	else:
		cat_piece.visible = false
		mark.visible = false

func _cell_style(region: int, conflicted: bool) -> StyleBoxFlat:
	if not _style_cache.has(region):
		var color: Color = REGION_COLORS[region % REGION_COLORS.size()]
		_style_cache[region] = [_make_cell_style(color, false), _make_cell_style(color, true)]
	return _style_cache[region][1 if conflicted else 0]

func _make_cell_style(color: Color, conflicted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# A conflicting cat is flagged on the tile, not on the piece: the piece is
	# an image, so there's no font_color to tint (see the project notes). A red border
	# alone stopped being enough once the fills came from the art's palette -
	# several of them are warm reds and pinks, and red-on-red vanishes - so the
	# fill shifts toward DANGER *and* the border goes near-black, which reads
	# against all ten.
	style.bg_color = color.lerp(AppTheme.DANGER, 0.55) if conflicted else color
	style.border_color = AppTheme.SOIL_DEEP.darkened(0.35) if conflicted else Color(AppTheme.TEXT, 0.3)
	style.set_border_width_all(4 if conflicted else 1)
	style.set_corner_radius_all(8)
	return style
