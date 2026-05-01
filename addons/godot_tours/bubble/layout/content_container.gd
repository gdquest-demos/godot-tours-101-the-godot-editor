@tool
extends MarginContainer

## Separation between paragraphs of text and elements in the content box, in pixels.
@export var paragraph_separation: int = 12:
	set = set_paragraph_separation

@onready var _element_list: VBoxContainer = %List


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_element_list = %List


func _ready() -> void:
	_update_paragraph_separation()


# Properties.

func set_paragraph_separation(value: int) -> void:
	if paragraph_separation == value:
		return

	paragraph_separation = value
	_update_paragraph_separation()


func _update_paragraph_separation() -> void:
	if not is_node_ready():
		return

	_element_list.add_theme_constant_override("separation", paragraph_separation * EditorInterface.get_editor_scale())


# Element management.

func add_element(element: Control) -> void:
	_element_list.add_child(element)


func fit_element_to_width(element: Control, aspect_ratio: float) -> void:
	if element.get_parent() != _element_list:
		return

	element.custom_minimum_size = Vector2(
		_element_list.size.x,
		_element_list.size.x * aspect_ratio
	)


func clear_elements() -> void:
	for child_node in _element_list.get_children():
		_element_list.remove_child(child_node)
		child_node.queue_free()
