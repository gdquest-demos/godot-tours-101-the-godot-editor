extends "res://addons/godot_tours/tour.gd"

const Gobot := preload("res://addons/godot_tours/bubble/gobot/gobot.gd")

const TEXTURE_BUBBLE_BACKGROUND := preload("res://assets/bubble-background.png")
const TEXTURE_GDQUEST_LOGO := preload("res://assets/gdquest-logo.svg")

const CREDITS_FOOTER_GDQUEST := "[center]Godot Interactive Tours · Made by [url=https://www.gdquest.com/][b]GDQuest[/b][/url] · [url=https://github.com/GDQuest][b]Github page[/b][/url][/center]"

const LEVEL_RECT := Rect2(Vector2.ZERO, Vector2(1920, 1080))
const LEVEL_CENTER_AT := Vector2(960, 540)

# TODO: rather than being constant, these should probably scale with editor scale, and probably.
# be calculated relative to the position of some docks etc. in Godot. So that regardless of their
# resolution, people get the windows roughly in the same place.
# We should write a function for that.
#
# Position we set to popup windows relative to the editor's top-left. This helps to keep the popup
# windows outside of the bubble's area.
const POPUP_WINDOW_POSITION := Vector2i(150, 150)
# We limit the size of popup windows
const POPUP_WINDOW_MAX_SIZE := Vector2i(860, 720)

const ICONS_MAP = {
	node_position_unselected = "res://assets/icon_editor_position_unselected.svg",
	node_position_selected = "res://assets/icon_editor_position_selected.svg",
	script_signal_connected = "res://assets/icon_script_signal_connected.svg",
	script = "res://assets/icon_script.svg",
	script_indent = "res://assets/icon_script_indent.svg",
	zoom_in = "res://assets/icon_zoom_in.svg",
	zoom_out = "res://assets/icon_zoom_out.svg",
	open_in_editor = "res://assets/icon_open_in_editor.svg",
	node_signal_connected = "res://assets/icon_signal_scene_dock.svg",
}

var scene_completed_project := "res://completed_project.tscn"
var scene_start := "res://start.tscn"
var scene_player := "res://player/player.tscn"
var script_player := "res://player/player.gd"
var script_health_bar := "res://interface/bars/ui_health_bar.gd"
var room_scenes: Array[String] = [
	"res://levels/rooms/room_a.tscn",
	"res://levels/rooms/room_b.tscn",
	"res://levels/rooms/room_c.tscn",
]
var scene_background_sky := "res://levels/background/background_blue_sky.tscn"
var scene_health_bar := "res://interface/bars/ui_health_bar.tscn"
var scene_chest := "res://levels/rooms/chests/chest.tscn"
var script_chest := "res://levels/rooms/chests/chest.gd"


func _build() -> void:
	# Set editor state according to the tour's needs.
	queue_command(func reset_editor_state_for_tour():
		interface.canvas_item_editor_toolbar_grid_button.button_pressed = false
		interface.canvas_item_editor_toolbar_smart_snap_button.button_pressed = false
		interface.bottom_button_output.button_pressed = false
	)

	steps_010_intro()
	steps_020_first_look()
	steps_030_opening_scene()
	steps_040_scripts()
	steps_050_signals()
	steps_090_conclusion()


func steps_010_intro() -> void:

	# 0010: introduction
	context_set_2d()
	scene_open(scene_completed_project)
	bubble_move_and_anchor(interface.base_control, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_background(TEXTURE_BUBBLE_BACKGROUND)
	bubble_add_texture(TEXTURE_GDQUEST_LOGO)
	bubble_set_title("")
	bubble_add_text([bbcode_wrap_font_size(gtr("[center][b]Welcome to Godot[/b][/center]"), 32)])
	bubble_add_text(
		[gtr("[center]In this tour, you take your first steps in the [b]Godot editor[/b].[/center]"),
		gtr("[center]You get an overview of the engine's four pillars: [b]Scenes[/b], [b]Nodes[/b], [b]Scripts[/b], and [b]Signals[/b].[/center]"),
		gtr("[center]In the next tour, you'll get to assemble your first game from premade parts and put all this into practice.[/center]"),
		gtr("[center][b]Let's get started![/b][/center]"),]
	)
	bubble_set_footer(CREDITS_FOOTER_GDQUEST)
	queue_command(func avatar_wink(): bubble.avatar.do_wink())
	complete_step()


	# 0020: First look at game you'll make
	highlight_controls([interface.run_bar_play_button], true)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_add_task_press_button(interface.run_bar_play_button)
	bubble_set_title(gtr("Try the game"))
	bubble_add_text(
		[gtr("When a project is first opened in Godot, we land on the [b]Main Scene[/b]. It is the entry point of a Godot game."),
		gtr("Click the play icon in the top right of the editor to run the Godot project."),
		gtr("Then, press [b]%s[/b] on your keyboard or close the game window to stop the game.") % shortcuts.stop]
	)
	complete_step()


	# 0030: Start of editor tour
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("Editor tour"))
	bubble_add_text(
		[gtr("Great! Now let's take a quick tour of the editor."),]
	)
	queue_command(func():
		interface.bottom_button_output.button_pressed = false
	)
	complete_step()


func steps_020_first_look() -> void:
	# 0040: central viewport
	highlight_controls([interface.canvas_item_editor])
	bubble_move_and_anchor(interface.inspector_dock, Bubble.At.BOTTOM_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(gtr("The viewport"))
	bubble_add_text(
		[gtr("The central part of the editor outlined in purple is the viewport. It's a view of the currently open [b]scene[/b]."),]
	)
	complete_step()


	# 0041: scene explanation
	highlight_controls([interface.canvas_item_editor])
	bubble_set_title(gtr("A scene is a reusable template"))
	bubble_add_text(
		[gtr("In Godot, a scene is a template that can represent anything: A character, a chest, an entire level, a menu, or even a complete game!"),
		gtr("We are currently looking at a scene file called [b]%s[/b]. This scene consists of a complete game.") % scene_completed_project.get_file(),]
	)
	complete_step()

	# 0041: looking around
	var controls_0041: Array[Control] = []
	controls_0041.assign([
		interface.scene_dock,
		interface.filesystem_dock,
		interface.inspector_dock,
		interface.context_switcher,
		interface.run_bar,
	] + interface.bottom_buttons)
	highlight_controls(controls_0041)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("Let's look around"))
	bubble_add_text(
		[gtr("We're going to explore the interface next, so you get a good feel for it."),]
	)
	complete_step()


	# 0042: playback controls/game preview buttons
	highlight_controls([interface.run_bar], true)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("Runner Buttons"))
	bubble_add_text([gtr("Those buttons in the top-right are the Runner Buttons. You can [b]play[/b] and [b]stop[/b] the game with them.")])
	complete_step()


	# 0042: main screen buttons / "context switcher"
	highlight_controls([interface.context_switcher], true)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("Context Switcher"))
	bubble_add_text([
		gtr("Centered at the top of the editor, you find the Godot [b]Context Switcher[/b]."),
		gtr("You can change between the different [b]Editor[/b] views here. We are currently on the [b]2D View[/b]. Later, we will switch to the [b]Script Editor[/b]!"),
	])
	complete_step()


	# 0042: scene dock
	context_set_2d()
	highlight_controls([interface.scene_dock])
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_LEFT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(gtr("Scene Dock"))
	bubble_add_text([gtr("At the top-left, you have the [b]Scene Dock[/b]. You can see all the building blocks of a scene here."),
		gtr("In Godot, these building blocks are called [b]nodes[/b]."),
		gtr("A scene is made up of one or more nodes."),
		gtr("There are nodes to draw images, play sounds, design animations, and more."),
	])
	complete_step()


	# 0042: Filesystem dock
	highlight_controls([interface.filesystem_dock])
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.BOTTOM_LEFT)
	bubble_set_title(gtr("FileSystem Dock"))
	bubble_add_text([gtr("At the bottom-left, you can see the [b]FileSystem Dock[/b]. It lists all the files used in your project (all the scenes, images, scripts...).")])
	complete_step()


	# 0044: inspector dock
	highlight_controls([interface.inspector_dock])
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.CENTER_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("The Inspector"))
	bubble_add_text([
		gtr("On the right, we have the [b]Inspector Dock[/b]. In this dock, you can view and edit the properties of selected nodes."),
	])
	complete_step()


	# 0045: inspector test
	scene_deselect_all_nodes()
	highlight_controls([interface.inspector_dock, interface.scene_dock])
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	queue_command(func set_avatar_surprised() -> void:
		bubble.avatar.set_expression(Gobot.Expressions.SURPRISED)
	)
	bubble_set_title(gtr("Try the Inspector"))
	bubble_add_text([
		gtr("Try the [b]Inspector[/b]! Click on the different nodes in the [b]Scene Dock[/b] on the left to see their properties in the [b]Inspector[/b] on the right."),
	])
	mouse_click()
	mouse_move_by_callable(
		get_tree_item_center_by_path.bind(interface.scene_tree, ("Main")),
		get_tree_item_center_by_path.bind(interface.scene_tree, ("Main/Bridges")),
	)
	mouse_click()
	mouse_move_by_callable(
		get_tree_item_center_by_path.bind(interface.scene_tree, ("Main/Bridges")),
		get_tree_item_center_by_path.bind(interface.scene_tree, ("Main/Player")),
	)
	mouse_click()
	complete_step()


	# 0046: bottom panels
	queue_command(func debugger_open():
		interface.bottom_button_debugger.button_pressed = true
	)
	highlight_controls([interface.debugger])
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.BOTTOM_CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("The Bottom Panels"))
	bubble_add_text([
		gtr("At the bottom, you'll find editors like the [b]Output[/b] and [b]Debugger[/b] panels."),
		gtr("That's where you'll edit animations, write visual effects code (shaders), and more."),
		gtr("These editors are contextual. We'll see what that means in the next tour."),
	])
	complete_step()

	queue_command(func debugger_close():
		interface.bottom_button_debugger.button_pressed = false
	)


func steps_030_opening_scene() -> void:

	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_LEFT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	highlight_scene_nodes_by_path(["Main", "Main/Bridges", "Main/InvisibleWalls", "Main/UILayer"])
	bubble_set_title(gtr("The complete scene's nodes"))
	bubble_add_text([
		gtr("This completed game scene has four [b]nodes[/b]: [b]Main[/b], [b]Bridges[/b], [b]InvisibleWalls[/b], and [b]UILayer[/b]."),
		gtr("We can see that in the [b]Scene Dock[/b] at the top-left.")
	])
	complete_step()


	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_LEFT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	highlight_scene_nodes_by_path(["Main/Player"])
	bubble_set_title(gtr("Scene instances"))
	bubble_add_text([
		gtr("Other elements, like the [b]Player[/b], have an [b]Open In Editor[/b] %s icon.") % bbcode_generate_icon_image_string(ICONS_MAP.open_in_editor),
		gtr("When you see this icon, you are looking at a [b]scene instance[/b]. It's a copy of another scene. You can think of it as a scene that uses another scene as its template. In Godot, we nest scene instances to create complete games."),
		gtr("Click the [b]Open in Editor[/b] %s icon next to the [b]Player[/b] node in the [b]Scene Dock[/b] to open the Player scene.") % bbcode_generate_icon_image_string(ICONS_MAP.open_in_editor),
	])
	bubble_add_task(
		(gtr("Open the Player scene.")),
		1,
		func task_open_start_scene(task: Task) -> int:
			var scene_root: Node = EditorInterface.get_edited_scene_root()
			if scene_root == null:
				return 0
			return 1 if scene_root.name == "Player" else 0
	)
	complete_step()


	context_set_2d()
	canvas_item_editor_center_at(Vector2.ZERO)
	canvas_item_editor_zoom_reset()
	highlight_controls([interface.scene_dock, interface.canvas_item_editor])
	bubble_move_and_anchor(interface.inspector_dock, Bubble.At.BOTTOM_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(gtr("The Player scene"))
	bubble_add_text([
		gtr("When opening a scene, the [b]Scene Dock[/b] and the viewport update to display the scene's contents."),
		gtr("In the Scene Dock at the top-left, you can see all the nodes that form the player's character."),
	])
	complete_step()



func steps_040_scripts() -> void:

	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("Scripts bring nodes to life"))
	bubble_add_text([
		gtr("By themselves, nodes and scenes don't interact."),
		gtr("To bring them to life, you need to give them instructions by writing code in a script and connecting it to the node or scene."),
		gtr("Let's have a look at an example of a script."),
	])
	complete_step()


	highlight_scene_nodes_by_path(["Player"])
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_LEFT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("Open the Player script"))
	bubble_add_text([
		gtr("The [b]Player[/b] node has a script file attached to it. We can see this thanks to the [b]Attached Script[/b] %s icon located to the right of the node in the [b]Scene Dock[/b].") % bbcode_generate_icon_image_string(ICONS_MAP.script),
		gtr("Click the script icon to open the [b]Player Script[/b] in the [b]Script Editor[/b]."),
	])
	bubble_add_task(
		gtr("Open the script attached to the [b]Player[/b] node."),
		1,
		func(task: Task) -> int:
			if not interface.is_in_scripting_context():
				return 0
			var open_script: String = EditorInterface.get_script_editor().get_current_script().resource_path
			return 1 if open_script == script_player else 0,
	)
	complete_step()


	highlight_controls([interface.script_editor_code_panel])
	bubble_move_and_anchor(interface.inspector_dock, Bubble.At.BOTTOM_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(gtr("The scripting context"))
	bubble_add_text([
		gtr("We're now in the scripting context, which displays all the code in the open script file."),
		gtr("This code gives instructions to the computer about how to move the character, when to play sounds, and more."),
		gtr("Don't worry if you can't read the code yet: We made a FREE app to help you [color=#ffd500][b][url=https://gdquest.com/tutorial/godot/learning-paths/learn-gdscript-from-zero/]Learn GDScript from Zero[/url][/b][/color]. It's a free part of our complete course Learn Gamedev From Zero."),
		gtr("Use your [b]Mouse Wheel[/b] to scroll up and down the file or click and drag the scrollbar on the right."),
	])
	complete_step()


	highlight_scene_nodes_by_path(["Player", "Player/GodotArmor", "Player/WeaponHolder", "Player/ShakingCamera2D"])
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_LEFT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(gtr("Any node can have a script"))
	bubble_add_text([
		gtr("If we look back at the [b]Scene Dock[/b] at the top-left, we can see multiple nodes with script icons."),
		gtr("You can attach scripts to as many nodes as you need to control their behavior."),
	])
	complete_step()


func steps_050_signals() -> void:

	highlight_controls([interface.context_switcher], true)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("Go back to the 2D view"))
	bubble_add_text([
		gtr("We have one more essential pillar of Godot to look at: [b]Signals[/b]."),
		gtr("Let's head back to the completed project scene. First, click the 2D workspace at the top of the editor to change the center view back to the viewport."),
		gtr("This will show you the player character once again."),
	])
	bubble_add_task(
		gtr("Navigate to the [b]2D[/b] view."),
		1,
		func task_navigate_to_2d_view(task: Task) -> int:
			return 1 if interface.canvas_item_editor.visible else 0
	)
	complete_step()

	context_set_2d()
	highlight_controls([interface.main_screen_tabs], true)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(gtr("Change the active scene"))
	bubble_add_text([
		gtr("Let's change the active scene to the completed project scene."),
		gtr("Click on the [b]completed_project[/b] tab above the central viewport to change the scene."),
	])
	bubble_add_task(
		gtr("Navigate to the Completed Project scene."),
		1,
		func task_open_completed_project_scene(task: Task) -> int:
			var scene_root: Node = EditorInterface.get_edited_scene_root()
			if scene_root == null:
				return 0
			return 1 if scene_root.name == "Main" else 0
	)
	complete_step()

	context_set_2d()
	scene_open(scene_completed_project)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("Signals"))
	bubble_add_text([
		gtr("Games have buttons, doors, chests and a myriad of other elements you interact with and that you expect to respond in a specific way."),
		gtr("To do what you need them to do, these elements need to report events to the game to trigger the action you expect them to trigger."),
		gtr("We call that a signal."),
	])
	complete_step()

	highlight_scene_nodes_by_path(["Main/Player"])
	highlight_controls([interface.node_dock_signals_editor])
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("Click the signal icon"))
	bubble_add_text([
		gtr("In the [b]Scene Dock[/b] at the top-left, look at the [b]Player[/b] node."),
		gtr("You can see the [b]Signal Emission[/b] %s icon emitting little waves. This icon tells you that the node has a signal connection.") % bbcode_generate_icon_image_string(ICONS_MAP.node_signal_connected),
		gtr("Click the icon to open the [b]Node Dock[/b] at the right of the editor."),
	])
	bubble_add_task_set_tab_by_control(interface.node_dock, gtr("Click the signal emission icon next to the [b]Player[/b] node and open the [b]Node Dock[/b]."))
	complete_step()

	highlight_controls([interface.node_dock_signals_editor], true)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.CENTER_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("The Node Dock"))
	bubble_add_text([
		gtr("On the right, you can see the [b]Node Dock[/b]. It lists all the signals of the selected node. In this case, it's the [b]Player[/b] node."),
		gtr("The signal list is long: nodes emit many signals, because there are many kinds of events we need to react to in a game."),
	])
	complete_step()

	highlight_signals(["health_changed"], true)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("The health_changed signal"))
	bubble_add_text([
		gtr("The player node has one especially useful signal: [b]health_changed[/b]."),
		gtr("The [b]health_changed[/b] signal tells us when the player takes damage or heals up."),
	])
	complete_step()

	# Highlights the signal connection line
	highlight_signals(["../UILayer"], true)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("The signal connection"))
	bubble_add_text([
		gtr("Notice the [b]Connected Signal[/b] %s icon below the signal: it shows that the signal is connected to a piece of code.") % bbcode_generate_icon_image_string(ICONS_MAP.script_signal_connected),
		gtr("It means that each time the player health changes, Godot will run the connected piece of code."),
		gtr("We can double-click the line with the green icon to open the connected piece of code."),
	])
	bubble_add_task(
		gtr("Double-click the signal connection in the node dock."),
		1,
		func task_open_health_changed_signal_connection(task: Task) -> int:
			if not interface.is_in_scripting_context():
				return 0
			var open_script: String = EditorInterface.get_script_editor().get_current_script().resource_path
			return 1 if open_script == script_health_bar else 0,
	)
	complete_step()

	highlight_code(17, 24)
	bubble_move_and_anchor(interface.inspector_dock, Bubble.At.BOTTOM_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(gtr("The connected code"))
	bubble_add_text([
		gtr("The script editor reopens and focuses the view on the [b]set_health[/b] function."),
			gtr("A function is a name we give to multiple lines of code for easy reuse: in other game code, we can then use the function name to execute all the lines of code in the function."),
	])
	complete_step()

	# Highlight the set_health function, don't re-center on it to avoid a jump after the previous
	# slide.
	highlight_code(17, 17, 0, false, false)
	bubble_move_and_anchor(interface.inspector_dock, Bubble.At.BOTTOM_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(gtr("The set_health function"))
	bubble_add_text([
		gtr("This function updates the display of the player health bar."),
		gtr("Notice the green [b]Connected Signal[/b] %s icon in the left margin of the script editor. When coding a game, it reminds you of existing signal connections.") % bbcode_generate_icon_image_string(ICONS_MAP.script_signal_connected),
		gtr("So, each time the player health changes, the [b]Player[/b] node emits the [b]health_changed[/b] signal and, in turn, Godot runs the [b]set_health[/b] function that updates the health bar in the running game."),
	])
	complete_step()

	highlight_controls([interface.run_bar_play_button], true)
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.TOP_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_add_task_press_button(interface.run_bar_play_button)
	bubble_set_title(gtr("Run the game"))
	bubble_add_text(
		[gtr("Run the game again and pay attention to the health bar in the top-left."),
		gtr("Move the player character to an enemy and touch them to lose health. You will see the health bar lose one point."),
		gtr("This happens thanks to the [b]health_changed[/b] signal connection."),]
	)
	complete_step()

	queue_command(func debugger_close():
		interface.bottom_button_debugger.button_pressed = false
	)


func steps_090_conclusion() -> void:

	context_set_2d()
	bubble_move_and_anchor(interface.canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(gtr("In summary"))
	bubble_add_text(
		[
			gtr("Godot has four essential concepts on which your games rely: scenes, nodes, scripts, and signals."),
			gtr("[b]Scenes[/b] are reusable templates that represent anything in your game."),
			gtr("[b]Nodes[/b] are the building blocks of scenes. They are the elements you see in the viewport."),
			gtr("[b]Scripts[/b] are text files that give instructions to the computer. You can attach them to nodes to control their behavior."),
			gtr("And [b]Signals[/b] are events that nodes emit to report what's happening in the game. You can connect signals to scripts to run code when an event occurs."),
		]
	)
	complete_step()


	bubble_move_and_anchor(interface.main_screen)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	queue_command(func set_avatar_happy() -> void:
		bubble.avatar.set_expression(Gobot.Expressions.HAPPY)
	)
	bubble_set_background(TEXTURE_BUBBLE_BACKGROUND)
	bubble_add_texture(TEXTURE_GDQUEST_LOGO)
	bubble_set_title(gtr("Congratulations on your first Godot Tour!"))
	bubble_add_text([gtr("[center]Next, we'll practice and learn more by assembling a game[/center]")])
	# TODO: add video of other parts here if on free version
	bubble_set_footer((CREDITS_FOOTER_GDQUEST))
	complete_step()

