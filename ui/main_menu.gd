extends Control

## App entry point: title, and navigation into the rest of the app.
##
## Layout here is pixel-positioned against the artist's source canvas rather
## than flowed through containers like every other screen - the art in
## res://art/menu/ was hand-composed on a single 1170x2532 canvas (this
## project's 390x844 point canvas at the 3x/@3x density convention, see
## the project notes), and each element's on-screen position/size is read directly
## off that canvas via its alpha bounding box, so what she drew is what
## renders. The cropping/positioning helpers and AppTheme.ART_SCALE live in
## ui/theme.gd because the game screen draws from this same art set too.

const ART_DIR := "res://art/menu/"

# Alpha-bounding-box regions (px, in the original 1170x2532 canvas) for the
# elements only this screen uses; the ones shared with the game screen
# (capy, settings) are AppTheme.REGION_* instead.
const REGION_LOGO := Rect2i(282, 396, 612, 150)
const REGION_PLAY := Rect2i(266, 1062, 654, 436)
const REGION_LEADERBOARD := Rect2i(656, 1598, 244, 286)
const REGION_DAILY := Rect2i(288, 1578, 244, 326)
const REGION_STREAK := Rect2i(226, 1988, 714, 142)
## The badge that caps the streak track, where the running count goes.
const REGION_STREAK_BADGE := Rect2i(799, 1987, 143, 143)
## Right-hand edge (source px) of each step of that track - the four day
## squares in turn, then the badge. The track fills left-to-right up to the
## step matching the current streak, so the meter is one cropped copy of the
## art over a drained one rather than five separately-placed pips.
const STREAK_STEP_ENDS: Array[int] = [307, 451, 594, 737, 942]

func _ready() -> void:
	add_child(AppTheme.art_background())

	# Not wrapped in AppTheme.safe_area_root() like every other screen - her
	# art is positioned against the full 390x844 canvas with its own top
	# margin already baked in (132pt before the logo), so adding the safe
	# area's own device-notch offset on top of that pushed everything down
	# twice and threw off her exact layout.
	var logo := AppTheme.art_rect(ART_DIR + "logo.png", REGION_LOGO)
	add_child(logo)

	var capy := AppTheme.art_rect(AppTheme.ART_CAPY, AppTheme.REGION_CAPY)
	add_child(capy)

	var play_button := AppTheme.art_button(ART_DIR + "play.png", REGION_PLAY)
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)

	# Both top-row glyphs are drawn small (~29x23pt and ~24x24pt) - too small a
	# tap target on their own, so art_tap_button grows the hit area around each
	# glyph's visual center rather than resizing the art.
	var settings_button := AppTheme.art_tap_button(AppTheme.ART_SETTINGS, AppTheme.REGION_SETTINGS)
	settings_button.pressed.connect(_go_to.bind("res://ui/settings.tscn"))
	add_child(settings_button)

	add_child(_build_profile_badge())

	# Today's puzzle - the same board for everyone on the same date, seeded off
	# the date itself rather than handed out by a server (GameData.daily_seed),
	# so it needs none of the backend that hasn't been chosen yet.
	var daily_button := AppTheme.art_button(ART_DIR + "daily.png", REGION_DAILY)
	daily_button.pressed.connect(_on_daily_pressed)
	add_child(daily_button)
	if GameData.is_daily_done_today():
		# Still playable - replaying it just can't move the streak again.
		daily_button.modulate = Color(1, 1, 1, 0.6)

	var leaderboard_button := AppTheme.art_button(ART_DIR + "champ_board.png", REGION_LEADERBOARD)
	leaderboard_button.pressed.connect(_go_to.bind("res://ui/leaderboard.tscn"))
	add_child(leaderboard_button)

	_add_streak_meter()

## The account badge, filling the slot the artist marked for it top-left -
## opposite the settings glyph, at AppTheme.REGION_PROFILE. icon_raw.png only
## draws a gray placeholder mark in that slot, so the slot gets a rounded card
## with the game's own capybara on it.
##
## The capybara is `cat_piece.png` (already cropped, transparent) drawn over a
## stylebox, *not* res://icon.png masked to shape: the icon is a hard-edged
## square, and rounding it needs `clip_children`, which turns the node into a
## canvas group - a construct worth avoiding on a screen this simple when the
## renderer on device (Forward Mobile) isn't the one being looked at here.
## Same picture, nothing exotic to go wrong on hardware.
##
## Drawn but not tappable, same as daily/streak below - there are no accounts
## to open yet, and a button that does nothing is worse than a plain image.
func _build_profile_badge() -> Control:
	var frame := Panel.new()
	frame.position = Vector2(AppTheme.REGION_PROFILE.position) / AppTheme.ART_SCALE
	frame.size = Vector2(AppTheme.REGION_PROFILE.size) / AppTheme.ART_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = AppTheme.SURFACE
	style.set_corner_radius_all(8)
	style.border_color = Color(AppTheme.TEXT, 0.25)
	style.set_border_width_all(1)
	frame.add_theme_stylebox_override("panel", style)

	var piece := AppTheme.art_piece_rect(AppTheme.ART_CAT_PIECE, frame.size * 0.72)
	frame.add_child(piece)
	return frame

## The daily-streak track along the bottom. Drawn as the full track drained of
## colour, with a left-to-right crop of the same art laid back over it in full
## colour up to however many days are running - so the meter can never drift
## out of alignment with the artwork, and the count lands on the badge the
## artist put at the end of it.
func _add_streak_meter() -> void:
	var empty := AppTheme.art_rect(ART_DIR + "streak.png", REGION_STREAK)
	empty.material = AppTheme.grayscale_material()
	empty.modulate = Color(1, 1, 1, 0.5)
	add_child(empty)

	var streak := GameData.daily_streak()
	if streak > 0:
		var end_px: int = STREAK_STEP_ENDS[mini(streak, STREAK_STEP_ENDS.size()) - 1]
		add_child(AppTheme.art_rect(ART_DIR + "streak.png", Rect2i(
			REGION_STREAK.position.x,
			REGION_STREAK.position.y,
			end_px - REGION_STREAK.position.x,
			REGION_STREAK.size.y
		)))

	var count := AppTheme.heading(str(streak), 22, AppTheme.ON_PRIMARY)
	count.position = Vector2(REGION_STREAK_BADGE.position) / AppTheme.ART_SCALE
	count.size = Vector2(REGION_STREAK_BADGE.size) / AppTheme.ART_SCALE
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count)

func _on_play_pressed() -> void:
	Audio.play_ui_tap()
	get_tree().change_scene_to_file("res://ui/main.tscn")

func _on_daily_pressed() -> void:
	Audio.play_ui_tap()
	GameData.pending_daily = true
	get_tree().change_scene_to_file("res://ui/main.tscn")

func _go_to(path: String) -> void:
	Audio.play_ui_tap()
	get_tree().change_scene_to_file(path)
