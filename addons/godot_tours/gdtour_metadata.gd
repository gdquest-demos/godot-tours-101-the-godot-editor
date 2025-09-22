## Base class for registering tours and their metadata in a project.
## Create a file res://godot_tours.gd or res://tours/godot_tours.gd in your project and append GDTourMetadata objects to the [member list] property to define and register tours in your project.
@tool
extends Node

const NAME := "GDTourMetadata"

## Represents the metadata of a given tour.
## You need to create these objects and append them to the list property in your project's godot_tours.gd file.
class TourMetadata:
	var _cache := {}

	var id := ""
	var title := ""
	var is_free := false
	var is_locked := false
	var tour_path := ""

	func _init(id: String, title: String, tour_path: String, is_free := false, is_locked := false) -> void:
		self.id = id
		self.title = title
		self.tour_path = tour_path
		self.is_free = is_free
		self.is_locked = is_locked

	func _to_string() -> String:
		return str(to_dictionary())

	func to_dictionary(exclude: Array[String] = ["@*", "_*"]) -> Dictionary:
		if "dictionary" in _cache:
			return _cache.dictionary

		var result := inst_to_dict(self)
		var predicate := func(key: String) -> bool: return exclude.any(
			func(e: String) -> bool: return key.match(e)
		)

		for key in result.keys().filter(predicate):
			result.erase(key)

		_cache.dictionary = result
		return result

## Create and store tour metadata objects in here to register tours.
var list: Array[TourMetadata] = []

## If true, the welcome menu will pop up automatically when opening the
## project in Godot.
var open_welcome_menu_automatically := true

## Register a single tour with the given parameters.
func register_tour(id: String, title: String, tour_path: String, is_free := false, is_locked := false) -> void:
	var metadata := TourMetadata.new(id, title, tour_path, is_free, is_locked)
	list.append(metadata)
