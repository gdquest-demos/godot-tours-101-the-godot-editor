@tool
extends "message_drawer.gd"

signal accept_button_pressed

@export var accept_button_text: String = "OK":
	set = set_accept_button_text

@onready var _accept_button: Button = %AcceptButton


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_accept_button = %AcceptButton


func _ready() -> void:
	super()
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_accept_button.pressed.connect(accept_button_pressed.emit)


# Properties.

func set_accept_button_text(value: String) -> void:
	if accept_button_text == value:
		return

	accept_button_text = value
	_accept_button.text = accept_button_text
