@tool
extends Button

const Utils = preload("../utils.gd")


func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	theme = Utils.get_default_theme()
