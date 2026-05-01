@tool
extends "message_drawer.gd"

signal left_button_pressed
signal right_button_pressed

@export var left_button_text: String = "LEFT":
	set = set_left_button_text
@export var right_button_text: String = "RIGHT":
	set = set_right_button_text

@onready var _left_button: Button = %LeftButton
@onready var _right_button: Button = %RightButton


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_left_button = %LeftButton
		_right_button = %RightButton


func _ready() -> void:
	super()
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_left_button.pressed.connect(left_button_pressed.emit)
	_right_button.pressed.connect(right_button_pressed.emit)


# Properties.

func set_left_button_text(value: String) -> void:
	if left_button_text == value:
		return

	left_button_text = value
	_left_button.text = left_button_text


func set_right_button_text(value: String) -> void:
	if right_button_text == value:
		return

	right_button_text = value
	_right_button.text = right_button_text
