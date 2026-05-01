@tool
extends "res://addons/godot_tours/gdtour_metadata.gd"

func _define() -> void:
	auto_open_tour_list = true
	sample_mode = true

	title = tr("Welcome to GDTours")
	subtitle = tr("Getting Started with Godot")
	# Note about the description, it's made a bit longer to easily make the menu fit the size of the
	# GDSchool panel on the right.
	description.push_back(
		"[center]" +
		tr("In this guided tour, you take your first steps in the Godot UI and discover its essential building blocks: Scenes, Nodes, Scripts, and Signals.") +
		"[/center]",
	)

	register_tour(
		"getting_started_101_the_godot_editor",
		"101",
		tr("The Godot Editor"),
		30,
		"res://tours/101_the_godot_editor/101_the_godot_editor.gd",
	)
	register_tour(
		"102a_add_player_and_rooms",
		"102.a",
		tr("Add a Player and Rooms"),
		21,
		"",
		true,
	)
	register_tour(
		"102b_add_bridges",
		"102.b",
		tr("Add bridges"),
		17,
		"",
		true,
	)
	register_tour(
		"102c_add_sky_and_healthbar",
		"102.c",
		tr("Add a sky and a healthbar"),
		17,
		"",
		true,
	)
	register_tour(
		"102d_connect_healthbar_to_player",
		"102.d",
		tr("Connect the healthbar to the player health"),
		13,
		"",
		true,
	)
	register_tour(
		"102e_add_chest_spawns_pickups",
		"102.e",
		tr("Add a chest that spawns pickups"),
		19,
		"",
		true,
	)
