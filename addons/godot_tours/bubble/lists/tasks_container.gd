@tool
extends MarginContainer

const Task := preload("task_item.gd")
const TaskPackedScene: PackedScene = preload("task_item.tscn")

@onready var _task_list: VBoxContainer = %List


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_task_list = %List


func create_task(description: String, repeat: int, repeat_callable: Callable, error_predicate: Callable, setup_callable: Callable) -> Task:
	var task := TaskPackedScene.instantiate()
	task.description = description
	task.repeat = repeat
	task.set_repeat_callable(repeat_callable)
	task.set_error_predicate(error_predicate)

	_task_list.add_child(task)

	if setup_callable.is_valid():
		setup_callable.call(task)

	return task


func has_tasks() -> bool:
	return _task_list.get_child_count() > 0


func check_tasks() -> bool:
	for task: Task in _task_list.get_children():
		if not task.is_done():
			return false

	return true


func clear_tasks() -> void:
	for child_node in _task_list.get_children():
		_task_list.remove_child(child_node)
		child_node.queue_free()
