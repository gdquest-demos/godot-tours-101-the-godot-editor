# Uses functions to find and load resources in the project, and exposes those 
# resources to other parts of the game for procedural generation.
extends Node

const PICKUP_TILE_ID := 0
const ENEMY_TILE_ID := 1

var pickups := _load_resources(_find_scenes_in_directory("res://pickups"))
var enemies := _load_resources(_find_scenes_in_directory("res://enemies"))
var rooms := _load_resources(_find_scenes_in_directory("res://levels/rooms"))
var weapons := _load_resources(_find_scenes_in_directory("res://spells"))

# We use a Dictionary to look up the tile index on each of the Tilemap's tiles.
var scenes_map := {
	PICKUP_TILE_ID: pickups,
	ENEMY_TILE_ID: enemies,
}


func _load_resources(file_paths: Array) -> Array:
	var resources := []
	for path in file_paths:
		resources.append(load(path))
	return resources


func _find_scenes_in_directory(directory_path: String) -> Array:
	return _find_files_in_directory(directory_path, "tscn")


func _find_files_in_directory(directory_path: String, file_extension: String) -> Array:
	var file_names := DirAccess.get_files_at(directory_path)
	var file_paths := []
	for file_name in file_names:
		if file_name.get_extension() != file_extension:
			continue
		file_paths.append(directory_path.path_join(file_name))
	return file_paths
