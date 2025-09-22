@tool
extends "res://addons/godot_tours/gdtour_metadata.gd"


func _init() -> void:
	open_welcome_menu_automatically = true
	register_tour(
		"getting_started_101_the_godot_editor",
		"101: The Godot Editor",
		"res://tours/godot-first-tour/godot_first_tour.gd",
		true,
		false
	)
	register_tour(
		"getting_started_102_assemble_your_first_game",
		"102: Assemble Your First Game",
		"res://tours/learn-gamedev-from-zero/assemble_path_of_sorcerers.gd",
		false,
		true
	)