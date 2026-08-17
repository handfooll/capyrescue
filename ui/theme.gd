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

const BG := Color("fdf3e7")
const BG_ALT := Color("f7e6d0")
const SURFACE := Color("ffffff")
const PRIMARY := Color("ff8c5a")
const PRIMARY_DARK := Color("e8703c")
const SECONDARY := Color("4fb8b0")
const SECONDARY_DARK := Color("389a92")
const TEXT := Color("4a3428")
const TEXT_MUTED := Color("9c8a7c")
const DANGER := Color("e0574f")
const DANGER_DARK := Color("c8453e")
const SUCCESS := Color("4caf6e")
const WARNING := Color("f2b134")

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
	style_button(button, PRIMARY, PRIMARY_DARK, SURFACE, 18, font_size)
	return button

static func secondary_button(text: String, font_size: int = 18) -> Button:
	var button := Button.new()
	button.text = text
	style_button(button, SECONDARY, SECONDARY_DARK, SURFACE, 16, font_size)
	return button

static func ghost_button(text: String, font_size: int = 16) -> Button:
	var button := Button.new()
	button.text = text
	style_button(button, BG_ALT, BG_ALT.darkened(0.08), TEXT, 14, font_size)
	return button

static func danger_button(text: String, font_size: int = 18) -> Button:
	var button := Button.new()
	button.text = text
	style_button(button, DANGER, DANGER_DARK, SURFACE, 16, font_size)
	return button

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

static func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]

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
