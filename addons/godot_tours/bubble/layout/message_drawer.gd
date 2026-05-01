@tool
extends PanelContainer

signal message_meta_clicked(data: Variant)

@export_multiline var message: String = "Message for [b]this action[/b].":
	set = set_message
@export_range(0.0, 100.0, 0.01, "or_greater") var maximum_message_height: float = 0.0:
	set = set_maximum_message_height

var _last_message_height: float = 0.0

@onready var _layout: VBoxContainer = %Layout
@onready var _message_container: MarginContainer = %MessageContainer
@onready var _message_label: RichTextLabel = %MessageLabel
@onready var _buttons_box: Control = %Buttons


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_message_label = %MessageLabel


func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_message_label.meta_clicked.connect(message_meta_clicked.emit)

	# Monitor RTL changes and update message height limit accordingly. We need to
	# rely on draw signals as well as finished, because finished doesn't mean the
	# final shaping has happened. But we must avoid infinite looping, so we store
	# last known message height and only update when on draw that differs.
	_message_label.finished.connect(_update_message_height, CONNECT_DEFERRED)
	_message_label.draw.connect(_check_message_height)
	_update_message_height()


# Properties.

func set_message(value: String) -> void:
	if message == value:
		return

	message = value
	_message_label.text = message


# Sizing.

func get_base_height() -> float:
	var base_height := _buttons_box.size.y
	base_height += _message_container.get_theme_constant("margin_top") + _message_container.get_theme_constant("margin_bottom")
	base_height += _layout.get_theme_constant("separation")

	var panel_style := get_theme_stylebox("panel")
	if panel_style:
		base_height += panel_style.get_minimum_size().y

	return base_height


func get_content_height() -> float:
	return _message_label.get_content_height()


func set_maximum_message_height(value: float) -> void:
	if maximum_message_height == value:
		return

	maximum_message_height = value
	_update_message_height()


func _check_message_height() -> void:
	var message_height := _message_label.get_content_height()
	if message_height == _last_message_height:
		return

	_update_message_height()


func _update_message_height() -> void:
	if not is_node_ready():
		return

	var content_height := _message_label.get_content_height()
	if maximum_message_height > 0.0:
		_message_label.custom_minimum_size.y = minf(content_height, maximum_message_height)
	else:
		_message_label.custom_minimum_size.y = content_height

	_last_message_height = content_height
