#!/usr/bin/env -S godot --headless --script
extends "res://addons/gd-plug/plug.gd"


func _plugging() -> void:
	plug("git@github.com:GDQuest/GDTour.git", {include = ["addons/godot_tours", "addons/gdquest_sparkly_bag", "addons/gdquest_theme_utils"]})
