extends Control

@export var restart_scene_path := "res://start.tscn"


func _on_RestartButton_pressed() -> void:
	get_tree().change_scene_to_file(restart_scene_path)


func _on_QuitButton_pressed() -> void:
	get_tree().quit()
