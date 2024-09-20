#!/usr/bin/env -S godot --headless --script
extends "res://addons/gd-plug/plug.gd"


func _plugging() -> void:
	plug("git@github.com:GDQuest/godot-tours.git", {include = ["addons/godot_tours"]})
