@tool
extends Container

@export_range(0.0, 100.0, 0.01, "or_greater") var maximum_height: float = 0.0:
	set = set_maximum_height

@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _content_box: VBoxContainer = %Content


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_scroll_container = %ScrollContainer
		_content_box = %Content

	elif what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()


func _ready() -> void:
	_content_box.visibility_changed.connect(update_minimum_size)
	_content_box.visibility_changed.connect(queue_sort)
	_content_box.minimum_size_changed.connect(update_minimum_size)
	_content_box.minimum_size_changed.connect(queue_sort)


# Container behavior.

func _get_minimum_size() -> Vector2:
	var minsize := _content_box.get_combined_minimum_size()
	if maximum_height > 0.0:
		minsize.y = minf(minsize.y, maximum_height)

	return minsize


func _sort_children() -> void:
	fit_child_in_rect(_scroll_container, Rect2(Vector2.ZERO, size))


# Properties.

func get_content_height() -> float:
	return _content_box.get_combined_minimum_size().y


func set_maximum_height(value: float) -> void:
	if maximum_height == value:
		return

	maximum_height = value
	update_minimum_size()
	queue_sort()
