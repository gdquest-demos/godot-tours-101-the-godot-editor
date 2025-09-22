## Main class used to design a tour. Provides an API to design tour steps.
##
##
## The tour is a series of steps, each step being a series of commands to execute.
## Commands are executed in the order they are added.
## [br][br]
## This class provides many common commands to use in your tour, like selecting a node in the scene
## tree, highlighting a control, or playing a mouse animation.
## [br][br]
## Each command is a ["addons/godot_tours/tour.gd".Command] object, which is a wrapper around a callable and
## its parameters. You can run any function in the editor by wrapping it in a [code]Command[/code] object.
## Use the utility function [method queue_command] to create a [code]Command[/code] and add it to
## [member step_commands] faster.
## [br][br]
## To design a tour, override the [method _build] function and write all your tour steps in it:
## [br][br]
## 1. Call API functions to queue commands required for your step. [br]
## 2. Call [method complete_step] to complete and save the current [code]step_commands[/code] as a new.
## [br][br]
## See the provided demo tour for an example.
extends Node

## Emitted when the tour moves to the next or previous [member step_commands].
signal step_changed(step_index: int)
## Emitted when the user completes the last [member step_commands].
signal ended
## Emitted when the user closes the tour.
signal closed

## Represents one command to execute in a step_commands. All commands are executed in the order they are added.
## Use the [member queue_command] function to create a [code]Command[/code] object and add it to
## [member step_commands] faster.
class Command:
	var callable := func() -> void: pass
	var parameters := []

	func _init(callable: Callable, parameters := []) -> void:
		self.callable = callable
		self.parameters = parameters

	func force() -> void:
		await callable.callv(parameters)

const Log := preload("log.gd")
const Shortcuts := preload("shortcuts.gd")
const EditorInterfaceAccess := preload("editor_interface_access.gd")
const Utils := preload("utils.gd")
const Overlays := preload("overlays/overlays.gd")
const Bubble := preload("bubble/bubble.gd")
const Task := preload("bubble/task/task.gd")
const Mouse := preload("mouse/mouse.gd")
const TranslationService := preload("translation/translation_service.gd")
const FlashArea := preload("overlays/flash_area/flash_area.gd")
const Guide3D := preload("assets/guide_3d.gd")

const Guide3DPackedScene := preload("assets/guide_3d.tscn")
const FlashAreaPackedScene := preload("overlays/flash_area/flash_area.tscn")

const WARNING_MESSAGE := "[color=orange][WARN][/color] %s for [b]'%s()'[/b] at [b]'step_commands(=%d)'[/b]."

enum Direction {BACK = -1, NEXT = 1}

const EVENTS := {
	f = preload("events/f_input_event_key.tres"),
}
## Index of the step_commands currently running.
var index := -1: set = set_index
var steps: Array[Array] = []
var step_commands: Array[Command] = []
var guides: Dictionary = {}

var log := Log.new()
var shortcuts := Shortcuts.new()
var editor_selection: EditorSelection = null
## Object that provides access to many nodes in the editor's user interface.
var interface: EditorInterfaceAccess = null
var overlays: Overlays = null
var translation_service: TranslationService = null
var mouse: Mouse = null
var bubble: Bubble = null


func _init(interface: EditorInterfaceAccess, overlays: Overlays,  translation_service: TranslationService) -> void:
	self.editor_selection = EditorInterface.get_selection()
	self.interface = interface
	self.overlays = overlays
	self.translation_service = translation_service
	interface.run_bar.stop_pressed.connect(_close_bottom_panel)
	translation_service.update_tour_key(get_script().resource_path)

	for key in EVENTS:
		var action: StringName = "tour_%s" % key
		InputMap.add_action(action)
		InputMap.action_add_event(action, EVENTS[key])

	# Applies the default layout so every tour starts from the same UI state.
	interface.restore_default_layout()
	_build()
	load_bubble()
	if index == -1:
		set_index(0)


## Virtual function to override to build the tour. Write all your tour steps in it.
## This function is called when the tour is created, after connecting signals and re-applying the
## editor's default layout, which helps avoid many UI edge cases.
func _build() -> void:
	pass


## Cleans up resources used by the tour, including removing input actions,
## clearing mouse animation and guides, and freeing the bubble UI.
## Called when the tour is closed or ends.
func clean_up() -> void:
	for key in EVENTS:
		var action: StringName = "tour_%s" % key
		if InputMap.has_action(action):
			InputMap.erase_action(action)

	clear_mouse()
	clear_guides()
	log.clean_up()
	if is_instance_valid(bubble):
		bubble.queue_free()


## Sets the current step index and runs the steps between the current index and the new one.
## This is used to navigate between steps, either going forward or backward, but
## also to jump and skip many steps.
##
## Parameters:
## - value: The target step index to move to.
func set_index(value: int) -> void:
	log.reopen()
	var step_count := steps.size()
	value = clampi(value, -1, step_count)
	log.info("[step_commands: %d]\n%s" % [value, interface.logger_rich_text_label.get_parsed_text()])
	run(steps[value])
	index = clampi(value, 0, step_count - 1)
	step_changed.emit(index)


## Loads and initializes the bubble UI for the tour.
## Frees any existing bubble and instantiates a new one, sets up connections
## to handle navigation, closing, and completing the tour.
##
## Parameters:
## - BubblePackedScene: Optional custom bubble scene. If null, uses the default
## bubble in the tour system.
func load_bubble(BubblePackedScene: PackedScene = null) -> void:
	if bubble != null:
		bubble.queue_free()

	if BubblePackedScene == null:
		BubblePackedScene = load("res://addons/godot_tours/bubble/default_bubble.tscn")

	bubble = BubblePackedScene.instantiate()
	bubble.setup(interface, log, translation_service, steps.size())
	interface.base_control.add_child(bubble)
	bubble.back_button_pressed.connect(back)
	bubble.next_button_pressed.connect(next)
	bubble.close_requested.connect(func() -> void:
		toggle_visible(false)
		closed.emit()
		clean_up()
	)
	bubble.finish_requested.connect(func() -> void:
		toggle_visible(false)
		clean_up()
		await get_tree().process_frame
		ended.emit()
	)
	step_changed.connect(bubble.on_tour_step_changed)


## Goes back to the previous step.
## Stops the currently playing scene and navigates to the previous step in the tour.
func back() -> void:
	EditorInterface.stop_playing_scene()
	set_index(index + Direction.BACK)


## Goes to the next step, or shows a button to end the tour if the last step is reached.
## Stops the currently playing scene and navigates to the next step in the tour.
func next() -> void:
	EditorInterface.stop_playing_scene()
	set_index(index + Direction.NEXT)


## Waits for the next frame and goes back to the previous step. Used for automated testing.
func auto_back() -> void:
	queue_command(func() -> void:
		await delay_process_frame()
		back()
	)


## Waits for the next frame and advances to the next step. Used for automated testing.
func auto_next() -> void:
	queue_command(func wait_for_frame_and_advance() -> void:
		await delay_process_frame()
		next()
	)


## Completes the current step's commands, adding some more commands to clear the bubble, overlays, and the mouse.
## Then, this function appends the completed step (an array of
## [Command] objects) to the tour.
func complete_step() -> void:
	var step_start: Array[Command] = [
		Command.new(func() -> void: bubble.clear()),
		Command.new(overlays.clean_up),
		Command.new(overlays.ensure_get_dimmer_for.bind(interface.base_control)),
		Command.new(clear_mouse),
		Command.new(clear_guides),
	]
	step_commands.push_back(Command.new(play_mouse))
	steps.push_back(step_start + step_commands)
	step_commands = []


## Runs all commands in a step sequentially.
## Each command is executed and the function waits for it to complete before moving to the next.
##
## Parameters:
## - current_step: An array of Command objects to execute.
func run(current_step: Array[Command]) -> void:
	for current_command in current_step:
		await current_command.force()


## Appends a command to the currently edited step. Commands are executed in the order they are added.
## To complete a step and start creating the next one, call [method complete_step].
func queue_command(callable: Callable, parameters := []) -> void:
	step_commands.push_back(Command.new(callable, parameters))


## Replace the current bubble with a new one.
## Use this to change the bubble UI appearance during the tour.
##
## Parameters:
## - BubblePackedScene: The new bubble scene to use. If null, uses the default bubble.
func swap_bubble(BubblePackedScene: PackedScene = null) -> void:
	queue_command(load_bubble, [BubblePackedScene])


## Open a scene in the editor.
## If the scene is already open, it will be reloaded.
##
## Parameters:
## - path: The file path to the scene to open. It must exist and have a .tscn extension.
func scene_open(path: String) -> void:
	if not FileAccess.file_exists(path) and path.get_extension() != "tscn":
		warn("[b]'path(=%s)'[/b] doesn't exist or has wrong extension" % path, "scene_open")
		return
	queue_command(func() -> void:
		if path in EditorInterface.get_open_scenes():
			EditorInterface.reload_scene_from_path(path)
		else:
			EditorInterface.open_scene_from_path(path)
	)


## Select nodes in the current scene by their node paths.
## First deselects all nodes, then selects the specified nodes.
##
## Parameters:
## - paths: Array of node paths to select. Paths should be relative to the scene root.
func scene_select_nodes_by_path(paths: Array[String] = []) -> void:
	scene_deselect_all_nodes()
	queue_command(func() -> void:
		var scene_root := EditorInterface.get_edited_scene_root()
		for node in Utils.find_children_by_path(scene_root, paths):
			editor_selection.add_node(node)
	)


## Lock or unlock nodes in the current scene by their paths.
## Locked nodes can't be selected or moved in the editor viewport.
##
## Parameters:
## - paths: Array of node paths to lock/unlock. Paths should be relative to the scene root.
## - is_locked: If true, lock (true) or unlock (false) the nodes.
func scene_toggle_lock_nodes_by_path(paths: Array[String] = [], is_locked := true) -> void:
	queue_command(func get_and_lock_nodes() -> void:
		var nodes := Utils.find_children_by_path(EditorInterface.get_edited_scene_root(), paths)
		var prop := &"_edit_lock_"
		for node in nodes:
			node.set_meta(prop, is_locked) if is_locked else node.remove_meta(prop)
	)


## Deselect all nodes in the editor.
## This clears the current editor selection.
func scene_deselect_all_nodes() -> void:
	queue_command(editor_selection.clear)


## Frees the `Guide3D` nodes from the currently edited scene.
## This cleans up any visual guide indicators that were added to help users during the tour.
func clear_guides() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return

	for guide in guides.values():
		guide.queue_free()
	guides = {}


## Set a TabBar to a specific tab index.
##
## Parameters:
## - tabs: The TabBar to manipulate
## - index: The index of the tab to select. Must be within range of available tabs.
func tabs_set_to_index(tabs: TabBar, index: int) -> void:
	if index < 0 or index >= tabs.tab_count:
		warn("[b]'index(=%d)'[/b] not in [b]'range(0, tabs.tab_count(=%d))'[/b]." % [index, tabs.tab_count], "tabs_set_to_index")
		return
	queue_command(tabs.set_current_tab, [index])


## Set a TabBar to a specific tab by its title.
## Finds the tab with the matching title and selects it.
##
## Parameters:
## - tabs: The TabBar to manipulate
## - title: The title of the tab to select. Must match an existing tab title.
func tabs_set_to_title(tabs: TabBar, title: String) -> void:
	var index := find_tabs_title(tabs, title)
	if index == -1:
		var titles := range(tabs.tab_count).map(func(index: int) -> String: return tabs.get_tab_title(index))
		warn("[b]'title(=%s)'[/b] not found in tabs [b]'[%s]'[/b]." % [title, ", ".join(titles)], "tabs_set_to_title")
	else:
		tabs_set_to_index(tabs, index)


## Switch a TabContainer's active tab to display the tab
## containing a specific control.
##
## Parameters:
## - control: The control to find and show in its parent TabContainer.
##   Must be a direct child of a TabContainer.
func tabs_set_by_control(control: Control) -> void:
	const FUNC_NAME := "tabs_set_to_control"
	if control == null or (control != null and not control.get_parent() is TabContainer):
		warn("[b]'control(=%s)'[/b] is 'null' or parent is not TabContainer." % [control], FUNC_NAME)
		return

	var tab_container: TabContainer = control.get_parent()
	var tab_idx := find_tabs_control(tab_container, control)
	if tab_idx == -1:
		warn("[b]'control(=%s)'[/b] is not a child of [b]'[%s]'[/b]." % [control, tab_container], FUNC_NAME)
	else:
		tabs_set_to_index(tab_container.get_tab_bar(), tab_idx)


## Set the TileSet editor tabs to the tab containing a
## specific control.
##
## Parameters:
## - control: The control to find and show in the TileSet editor tabs.
##   Must be a control in the interface.tileset_panels array.
func tileset_tabs_set_by_control(control: Control) -> void:
	var index := interface.tileset_panels.find(control)
	if index == -1:
		warn("[b]'control(=%s)'[/] must be found in '[b]interface.tilset_controls[/b]'" % [control], "tileset_set_to_control")
	else:
		tabs_set_to_index(interface.tileset_tabs, index)


## Set the TileMap editor tabs to the tab containing a specific control.
##
## Parameters:
## - control: The control to find and show in the TileMap editor tabs.
##   Must be a control in the interface.tilemap_panels array.
func tilemap_tabs_set_by_control(control: Control) -> void:
	var index := interface.tilemap_panels.find(control)
	if index == -1:
		warn("[b]'control(=%s)'[/] must be found in '[b]interface.tilmap_controls[/b]'" % [control], "tilemap_set_to_control")
	else:
		tabs_set_to_index(interface.tilemap_tabs, index)


## Find and activate tree items that start with a specific prefix.
## Useful for activating specific signals, nodes, or resources in tree views.
##
## Parameters:
## - tree: The Tree control to search in
## - prefix: The text prefix to search for in tree items
func tree_activate_by_prefix(tree: Tree, prefix: String) -> void:
	queue_command(func() -> void:
		if tree == interface.node_dock_signals_tree and interface.signals_dialog_window.visible:
			return
		await delay_process_frame()
		tree.deselect_all()
		var items := Utils.filter_tree_items(
			tree.get_root(),
			func(item: TreeItem) -> bool: return item.get_text(0).begins_with(prefix)
		)
		for item in items:
			item.select(0)
		tree.item_activated.emit()
	)


## Center the 2D viewport at a specific position with a specific zoom level.
##
## Parameters:
## - position: The position to center the viewport at. Defaults to Vector2.ZERO.
## - zoom: The zoom level to set, where 1.0 is 100%. Defaults to 1.0.
func canvas_item_editor_center_at(position := Vector2.ZERO, zoom := 1.0) -> void:
	queue_command(func() -> void:
		await delay_process_frame()
		interface.canvas_item_editor.center_at(position)
		interface.canvas_item_editor_zoom_widget.set_zoom(zoom)
	)


## Resets the zoom of the 2D viewport to 100%.
func canvas_item_editor_zoom_reset() -> void:
	queue_command(interface.canvas_item_editor_zoom_widget.set_zoom.bind(1.0))


## Play a flash animation in the 2D viewport over a specific rectangle area.
## Useful for drawing attention to a specific part of the scene.
##
## Parameters:
## - rect: The rectangle area to flash in the 2D viewport
func canvas_item_editor_flash_area(rect: Rect2) -> void:
	queue_command(func flash_canvas_item_editor() -> void:
		var flash_area := FlashAreaPackedScene.instantiate()
		overlays.ensure_get_dimmer_for(interface.canvas_item_editor).add_child(flash_area)
		interface.canvas_item_editor_viewport.draw.connect(
			flash_area.refresh.bind(interface.canvas_item_editor_viewport, rect)
		)
		flash_area.refresh(interface.canvas_item_editor_viewport, rect)
	)


## Focus the 3D viewport on the currently selected node.
## This simulates pressing the "F" key in the 3D viewport to frame the selection.
func spatial_editor_focus() -> void:
	queue_command(func() -> void:
		for surface in interface.spatial_editor_surfaces:
			if surface.is_inside_tree():
				surface.gui_input.emit(EVENTS.f)
	)


## Select nodes by their paths and then focus the 3D viewport on them.
## This combines selecting nodes and framing them in the 3D viewport.
##
## Parameters:
## - paths: Array of node paths to select and focus on
func spatial_editor_focus_node_by_paths(paths: Array[String]) -> void:
	scene_select_nodes_by_path(paths)
	spatial_editor_focus()


enum ViewportLayouts {
	ONE = 0, TWO = 1, TWO_ALT = 2, THREE = 3, THREE_ALT = 4, FOUR = 5
}
## Changes the layout of the 3D viewport. Corresponds to clicking items in the
## View menu in the toolbar above the 3D viewport.
func spatial_editor_change_viewport_layout(layout: ViewportLayouts) -> void:
	queue_command(func spatial_editor_change_viewport_layout() -> void:
		var popup := interface.spatial_editor_toolbar_view_menu_button.get_popup()
		var event := InputEventKey.new()
		event.pressed = true
		event.ctrl_pressed = true

		if layout == ViewportLayouts.ONE:
			event.keycode = KEY_1
		elif layout == ViewportLayouts.TWO:
			event.keycode = KEY_2
		elif layout == ViewportLayouts.TWO_ALT:
			event.keycode = KEY_2
			event.alt = true
		elif layout == ViewportLayouts.THREE:
			event.keycode = KEY_3
		elif layout == ViewportLayouts.THREE_ALT:
			event.keycode = KEY_3
			event.alt = true
		elif layout == ViewportLayouts.FOUR:
			event.keycode = KEY_4

		popup.activate_item_by_event(event)
	)


## Switch the editor to a specific main screen context.
## You can use the specific context_set functions, like [context_set_2d], [context_set_3d], etc. instead.
##
## Parameters:
## - type: The editor context to switch to (e.g., "2D", "3D", "Script", etc.)
func context_set(type: String) -> void:
	queue_command(EditorInterface.set_main_screen_editor, [type])


## Switch the editor to the 2D context.
## Shorthand for context_set("2D").
func context_set_2d() -> void:
	context_set("2D")


## Switch the editor to the 3D context.
## Shorthand for context_set("3D").
func context_set_3d() -> void:
	context_set("3D")


## Switch the editor to the Script context.
## Shorthand for context_set("Script").
func context_set_script() -> void:
	context_set("Script")


## Switch the editor to the Game context.
## Shorthand for context_set("Game").
func context_set_game() -> void:
	context_set("Game")


## Switch the editor to the Asset Library context.
## Shorthand for context_set("AssetLib").
func context_set_asset_lib() -> void:
	context_set("AssetLib")


## Set the title of the bubble UI component.
##
## Parameters:
## - title_text: The text to set as the bubble's title
func bubble_set_title(title_text: String) -> void:
	queue_command(func bubble_set_title() -> void: bubble.set_title(title_text))


## Add text paragraphs to the bubble UI component.
##
## Parameters:
## - text: Array of strings, each representing a paragraph to add to the bubble
func bubble_add_text(text: Array[String]) -> void:
	queue_command(func bubble_add_text() -> void: bubble.add_text(text))


## Add a texture to the bubble UI component.
##
## Parameters:
## - texture: The texture to add to the bubble
## - max_height: Optional maximum height for the texture in pixels, scaled by editor scale.
##   If 0, the texture will use its natural height.
func bubble_add_texture(texture: Texture2D, max_height := 0.0) -> void:
	queue_command(func bubble_add_texture() -> void:
		bubble.add_texture(texture, max_height * EditorInterface.get_editor_scale())
	)


## Add code with syntax highlighting to the bubble UI component.
##
## Parameters:
## - lines: Array of strings, each representing a line of code to add to the bubble
func bubble_add_code(lines: Array[String]) -> void:
	queue_command(func bubble_add_code() -> void: bubble.add_code(lines))


## Add a video player to the bubble UI component.
##
## Parameters:
## - stream: The VideoStream resource to play in the bubble
func bubble_add_video(stream: VideoStream) -> void:
	queue_command(func bubble_add_video() -> void: bubble.add_video(stream))


## Set the header text of the bubble UI component.
## This text appears above the title section.
##
## Parameters:
## - text: The text to set as the bubble's header
func bubble_set_header(text: String) -> void:
	queue_command(func bubble_set_header() -> void: bubble.set_header(text))


## Set the footer text of the bubble UI component.
## This text appears below the content section. You can use it for side notes
## and less important information.
##
## Parameters:
## - text: The text to set as the bubble's footer
func bubble_set_footer(text: String) -> void:
	queue_command(func bubble_set_footer() -> void: bubble.set_footer(text))


## Set the background texture of the bubble UI component.
##
## Parameters:
## - texture: The texture to use as the bubble's background
func bubble_set_background(texture: Texture2D) -> void:
	queue_command(func bubble_set_background() -> void: bubble.set_background(texture))


## Add a task to the bubble UI component.
## Tasks are interactive elements that wait for the user to complete a specific action.
## The action is determined by the `repeat_callable` function, which is called
## every frame. The task is passed if the value returned by `repeat_callable` is
## equal to `repeat`.
##
## Parameters:
## - description: Text description of the task for the user
## - repeat: Number of times the task needs to be completed
## - repeat_callable: Function that checks if the task is complete and returns its progress
## - error_predicate: Optional function that returns true if the task has an error state
func bubble_add_task(description: String, repeat: int, repeat_callable: Callable, error_predicate := noop_error_predicate) -> void:
	queue_command(func() -> void: bubble.add_task(description, repeat, repeat_callable, error_predicate))


## Creates a task that waits for the user to press a specific button.
## This is commonly used for guiding users through the interface by having
## them interact with specific buttons.
##
## Parameters:
## - button: The Button that the user needs to press
## - description: Optional custom task description. If empty, uses button text or tooltip.
##   and automatically generates a description like "Press the [ButtonName] button."
func bubble_add_task_press_button(button: Button, description := "") -> void:
	var text: String = description
	if text.is_empty():
		if button.text.is_empty():
			text = button.tooltip_text
		else:
			text = button.text
	text = text.replace(".", "")
	description = gtr("Press the [b]%s[/b] button.") % text
	bubble_add_task(
		description,
		1,
		func(task: Task) -> int:
			if not button.pressed.is_connected(task._on_button_pressed_hack):
				button.pressed.connect(task._on_button_pressed_hack.bind(button))
			return 1 if task.is_done() or button.button_pressed else 0,
		noop_error_predicate,
	)


## Creates a task that waits for the user to toggle a button to a specific state.
## This is useful for teaching users about toggle buttons and how to activate or
## deactivate features in the editor.
##
## Parameters:
## - button: The Button that needs to be toggled
## - is_toggled: The target toggle state (true for ON, false for OFF)
## - description: Optional custom task description. If empty, automatically generates
##   a description like "Turn the [ButtonName] button ON/OFF."
func bubble_add_task_toggle_button(button: Button, is_toggled := true, description := "") -> void:
	if not button.toggle_mode:
		warn("[b]'button(=%s)'[/b] at [b]'path(=%s)'[/b] doesn't have toggle_mode ON." % [str(button), button.get_path()], "bubble_add_task_toggle_button")
		return

	const TOGGLE_MAP := {true: "ON", false: "OFF"}
	if description.is_empty():
		var text: String
		if button.text.is_empty():
			text = button.tooltip_text
		else:
			text = button.text
		text = text.replace(".", "")
		description = gtr("Turn the [b]%s[/b] button %s.") % [text, TOGGLE_MAP[is_toggled]]

	bubble_add_task(
		description,
		1,
		func(_task: Task) -> int: return 1 if button.button_pressed == is_toggled else 0,
		noop_error_predicate,
	)


## Creates a task that waits for the user to select a specific tab by its index.
## Use this to guide users through tabbed docks like the Inspector,
## FileSystem, or other docked panels.
##
## Parameters:
## - tabs: The TabBar control containing the tabs
## - index: The index of the tab that needs to be selected
## - description: Optional custom task description. If empty, automatically generates
##   a description like "Change to the [TabTitle] tab."
func bubble_add_task_set_tab_to_index(tabs: TabBar, index: int, description := "") -> void:
	if index < 0 or index >= tabs.tab_count:
		warn("[b]'index(=%d)'[/b] not in [b]'range(0, tabs.tab_count(=%d))'[/b]" % [index, tabs.tab_count], "bubble_add_task_set_tab_to_index")
		return
	var title := tabs.get_tab_title(index)
	description = gtr("Change to the [b]%s[/b] tab.") % [title] if description.is_empty() else description
	bubble_add_task(description, 1, func(_task: Task) -> int: return 1 if index == tabs.current_tab else 0, noop_error_predicate)


## Creates a task that waits for the user to select a specific tab by its title.
## Similar to [method bubble_add_task_set_tab_to_index], but uses the tab's title
## to find the index.
##
## Parameters:
## - tabs: The TabBar control containing the tabs
## - title: The title of the tab that needs to be selected
## - description: Optional custom task description. If empty, inherits the description
##   from bubble_add_task_set_tab_to_index
func bubble_add_task_set_tab_to_title(tabs: TabBar, title: String, description := "") -> void:
	var index := find_tabs_title(tabs, title)
	if index == -1:
		var titles := range(tabs.tab_count).map(func(index: int) -> String: return tabs.get_tab_title(index))
		warn("[b]'title(=%s)'[/b] not found in tabs [b]'[%s]'[/b]" % [title, ", ".join(titles)], "bubble_add_task_set_tab_to_title")
	else:
		bubble_add_task_set_tab_to_index(tabs, index, description)


## Creates a task that waits for the user to select a tab containing a specific control.
## This is useful when you have a reference to a control inside a tab, but don't know
## its index or title.
##
## Parameters:
## - control: The Control that's a direct child of a TabContainer
## - description: Optional custom task description. If empty, inherits the description
##   from bubble_add_task_set_tab_to_index
func bubble_add_task_set_tab_by_control(control: Control, description := "") -> void:
	if control == null or (control != null and not control.get_parent() is TabContainer):
		warn("[b]'control(=%s)'[/b] is 'null' or parent is not TabContainer." % [control], "bubble_add_task_set_tab_to_title")
		return

	var tab_container: TabContainer = control.get_parent()
	var index := find_tabs_control(tab_container, control)
	var tabs := tab_container.get_tab_bar()
	bubble_add_task_set_tab_to_index(tabs, index, description)


## Creates a task that waits for the user to select a specific tab in the TileSet editor.
## This is specifically for guiding users through the TileSet editor interface, which has
## tabs for different tileset editing features.
##
## Parameters:
## - control: The control in the TileSet editor tabs that needs to be shown
## - description: Optional custom task description. If empty, inherits the description
##   from bubble_add_task_set_tab_to_index
func bubble_add_task_set_tileset_tab_by_control(control: Control, description := "") -> void:
	var index := interface.tileset_panels.find(control)
	if index == -1:
		warn("[b]'control(=%s)'[/b] must be found in '[b]interface.tilset_controls[/b]'" % [control], "bubble_add_task_set_tileset_tab_by_control")
	else:
		bubble_add_task_set_tab_to_index(interface.tileset_tabs, index, description)


## Creates a task that waits for the user to select a specific tab in the TileMap editor.
## This is for guiding users through the TileMap editor interface, which has
## special tabs for terrains etc.
##
## Parameters:
## - control: The control in the TileMap editor tabs that needs to be shown
## - description: Optional custom task description. If empty, inherits the description
##   from bubble_add_task_set_tab_to_index
func bubble_add_task_set_tilemap_tab_by_control(control: Control, description := "") -> void:
	var index := interface.tilemap_panels.find(control)
	if index == -1:
		warn("[b]'control(=%s)'[/] must be found in '[b]interface.tilmap_controls[/b]'" % [control], "bubble_add_task_set_tilemap_tab_by_control")
	else:
		bubble_add_task_set_tab_to_index(interface.tilemap_tabs, index, description)


## Creates a task that waits for the user to select specific nodes in the Scene Dock.
##
## Parameters:
## - node_paths: Array of paths to nodes that need to be selected
## - description_override: Optional custom task description. If empty, automatically generates
##   a description like "Select the [NodeName] node(s) in the Scene Dock."
func bubble_add_task_select_nodes_by_path(node_paths: Array[String], description_override := "") -> void:
	var description := description_override
	if description.is_empty():
		description = gtr("Select the %s %s in the [b]Scene Dock[/b].") % [", ".join(node_paths.map(func(s: String) -> String: return "[b]%s[/b]" % s.get_file())), "node" if node_paths.size() == 1 else "nodes"]
	bubble_add_task(
		description,
		1,
		func task_select_node(_task: Task) -> int:
			var scene_root := EditorInterface.get_edited_scene_root()
			var nodes := get_scene_nodes_by_path(node_paths)
			nodes.sort_custom(sort_ascending_by_path)
			var selected_nodes := EditorInterface.get_selection().get_selected_nodes()
			selected_nodes.sort_custom(sort_ascending_by_path)
			return 1 if nodes == selected_nodes else 0
	)


## Creates a task that waits for the user to set multiple Range controls to specific values.
## This is useful for teaching users how to use sliders, spinboxes, and other numeric input
## controls for settings like grid size, snap values, etc.
##
## Parameters:
## - ranges: Dictionary mapping Range controls to their target values
## - label_text: The label to show in the task description (e.g., "Grid Size")
## - description: Optional custom task description. If empty, automatically generates
##   a description like "Set [label_text] to [values]"
func bubble_add_task_set_ranges(ranges: Dictionary, label_text: String, description := "") -> void:
	var controls := ranges.keys()
	if controls.any(func(n: Node) -> bool: return not n is Range):
		var classes := controls.map(func(x: Node) -> String: return x.get_class())
		warn("Not all 'ranges' are of type 'Range' [b]'[%s]'[/b]" % [classes], "bubble_add_task_set_range_value")
	else:
		if description.is_empty():
			description = gtr(
				"""Set [b]%s[/b] to [code]%s[/code]"""
				) % [
					label_text,
					"x".join(ranges.keys().map(func(r: Range) -> String: return str(snappedf(ranges[r], r.step)))),
				]
		bubble_add_task(
			description,
			1,
			func set_ranges(_task: Task) -> int:
				return 1 if ranges.keys().all(func(r: Range) -> bool: return r.value == ranges[r]) else 0,
		)


## Creates a task that waits for the user to set a property of a node to a specific value.
## This is useful for teaching users how to modify node properties in the Inspector dock,
## like changing a sprite's texture, a control's size, or a body's collision layers.
##
## Parameters:
## - node_name: The name of the node whose property needs to be modified
## - property_name: The name of the property to change (e.g., "position", "texture")
## - property_value: The target value for the property
## - description: Optional custom task description. If empty, automatically generates
##   a description like "Set [NodeName]'s [PropertyName] property to [Value]"
func bubble_add_task_set_node_property(node_name: String, property_name: String, property_value: Variant, description := "") -> void:
	if description.is_empty():
		description = gtr("""Set [b]%s[/b]'s [b]%s[/b] property to [b]%s[/b]""") % [node_name, property_name.capitalize(), str(property_value).get_file()]
	bubble_add_task(description, 1, func set_node_property(_task: Task) -> int:
		var scene_root := EditorInterface.get_edited_scene_root()
		var node := scene_root if node_name == scene_root.name else scene_root.find_child(node_name)
		if node == null:
			return 0

		var node_property := node.get(property_name)
		var is_equal := false
		if (
			node_property is Vector2 or
			node_property is Vector2i or
			node_property is Vector3 or
			node_property is Vector3i or
			node_property is Vector4 or
			node_property is Vector4i or
			node_property is Rect2 or
			node_property is Transform2D or
			node_property is Plane or
			node_property is Quaternion or
			node_property is AABB or
			node_property is Basis or
			node_property is Transform3D or
			node_property is Color
		):
			is_equal = node_property.is_equal_approx(property_value)
		elif node_property is float:
			is_equal = is_equal_approx(node_property, property_value)
		elif node_property is Node:
			is_equal = node_property == get_scene_node_by_path(property_value)
		else:
			is_equal = node_property == property_value

		var result := 1 if is_equal else 0
		if mouse != null:
			mouse.visible = result == 0
		return result
	)


## Creates a task that waits for the user to open a specific scene.
##
## Parameters:
## - path: The file path to the scene that needs to be opened
## - description: Optional custom task description. If empty, automatically generates
##   a description like "Open the scene [SceneName]"
func bubble_add_task_open_scene(path: String, description := "") -> void:
	if description.is_empty():
		description = gtr("""Open the scene [b]%s[/b]""") % path.get_file()
	bubble_add_task(description, 1, func open_scene(_task: Task) -> int:
		var current_tab := interface.main_screen_tabs.current_tab
		var current_tab_title = interface.main_screen_tabs.get_tab_title(current_tab)
		return 1 if path in EditorInterface.get_open_scenes() and current_tab_title == path.get_file().get_basename() else 0
	)


## Creates a task that waits for the user to expand a property in the Inspector dock.
##
## Parameters:
## - property_name: The name of the property that needs to be expanded
## - description: Optional custom task description. If empty, automatically generates
##   a description like "Expand the property [PropertyName] in the Inspector"
func bubble_add_task_expand_inspector_property(property_name: String, description := "") -> void:
	if description.is_empty():
		description = gtr("""Expand the property [b]%s[/b] in the [b]Inspector[/b]""") % property_name.capitalize()
	bubble_add_task(description, 1, func expand_property(_task: Task) -> int:
		var result := 0
		var properties := interface.inspector_editor.find_children("", "EditorProperty", true, false)
		for property: EditorProperty in properties:
			if property.is_class("EditorPropertyResource") and property.get_edited_property() == property_name and property.get_child_count() > 1:
				result = 1
		return result
	)

## Used to tell [method bubble_add_task_node_to_guide] to check if the node position perfectly matches the guide's position or if it's just in the guide box's bounding box.
enum Guide3DCheckMode {
	## The node's position must be the same as the guide's position, or within a small margin of error.
	POSITION,
	## The node's position must be within the guide box's bounding box.
	IN_BOUNDING_BOX
}

## Parameters to add a task to move a node to a specific position. The location to move to is represented by a transparent guide box.
## Used by the function [method bubble_add_task_node_to_guide].
class Guide3DTaskParameters:
	## The name of the node to check.
	var node_name: String
	var global_position: Vector3
	## The offset of the guide box relative to the node's position.
	## This is useful when the checked node's origin is not at the center of the object.
	var box_offset := Vector3.ZERO
	## The size of the guide box in meters.
	var box_size := Vector3.ONE
	## The mode to check the node's position. See [enum Guide3DCheckMode] for more information.
	var check_mode: Guide3DCheckMode = Guide3DCheckMode.POSITION
	## The margin of error to check the node's position, in meters. Only used when [member check_mode] is set to [constant Guide3DCheckMode.POSITION]
	var position_margin := 0.1
	## The description of the task. If not set, the function generates the description automatically.
	var description_override := ""

	func _init(p_node_name: String, p_global_position: Vector3, p_check_mode := Guide3DCheckMode.POSITION) -> void:
		self.node_name = p_node_name
		self.global_position = p_global_position
		self.check_mode = p_check_mode


## Adds a task to move a given node to a specific position or within a box. The location to move to is represented by a transparent guide box.
func bubble_add_task_node_to_guide(parameters: Guide3DTaskParameters) -> void:
	if parameters.description_override.is_empty():
		parameters.description_override = gtr("""Move [b]%s[/b] inside the guide box""") % parameters.node_name

	queue_command(func() -> void:
		var scene_root := EditorInterface.get_edited_scene_root()
		var guide := Guide3DPackedScene.instantiate()
		scene_root.add_child(guide)
		guides[parameters.node_name] = guide
		guide.global_position = parameters.global_position
		guide.box_offset = parameters.box_offset
		guide.size = parameters.box_size
		guide.owner = scene_root
		guide.name = "GDTourGuide"
		guide.set_meta(&"_edit_lock_", true)
	)
	bubble_add_task(parameters.description_override, 1, func node_to_guide(_task: Task) -> int:
		var scene_root := EditorInterface.get_edited_scene_root()
		var node: Node3D = null
		if parameters.node_name == scene_root.name:
			node = scene_root
		else:
			node = scene_root.find_child(parameters.node_name)

		var guide: Guide3D = guides.get(parameters.node_name, null)
		var does_match := node != null and guide != null
		if not does_match:
			return 0

		if parameters.check_mode == Guide3DCheckMode.POSITION:
			does_match = does_match and node.global_position.distance_to(guide.global_position) < parameters.position_margin
		elif parameters.check_mode == Guide3DCheckMode.IN_BOUNDING_BOX:
			var aabb := guide.get_aabb()
			aabb.position += guide.global_position
			does_match = does_match and aabb.has_point(node.global_position)

		return 1 if does_match else 0
	)


## Creates a task that waits for the user to instantiate a scene as a child of a specific node.
##
## Parameters:
## - file_path: The file path to the scene that needs to be instantiated
## - node_name: The name the instantiated node should have
## - parent_node_name: The name of the node that should be the parent of the instantiated scene
## - description: Optional custom task description. If empty, automatically generates
##   a description like "Instantiate the [SceneName] scene as a child of [ParentName]"
func bubble_add_task_instantiate_scene(file_path: String, node_name: String, parent_node_name: String, description := "") -> void:
	if description.is_empty():
		description = gtr("Instantiate the [b]%s[/b] scene as a child of [b]%s[/b]") % [file_path.get_file(), parent_node_name]
	bubble_add_task(
		description,
		1,
		func instantiate_platform_goal(_task: Task) -> int:
			var scene_root := EditorInterface.get_edited_scene_root()
			var parent := scene_root if parent_node_name == scene_root.name else scene_root.find_child(parent_node_name)
			var node := parent.get_node_or_null(node_name)
			var result := 1 if node != null and node.scene_file_path == file_path else 0
			if mouse != null:
				mouse.visible = result == 0
			return result
	)


## Creates a task that waits for the user to focus the camera on a specific node in the 3D view.
##
## Parameters:
## - node_name: The name of the node to focus on
## - description: Optional custom task description. If empty, automatically generates
##   a description like "Focus the [NodeName] node"
func bubble_add_task_focus_node(node_name: String, description := "") -> void:
	if description.is_empty():
		description = gtr("""Focus the [b]%s[/b] node""" % node_name)
	bubble_add_task(
		description,
		1,
		func focus_camera_task(task: Task) -> int:
			var scene_root := EditorInterface.get_edited_scene_root()
			var node := scene_root if node_name == scene_root.name else scene_root.find_child(node_name)
			var selected_nodes := EditorInterface.get_selection().get_selected_nodes()
			var is_node_selected := node in selected_nodes
			var is_focus_on_node := interface.spatial_editor_surfaces.any(control_has_focus) and Input.is_action_just_pressed("tour_f")
			return 1 if task.is_done() or is_node_selected and is_focus_on_node else 0
	)


## Moves and anchors the bubble relative to the given control.
## You can optionally set a margin and an offset to fine-tune the bubble's position.
## This allows positioning the bubble UI near relevant elements in the editor to guide the user's
## attention to specific parts of the interface.
##
## Parameters:
## - control: The Control to anchor the bubble to
## - at: The anchor position (use the Bubble.At enum) relative to the control
## - margin: The distance between the bubble and the control in pixels
## - offset: Additional pixel offset from the anchored position
func bubble_move_and_anchor(control: Control, at := Bubble.At.CENTER, margin := 16.0, offset := Vector2.ZERO) -> void:
	queue_command(func() -> void: bubble.move_and_anchor(control, at, margin, offset))


## Places the avatar on the given side of the bubble.
## The avatar is a mascot that guides the user through the tour.
##
## Parameters:
## - at: The position to place the avatar (use the Bubble.AvatarAt enum)
func bubble_set_avatar_at(at: Bubble.AvatarAt) -> void:
	queue_command(func() -> void: bubble.set_avatar_at(at))


## Changes the minimum size of the bubble, scaled by the editor scale setting.
## This is useful to have the bubble take the same space on different screens.
##
## If you want to set the minimum size for one step_commands only, for example, when using only a title
## you can call this function with a [code]size[/code] of [constant Vector2.ZERO] on the following
## [member step_commands] to let the bubble automatically control its size again.
func bubble_set_minimum_size_scaled(size := Vector2.ZERO) -> void:
	queue_command(func() -> void: bubble.panel_container.set_custom_minimum_size(size * EditorInterface.get_editor_scale()))


## Highlights nodes in the Scene dock by their names.
##
## Parameters:
## - names: Array of node names to highlight
## - button_index: Optional button index for tree items that have buttons or icons, to highlight only specify icons (like the visibility icon). Use -1 to highlight the entire item.
## - do_center: If true, center the view on the highlighted items
## - play_flash: If true, plays a flash animation on the highlighted items
func highlight_scene_nodes_by_name(names: Array[String], button_index := -1, do_center := true, play_flash := true) -> void:
	queue_command(overlays.highlight_scene_nodes_by_name, [names, button_index, do_center, play_flash])


## Highlights nodes in the Scene dock by their paths.
## This is more precise than highlighting by name when there are nodes with the same name.
##
## Parameters:
## - paths: Array of node paths to highlight
## - button_index: Optional button index for tree items that have buttons (-1 for entire item)
## - do_center: If true, center the view on the highlighted items
## - play_flash: If true, plays a flash animation on the highlighted items
func highlight_scene_nodes_by_path(paths: Array[String], button_index := -1, do_center := true, play_flash := true) -> void:
	queue_command(overlays.highlight_scene_nodes_by_path, [paths, button_index, do_center, play_flash])


## Highlights files or directories in the FileSystem dock.
## This helps users locate files they need to work with, like scenes or scripts.
##
## Parameters:
## - paths: Array of file or directory paths to highlight
## - do_center: If true, center the view on the highlighted items
## - play_flash: If true, plays a flash animation on the highlighted items
func highlight_filesystem_paths(paths: Array[String], do_center := true, play_flash := true) -> void:
	queue_command(overlays.highlight_filesystem_paths, [paths, do_center, play_flash])


## Expands a specific resource property in the Inspector dock if this property
## has a valid resource assigned. This is useful when you need to access
## sub-properties of a resource that are hidden when the resource is collapsed
## in the inspector. Call this method with the [code]name[/code] of the resource
## property you want to expand first, then call [method
## highlight_inspector_properties] to highlight the expanded property.
##
## Parameters:
## - resource_property_name: The name of the resource property to expand
func expand_inspector_resource(resource_property_name: StringName) -> void:
	queue_command(overlays.expand_inspector_resource, [resource_property_name])


## Highlights properties in the Inspector dock.
## This helps users find specific properties they need to modify in the currently selected node.
## [b]WARNING[/b]: It does not support section-like properties with a checkbox (in Godot 4.5+). Use
## [method highlight_inspector_section_property] for that.
##
## Parameters:
## - names: Array of property names to highlight
## - do_center: If true, center the view on the highlighted properties
## - play_flash: If true, plays a flash animation on the highlighted properties
func highlight_inspector_properties(names: Array[StringName], do_center := true, play_flash := true) -> void:
	for current_name in names:
		queue_command(overlays.highlight_inspector_property, [current_name, do_center, play_flash])


## Highlights a specific property that is section-like with a checkbox in the Inspector dock.
## These properties are not exposed to the editor API directly, so this method helps find them
## by specifying their first child property names.
##
## Parameters:
## - first_child_names: Array of the first-level child property names of the section property to highlight.
func highlight_inspector_section_properties(first_child_names: Array[StringName], do_center := true, play_flash := true) -> void:
	for current_name in first_child_names:
		queue_command(overlays.highlight_inspector_section_property, [current_name, do_center, play_flash])


## Highlights signals in the Node dock's Signals tab.
## This helps users locate specific signals when working with signal connections.
##
## Parameters:
## - paths: Array of signal paths to highlight (in format "node_name/signal_name")
## - do_center: If true, center the view on the highlighted signals
## - play_flash: If true, plays a flash animation on the highlighted signals
func highlight_signals(paths: Array[String], do_center := true, play_flash := true) -> void:
	queue_command(overlays.highlight_signals, [paths, do_center, play_flash])


## Highlights code in the script editor.
## This draws attention to specific lines of code in the currently edited script.
##
## Parameters:
## - start: The starting line number to highlight
## - end: The ending line number to highlight (if 0, only highlights the start line)
## - caret: The line to place the text cursor on (if 0, places it at the start line)
## - do_center: If true, center the view on the highlighted code
## - play_flash: If true, play a flash animation on the highlighted code
func highlight_code(start: int, end := 0, caret := 0, do_center := true, play_flash := false) -> void:
	queue_command(overlays.highlight_code, [start, end, caret, do_center, play_flash])


## Highlights UI controls in the editor.
## This draws attention to specific UI elements like buttons, panels, or fields.
##
## Parameters:
## - controls: Array of Control nodes to highlight
## - play_flash: If true, play a flash animation on the highlighted controls
func highlight_controls(controls: Array[Control], play_flash := false) -> void:
	queue_command(overlays.highlight_controls, [controls, play_flash])


## Highlights a tab in a TabBar or TabContainer by its index.
##
## Parameters:
## - tabs: The TabBar or TabContainer control containing the tabs
## - index: The index of the tab to highlight (-1 for all tabs)
## - play_flash: If true, play a flash animation on the highlighted tab
func highlight_tabs_index(tabs: Control, index := -1, play_flash := true) -> void:
	queue_command(overlays.highlight_tab_index, [tabs, index, play_flash])


## Highlights a tab in a TabBar or TabContainer by its title.
##
## Parameters:
## - tabs: The TabBar or TabContainer control containing the tabs
## - title: The title of the tab to highlight
## - play_flash: If true, play a flash animation on the highlighted tab
func highlight_tabs_title(tabs: Control, title: String, play_flash := true) -> void:
	queue_command(overlays.highlight_tab_title, [tabs, title, play_flash])


## Highlights a rectangular area in the 2D viewport.
## This draws attention to a specific area in the scene being edited, like a node's
## position or a region the user needs to work with.
##
## Parameters:
## - rect: The rectangle area to highlight in the 2D viewport
## - play_flash: If true, play a flash animation on the highlighted area
func highlight_canvas_item_editor_rect(rect: Rect2, play_flash := false) -> void:
	queue_command(func() -> void:
		var rect_getter := func() -> Rect2:
			var scene_root := EditorInterface.get_edited_scene_root()
			if scene_root == null:
				return Rect2()
			return interface.canvas_item_editor_viewport.get_global_rect().intersection(
				scene_root.get_viewport().get_screen_transform() * rect
			)
		overlays.add_highlight_to_control(interface.canvas_item_editor_viewport, rect_getter, play_flash),
	)


## Highlights an item in an ItemList control in the TileMap editor.
## This is useful for drawing attention to specific tiles or patterns in the tileset.
##
## Parameters:
## - item_list: The ItemList control containing the items
## - item_index: The index of the item to highlight
## - play_flash: If true, play a flash animation on the highlighted item
func highlight_tilemap_list_item(item_list: ItemList, item_index: int, play_flash := true) -> void:
	queue_command(overlays.highlight_tilemap_list_item.bind(item_list, item_index, play_flash))


## Highlights a 2D, rectangular region of the 3D viewport defined by two 3D
## corner points projected back onto the viewport.
## This does not highlight an area in the 3D view, but rather highlights
## the area in the 2D view that corresponds to the 3D region.
##
## Parameters:
## - start: The starting corner position of the region in 3D space
## - end: The ending corner position of the region in 3D space
## - index: The index of the camera view to use in split-view mode
## - play_flash: If true, play a flash animation on the highlighted region
func highlight_spatial_editor_camera_region(start: Vector3, end: Vector3, index := 0, play_flash := false) -> void:
	if index < 0 or index > interface.spatial_editor_cameras.size():
		warn("[b]'index(=%d)'[/b] not in [b]'range(0, interface.spatial_editor_cameras.size()(=%d))'[/b]." % [index, interface.spatial_editor_cameras.size()], "highlight_spatial_editor_camera_region")
		return
	var camera := interface.spatial_editor_cameras[index]
	queue_command(func() -> void:
		if camera.is_position_behind(start) or camera.is_position_behind(end):
			return
		var rect_getter := func() -> Rect2:
			var s := camera.unproject_position(start)
			var e := camera.unproject_position(end)
			return interface.spatial_editor.get_global_rect().intersection(
				camera.get_viewport().get_screen_transform() * Rect2(Vector2(min(s.x, e.x), min(s.y, e.y)), (e - s).abs())
			)
		overlays.add_highlight_to_control(interface.spatial_editor, rect_getter, play_flash),
	)


## Highlights the material preview in the Inspector dock.
##
## Note: Currently limited to finding and highlighting only the "material" property.
## FIXME: follow scroll and parametrize to highlight a preview other than "material" property.
func highlight_material_preview() -> void:
	queue_command(func highlight_preview() -> void:
		interface.inspector_editor.scroll_vertical = 0
		var properties := interface.inspector_editor.find_children("", "EditorProperty", true, false)
		for property: EditorProperty in properties:
			if property.is_class("EditorPropertyResource") and property.get_edited_property() == "material" and property.get_child_count() > 1:
				var controls: Array[Control] = []
				controls.assign(property.find_children("", "MaterialEditor", true, false))
				overlays.highlight_controls(controls)
	)


## Moves an animated mouse cursor from one position to another using global
## coordinates.
##
## Parameters:
## - from: The starting position in global coordinates
## - to: The target position in global coordinates
func mouse_move_by_position(from: Vector2, to: Vector2) -> void:
	queue_command(func() -> void:
		ensure_mouse()
		mouse.add_move_operation(func() -> Vector2: return from, func() -> Vector2: return to)
	)


## Moves an animated mouse cursor from one position to another using callable
## functions that return positions. This is useful when target positions need to
## be calculated at runtime.
##
## Parameters:
## - from: A callable that returns the starting position
## - to: A callable that returns the target position
func mouse_move_by_callable(from: Callable, to: Callable) -> void:
	queue_command(func() -> void:
		ensure_mouse()
		await delay_process_frame()
		mouse.add_move_operation(from, to),
	)


## Displays an animated mouse pointer clicking and dragging from one position to
## another using callable functions.
##
## Parameters:
## - from: The starting position in global coordinates
## - to: The target position in global coordinates
## - press_texture: Optional texture to display during the press action
func mouse_click_drag_by_position(from: Vector2, to: Vector2, press_texture: CompressedTexture2D = null) -> void:
	queue_command(func() -> void:
		ensure_mouse()
		mouse.add_press_operation(press_texture)
		mouse.add_move_operation(func() -> Vector2: return from, func() -> Vector2: return to)
		mouse.add_release_operation()
	)


## Displays an animated mouse pointer clicking and dragging from one position to another using callable functions.
## This is useful when the positions need to be calculated at runtime.
##
## Parameters:
## - from: A callable that returns the starting position
## - to: A callable that returns the target position
## - press_texture: Optional texture to display during the press action
func mouse_click_drag_by_callable(from: Callable, to: Callable, press_texture: CompressedTexture2D = null) -> void:
	queue_command(func() -> void:
		ensure_mouse()
		mouse.add_press_operation(press_texture)
		mouse.add_move_operation(from, to)
		mouse.add_release_operation()
	)


## Makes an animated mouse pointer bounce at a specific position to draw
## attention to it.
##
## Parameters:
## - loops: Number of times to bounce the mouse pointer in a row
## - at: A callable that returns the position to bounce at
func mouse_bounce(loops := 2, at := Callable()) -> void:
	queue_command(func() -> void:
		ensure_mouse()
		await delay_process_frame()
		mouse.add_bounce_operation(loops, at),
	)


## Animates an animated mouse pointer pressing the mouse button down.
## Used as part of multi-step mouse interactions.
##
## Parameters:
## - press_texture: Optional texture to display during the press action
func mouse_press(press_texture: CompressedTexture2D = null) -> void:
	queue_command(func() -> void:
		ensure_mouse()
		mouse.add_press_operation(press_texture)
	)


## Animates a mouse pointer doing a release action.
## Used as part of multi-step mouse interactions, typically after [method mouse_press] and moving the pointer.
func mouse_release() -> void:
	queue_command(func() -> void:
		ensure_mouse()
		mouse.add_release_operation()
	)


## Animates a mouse pointer clicking the mouse (press and release) a specified number of times.
##
## Parameters:
## - loops: Number of times to click the mouse (default: 1)
func mouse_click(loops := 1) -> void:
	queue_command(func() -> void:
		ensure_mouse()
		mouse.add_click_operation(loops)
	)


## Ensures that the mouse pointer node exists in the scene.
## If no mouse pointer exists, creates and adds one to the viewport.
func ensure_mouse() -> void:
	if mouse == null:
		# We don't preload to avoid errors on a project's first import, to distribute the tour to
		# schools for example.
		var MousePackedScene := load("res://addons/godot_tours/mouse/mouse.tscn")
		mouse = MousePackedScene.instantiate()
		interface.base_control.get_viewport().add_child(mouse)


## Removes the mouse pointer node from the scene if it exists.
## This is typically called during cleanup when a tour ends.
func clear_mouse() -> void:
	if mouse != null:
		mouse.queue_free()
		mouse = null


## Starts the mouse pointer animation.
## This function ensures the mouse pointer exists and then starts its animation.
func play_mouse() -> void:
	ensure_mouse()
	mouse.play()


## Finds and returns a node in the current scene by its path.
##
## Parameters:
## - path: The path of the node to find, relative to the scene root
##
## Returns: The found node, or null if no node is found at the given path
func get_scene_node_by_path(path: String) -> Node:
	var result: Node = null
	var root := EditorInterface.get_edited_scene_root()
	if root.name == path:
		result = root
	else:
		for child in root.find_children("*"):
			if child.owner == root and root.name.path_join(root.get_path_to(child)) == path:
				result = child
				break
	return result


## Finds and returns multiple nodes in the current scene by their paths.
##
## Parameters:
## - paths: Array of node paths to find, relative to the scene root
##
## Returns: Array of found nodes. If a path doesn't match any node, it's not included in the result.
func get_scene_nodes_by_path(paths: Array[String]) -> Array[Node]:
	var result: Array[Node] = []
	for path in paths:
		var node := get_scene_node_by_path(path)
		if node != null:
			result.push_back(node)
	return result


## Finds and returns all nodes in the current scene whose names start with a specific prefix.
##
## Parameters:
## - prefix: The name prefix to search for
##
## Returns: Array of nodes whose names start with the given prefix
func get_scene_nodes_by_prefix(prefix: String) -> Array[Node]:
	var result: Array[Node] = []
	var root := EditorInterface.get_edited_scene_root()
	result.assign(root.find_children("%s*" % prefix).filter(func(n: Node) -> bool: return n.owner == root))
	return result


## Finds the center position of a tree item identified by its path.
##
## Parameters:
## - tree: The Tree control to search in
## - path: The path of the tree item to find
## - button_index: Optional index of a button within the tree item (-1 for the entire item)
##
## Returns: The global center position of the tree item, or Vector2.ZERO if not found
func get_tree_item_center_by_path(tree: Tree, path: String, button_index := -1) -> Vector2:
	var result := Vector2.ZERO
	var root := tree.get_root()
	if root == null:
		return result
	for item in Utils.filter_tree_items(root, func(ti: TreeItem) -> bool: return path == Utils.get_tree_item_path(ti)):
		var rect := tree.get_global_transform() * tree.get_item_area_rect(item, 0, button_index)
		result = rect.get_center()
		break
	return result


## Finds the center position of a tree item identified by its name.
##
## Parameters:
## - tree: The Tree control to search in
## - name: The name of the tree item to find
##
## Returns: The global center position of the tree item, or Vector2.ZERO if not found
func get_tree_item_center_by_name(tree: Tree, name: String) -> Vector2:
	var result := Vector2.ZERO
	var root := tree.get_root()
	if root == null:
		return result

	var item := Utils.find_tree_item_by_name(tree, name)
	var rect := tree.get_global_transform() * tree.get_item_area_rect(item, 0)
	result = rect.get_center()
	return result


## Calculates the global rectangle (in pixels) covered by a TileMap.
##
## Parameters:
## - tilemap_node: The TileMap node to calculate the rectangle for
##
## Returns: A Rect2 representing the global area covered by the TileMap in pixels
func get_tilemap_global_rect_pixels(tilemap_node: TileMap) -> Rect2:
	var rect := Rect2(tilemap_node.get_used_rect())
	rect.size *= Vector2(tilemap_node.tile_set.tile_size)
	rect.position = tilemap_node.global_position
	return rect


## Finds the center position of a property in the Inspector dock.
##
## Parameters:
## - name: The name of the property to find in the Inspector
##
## Returns: The global center position of the property control, or Vector2.ZERO if not found
func get_inspector_property_center(name: String) -> Vector2:
	var result := Vector2.ZERO
	var properties := interface.inspector_editor.find_children("", "EditorProperty", true, false)
	var predicate_first := func predicate_first(p: EditorProperty) -> bool: return p.get_edited_property() == name
	for property: EditorProperty in properties.filter(predicate_first):
		result = property.get_global_rect().get_center()
		break
	return result



## Returns the global center position of a Control node.
##
## Parameters:
## - control: The Control node to get the center position of
##
## Returns: The global center position of the control
func get_control_global_center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


## Finds the full path of a node by its name in the currently edited scene.
##
## Parameters:
## - node_name: The name of the node to find
##
## Returns: The full path of the node relative to the scene root, or an empty string if not found
func node_find_path(node_name: String) -> String:
	var root_node := EditorInterface.get_edited_scene_root()
	var found_node := root_node.find_child(node_name)
	if found_node == null:
		return ""
	var path_from_root: String = root_node.name.path_join(root_node.get_path_to(found_node))
	return path_from_root


## Finds the index of a tab in a TabBar by its title.
##
## Parameters:
## - tabs: The TabBar to search in
## - title: The title of the tab to find
##
## Returns: The index of the tab with the matching title, or -1 if not found
func find_tabs_title(tabs: TabBar, title: String) -> int:
	var result := -1
	for index in range(tabs.tab_count):
		var tab_title: String = tabs.get_tab_title(index)
		if title == tab_title or tabs == interface.main_screen_tabs and "%s(*)" % title == tab_title:
			result = index
			break
	return result


## Finds the index of a tab in a TabContainer by its control.
##
## Parameters:
## - tab_container: The TabContainer to search in
## - control: The control to find in the TabContainer
##
## Returns: The index of the tab containing the control, or -1 if not found
func find_tabs_control(tab_container: TabContainer, control: Control) -> int:
	var result := -1
	var predicate := func(idx: int) -> bool: return tab_container.get_tab_control(idx) == control
	for tab_idx in range(tab_container.get_tab_count()).filter(predicate):
		result = tab_idx
		break
	return result


## Toggles the visibility of all the tour-specific nodes: overlays, bubble, and mouse.
func toggle_visible(is_visible: bool) -> void:
	for node in [bubble, mouse]:
		if node != null:
			node.visible = is_visible
	overlays.toggle_dimmers(is_visible)


## A predicate function that always returns false.
## Used as a default for task checks that should never succeed.
func noop_error_predicate(_task: Task) -> bool:
	return false


## Returns the translation of a given String from English to the currently set
## editor language. Requires translation files to be included with the tour.
func gtr(src_message: StringName, context: StringName = "") -> String:
	return translation_service.get_tour_message(src_message, context)


## Returns the plural translation of a given String from English to the currently set
## editor language. Requires translation files to be included with the tour.
func gtr_n(src_message: StringName, src_plural_message: StringName, n: int, context: StringName = "") -> String:
	return translation_service.get_tour_plural_message(src_message, src_plural_message, n, context)


## Returns the path of a translated resource (like an image used for a specific language)
## based on the current editor language.
func ptr(resource_path: String) -> String:
	return translation_service.get_resource_path(resource_path)


func warn(msg: String, func_name: String) -> void:
	print_rich(WARNING_MESSAGE % [msg, func_name, steps.size()])


## Generates a BBCode [code][img][/code] tag for a Godot editor icon, scaling the image size based on the editor.
## scale.
func bbcode_generate_icon_image_string(image_filepath: String) -> String:
	const BASE_SIZE_PIXELS := 24
	var size := BASE_SIZE_PIXELS * EditorInterface.get_editor_scale()
	return "[img=%sx%s]" % [size, size] + image_filepath + "[/img]"


## Generates a BBCode [code][img][/code] tag for a Godot editor icon by name,
## scaling the image size based on the editor scale.
## The icon name must match the name of the SVG file in the [code]res://addons/godot_tours/bubble/assets/icons[/code] directory, without the extension.
## Example: For Node2D.svg, the icon name is "Node2D"
func bbcode_generate_icon_image_by_name(icon_name: String) -> String:
	var path := "res://addons/godot_tours/bubble/assets/icons/".path_join(icon_name + ".svg")
	assert(FileAccess.file_exists(path), "Icon file not found: %s" % path)
	return bbcode_generate_icon_image_string(path)


## Wraps the text in a [code][font_size][/code] BBCode tag, scaling the value of size_pixels based on the editor
## scale.
func bbcode_wrap_font_size(text: String, size_pixels: int) -> String:
	var size_scaled := size_pixels * EditorInterface.get_editor_scale()
	return "[font_size=%s]" % size_scaled + text + "[/font_size]"


## Waits for a specified number of frames to pass.
## This is a coroutine that can be used with `await` to introduce delays.
## You can use this for automated testing or occasionally to work around editor
## limitations like a process running in a thread that doesn't provide a signal
## when it finishes but reliably updates after a certain number of frames.
##
## Parameters:
## - frames: The number of frames to wait for (default: 1)
func delay_process_frame(frames := 1) -> void:
	for _frame in range(frames):
		await interface.base_control.get_tree().process_frame


## Checks if a control has keyboard focus.
##
## Parameters:
## - c: The Control node to check
##
## Returns: True if the control has focus, false otherwise
func control_has_focus(c: Control) -> bool: return c.has_focus()


## Compares two nodes by their paths for sorting in ascending order.
##
## Parameters:
## - a: First node to compare
## - b: Second node to compare
##
## Returns: True if node a's path comes before node b's path alphabetically
func sort_ascending_by_path(a: Node, b: Node) -> bool: return str(a.get_path()) < str(b.get_path())


## Closes the bottom panel in the editor by setting the output button to unpressed.
func _close_bottom_panel() -> void:
	interface.bottom_output_button.button_pressed = false
