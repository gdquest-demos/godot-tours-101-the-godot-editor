@tool
extends "res://addons/godot_tours/gdtour_metadata.gd"


func _init() -> void:
	auto_open_tour_list = true
	sample_mode = true

	title = "Welcome to GDTour!"
	subtitle = "Getting Started with Godot"
	description.push_back("TOUR SERIES DESCRIPTION")

	register_tour(
		"getting_started_101_the_godot_editor",
		"101. The Godot Editor",
		32,
		"res://tours/godot-first-tour/godot_first_tour.gd",
	)
	register_tour(
		"getting_started_102_assemble_your_first_game",
		"102. Assemble Your First Game",
		99,
		"res://tours/learn-gamedev-from-zero/assemble_path_of_sorcerers.gd",
		true
	)
