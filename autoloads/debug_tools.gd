extends Node


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reload"):
		var player = get_node("/root/Main/Player")
		var saved_position = player.global_position
		get_tree().reload_current_scene()
		player.global_position = saved_position
