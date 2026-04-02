@tool
extends HBoxContainer

@onready var _gdquest_logo: TextureRect = %GDQuestLogo
@onready var _copyright_icon: TextureRect = %CopyrightIcon


func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	var editor_scale := EditorInterface.get_editor_scale()
	_gdquest_logo.custom_minimum_size *= editor_scale
	_copyright_icon.custom_minimum_size *= editor_scale
