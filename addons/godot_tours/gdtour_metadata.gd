## Base class for registering tours and their metadata in a project.
## Create a [code]res://godot_tours.gd[/code] or [code]res://tours/godot_tours.gd[/code]
## file in your project and register your tours with [method register_tour].
## Each tour must have at least a unique id, a title, and a path to
## the tour script.
@tool
extends RefCounted

const Utils := preload("utils.gd")

## Main title of this tour series.
var title: String = "Welcome to GDTours"
## Subtitle of this tour series.
var subtitle: String = ""
## Description of this tour series, as individual paragraphs.
var description: Array[String] = []

## Collection of registered tours.
var tours: Array[Tour] = []
## Mapping between tour ids and tour metadata.
var _tour_id_map: Dictionary[String, Tour] = {}

## Flag that forces the tour list to appear automatically when the project
## is opened.
var auto_open_tour_list: bool = true
## Flag that puts the tour selector into the sample mode, where some tours
## only appear as promotional material. Set before registering tours to
## ensure correct validation of metadata.
var sample_mode: bool = false


func _init() -> void:
	# Use empty name for metadata's domain for simplicity; tours put their id in there
	# (which cannot be empty).
	set_translation_domain(Utils.TRANSLATION_TOUR_DOMAIN % "")

	_define()


## [b]Virtual[/b] method for defining metadata's content.
func _define() -> void:
	pass


## Register a single tour with the given unique [param id], [param title],
## and [param script_path]. The script must exist, unless the series is in
## the sample mode and the tour is locked.
##
## For the time being, the number of steps must be supplied here as well.
func register_tour(id: String, title_key: String, title: String, step_count: int, script_path: String, is_locked: bool = false) -> void:
	if id.is_empty() or title.is_empty():
		push_error("GDTourMetadata: Attempting to register a tour, but id and title cannot be empty.")
		return

	if _tour_id_map.has(id):
		push_error("GDTourMetadata: Attempting to register a tour, but the identifier '%s' already exists." % [ id ])
		return

	if (not sample_mode or not is_locked) and (script_path.is_empty() or not FileAccess.file_exists(script_path)):
		push_error("GDTourMetadata: Attempting to register a tour, but the tour script at '%s' doesn't exist." % [ script_path ])
		return

	if not sample_mode and is_locked:
		push_warning("GDTourMetadata: Marking a tour as locked is only possible in sample mode, check tour '%s'." % [ id ])

	var tour := Tour.new()
	tour.id = id
	tour.title = title
	tour.title_key = title_key
	tour.step_count = step_count
	tour.script_path = script_path
	tour.is_locked = is_locked

	tours.append(tour)
	_tour_id_map[id] = tour


func get_tour(id: String) -> Tour:
	if not _tour_id_map.has(id):
		return null

	return _tour_id_map[id]


func is_last_tour(tour: Tour) -> bool:
	var tour_index := tours.find(tour)
	if tour_index < 0:
		return false

	return tour_index >= tours.size() - 1


func get_next_tour_id(tour: Tour) -> String:
	var tour_index := tours.find(tour)
	if tour_index < 0 or tour_index >= tours.size() - 1:
		return ""

	var next_tour := tours[tour_index + 1]
	return next_tour.id


## Object represeting the metadata of an individual tour in the series. There can only
## be one series per project, but multiple tours per series. Use [method register_tour]
## to define tours in your [code]godot_tours.gd[/code] file.
class Tour:
	## Unique identifier of the tour.
	var id := ""
	## Display title for the tour.
	var title := ""
	## Key part of the display title for the tour, e.g. "101".
	var title_key := ""
	## Number of steps in the tour.
	var step_count := 0
	## Path to the tour's script.
	var script_path := ""
	## Flag that makes the tour appear locked when in sample mode.
	var is_locked := false


	func _to_string() -> String:
		var dict := inst_to_dict(self)

		const EXCLUDE_KEYS: Array[String] = ["@*", "_*"]
		var excluded := dict.keys().filter(func(key: String) -> bool:
			return EXCLUDE_KEYS.any(
				func(mask: String) -> bool: return key.match(mask)
			)
		)
		for key: String in excluded:
			dict.erase(key)

		return str(dict)
