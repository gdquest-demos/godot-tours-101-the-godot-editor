@tool
extends EditorPlugin

signal debug_mode_toggled(enabled: bool)

## Paths to the script files from which the plugin finds and registers tours.
## Contains a GDTourMetadata class with code to change the GDTour settings or register tours.
const TOUR_SCRIPT_PATHS := ["res://godot_tours.gd", "res://tours/godot_tours.gd"]
const SINGLE_WINDOW_MODE_PROPERTY := "interface/editor/single_window_mode"

const EditorInterfaceAccess := preload("res://addons/gdquest_editor_interface/editor_interface_access.gd")
const EditorNodePoints := EditorInterfaceAccess.Enums.NodePoint
# TODO: Update windows on demand, as tours request them, instead of hardcoding?
const TOUR_MODE_WINDOW_POINTS := [
	EditorNodePoints.SIGNALS_DIALOG,
	EditorNodePoints.SCENE_DOCK_CREATE_DIALOG,
	EditorNodePoints.SCENE_DOCK_SCRIPT_CREATE_DIALOG,
	EditorNodePoints.SCENE_DOCK_SHADER_CREATE_DIALOG,
	EditorNodePoints.IMPORT_SCENE_SETTINGS_DIALOG,
]

const Utils := preload("utils.gd")
const GDTourMetadata := preload("gdtour_metadata.gd")
const Tour := preload("tour.gd")

const Overlays := preload("overlays/overlays.gd")
const ToursBubble := preload("bubble/tours_bubble.gd")

const GDTourButtonPackedScene := preload("editor/gdtour_button.tscn")
const ToursBubblePackedScene := preload("bubble/tours_bubble.tscn")

const Debugger := preload("debugger/debugger.gd")
const DebuggerPackedScene := preload("debugger/debugger.tscn")

const ALERT_TEXT := "You're using Godot '%s', but GDTour does not support this version currently.\nPlease use one of the supported versions: '%s <= VERSION <= %s'."

var _supported_versions := {
	min = { major = 4, minor = 6, op = func(a: int, b: int) -> bool: return a <= b },
	max = { major = 4, minor = 6, op = func(a: int, b: int) -> bool: return a >= b },
}
var version_info := Engine.get_version_info()

var plugin_path: String = get_script().resource_path.get_base_dir()
var debugger: Debugger = null
## When debug mode is active you can bypass tasks and flip through steps with
## keyboard shortcuts.
var is_debug_mode: bool = false

## Root node that houses all tour components added to the editor tree globally.
var _gdtour_ui_root: Node = null
## Layer of overlays covering editor UI with gaps for highlights.
var _gdtour_overlays: Overlays = null
## Button to open the tour selection menu, sitting in the editor top bar.
## This button only shows when there's no tour active and the welcome menu is hidden.
var _gdtour_button: Button = null
## Main bubble for the plugin.
var _gdtour_bubble: ToursBubble = null
## Windows with properties modified to support tour needs.
var _tour_mode_windows: Array[Window] = []

## Metadata defining the series of tours.
var _series_metadata: GDTourMetadata = null
## Collection of file paths for the tours.
var _series_paths: Array[String] = []
## The currently running tour, if any.
var _current_tour: Tour = null


# Lifecycle.

func _is_supported_version() -> bool:
	var result := true
	for bound: String in _supported_versions:
		var dict: Dictionary = _supported_versions[bound]
		result = result and dict.op.call(dict.major, version_info.major) and dict.op.call(dict.minor, version_info.minor)
	return result


func _ready() -> void:
	_finalize_plugin_load.call_deferred()

	debug_mode_toggled.connect(func(enabled: bool) -> void: is_debug_mode = enabled)


func _enter_tree() -> void:
	# Check for Godot version compatibility first.
	if not _is_supported_version():
		var accept_dialog := AcceptDialog.new()
		add_child(accept_dialog)
		accept_dialog.dialog_text = ALERT_TEXT % ([version_info.string] + _supported_versions.keys().map(
				func(k: String) -> String: return "{major}.{minor}".format(_supported_versions[k])
			) )
		accept_dialog.initial_position = AcceptDialog.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		accept_dialog.exclusive = false
		accept_dialog.show()
		return

	_load_tour_series()

	# There is no content for tours, so do nothing.
	if _series_metadata == null:
		return

	# Set up translations.

	Utils.load_plugin_translation(plugin_path.path_join("bubble"), Utils.TranslationDomains.BUBBLE_UI)

	var pot_files: Array[String] = [ plugin_path.path_join("tour.gd") ]
	pot_files.append_array(_series_paths)
	Utils.register_translation_pot_files(pot_files)

	# Set up plugin UI.

	_gdtour_ui_root = Node.new()
	_gdtour_ui_root.name = "GDTour"
	EditorInterface.get_base_control().add_child(_gdtour_ui_root)

	_gdtour_overlays = Overlays.new()
	_gdtour_overlays.name = "Overlays"
	_gdtour_ui_root.add_child(_gdtour_overlays)

	_gdtour_bubble = ToursBubblePackedScene.instantiate()
	_gdtour_ui_root.add_child(_gdtour_bubble)
	_update_tour_list()

	_add_top_bar_button()


## Adds a button labeled GDTour to the editor top bar, right before the run buttons.
## This button only shows when there are tours in the project, there's no tour active,
## and the welcome menu is hidden.
func _add_top_bar_button() -> void:
	if _series_metadata == null:
		return

	_gdtour_button = GDTourButtonPackedScene.instantiate()

	var editor_run_bar := EditorInterfaceAccess.get_node(EditorNodePoints.RUN_BAR)
	editor_run_bar.add_sibling(_gdtour_button)
	_gdtour_button.get_parent().move_child(_gdtour_button, editor_run_bar.get_index())
	_gdtour_button.pressed.connect(_show_tour_list)


## Perform final initialization steps, setting up the editor and showing plugin
## GUI. We must delay these steps as far as possible, to ensure we don't interfere
## with the startup. An early restart can cause an editor crash.
func _finalize_plugin_load() -> void:
	# Also enable the debugger dock if requested.
	if Debugger.CLI_OPTION_DEBUG in OS.get_cmdline_user_args():
		_toggle_debugger_dock_visible()

	# Apply mandatory settings for the editor.

	var editor_settings := EditorInterface.get_editor_settings()
	var is_single_window_mode := editor_settings.get_setting(SINGLE_WINDOW_MODE_PROPERTY)
	if not is_single_window_mode:
		editor_settings.set_setting(SINGLE_WINDOW_MODE_PROPERTY, true)
		EditorInterface.restart_editor(false)
		return

	for node_point: EditorNodePoints in TOUR_MODE_WINDOW_POINTS:
		var window_node: Window = EditorInterfaceAccess.get_node(node_point)
		if window_node:
			_tour_mode_windows.push_back(window_node)
			_toggle_window_tour_mode(window_node, true)

	await get_tree().process_frame
	get_viewport().mode = Window.MODE_MAXIMIZED

	# Show welcome menu automatically if the setting is enabled.

	if _series_metadata.auto_open_tour_list:
		_show_tour_list()
	else:
		_gdtour_button.show()


func _exit_tree() -> void:
	# Clean up tour data.

	if _current_tour != null:
		_current_tour.clean_up()
		_current_tour = null

	# Clean up plugin UI.

	if is_instance_valid(_gdtour_bubble):
		_gdtour_bubble.queue_free()
		_gdtour_bubble = null

	if is_instance_valid(_gdtour_overlays):
		_gdtour_overlays.clean_up()
		_gdtour_overlays.queue_free()
		_gdtour_overlays = null

	if is_instance_valid(_gdtour_ui_root):
		EditorInterface.get_base_control().remove_child(_gdtour_ui_root)
		_gdtour_ui_root.queue_free()
		_gdtour_ui_root = null

	if is_instance_valid(_gdtour_button):
		_gdtour_button.queue_free()
		_gdtour_button = null

	if is_instance_valid(debugger):
		if debugger.is_inside_tree():
			remove_control_from_docks(debugger)
		debugger.queue_free()
		debugger = null

	# Clean up translations.
	# Doing it after the UI has been removed, to avoid unnecessary updates.

	Utils.unload_all_translations()

	# Restore tour window state.

	for window in _tour_mode_windows:
		_toggle_window_tour_mode(window, false)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_F10 and event.ctrl_pressed and event.pressed:
		_toggle_debugger_dock_visible()

	if event is InputEventKey and event.keycode == KEY_D and event.ctrl_pressed and event.shift_pressed and event.pressed:
		var new_debug_mode := not is_debug_mode
		debug_mode_toggled.emit(new_debug_mode)
		prints("GDTour: Debug mode", "enabled" if new_debug_mode else "disabled")


# Tour management.

func _load_tour_series() -> void:
	_series_metadata = null
	_series_paths.clear()

	## Look for a [code]godot_tours.gd[/code] script file in the project root or in
	## the [code]tours/[/code] folder. This script should extend GDTourMetadata and
	## define available tours.

	for script_path in TOUR_SCRIPT_PATHS:
		if FileAccess.file_exists(script_path):
			var tour_script: Script = load(script_path)
			if not tour_script:
				push_warning("GDTour: Tour script file at '%s' exists but cannot be loaded." % [ script_path ])
				continue

			_series_metadata = tour_script.new()

	if not _series_metadata:
		push_warning(
			"GDTour: Tours are missing; create a script file at one of these paths to register tours: %s" % [ ", ".join(TOUR_SCRIPT_PATHS) ]
		)
		return

	for tour in _series_metadata.tours:
		_series_paths.push_back(tour.script_path)


func _update_tour_list() -> void:
	if not _series_metadata:
		return

	_gdtour_bubble.clear()
	_gdtour_bubble.set_title(_series_metadata.title)
	_gdtour_bubble.set_subtitle(_series_metadata.subtitle)
	_gdtour_bubble.add_text(_series_metadata.description)

	for tour in _series_metadata.tours:
		_gdtour_bubble.add_tour(tour, _series_metadata.sample_mode)

	if not _gdtour_bubble.close_requested.is_connected(_hide_tour_list):
		_gdtour_bubble.close_requested.connect(_hide_tour_list)

	if not _gdtour_bubble.tour_start_requested.is_connected(_start_tour):
		_gdtour_bubble.tour_start_requested.connect(_start_tour)

	if not _gdtour_bubble.tour_reset_requested.is_connected(_reset_tour):
		_gdtour_bubble.tour_reset_requested.connect(_reset_tour)


## Shows the welcome bubble with a short description of the series and a list of
## available tours.
func _show_tour_list() -> void:
	if not _series_metadata and not Debugger.CLI_OPTION_DEBUG in OS.get_cmdline_user_args():
		return

	_gdtour_button.hide()

	# HACK: Use internal methods to update positional data immediately and avoid transitions.
	_gdtour_bubble.set_avatar_at(ToursBubble.AvatarAt.PRIME_CENTER)
	_gdtour_bubble._transition_avatar(true)
	_gdtour_bubble.move_and_anchor(EditorInterface.get_base_control(), ToursBubble.At.CENTER)
	_gdtour_bubble._transition_bubble(true)
	_gdtour_bubble.show()


## Hides the welcome bubble.
func _hide_tour_list() -> void:
	_gdtour_button.show()
	_gdtour_bubble.hide()


func _start_tour(tour_id: String) -> void:
	if is_instance_valid(_current_tour):
		_current_tour.clean_up()
		_gdtour_ui_root.remove_child(_current_tour)
		_current_tour.queue_free()
		_current_tour = null

	if tour_id.is_empty():
		return

	var tour_metadata := _series_metadata.get_tour(tour_id)
	if not tour_metadata or tour_metadata.script_path.is_empty() or tour_metadata.is_locked:
		return

	_gdtour_bubble.hide()

	var tour_is_last := _series_metadata.is_last_tour(tour_metadata)
	Utils.load_tour_translation(tour_metadata.script_path.get_base_dir(), tour_metadata.id)
	_current_tour = load(tour_metadata.script_path).new(tour_metadata, _gdtour_overlays, tour_is_last)
	_gdtour_ui_root.add_child(_current_tour)

	_current_tour.closed.connect(_gdtour_button.show)
	_current_tour.ended.connect(_continue_tour_series)
	_current_tour.bubble.set_is_debug_mode(is_debug_mode)
	debug_mode_toggled.connect(_current_tour.bubble.set_is_debug_mode)


func _continue_tour_series() -> void:
	if not _current_tour:
		return

	var next_tour_id := _series_metadata.get_next_tour_id(_current_tour.tour_metadata)
	if next_tour_id.is_empty():
		_show_tour_list()
		return

	var next_tour := _series_metadata.get_tour(next_tour_id)
	if next_tour.script_path.is_empty() or next_tour.is_locked:
		_show_tour_list()
		return

	_start_tour(next_tour_id)


func _reset_tour(tour_id: String) -> void:
	var tour_metadata := _series_metadata.get_tour(tour_id)
	if not tour_metadata:
		return

	var was_reset_successful := _reset_tour_files(tour_metadata.script_path)
	if was_reset_successful:
		_gdtour_bubble.show_reset_success_message()
	else:
		_gdtour_bubble.show_reset_failure_message()


## Finds GDScript, tscn, and tres files in the tour source directory, next to the
## tour's .gd file, and copies them to the root directory. Returns true if the
## operation was successful, false otherwise. We assume that files in the tour source
## directory are the starting files required by the tour. All assets and other files
## you don't want to copy or overwrite should be in a separate subdirectory
## (example: "res://assets", "res://scenes"...).
func _reset_tour_files(tour_path: String) -> bool:
	var was_reset_successful := true
	const PREFIX := &"res://"

	var tour_dir_path := "%s/" % tour_path.get_base_dir()
	var tour_file_paths := Utils.fs_find("*", tour_dir_path).filter(
		func(path: String) -> bool: return not (path.get_extension() == "import" or path.get_extension() == "md" or path == tour_path)
	)

	var open_scene_paths := EditorInterface.get_open_scenes()
	var reload_scene_paths: Array[String] = []
	for tour_file_path: String in tour_file_paths:
		var destination_file_path := PREFIX.path_join(tour_file_path.replace(tour_dir_path, ""))
		var destination_dir_path := destination_file_path.get_base_dir()
		DirAccess.make_dir_recursive_absolute(destination_dir_path)

		var extension := tour_file_path.get_extension()
		if extension in ["gd", "tscn", "tres"]:
			var contents := FileAccess.get_file_as_string(tour_file_path)
			contents = contents.replace(tour_dir_path, destination_dir_path)
			var file_access := FileAccess.open(destination_file_path, FileAccess.WRITE)
			if file_access == null:
				push_error(
					"GDTour: Could not open file '%s' for writing. Resetting the tour '%s' was not successful." % [destination_file_path, tour_path],
				)
				was_reset_successful = false
				break
			file_access.store_string(contents)
			if destination_file_path in open_scene_paths:
				reload_scene_paths.push_back(destination_file_path)
		else:
			var error := DirAccess.copy_absolute(tour_file_path, destination_file_path)
			if error != OK:
				push_error(
					"GDTour: Could not copy folder '%s' to '%s'. Resetting the tour '%s' was not successful." % [tour_file_path, destination_file_path, tour_path],
				)
				was_reset_successful = false
				break

	EditorInterface.get_resource_filesystem().scan()
	while EditorInterface.get_resource_filesystem().is_scanning():
		pass

	for scene_path: String in reload_scene_paths:
		EditorInterface.reload_scene_from_path(scene_path)

	return was_reset_successful


## Changes properties of the target window to make it play nice with tours.
func _toggle_window_tour_mode(window: ConfirmationDialog, is_in_tour: bool) -> void:
	window.dialog_close_on_escape = not is_in_tour
	window.transient = is_in_tour
	window.exclusive = not is_in_tour
	window.physics_object_picking = is_in_tour
	window.physics_object_picking_sort = is_in_tour


# Helpers.

## Toggles the debugger dock. If it's not present, it's added to the upper-left dock slot.
func _toggle_debugger_dock_visible() -> void:
	if debugger == null:
		debugger = DebuggerPackedScene.instantiate()
		debugger.setup(
			plugin_path,
			_gdtour_overlays,
			_series_metadata,
			_current_tour,
			debug_mode_toggled,
		)
		debugger.set_is_debug_mode(is_debug_mode)

	if debugger.is_inside_tree():
		_gdtour_overlays.remove_highlights_from_control(debugger)
		remove_control_from_docks(debugger)
		debugger.queue_free()
		debugger = null
		if _current_tour == null:
			_show_tour_list()
	else:
		add_control_to_dock(DOCK_SLOT_LEFT_UL, debugger)
		_gdtour_button.hide()
