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
## Use the utility function [method queue_command] to create a [code]Command[/code] object and add it
## to the step.
## [br][br]
## To design a tour, override the [method _build] function and write all your tour steps in it:
## [br][br]
## 1. Call API functions to queue commands required for your step. [br]
## 2. Call [method complete_step] to finalize the current step and start a new one.
## [br][br]
## See the provided demo tour for an example.
extends Node

## Emitted when the tour moves to the next or previous step. See [member steps].
signal step_changed(step_index: int)
## Emitted when the user completes the last step.
signal ended
## Emitted when the user closes the tour.
signal closed


## Represents one command to execute during a step. All commands are executed in the order they
## are added. Use [method queue_command] to create a [code]Command[/code] object and add it to
## the current step, then call [method complete_step] to finalize the step and start a new one.
class Command:
	var callable := func() -> void: pass
	var parameters := []

	func _init(callable: Callable, parameters := []) -> void:
		self.callable = callable
		self.parameters = parameters

	func force() -> void:
		await callable.callv(parameters)


## Represents current persistent state of the bubble, which can be configured in one step and then
## cross-over into the next. It is tracked this way so stepping backwards correctly restores
## whatever was valid for the previous step, even if the previous step didn't set it directly.
class BubbleState:
	var minimal_size: Vector2 = BUBBLE_MIN_SIZE
	var avatar_at: Bubble.AvatarAt = Bubble.AvatarAt.LEFT


enum Direction { BACK = -1, NEXT = 1 }

const BUBBLE_MIN_SIZE := Vector2(520.0, 0.0)

const DEFAULT_BOOKEND_MINSIZE := Vector2(496.0, 0.0)
const DEFAULT_WELCOME_TITLE := "Welcome to Godot!"
const DEFAULT_WELCOME_BUTTON_TEXT := "LET'S GO!"
const DEFAULT_FINALE_TITLE := "Excellent!"
const DEFAULT_FINALE_BUTTON_TEXT := "CONTINUE"
const DEFAULT_FINALE_LAST_TITLE := "Congratulations!"
const DEFAULT_FINALE_LAST_BUTTON_TEXT := "BACK TO MENU"

# External utilities.

const EditorInterfaceAccess := preload("res://addons/gdquest_editor_interface/editor_interface_access.gd")
const EditorNodePoints := EditorInterfaceAccess.Enums.NodePoint

# Internal utilities.

const Utils := preload("utils.gd")

# Tour types.

const Log := preload("log.gd")
const Shortcuts := preload("shortcuts.gd")

const GDTourMetadata := preload("gdtour_metadata.gd")
const Overlays := preload("overlays/overlays.gd")
const Mouse := preload("mouse/mouse.gd")
const Bubble := preload("bubble/bubble_base.gd")
const Task := preload("bubble/lists/task_item.gd")

# Tour components.

const DefaultBubbleScene := preload("bubble/default_bubble.tscn")

const Guide3D := preload("assets/guide_3d.gd")
const Guide3DPackedScene := preload("assets/guide_3d.tscn")

# Runtime data.

var log := Log.new()
var shortcuts := Shortcuts.new()

var overlays: Overlays = null
var mouse: Mouse = null
var bubble: Bubble = null

## Metadata defining this tour.
var tour_metadata: GDTourMetadata.Tour = null
## Flag that indicates if there are more tours following this one.
var tour_is_last: bool = false
## Collection of steps in this tour, each in turn consisting of [Command] objects.
var steps: Array[Array] = []
## Index of the current step command.
var index := -1:
	set = set_index

var _welcome_commands: Array[Command] = []
var _finale_commands: Array[Command] = []
var _step_commands: Array[Command] = []
var _step_bubble_state: BubbleState = BubbleState.new()

var _guides: Dictionary[String, Node] = { }


#region Lifecycle.

func _init(tour_metadata: GDTourMetadata.Tour, overlays: Overlays, tour_is_last: bool = false) -> void:
	name = "Tour"
	self.tour_metadata = tour_metadata
	self.overlays = overlays
	self.tour_is_last = tour_is_last

	Utils.set_tour_translation_domain(self, tour_metadata.id)

	var editor_run_bar := EditorInterfaceAccess.get_node(EditorNodePoints.RUN_BAR)
	editor_run_bar.stop_pressed.connect(_close_bottom_panel)
	var editor_node := EditorInterfaceAccess.get_node(EditorNodePoints.EDITOR_NODE)
	editor_node.scene_changed.connect(_update_scene_guides)

	_build()
	_build_bookends()
	load_bubble()

	if index == -1:
		set_index(0)


## [b]Virtual[/b] method for building the tour's content. Write all your tour steps in it.
## This function is called when the tour is created, after connecting signals and re-applying the
## editor's default layout, which helps avoid many UI edge cases.
func _build() -> void:
	pass


## Generates special bookend steps, to start and end the tour.
func _build_bookends() -> void:
	var layout_root := EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_ROOT)

	var tour_start_func := func() -> void:
		bubble.clear()
		bubble.ensure_minimum_size(DEFAULT_BOOKEND_MINSIZE)
		bubble.move_and_anchor(layout_root, Bubble.At.CENTER)
		bubble.set_avatar_at(Bubble.AvatarAt.PRIME_LEFT)
		bubble.set_bookend_title(DEFAULT_WELCOME_TITLE)
		bubble.set_bookend_button_text(DEFAULT_WELCOME_BUTTON_TEXT)

	var tour_start: Array[Command] = [
		Command.new(_clean_up_step),
		Command.new(tour_start_func),
	]
	steps.push_front(tour_start + _welcome_commands)

	var tour_end_func := func() -> void:
		bubble.clear()
		bubble.ensure_minimum_size(DEFAULT_BOOKEND_MINSIZE)
		bubble.move_and_anchor(layout_root, Bubble.At.CENTER)
		bubble.set_avatar_at(Bubble.AvatarAt.PRIME_LEFT)
		bubble.set_bookend_title(DEFAULT_FINALE_LAST_TITLE if tour_is_last else DEFAULT_FINALE_TITLE)
		bubble.set_bookend_button_text(DEFAULT_FINALE_LAST_BUTTON_TEXT if tour_is_last else DEFAULT_FINALE_BUTTON_TEXT)

	var tour_end: Array[Command] = [
		Command.new(_clean_up_step),
		Command.new(tour_end_func),
	]
	steps.push_back(tour_end + _finale_commands)


## Cleans up resources used by the tour, including removing input actions,
## clearing mouse animation and guides, and freeing the bubble UI.
## Called when the tour is closed or ends.
func clean_up() -> void:
	clear_mouse()
	clear_guides()
	log.clean_up()
	overlays.clean_up()
	if is_instance_valid(bubble):
		bubble.queue_free()


func _clean_up_step() -> void:
	var layout_root := EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_ROOT)

	overlays.clean_up()
	overlays.ensure_control_window_dimmer(layout_root)
	clear_mouse()
	clear_guides()

## Loads and initializes the bubble UI for the tour.
## Frees any existing bubble and instantiates a new one, sets up connections
## to handle navigation, closing, and completing the tour.
##
## Parameters:
## - bubble_scene: Optional custom bubble scene. If null, uses the default
## bubble in the tour system.
func load_bubble(bubble_scene: PackedScene = null) -> void:
	if is_instance_valid(bubble):
		remove_child(bubble)
		bubble.queue_free()
		bubble = null

	if bubble_scene == null:
		bubble_scene = DefaultBubbleScene

	bubble = bubble_scene.instantiate()
	bubble.setup(steps.size())
	add_child(bubble)
	bubble.set_content_translation_domain(tour_metadata.id)

	bubble.prev_step_requested.connect(back)
	bubble.next_step_requested.connect(next)
	bubble.close_requested.connect(close_tour)
	bubble.finish_requested.connect(finish_tour)
	bubble.log_requested.connect(request_log_file)

	step_changed.connect(bubble.set_current_step)


## Toggles the visibility of all the tour-specific nodes: overlays, bubble, and mouse.
func toggle_visible(is_visible: bool) -> void:
	for node in [bubble, mouse]:
		if node != null:
			node.visible = is_visible
	overlays.toggle_dimmers(is_visible)

#endregion


#region Step navigation.

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

	var editor_output_rtl: RichTextLabel = EditorInterfaceAccess.get_node(EditorNodePoints.OUTPUT_DOCK_RICH_TEXT)
	log.info("[step_commands: %d]\n%s" % [value, editor_output_rtl.get_parsed_text()])

	run(steps[value])
	index = clampi(value, 0, step_count - 1)
	step_changed.emit(index)


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
	queue_command(
		func() -> void:
			await delay_process_frame()
			back()
	)


## Waits for the next frame and advances to the next step. Used for automated testing.
func auto_next() -> void:
	queue_command(
		func wait_for_frame_and_advance() -> void:
			await delay_process_frame()
			next()
	)


## Runs all commands in a step sequentially.
## Each command is executed and the function waits for it to complete before moving to the next.
##
## Parameters:
## - current_step: An array of Command objects to execute.
func run(current_step: Array[Command]) -> void:
	for current_command in current_step:
		await current_command.force()


## Closes the tour bubble and ends the tour without confirmation. Normally, triggered by the
## user when they confirm the intention to close the tour.
func close_tour() -> void:
	toggle_visible(false)
	closed.emit()
	clean_up()


## Finishes the tour and closes the bubble. Normally, triggered by the user upon completion of
## the tour's last step.
func finish_tour() -> void:
	toggle_visible(false)
	clean_up()
	await get_tree().process_frame
	ended.emit()

#endregion


#region Core commands.

## Appends a command to the currently edited step. Commands are executed in the order they are added.
## To complete a step and start creating the next one, call [method complete_step].
func queue_command(callable: Callable, parameters := []) -> void:
	_step_commands.push_back(Command.new(callable, parameters))


## Appends a command to the welcome bookend. Can be called at any time in the [method _build] routine.
## Commands are executed in the order they are added.
func queue_welcome_command(callable: Callable, parameters := []) -> void:
	_welcome_commands.push_back(Command.new(callable, parameters))


## Appends a command to the finale bookend. Can be called at any time in the [method _build] routine.
## Commands are executed in the order they are added.
func queue_finale_command(callable: Callable, parameters := []) -> void:
	_finale_commands.push_back(Command.new(callable, parameters))


## Waits for a specified number of frames to pass.
## This is a coroutine that can be used with `await` to introduce delays.
## You can use this for automated testing or occasionally to work around editor
## limitations like a process running in a thread that doesn't provide a signal
## when it finishes but reliably updates after a certain number of frames.
##
## Parameters:
## - frames: The number of frames to wait for (default: 1)
func delay_process_frame(frames := 1) -> void:
	var editor_tree := EditorInterface.get_base_control().get_tree()
	for _frame in range(frames):
		await editor_tree.process_frame


## Completes the current step's commands, adding some more commands to clear the bubble,
## overlays, and the mouse. Then, this function appends the completed step (an array of
## [Command] objects) to the tour.
func complete_step() -> void:
	var current_minsize := _step_bubble_state.minimal_size
	var current_avatar_at := _step_bubble_state.avatar_at

	var step_start_func := func() -> void:
		bubble.clear()
		# Force bubble state at the start of the step. See [BubbleState].
		bubble.ensure_minimum_size(current_minsize)
		bubble.set_avatar_at(current_avatar_at)

	var step_start: Array[Command] = [
		Command.new(_clean_up_step),
		Command.new(step_start_func),
	]
	_step_commands.push_back(Command.new(play_mouse))
	steps.push_back(step_start + _step_commands)
	_step_commands = []

#endregion


#region Bubble commands.

func bubble_set_welcome_title(text: String) -> void:
	queue_welcome_command(func() -> void: bubble.set_bookend_title(text))


func bubble_add_welcome_text(text: Array[String], style: Bubble.BookendTextStyle) -> void:
	queue_welcome_command(func() -> void: bubble.add_bookend_text(text, style))


func bubble_set_welcome_button_text(text: String) -> void:
	queue_welcome_command(func() -> void: bubble.set_bookend_button_text(text))


func bubble_set_finale_title(text: String) -> void:
	queue_finale_command(func() -> void: bubble.set_bookend_title(text))


func bubble_add_finale_text(text: Array[String], style: Bubble.BookendTextStyle) -> void:
	queue_finale_command(func() -> void: bubble.add_bookend_text(text, style))


func bubble_set_finale_button_text(text: String) -> void:
	queue_finale_command(func() -> void: bubble.set_bookend_button_text(text))


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
	queue_command(
		func bubble_add_texture() -> void:
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
## If you want to set the minimum size for one step only, for example, when using only a title
## you can call this function with a [param size] of [constant Vector2.ZERO] on the following
## [member _step_commands] to let the bubble automatically control its size again.
func bubble_set_minimum_size_scaled(size := BUBBLE_MIN_SIZE) -> void:
	_step_bubble_state.minimal_size = size
	queue_command(func() -> void: bubble.ensure_minimum_size(size))

#endregion


#region Task commands.

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
## - setup_callable: Function that is called when the task is being created, allowing extra setup
func bubble_add_task(description: String, repeat: int, repeat_callable: Callable, error_predicate := Callable(), setup_callable := Callable()) -> void:
	queue_command(func() -> void: bubble.add_task(description, repeat, repeat_callable, error_predicate, setup_callable))


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
	description = atr("Press the [b]%s[/b] button.") % text

	var meta_name := "button_pressed_%d_count" % [ button.get_instance_id() ]

	var setup_func := func(task: Task) -> void:
		var button_press_counter := func() -> void:
			var meta_value := task.get_meta(meta_name, 0)
			task.set_meta(meta_name, meta_value + 1)

		button.pressed.connect(button_press_counter)
		task.set_connected_callable(button.pressed, button_press_counter)

	var check_func := func(task: Task) -> int:
		var meta_value := task.get_meta(meta_name, 0)

		return 1 if meta_value > 0 or button.button_pressed else 0

	bubble_add_task(description, 1, check_func, Callable(), setup_func)


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

	const TOGGLE_MAP := { true: "ON", false: "OFF" }
	if description.is_empty():
		var text: String
		if button.text.is_empty():
			text = button.tooltip_text
		else:
			text = button.text
		text = text.replace(".", "")
		description = atr("Turn the [b]%s[/b] button %s.") % [text, TOGGLE_MAP[is_toggled]]

	bubble_add_task(
		description,
		1,
		func(_task: Task) -> int: return 1 if button.button_pressed == is_toggled else 0,
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
	description = atr("Change to the [b]%s[/b] tab.") % [title] if description.is_empty() else description
	bubble_add_task(description, 1, func(_task: Task) -> int: return 1 if index == tabs.current_tab else 0)


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
	# Not a TabContainer with children, so we rely on indices manually.
	var tileset_panels: Array[Control] = [
		EditorInterfaceAccess.get_node(EditorNodePoints.TILE_SET_TILES_PANEL),
		EditorInterfaceAccess.get_node(EditorNodePoints.TILE_SET_PATTERNS_PANEL),
	]

	var index := tileset_panels.find(control)
	if index == -1:
		warn("[b]'control(=%s)'[/] must be one of '[b]TILE_SET_*_PANEL[/b]' nodes" % [control], "bubble_add_task_set_tileset_tab_by_control")
		return

	var tileset_tabs: TabBar = EditorInterfaceAccess.get_node(EditorNodePoints.TILE_SET_DOCK_TABS)
	bubble_add_task_set_tab_to_index(tileset_tabs, index, description)


## Creates a task that waits for the user to select a specific tab in the TileMap editor.
## This is for guiding users through the TileMap editor interface, which has
## special tabs for terrains etc.
##
## Parameters:
## - control: The control in the TileMap editor tabs that needs to be shown
## - description: Optional custom task description. If empty, inherits the description
##   from bubble_add_task_set_tab_to_index
func bubble_add_task_set_tilemap_tab_by_control(control: Control, description := "") -> void:
	# Not a TabContainer with children, so we rely on indices manually.
	var tilemap_panels: Array[Control] = [
		EditorInterfaceAccess.get_node(EditorNodePoints.TILE_MAP_TILES_PANEL),
		EditorInterfaceAccess.get_node(EditorNodePoints.TILE_MAP_PATTERNS_PANEL),
		EditorInterfaceAccess.get_node(EditorNodePoints.TILE_MAP_TERRAINS_PANEL),
	]

	var index := tilemap_panels.find(control)
	if index == -1:
		warn("[b]'control(=%s)'[/] must be one of '[b]TILE_MAP_*_PANEL[/b]' nodes" % [control], "bubble_add_task_set_tilemap_tab_by_control")
		return

	var tilemap_tabs: TabBar = EditorInterfaceAccess.get_node(EditorNodePoints.TILE_MAP_DOCK_TABS)
	bubble_add_task_set_tab_to_index(tilemap_tabs, index, description)


## Creates a task that waits for the user to select specific nodes in the Scene Dock.
##
## Parameters:
## - node_paths: Array of paths to nodes that need to be selected
## - description_override: Optional custom task description. If empty, automatically generates
##   a description like "Select the [NodeName] node(s) in the Scene Dock."
func bubble_add_task_select_nodes_by_path(node_paths: Array[String], description_override := "") -> void:
	var description := description_override
	if description.is_empty():
		description = atr("Select the %s %s in the [b]Scene Dock[/b].") % [", ".join(node_paths.map(func(s: String) -> String: return "[b]%s[/b]" % s.get_file())), "node" if node_paths.size() == 1 else "nodes"]
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
			description = atr(
				"""Set [b]%s[/b] to [code]%s[/code]""",
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
		description = atr("""Set [b]%s[/b]'s [b]%s[/b] property to [b]%s[/b]""") % [node_name, property_name.capitalize(), str(property_value).get_file()]
	bubble_add_task(
		description,
		1,
		func set_node_property(_task: Task) -> int:
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
		description = atr("""Open the scene [b]%s[/b]""") % path.get_file()
	bubble_add_task(
		description,
		1,
		func open_scene(_task: Task) -> int:
			var scene_tabs: TabBar = EditorInterfaceAccess.get_node(EditorNodePoints.SCENE_TABS_TAB_BAR)
			var current_tab_title := scene_tabs.get_tab_title(scene_tabs.current_tab)
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
		description = atr("""Expand the property [b]%s[/b] in the [b]Inspector[/b]""") % property_name.capitalize()
	bubble_add_task(
		description,
		1,
		func expand_property(_task: Task) -> int:
			var main_inspector: EditorInspector = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK_INSPECTOR)
			var properties := main_inspector.find_children("", "EditorProperty", true, false)

			for property: EditorProperty in properties:
				if (
					property.is_class("EditorPropertyResource") and
					property.get_edited_property() == property_name and
					property.get_child(property.get_child_count() - 1) is EditorInspector
				):
					return 1
			return 0
	)


## Used to tell [method bubble_add_task_node_to_guide] to check if the node position perfectly matches the guide's position or if it's just in the guide box's bounding box.
enum Guide3DCheckMode {
	## The node's position must be the same as the guide's position, or within a small margin of error.
	POSITION,
	## The node's position must be within the guide box's bounding box.
	IN_BOUNDING_BOX,
}


## Parameters to add a task to move a node to a specific position. The location to move to is represented by a transparent guide box.
## Used by the function [method bubble_add_task_node_to_guide].
class Guide3DTaskParameters:
	## The name of the node to check.
	var node_name := ""
	## The target position of the node.
	var global_position := Vector3.ZERO
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
		parameters.description_override = atr("""Move [b]%s[/b] inside the guide box""") % parameters.node_name

	queue_command(
		func() -> void:
			var scene_root := EditorInterface.get_edited_scene_root()
			if not scene_root:
				return

			var guide := Guide3DPackedScene.instantiate()
			var guide_scene_key := "%s::%s" % [ scene_root.get_instance_id(), parameters.node_name ]
			_guides[guide_scene_key] = guide

			# Add directly to the first viewport, which lets it exist in the
			# 3D world without interacting with the edited scene.
			var spatial_viewport := EditorInterfaceAccess.get_node_3d_viewport(0)
			var spatial_viewport_scene_root: SubViewport = EditorInterfaceAccess.get_node_relative(spatial_viewport, EditorNodePoints.NODE_3D_EDITOR_VIEWPORT_SCENE_ROOT)
			spatial_viewport_scene_root.add_child(guide)

			guide.global_position = parameters.global_position
			guide.box_offset = parameters.box_offset
			guide.size = parameters.box_size
			guide.name = "GDTourGuide"
	)
	bubble_add_task(
		parameters.description_override,
		1,
		func node_to_guide(_task: Task) -> int:
			var scene_root := EditorInterface.get_edited_scene_root()
			if not scene_root:
				return 0

			var node: Node3D = null
			if parameters.node_name == scene_root.name:
				node = scene_root
			else:
				node = scene_root.find_child(parameters.node_name)

			var guide_scene_key := "%s::%s" % [ scene_root.get_instance_id(), parameters.node_name ]
			var guide: Guide3D = _guides.get(guide_scene_key, null)
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
		description = atr("Instantiate the [b]%s[/b] scene as a child of [b]%s[/b]") % [file_path.get_file(), parent_node_name]
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
		description = atr("""Focus the [b]%s[/b] node""" % node_name)
	bubble_add_task(
		description,
		1,
		func focus_camera_task(task: Task) -> int:
			var scene_root := EditorInterface.get_edited_scene_root()
			var node := scene_root if node_name == scene_root.name else scene_root.find_child(node_name)
			var selected_nodes := EditorInterface.get_selection().get_selected_nodes()

			var is_node_selected := node in selected_nodes
			var is_focus_on_node := false

			for i in 4:
				var spatial_viewport := EditorInterfaceAccess.get_node_3d_viewport(i)
				var spatial_viewport_overlay: Control = EditorInterfaceAccess.get_node_relative(spatial_viewport, EditorNodePoints.NODE_3D_EDITOR_VIEWPORT_OVERLAYS)
				if spatial_viewport_overlay.has_focus() and Input.is_action_just_pressed("tour_f"):
					is_focus_on_node = true
					break

			return 1 if task.is_done() or is_node_selected and is_focus_on_node else 0
	)

#endregion


#region Highlight commands.

## Highlights nodes in the Scene dock by their names.
##
## Parameters:
## - names: Array of node names to highlight
## - button_index: Optional button index for tree items that have buttons or icons, to
##   highlight only specify icons (like the visibility icon). Use -1 to highlight the entire item.
## - do_center: If true, center the view on the highlighted items
## - play_flash: If true, plays a flash animation on the highlighted items
func highlight_scene_nodes_by_name(names: Array[String], button_index := -1, do_center := true, play_flash := true) -> void:
	queue_command(func() -> void:
		var scene_tree := EditorInterfaceAccess.get_node(EditorNodePoints.SCENE_TREE_LOCAL_TREE)
		var predicate := func(item: TreeItem) -> bool: return item.get_text(0) in names
		overlays.highlight_tree_items(scene_tree, predicate, button_index, do_center, play_flash)
	)


## Highlights nodes in the Scene dock by their paths.
## This is more precise than highlighting by name when there are nodes with the same name.
##
## Parameters:
## - paths: Array of node paths to highlight
## - button_index: Optional button index for tree items that have buttons (-1 for entire item)
## - do_center: If true, center the view on the highlighted items
## - play_flash: If true, plays a flash animation on the highlighted items
func highlight_scene_nodes_by_path(paths: Array[String], button_index := -1, do_center := true, play_flash := true) -> void:
	queue_command(func() -> void:
		var scene_tree := EditorInterfaceAccess.get_node(EditorNodePoints.SCENE_TREE_LOCAL_TREE)
		var predicate := func(item: TreeItem) -> bool: return Utils.get_tree_item_path(item) in paths
		overlays.highlight_tree_items(scene_tree, predicate, button_index, do_center, play_flash)
	)


## Highlights files or directories in the FileSystem dock.
## This helps users locate files they need to work with, like scenes or scripts.
##
## Parameters:
## - paths: Array of file or directory paths to highlight
## - do_center: If true, center the view on the highlighted items
## - play_flash: If true, plays a flash animation on the highlighted items
func highlight_filesystem_paths(paths: Array[String], do_center := true, play_flash := true) -> void:
	queue_command(func() -> void:
		var filesystem_tree := EditorInterfaceAccess.get_node(EditorNodePoints.FILE_SYSTEM_TREE)
		var predicate := func(item: TreeItem) -> bool: return Utils.get_tree_item_path(item) in paths
		overlays.highlight_tree_items(filesystem_tree, predicate, -1, do_center, play_flash)
	)


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


## Highlights signals in the Signals dock.
## This helps users locate specific signals when working with signal connections.
##
## Parameters:
## - names: Array of signal names to highlight (in format "node_name/signal_name")
## - do_center: If true, center the view on the highlighted signals
## - play_flash: If true, plays a flash animation on the highlighted signals
func highlight_signals(names: Array[String], do_center := true, play_flash := true) -> void:
	queue_command(func() -> void:
		var signals_tree := EditorInterfaceAccess.get_node(EditorNodePoints.SIGNALS_EDITOR_TREE)
		var predicate := func(item: TreeItem) -> bool:
			var filter := func(sn: String) -> bool: return item.get_text(0).begins_with(sn)
			return names.any(filter)

		overlays.highlight_tree_items(signals_tree, predicate, -1, do_center, play_flash)
	)


## Highlights code in the script editor.
## This draws attention to specific lines of code in the currently edited script.
##
## Parameters:
## - start: The starting line number to highlight (1-based)
## - end: The ending line number to highlight (if 0, only highlights the start line)
## - caret: The line to place the text cursor on (if 0, places it at the start line)
## - do_center: If true, center the view on the highlighted code
## - play_flash: If true, play a flash animation on the highlighted code
func highlight_code(start: int, end := 0, caret := 0, do_center := true, play_flash := false) -> void:
	queue_command(func() -> void:
		var script_editor: ScriptEditor = EditorInterfaceAccess.get_node(EditorNodePoints.SCRIPT_EDITOR)
		var code_editor: CodeEdit = script_editor.get_current_editor().get_base_editor()

		if start > 0:
			script_editor.goto_line(start - 1)
		overlays.highlight_code(code_editor, start, end, caret, do_center, play_flash)
	)


## Highlights UI controls in the editor using a direct reference to a control node.
## This draws attention to specific UI elements like buttons, panels, or fields.
##
## NOTE: this function will be deprecated then removed in a future update.
##
## Parameters:
## - controls: Array of Control nodes to highlight
## - play_flash: If true, play a flash animation on the highlighted controls
func highlight_controls(controls: Array[Control], play_flash := false) -> void:
	queue_command(overlays.highlight_controls, [controls, play_flash])


## Highlights UI controls in the editor using enumerated values associated with
## them. This draws attention to specific UI elements like buttons, panels, or
## fields.
##
## Parameters:
## - node_points: Array of editor node points to highlight
## - play_flash: If true, play a flash animation on the highlighted controls
func highlight_editor_nodes(node_points: Array[EditorNodePoints], play_flash := false) -> void:
	queue_command(overlays.highlight_editor_nodes, [node_points, play_flash])


## Highlights a tab in a TabBar or TabContainer by its index.
##
## Parameters:
## - tabs: The TabBar or TabContainer control containing the tabs
## - index: The index of the tab to highlight (-1 for all tabs)
## - play_flash: If true, play a flash animation on the highlighted tab
func highlight_tabs_index(tabs: Control, index := -1, play_flash := true) -> void:
	queue_command(overlays.highlight_tab_index, [tabs, index, null, play_flash])


## Highlights a tab in a TabBar or TabContainer by its title.
##
## Parameters:
## - tabs: The TabBar or TabContainer control containing the tabs
## - title: The title of the tab to highlight
## - play_flash: If true, play a flash animation on the highlighted tab
func highlight_tabs_title(tabs: Control, title: String, play_flash := true) -> void:
	queue_command(overlays.highlight_tab_title, [tabs, title, null, play_flash])


## Highlights a rectangular area in the 2D viewport.
## This draws attention to a specific area in the scene being edited, like a node's
## position or a region the user needs to work with.
##
## Parameters:
## - rect: The rectangle area to highlight in the 2D viewport
## - play_flash: If true, play a flash animation on the highlighted area
func highlight_canvas_item_editor_rect(rect: Rect2, play_flash := false) -> void:
	queue_command(
		func() -> void:
			var canvas_item_editor_overlays: Control = EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR_VIEWPORT_OVERLAYS)

			var rect_getter := func() -> Rect2:
				var scene_root := EditorInterface.get_edited_scene_root()
				if scene_root == null:
					return Rect2()
				return scene_root.get_viewport().get_screen_transform() * rect
			var clamp_getter := canvas_item_editor_overlays.get_global_rect

			overlays.add_highlight_to_control(canvas_item_editor_overlays, rect_getter, clamp_getter, play_flash),
	)


## Highlights an item in an ItemList control in the TileMap editor.
## This is useful for drawing attention to specific tiles or patterns in the tileset.
##
## Parameters:
## - item_list: The ItemList control containing the items
## - item_index: The index of the item to highlight
## - play_flash: If true, play a flash animation on the highlighted item
func highlight_tilemap_list_item(item_list: ItemList, item_index: int, play_flash := true) -> void:
	queue_command(func() -> void:
		var tilemap := EditorInterfaceAccess.get_node(EditorNodePoints.TILE_MAP_DOCK)
		overlays.highlight_list_item(item_list, item_index, tilemap, play_flash)
	)


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
	var spatial_viewport := EditorInterfaceAccess.get_node_3d_viewport(index)
	if spatial_viewport == null:
		warn("[b]'index(=%d)'[/b] not a valid viewport index." % [index], "highlight_spatial_editor_camera_region")
		return

	var spatial_editor: Control = EditorInterfaceAccess.get_node(EditorNodePoints.NODE_3D_EDITOR)
	var spatial_viewport_camera: Camera3D = EditorInterfaceAccess.get_node_relative(spatial_viewport, EditorNodePoints.NODE_3D_EDITOR_VIEWPORT_CAMERA)

	queue_command(
		func() -> void:
			if spatial_viewport_camera.is_position_behind(start) or spatial_viewport_camera.is_position_behind(end):
				return
			var rect_getter := func() -> Rect2:
				var s := spatial_viewport_camera.unproject_position(start)
				var e := spatial_viewport_camera.unproject_position(end)
				return spatial_viewport_camera.get_viewport().get_screen_transform() * Rect2(Vector2(min(s.x, e.x), min(s.y, e.y)), (e - s).abs())
			var clamp_getter := spatial_editor.get_global_rect

			overlays.add_highlight_to_control(spatial_editor, rect_getter, clamp_getter, play_flash),
	)


## Highlights the material preview in the Inspector dock.
##
## Note: Currently limited to finding and highlighting only the "material" property.
## FIXME: follow scroll and parametrize to highlight a preview other than "material" property.
func highlight_material_preview() -> void:
	queue_command(
		func highlight_preview() -> void:
			var main_inspector: EditorInspector = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK_INSPECTOR)
			main_inspector.scroll_vertical = 0

			var properties := main_inspector.find_children("", "EditorProperty", true, false)
			for property: EditorProperty in properties:
				if property.is_class("EditorPropertyResource") and property.get_edited_property() == "material" and property.get_child_count() > 1:
					var controls: Array[Control] = []
					controls.assign(property.find_children("", "MaterialEditor", true, false))
					overlays.highlight_controls(controls)
	)

#endregion


#region Mouse commands.

## Moves an animated mouse cursor from one position to another using global
## coordinates.
##
## Parameters:
## - from: The starting position in global coordinates
## - to: The target position in global coordinates
func mouse_move_by_position(from: Vector2, to: Vector2) -> void:
	queue_command(
		func() -> void:
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
	queue_command(
		func() -> void:
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
	queue_command(
		func() -> void:
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
	queue_command(
		func() -> void:
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
	queue_command(
		func() -> void:
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
	queue_command(
		func() -> void:
			ensure_mouse()
			mouse.add_press_operation(press_texture)
	)


## Animates a mouse pointer doing a release action.
## Used as part of multi-step mouse interactions, typically after [method mouse_press] and moving the pointer.
func mouse_release() -> void:
	queue_command(
		func() -> void:
			ensure_mouse()
			mouse.add_release_operation()
	)


## Animates a mouse pointer clicking the mouse (press and release) a specified number of times.
##
## Parameters:
## - loops: Number of times to click the mouse (default: 1)
func mouse_click(loops := 1) -> void:
	queue_command(
		func() -> void:
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

		var editor_window: Window = EditorInterfaceAccess.get_node(EditorNodePoints.EDITOR_MAIN_WINDOW)
		editor_window.add_child(mouse)


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

#endregion


#region Global editor commands.

## Applies the default layout so every tour starts from the same UI state.
## [b]Note:[/b] This command runs on welcome bookend step.
func editor_reset_layout() -> void:
	queue_welcome_command(func() -> void:
		var editor_layout_menu: PopupMenu = EditorInterfaceAccess.get_node(EditorNodePoints.MENU_BAR_EDITOR_LAYOUT_MENU)
		Utils.activate_menu_option_by_shortcut(editor_layout_menu, "layout/default")
	)


## Resets editor components to their default state. At this time, this only
## includes resetting all dock containers to their default positions.  Can also
## run additional commands supplied via the [param extra_callback].
## [b]Note:[/b] This command runs on welcome bookend step.
func editor_reset_state(extra_callback: Callable = Callable()) -> void:
	# TODO: Consider other elements of the editor that can be reset for every tour.

	queue_welcome_command(func() -> void:
		# Reset all dock containers. Close the bottom one, set others to their
		# first tab.

		_close_bottom_panel()

		var dock_container_points: Array[EditorNodePoints] = [
			EditorNodePoints.LAYOUT_DOCK_LEFT_LEFT_TOP,
			EditorNodePoints.LAYOUT_DOCK_LEFT_LEFT_BOTTOM,
			EditorNodePoints.LAYOUT_DOCK_LEFT_RIGHT_TOP,
			EditorNodePoints.LAYOUT_DOCK_LEFT_RIGHT_BOTTOM,
			EditorNodePoints.LAYOUT_DOCK_RIGHT_LEFT_TOP,
			EditorNodePoints.LAYOUT_DOCK_RIGHT_LEFT_BOTTOM,
			EditorNodePoints.LAYOUT_DOCK_RIGHT_RIGHT_TOP,
			EditorNodePoints.LAYOUT_DOCK_RIGHT_RIGHT_BOTTOM,
		]
		for point in dock_container_points:
			var dock_container: TabContainer = EditorInterfaceAccess.get_node(point)
			if dock_container and dock_container.get_tab_count() > 0:
				dock_container.current_tab = 0
			elif dock_container:
				dock_container.current_tab = -1

		# Call user callback last.

		if extra_callback.is_valid():
			extra_callback.call()
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


## Makes the specified dock visible in the editor UI. If the dock is closed completely,
## it is restored to its default position. If the dock is in one of the side containers,
## that container switches to this dock. If the dock is in the bottom panel, the bottom
## panel becomes visible.
func docks_make_visible(dock: EditorDock) -> void:
	if not dock:
		return
	queue_command(dock.make_visible)

#endregion


#region Scene commands.

## Open a scene in the editor.
## If the scene is already open, it will be reloaded.
##
## Parameters:
## - path: The file path to the scene to open. It must exist and have a .tscn extension.
func scene_open(path: String) -> void:
	if not FileAccess.file_exists(path) and path.get_extension() != "tscn":
		warn("[b]'path(=%s)'[/b] doesn't exist or has wrong extension" % path, "scene_open")
		return
	queue_command(
		func() -> void:
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
	queue_command(
		func() -> void:
			var scene_root := EditorInterface.get_edited_scene_root()
			var editor_selection := EditorInterface.get_selection()

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
	queue_command(
		func get_and_lock_nodes() -> void:
			var nodes := Utils.find_children_by_path(EditorInterface.get_edited_scene_root(), paths)
			var prop := &"_edit_lock_"
			for node in nodes:
				node.set_meta(prop, is_locked) if is_locked else node.remove_meta(prop)
	)


## Deselect all nodes in the editor.
## This clears the current editor selection.
func scene_deselect_all_nodes() -> void:
	queue_command(EditorInterface.get_selection().clear)


## Updates the `Guide3D` nodes to only display those corresponding
## to the currently edited scene.
func _update_scene_guides() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root == null:
		for guide in _guides.values():
			guide.visible = false
		return

	var scene_key := "%s" % EditorInterface.get_edited_scene_root().get_instance_id()
	for guide_scene_key in _guides:
		var key_parts := guide_scene_key.split("::")
		if key_parts.size() != 2:
			continue

		var guide := _guides[guide_scene_key]
		guide.visible = (scene_key == key_parts[0])


## Frees the `Guide3D` nodes from the currently edited scene.
## This cleans up any visual guide indicators that were added to help users during the tour.
func clear_guides() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return

	for guide in _guides.values():
		guide.queue_free()
	_guides = { }

#endregion


#region Widgets and editors commands.

## Center the 2D viewport at a specific position with a specific zoom level.
##
## Parameters:
## - position: The position to center the viewport at. Defaults to Vector2.ZERO.
## - zoom: The zoom level to set, where 1.0 is 100%. Defaults to 1.0.
func canvas_item_editor_center_at(position := Vector2.ZERO, zoom := 1.0) -> void:
	queue_command(
		func() -> void:
			await delay_process_frame()
			EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR).center_at(position)
			EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR_VIEWPORT_ZOOM_WIDGET).set_zoom(zoom)
	)


## Resets the zoom of the 2D viewport to 100%.
func canvas_item_editor_zoom_reset() -> void:
	queue_command(
		func() -> void:
			EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR_VIEWPORT_ZOOM_WIDGET).set_zoom(1.0)
	)


## Play a flash animation in the 2D viewport over a specific rectangle area.
## Useful for drawing attention to a specific part of the scene.
##
## Parameters:
## - rect: The rectangle area to flash in the 2D viewport
func canvas_item_editor_flash_area(rect: Rect2) -> void:
	queue_command(overlays.flash_editor_node_area, [ EditorNodePoints.CANVAS_ITEM_EDITOR_VIEWPORT_OVERLAYS, rect ])


## Focus the 3D viewport on the currently selected node.
## This simulates pressing the "F" key in the 3D viewport to frame the selection.
func spatial_editor_focus() -> void:
	queue_command(
		func() -> void:
			for i in 4:
				var spatial_viewport := EditorInterfaceAccess.get_node_3d_viewport(i)
				var view_menu: MenuButton = EditorInterfaceAccess.get_node_relative(spatial_viewport, EditorNodePoints.NODE_3D_EDITOR_VIEWPORT_VIEW_DISPLAY_MENU)
				Utils.activate_menu_option_by_shortcut(view_menu.get_popup(), "spatial_editor/focus_selection")
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
	ONE = 0,
	TWO = 1,
	TWO_ALT = 2,
	THREE = 3,
	THREE_ALT = 4,
	FOUR = 5,
}


## Changes the layout of the 3D viewport. Corresponds to clicking items in the
## View menu in the toolbar above the 3D viewport.
func spatial_editor_change_viewport_layout(layout: ViewportLayouts) -> void:
	queue_command(
		func spatial_editor_change_viewport_layout() -> void:
			var view_button: MenuButton = EditorInterfaceAccess.get_node(EditorNodePoints.NODE_3D_EDITOR_MAIN_TOOLBAR_VIEW_OPTIONS_BUTTON)
			var popup := view_button.get_popup()

			match layout:
				ViewportLayouts.ONE:
					Utils.activate_menu_option_by_shortcut(popup, "spatial_editor/1_viewport")
				ViewportLayouts.TWO:
					Utils.activate_menu_option_by_shortcut(popup, "spatial_editor/2_viewports")
				ViewportLayouts.TWO_ALT:
					Utils.activate_menu_option_by_shortcut(popup, "spatial_editor/2_viewports_alt")
				ViewportLayouts.THREE:
					Utils.activate_menu_option_by_shortcut(popup, "spatial_editor/3_viewports")
				ViewportLayouts.THREE_ALT:
					Utils.activate_menu_option_by_shortcut(popup, "spatial_editor/3_viewports_alt")
				ViewportLayouts.FOUR:
					Utils.activate_menu_option_by_shortcut(popup, "spatial_editor/4_viewports")
	)


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
	queue_command(func() -> void:
		var main_inspector: EditorInspector = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK_INSPECTOR)
		Utils.expand_inspector_resource_property(main_inspector, resource_property_name)
	)


## Switches the TileSet editor tabs to the specified panel.
##
## Parameters:
## - control: The control to find and show in the TileSet editor tabs.
##   Must be one of the TILE_SET_*_PANEL node points.
func tileset_tabs_set_by_control(control: Control) -> void:
	# Not a TabContainer with children, so we rely on indices manually.
	var tileset_panels: Array[Control] = [
		EditorInterfaceAccess.get_node(EditorNodePoints.TILE_SET_TILES_PANEL),
		EditorInterfaceAccess.get_node(EditorNodePoints.TILE_SET_PATTERNS_PANEL),
	]

	var index := tileset_panels.find(control)
	if index == -1:
		warn("[b]'control(=%s)'[/] must be one of '[b]TILE_SET_*_PANEL[/b]' nodes" % [control], "tileset_tabs_set_by_control")
		return

	var tileset_tabs: TabBar = EditorInterfaceAccess.get_node(EditorNodePoints.TILE_SET_DOCK_TABS)
	tabs_set_to_index(tileset_tabs, index)


## Set the TileMap editor tabs to the tab containing a specific control.
##
## Parameters:
## - control: The control to find and show in the TileMap editor tabs.
##   Must be one of the TILE_MAP_*_PANEL node points.
func tilemap_tabs_set_by_control(control: Control) -> void:
	# Not a TabContainer with children, so we rely on indices manually.
	var tilemap_panels: Array[Control] = [
		EditorInterfaceAccess.get_node(EditorNodePoints.TILE_MAP_TILES_PANEL),
		EditorInterfaceAccess.get_node(EditorNodePoints.TILE_MAP_PATTERNS_PANEL),
		EditorInterfaceAccess.get_node(EditorNodePoints.TILE_MAP_TERRAINS_PANEL),
	]

	var index := tilemap_panels.find(control)
	if index == -1:
		warn("[b]'control(=%s)'[/] must be one of '[b]TILE_MAP_*_PANEL[/b]' nodes" % [control], "tilemap_tabs_set_by_control")
		return

	var tilemap_tabs: TabBar = EditorInterfaceAccess.get_node(EditorNodePoints.TILE_MAP_DOCK_TABS)
	tabs_set_to_index(tilemap_tabs, index)

#endregion


#region GUI commands.

## Set a TabBar to a specific tab index.
##
## Parameters:
## - tabs: The TabBar to manipulate
## - index: The index of the tab to select. Must be within range of available tabs.
func tabs_set_to_index(tabs: TabBar, index: int) -> void:
	const FUNC_NAME := "tabs_set_to_index"

	queue_command(func() -> void:
		if not is_instance_valid(tabs):
			warn("[b]'tabbar(=%d)'[/b] is no longer valid." % [tabs], FUNC_NAME)
			return
		if index < 0 or index >= tabs.tab_count:
			warn("[b]'index(=%d)'[/b] not in [b]'range(0, tabs.tab_count(=%d))'[/b]." % [index, tabs.tab_count], FUNC_NAME)
			return

		tabs.set_current_tab(index)
	)


## Set a TabBar to a specific tab by its title. Finds the tab with
## the matching title and selects it.
##
## Parameters:
## - tabs: The TabBar to manipulate
## - title: The title of the tab to select. Must match an existing tab title.
func tabs_set_to_title(tabs: TabBar, title: String) -> void:
	const FUNC_NAME := "tabs_set_to_title"

	queue_command(func() -> void:
		if not is_instance_valid(tabs):
			warn("[b]'tabbar(=%d)'[/b] is no longer valid." % [tabs], FUNC_NAME)
			return

		var index := find_tabs_title(tabs, title)
		if index == -1:
			var titles := range(tabs.tab_count).map(func(index: int) -> String: return tabs.get_tab_title(index))
			warn("[b]'title(=%s)'[/b] not found in tabs [b]'[%s]'[/b]." % [title, ", ".join(titles)], FUNC_NAME)
			return

		tabs.set_current_tab(index)
	)


## Switch a TabContainer's active tab to display the tab containing
## a specific control.
##
## Parameters:
## - control: The control to find and show in its parent TabContainer.
##   Must be a direct child of a TabContainer.
func tabs_set_by_control(control: Control) -> void:
	const FUNC_NAME := "tabs_set_to_control"

	queue_command(func() -> void:
		if not is_instance_valid(control):
			warn("[b]'control(=%d)'[/b] is no longer valid." % [control], FUNC_NAME)
			return
		if control.get_parent() is not TabContainer:
			warn("[b]'control(=%s)'[/b] is not a child of a [b]'TabContainer'[/b]." % [control], FUNC_NAME)
			return

		var tab_container: TabContainer = control.get_parent()
		var tab_idx := find_tabs_control(tab_container, control)
		if tab_idx == -1:
			warn("[b]'control(=%s)'[/b] is not a child of [b]'[%s]'[/b]." % [control, tab_container], FUNC_NAME)
			return

		tab_container.get_tab_bar().set_current_tab(tab_idx)
	)


## Find and activate tree items that start with a specific prefix.
## Useful for activating specific signals, nodes, or resources in tree views.
##
## Parameters:
## - tree: The Tree control to search in
## - prefix: The text prefix to search for in tree items
func tree_activate_by_prefix(tree: Tree, prefix: String) -> void:
	queue_command(
		func() -> void:
			var signals_editor_tree := EditorInterfaceAccess.get_node(EditorNodePoints.SIGNALS_EDITOR_TREE)
			var signals_dialog_window := EditorInterfaceAccess.get_node(EditorNodePoints.SIGNALS_DIALOG)
			if tree == signals_editor_tree and signals_dialog_window.visible:
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

#endregion


#region Command helpers.
# TODO: Should any of these be in Utils?

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
	var main_inspector: EditorInspector = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK_INSPECTOR)
	var predicate_first := func predicate_first(p: EditorProperty) -> bool: return p.get_edited_property() == name

	var properties := main_inspector.find_children("", "EditorProperty", true, false)
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
	if tabs == null:
		return -1

	var scene_tabs: TabBar = EditorInterfaceAccess.get_node(EditorNodePoints.SCENE_TABS_TAB_BAR)

	var result := -1
	for index in tabs.tab_count:
		var tab_title: String = tabs.get_tab_title(index)

		if title == tab_title:
			result = index
			break

		if tabs == scene_tabs and ("%s(*)" % title) == tab_title:
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


## Generates a BBCode [code][img][/code] tag for a Godot editor icon, scaling the image size based on the editor.
## scale.
func bbcode_generate_icon_image_string(image_filepath: String) -> String:
	const BASE_SIZE_PIXELS := 24
	var size := BASE_SIZE_PIXELS * EditorInterface.get_editor_scale()
	return "[img=%sx%s]" % [size, size] + image_filepath + "[/img]"


## Generates a BBCode [code][img][/code] tag for a Godot editor icon by name,
## scaling the image size based on the editor scale.
## The icon name must match the name of one of the editor theme icons. The
## complete list for the current version of Godot can be found in
## [code]https://github.com/godotengine/godot/tree/master/editor/icons[/code].
## Use the name of the desired SVG file from this directory, without the extension.
## Example: For Node2D.svg, the icon name is "Node2D"
func bbcode_generate_icon_image_by_name(icon_name: String) -> String:
	if not Utils.precache_icon_image(icon_name):
		warn("[b]'icon_name(=%s)'[/b] doesn't exist in the editor theme" % icon_name, "bbcode_generate_icon_image_by_name")
		return ""

	var icon_path := "editor://theme_icons/%s" % icon_name
	assert(ResourceLoader.exists(icon_path), "Icon resource not found: %s" % icon_path)
	return bbcode_generate_icon_image_string(icon_path)


## Wraps the text in a [code][font_size][/code] BBCode tag, scaling the value of size_pixels based on the editor
## scale.
func bbcode_wrap_font_size(text: String, size_pixels: int) -> String:
	var size_scaled := size_pixels * EditorInterface.get_editor_scale()
	return "[font_size=%s]" % size_scaled + text + "[/font_size]"


## Closes the bottom panel in the editor by unsetting the current tab.
func _close_bottom_panel() -> void:
	var bottom_dock_container: TabContainer = EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_DOCK_MIDDLE_BOTTOM)
	bottom_dock_container.current_tab = -1


## Compares two nodes by their paths for sorting in ascending order.
##
## Parameters:
## - a: First node to compare
## - b: Second node to compare
##
## Returns: True if node a's path comes before node b's path alphabetically
func sort_ascending_by_path(a: Node, b: Node) -> bool:
	return str(a.get_path()) < str(b.get_path())

#endregion


#region Utilities.

## Returns the path of a translated resource (like an image used for a specific language)
## based on the current editor language.
func ptr(resource_path: String) -> String:
	return Utils.get_translation_remapped_path(resource_path)


func warn(msg: String, func_name: String) -> void:
	const WARNING_MESSAGE := "[color=orange][WARN][/color] %s for [b]'%s()'[/b] at [b]'step_commands(=%d)'[/b]."

	print_rich(WARNING_MESSAGE % [msg, func_name, steps.size()])


func request_log_file() -> void:
	log.clean_up()
	OS.shell_show_in_file_manager(log.get_log_full_path())

#endregion
