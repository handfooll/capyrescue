@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type(
		"GodotxSafeArea",
		"Control",
		preload("godotx_safe_area.gd"),
		preload("godotx_safe_area.svg"),
	)

func _exit_tree() -> void:
	remove_custom_type("GodotxSafeArea")
