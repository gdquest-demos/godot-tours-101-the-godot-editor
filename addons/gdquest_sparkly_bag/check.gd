extends SceneTree

const Utils := preload("res://addons/gdquest_sparkly_bag/sparkly_bag_utils.gd")


func _init() -> void:
	Utils.check_godot_files(ProjectSettings.globalize_path("res://"))
	quit()
