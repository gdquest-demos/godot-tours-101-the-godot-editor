@tool
extends "res://addons/godot_tours/gdtour_metadata.gd"


func _define() -> void:
	auto_open_tour_list = true
	sample_mode = true

	title = tr("Welcome to GDTour!")
	subtitle = tr("Getting Started with Godot")
	description.push_back(tr("[center]%TOUR_SERIES_DESCRIPTION%[/center]"))

	register_tour(
		"getting_started_101_the_godot_editor",
		"101",
		tr("The Godot Editor"),
		30,
		"res://tours/godot-first-tour/godot_first_tour.gd",
	)
	register_tour(
		"getting_started_102_assemble_your_first_game",
		"102",
		tr("Assemble Your First Game"),
		99,
		"",
		true
	)
