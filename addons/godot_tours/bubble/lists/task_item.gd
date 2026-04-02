@tool
extends PanelContainer

signal status_changed

enum Status { NOT_DONE, DONE, ERROR }
const STATUS_COLORS: Array[Color] = [ Color("#567099"), Color("#4bff2e"), Color("#ff8a00") ]

@export var description: String = "":
	set = set_description
@export var error: String = "":
	set = set_error
@export_range(1, 99, 1, "or_greater") var repeat: int = 1:
	set = set_repeat

var _repeat_callable := Callable()
var _error_predicate := Callable()

var _current_status: Status = Status.NOT_DONE
var _current_repeat: int = 0

@onready var _checkbox_panel: Panel = %Checkbox
@onready var _checkbox_check_icon: TextureRect = %CheckIcon
@onready var _checkbox_error_icon: TextureRect = %ErrorIcon

@onready var _description_label: RichTextLabel = %DescriptionLabel
@onready var _repeat_label: Label = %RepeatLabel
@onready var _error_label: Label = %ErrorLabel


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_checkbox_panel = %Checkbox
		_checkbox_check_icon = %CheckIcon
		_checkbox_error_icon = %ErrorIcon

		_description_label = %DescriptionLabel
		_repeat_label = %RepeatLabel
		_error_label = %ErrorLabel


func _ready() -> void:
	_update_checkbox()

	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		set_process(false) # Disable processing when editing/designing the scene.
		return

	_checkbox_panel.custom_minimum_size *= EditorInterface.get_editor_scale()


func _process(_delta: float) -> void:
	if _repeat_callable.is_valid():
		_current_repeat = _repeat_callable.call(self)
	else:
		_current_repeat = 0

	var has_errors := false
	if _error_predicate.is_valid():
		has_errors = _error_predicate.call(self)

	if has_errors:
		set_current_status(Status.ERROR)
	else:
		set_current_status(Status.DONE if _current_repeat == repeat else Status.NOT_DONE)

	_update_repeat_label()


# Properties.

func set_description(value: String) -> void:
	if description == value:
		return

	description = value
	_description_label.text = description


func set_error(value: String) -> void:
	if error == value:
		return

	error = value
	_error_label.text = error
	_error_label.visible = not error.is_empty()


func set_repeat(value: int) -> void:
	if repeat == value:
		return

	repeat = max(1, value)

	_repeat_label.visible = repeat != 1
	_update_repeat_label()


func set_repeat_callable(callback: Callable) -> void:
	if not callback.is_valid():
		_repeat_callable = Callable()
		return

	_repeat_callable = callback


func set_error_predicate(callback: Callable) -> void:
	if not callback.is_valid():
		_error_predicate = Callable()
		return

	_error_predicate = callback


# Helpers.

func _update_checkbox() -> void:
	_checkbox_check_icon.visible = _current_status != Status.ERROR
	_checkbox_error_icon.visible = _current_status == Status.ERROR
	_checkbox_panel.self_modulate = STATUS_COLORS[_current_status]


func _update_repeat_label() -> void:
	if _current_status == Status.ERROR:
		_repeat_label.text = "? / %d" % [ repeat ]
	else:
		_repeat_label.text = "%d / %d" % [ _current_repeat, repeat ]


# Task management.

func set_current_status(value: Status) -> void:
	if value == _current_status:
		return

	_current_status = value

	_update_checkbox()
	status_changed.emit()


func is_done() -> bool:
	return _current_status == Status.DONE
