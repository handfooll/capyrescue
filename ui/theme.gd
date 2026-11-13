class_name AppTheme
extends RefCounted

## Shared visual language for every screen. All UI in this project is built
## in code (see the project notes), so this is the single place that defines colors,
## rounded-panel/button styleboxes, and spacing - keeps every screen looking
## like one app instead of five separately-styled ones.
##
## No custom font is bundled for the game itself: the only .ttf files in this
## repo belong to the GUT testing addon (vendored for its own GUI, under its
## own license) and reaching into another addon's internal assets for our
## production UI would be fragile - an addon update could move or drop them.
## The default Godot font, leaned on harder via size/weight/color/spacing, is
## the more robust choice absent dedicated art assets.

## Palette. Every value below is sampled out of res://art/menu/ rather than
## picked independently, so the code-built parts of the UI read as the same
## painted world as the artist's screens instead of a second design system
## layered on top of them. The earlier palette (cream #fdf3e7 / coral #ff8c5a /
## teal #4fb8b0 / white cards) predated the art and clashed with it - most
## visibly the teal, which appears nowhere in the drawn set.
##
## Source pixels, for anything that needs re-deriving:
##   sky #4bb3e4, cloud #d6f4ff, grass #5c8f26, soil #b76f54 / #ac5345 / #843a1c
##   play sign #fba561 on #ae2e0e, streak card #f7c85a / #ffe5b2 / #ffb525
##   champ board #f1d073 on #ff4943, daily card #dbadc6 / #e47387
##   wordmark #ae4527 on #d6fbff
const SKY := Color("4bb3e4")
const SKY_LIGHT := Color("d6f4ff")
const GRASS := Color("5c8f26")
const SOIL := Color("b76f54")
const SOIL_DEEP := Color("843a1c")

const BG := SKY
const BG_ALT := Color("f1d073")
const SURFACE := Color("ffe5b2")
const PRIMARY := Color("fba561")
const PRIMARY_DARK := Color("e08343")
const SECONDARY := Color("6ec8ea")
const SECONDARY_DARK := Color("4bb3e4")
const TEXT := Color("6b3a22")
const TEXT_MUTED := Color("a5765c")
const DANGER := Color("d94a3f")
const DANGER_DARK := Color("b0322a")
const SUCCESS := GRASS
const WARNING := Color("ffb525")
## Headline/wordmark brown-red, straight off logo.png.
const ACCENT := Color("ae4527")

## The art draws its lettering as a dark, saturated version of whatever it
## sits on (dark red on the orange play sign, red on the yellow streak card)
## rather than as white knockout text, so buttons follow the same rule.
const ON_PRIMARY := Color("9c3a14")
const ON_SECONDARY := Color("134f6b")
const ON_DANGER := Color("fff3da")

## Warm rather than neutral black - a straight 0,0,0 scrim over the soil
## backdrop grays the whole scene out.
const SCRIM := Color(0.22, 0.11, 0.05, 0.45)

const SPACING_SM := 8
const SPACING_MD := 16
const SPACING_LG := 28

## Full-rect ColorRect meant as the first child of a screen root, giving it a
## solid background color (Control itself paints nothing).
static func make_background(color: Color = BG) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func panel_style(bg: Color = SURFACE, radius: int = 24, with_shadow: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(SPACING_MD)
	if with_shadow:
		style.shadow_color = Color(0, 0, 0, 0.12)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 4)
	return style

## Applies a rounded, drop-shadowed stylebox to a button's normal/hover/
## pressed/disabled states plus matching font color, so every button in the
## app shares the same shape language without repeating boilerplate.
static func style_button(button: Button, bg: Color = PRIMARY, bg_pressed: Color = PRIMARY_DARK, font_color: Color = SURFACE, radius: int = 18, font_size: int = 20) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_corner_radius_all(radius)
	normal.set_content_margin_all(SPACING_MD)
	normal.shadow_color = Color(0, 0, 0, 0.15)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 3)

	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.08)

	var pressed := normal.duplicate()
	pressed.bg_color = bg_pressed
	pressed.shadow_size = 2
	pressed.shadow_offset = Vector2(0, 1)

	var disabled := normal.duplicate()
	disabled.bg_color = bg.darkened(0.05)
	disabled.bg_color.a = 0.5
	disabled.shadow_size = 0

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color, 0.7))
	button.add_theme_font_size_override("font_size", font_size)
	button.custom_minimum_size.y = 52

static func primary_button(text: String, font_size: int = 20) -> Button:
	var button := Button.new()
	button.text = text
	style_button(button, PRIMARY, PRIMARY_DARK, ON_PRIMARY, 18, font_size)
	return button

static func secondary_button(text: String, font_size: int = 18) -> Button:
	var button := Button.new()
	button.text = text
	style_button(button, SECONDARY, SECONDARY_DARK, ON_SECONDARY, 16, font_size)
	return button

static func ghost_button(text: String, font_size: int = 16) -> Button:
	var button := Button.new()
	button.text = text
	style_button(button, BG_ALT, BG_ALT.darkened(0.08), TEXT, 14, font_size)
	return button

static func danger_button(text: String, font_size: int = 18) -> Button:
	var button := Button.new()
	button.text = text
	style_button(button, DANGER, DANGER_DARK, ON_DANGER, 16, font_size)
	return button

## A compact one-of-several picker button (difficulty tiers). Selected reads as
## a filled primary chip, unselected as a flat sand one, so the current choice
## is obvious without a separate checkmark or radio glyph.
static func chip_button(text: String, selected: bool, font_size: int = 15) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_chip_selected(button, selected, font_size)
	return button

static func set_chip_selected(button: Button, selected: bool, font_size: int = 15) -> void:
	if selected:
		style_button(button, PRIMARY, PRIMARY_DARK, ON_PRIMARY, 14, font_size)
	else:
		style_button(button, BG_ALT.lightened(0.12), BG_ALT, TEXT, 14, font_size)
	# style_button sizes for a full-width action button; a chip is shorter.
	button.custom_minimum_size.y = 40

## The difficulty tier picker, shared by the Settings screen and the in-game
## pause card so the same choice is offered in the same shape wherever it turns
## up. (It used to be a screen of its own, res://ui/level_select.tscn, that
## nothing navigated to.) Each chip carries its board size in metadata, so
## refresh_difficulty_picker() can restyle the row in place instead of
## rebuilding and re-parenting it.
static func difficulty_picker(selected_size: int, on_pick: Callable) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", SPACING_SM)
	grid.add_theme_constant_override("v_separation", SPACING_SM)
	for size in range(GameData.MIN_SIZE, GameData.MAX_SIZE + 1):
		var button := chip_button(
			"%s  %dx%d" % [GameData.difficulty_name(size), size, size],
			size == selected_size
		)
		button.set_meta("board_size", size)
		button.pressed.connect(on_pick.bind(size))
		grid.add_child(button)
	return grid

static func refresh_difficulty_picker(picker: GridContainer, selected_size: int) -> void:
	for child in picker.get_children():
		var button := child as Button
		if button == null:
			continue
		set_chip_selected(button, int(button.get_meta("board_size", -1)) == selected_size)

static func heading(text: String, size: int = 40, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

static func body_label(text: String, size: int = 18, color: Color = TEXT_MUTED) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

## A rounded card container (PanelContainer + stylebox) ready to hold content.
static func card(bg: Color = SURFACE, radius: int = 24) -> PanelContainer:
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel", panel_style(bg, radius))
	return container

## A card sized to hug its contents - for a strip of text that has to stay
## readable over the painted backdrop (the game screen's timer/lives row sits
## on open sky, where plain labels wash out) rather than over another card.
static func pill(bg: Color = SURFACE, radius: int = 18, padding_x: int = SPACING_MD, padding_y: int = SPACING_SM) -> PanelContainer:
	var container := card(bg, radius)
	var style := container.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_left = padding_x
	style.content_margin_right = padding_x
	style.content_margin_top = padding_y
	style.content_margin_bottom = padding_y
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return container

## Sliders default to a gray track and grabber, which reads as unstyled engine
## chrome next to everything else here.
static func style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(TEXT, 0.15)
	track.set_corner_radius_all(4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4

	var filled := track.duplicate() as StyleBoxFlat
	filled.bg_color = PRIMARY

	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)

static func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]

## Wraps a screen's real content so it can't land under a notch, rounded
## corner, or home indicator. Every screen adds one of these directly to
## itself (after the full-rect background, which should stay edge-to-edge)
## and parents its actual content root inside it instead of onto the screen
## directly. See addons/godotx_safe_area - GodotxSafeArea already fills the
## viewport and keeps its offsets synced to DisplayServer's safe area.
static func safe_area_root() -> GodotxSafeArea:
	return GodotxSafeArea.new()

## Reserved space for a banner ad - standard mobile banner height (50px),
## full width, clearly marked as a placeholder since no ad network is
## integrated yet (see the project notes "Backend (Future Phase)": don't build
## against a service until one's actually chosen). Add as the last child of
## a screen's content, inside its safe_area_root() wrapper, so it sits above
## the home indicator instead of under it.
static func ad_placeholder() -> Control:
	var box := AppTheme.card(BG_ALT, 12)
	box.custom_minimum_size.y = 50
	var style := box.get_theme_stylebox("panel") as StyleBoxFlat
	style.set_content_margin_all(0)
	style.border_color = TEXT_MUTED
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_size = 0

	var label := body_label("Ad space", 14, TEXT_MUTED)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(label)
	return box

## A screen's content root: padded_root(), but with its top edge placed so a
## top bar starting there lines up with the main menu's own top row (see
## TOP_ROW_CENTER_Y) on every device. `safe_area`'s top inset is subtracted
## because the target is an absolute position on screen - a notched device
## would otherwise add its inset on top of a margin that already accounts for
## the row, and the same Back button would sit at a different height on every
## screen. Its `current_offsets` are populated by the time it's added to a
## parent that's already in the tree.
static func screen_root(safe_area: GodotxSafeArea, margin: int = SPACING_LG) -> MarginContainer:
	var container := padded_root(margin)
	container.add_theme_constant_override(
		"margin_top",
		maxi(SPACING_MD, int(TOP_ROW_CENTER_Y - TOP_ROW_HEIGHT / 2.0) - safe_area.current_offsets[1])
	)
	return container

## A full-rect MarginContainer with consistent screen edge padding - every
## non-game screen roots its content in one of these so nothing touches the
## viewport edge.
static func padded_root(margin: int = SPACING_LG) -> MarginContainer:
	var container := MarginContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("margin_left", margin)
	container.add_theme_constant_override("margin_right", margin)
	container.add_theme_constant_override("margin_top", margin)
	container.add_theme_constant_override("margin_bottom", margin)
	return container

## --- Shared menu art --------------------------------------------------
##
## The art in res://art/menu/ was hand-composed on a single 1170x2532
## canvas (this project's 390x844 point canvas at 3x), so every element is
## cropped out of its source file by its alpha bounding box - recorded in
## source pixels below - and ART_SCALE converts those to point-space.
## These live here rather than in ui/main_menu.gd because the menu is no
## longer the only screen that draws from this art set.

const ART_BACK := "res://art/menu/back.png"
const ART_BACK_GAME := "res://art/menu/back_game.png"
const ART_CLOUDS := "res://art/menu/clouds.png"
const ART_CAPY := "res://art/menu/capy.png"
const ART_SETTINGS := "res://art/menu/settings.png"
## Unlike the rest of art/menu/, this one is already tightly cropped to its
## own bounds rather than a full 1170x2532 canvas - no atlas region needed.
const ART_CAT_PIECE := "res://art/menu/cat_piece.png"
const ART_LIFE_ICON := "res://art/menu/life_icon.png"
## An emptied-out orange peel - shown for a spent life instead of dimming
## the full orange.
const ART_LIFE_ICON_USED := "res://art/menu/life_icon_used.png"

const ART_SCALE := 3.0

const REGION_CAPY := Rect2i(200, 614, 800, 198)
const REGION_SETTINGS := Rect2i(894, 284, 86, 70)
## The account/profile slot, drawn top-left opposite the top-right settings
## glyph. art/menu/icon_raw.png only puts a gray placeholder mark in it, so
## ui/main_menu.gd fills the slot with res://icon.png instead - same capybara,
## already squared off for the app icon by tools/_gen_app_icon.gd.
const REGION_PROFILE := Rect2i(204, 281, 73, 73)

## Where the menu's top row (profile badge / settings glyph) is centred, in
## points - (284 + 70/2) / ART_SCALE, i.e. the vertical middle of
## REGION_SETTINGS. Every screen that wants a top bar lines up with this rather
## than with the device's safe-area inset, so the same controls don't jump
## between screens. See ui/main.gd.
const TOP_ROW_CENTER_Y := 106.33
## Height of a top-bar row - a ghost_button's minimum height, which is what
## every screen's Back/Menu button is.
const TOP_ROW_HEIGHT := 52.0

## A full-canvas layer (background/clouds): the source PNG is already
## exactly ART_SCALE times the design canvas, so it stretches to fill with
## no cropping.
static func art_layer(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load(path)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

## The painted sky/ground backdrop, as a drop-in replacement for
## make_background() - add it as a screen's first child, edge to edge,
## before its safe_area_root(). Pass ART_BACK_GAME for the game screen's
## distinct backdrop; every other screen uses the default ART_BACK.
static func art_background(back_path: String = ART_BACK) -> Control:
	var layers := Control.new()
	layers.set_anchors_preset(Control.PRESET_FULL_RECT)
	layers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layers.add_child(art_layer(back_path))
	layers.add_child(art_layer(ART_CLOUDS))
	return layers

## Crops `path`'s texture to `region_px` (in source-canvas pixels).
static func art_atlas(path: String, region_px: Rect2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path)
	atlas.region = Rect2(region_px)
	return atlas

static func art_rect(path: String, region_px: Rect2i) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = art_atlas(path, region_px)
	# expand_mode must be set BEFORE .size below - a TextureRect's minimum
	# size defaults to its texture's raw pixel size (here the 3x atlas
	# region), and Control.size setters silently clamp up to at least the
	# minimum size. Setting expand_mode afterward doesn't retroactively
	# shrink an already-clamped size back down.
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.position = Vector2(region_px.position) / ART_SCALE
	rect.size = Vector2(region_px.size) / ART_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func art_button(path: String, region_px: Rect2i) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = art_atlas(path, region_px)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.position = Vector2(region_px.position) / ART_SCALE
	button.size = Vector2(region_px.size) / ART_SCALE
	return button

## art_button(), with the hit area grown around the glyph's *visual centre* to
## at least `tap_size` (Apple HIG's 44x44pt floor) instead of scaling the art
## up to meet it - several drawn glyphs (the settings gear is ~29x23pt, the
## profile badge ~24x24pt) are far too small to tap reliably at their own size.
static func art_tap_button(path: String, region_px: Rect2i, tap_size: float = 44.0) -> TextureButton:
	var button := art_button(path, region_px)
	var center := button.position + button.size / 2.0
	button.size = Vector2(maxf(button.size.x, tap_size), maxf(button.size.y, tap_size))
	button.position = center - button.size / 2.0
	return button

## The same art as art_rect(), but sized for a flow container (VBox/HBox)
## instead of pixel-positioned: keeps the source aspect ratio at `height`
## points tall and paints nothing outside it.
static func art_flow_rect(path: String, region_px: Rect2i, height: float) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size.y = height
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rect := TextureRect.new()
	rect.texture = art_atlas(path, region_px)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(rect)
	return wrapper

## A pre-cropped (non-atlas) texture, centered and aspect-correct - e.g.
## ART_CAT_PIECE, ART_LIFE_ICON. With no `box_size`, it fills whatever rect
## the caller sizes its parent to (anchored full-rect) - use this when the
## piece should fill its parent completely. With `box_size`, it instead
## renders smaller than its parent at exactly that size, wrapped in a
## CenterContainer: a Control anchor preset (PRESET_CENTER) computes its
## offset from the parent's size at the moment it's called, which is wrong
## here since the rect isn't parented yet when this builds it - a real
## Container recomputes on every layout pass instead, so parenting order
## can't leave it stuck off-center.
static func art_piece_rect(path: String, box_size: Vector2 = Vector2.ZERO) -> Control:
	var rect := TextureRect.new()
	rect.texture = load(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if box_size == Vector2.ZERO:
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		return rect
	# Rounded to whole pixels: CenterContainer lays its child out at integer
	# positions, so a fractional box size can't actually be centred - a 40.32pt
	# piece inside a 48pt cell was placed at offset 3 with 4.68 left over on the
	# far side, which reads as the art sitting up and to the left of its tile.
	# Callers should still pass an even size against an even-sized parent to
	# land the halves exactly.
	rect.custom_minimum_size = box_size.round()
	var wrapper := CenterContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(rect)
	return wrapper

## The same art as art_button(), but sized for a flow container (VBox/HBox)
## instead of pixel-positioned. `tap_size` is the hit area, kept at or above
## Apple's 44x44pt minimum - the drawn glyph is centered inside it at its own
## aspect ratio rather than stretched up to fill.
static func art_flow_button(path: String, region_px: Rect2i, tap_size: float = 44.0) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = art_atlas(path, region_px)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(tap_size, tap_size)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return button

## Desaturates whatever CanvasItem it's assigned to - used for the drained
## capybara on the out-of-lives card. `modulate` can't do this: it multiplies,
## so a gray modulate only dims the brown fur instead of draining the colour
## out of it (the same class of problem as tinting a colour-emoji glyph, see
## the project notes). In a canvas_item shader COLOR already arrives as
## texture * modulate, so collapsing it to its luminance is the whole job.
const _GRAYSCALE_SHADER := """
shader_type canvas_item;
void fragment() {
	COLOR.rgb = vec3(dot(COLOR.rgb, vec3(0.299, 0.587, 0.114)));
}
"""

static func grayscale_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = _GRAYSCALE_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	return material
