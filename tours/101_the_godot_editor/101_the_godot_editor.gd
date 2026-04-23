extends "res://addons/godot_tours/tour.gd"

const Gobot := preload("res://addons/godot_tours/bubble/gobot/gobot.gd")

const ICONS_MAP = {
	script_signal_connected = "Slot",
	script = "Script",
	open_in_editor = "InstanceOptions",
	node_signal_connected = "Signals",
}

const SCENE_COMPLETED_PROJECT := "res://completed_project.tscn"
const SCRIPT_PLAYER := "res://player/player.gd"
const SCRIPT_HEALTH_BAR := "res://interface/bars/ui_health_bar.gd"


func _build() -> void:
	ended.connect(OS.shell_open.bind("https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/learn_gdscript/learn_gdscript_app"))

	steps_welcome()
	steps_010_intro()
	steps_020_first_look()
	steps_030_opening_scene()
	steps_040_scripts()
	steps_050_signals()
	steps_090_conclusion()
	steps_finale()


func steps_welcome() -> void:
	editor_reset_layout()
	editor_reset_state(
		func reset_editor_state_for_tour():
			var grid_button: Button = EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_GRID_BUTTON)
			grid_button.button_pressed = false
			var smart_snap_button: Button = EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_SMART_SNAP_BUTTON)
			smart_snap_button.button_pressed = false
	)

	bubble_set_welcome_title(atr("Welcome to Godot"))
	bubble_set_welcome_button_text(atr("LET'S GET STARTED!"))
	bubble_add_welcome_text([
		"[center]" + atr("In this tour, you take your first steps in the [b]Godot editor[/b].") + "[/center]",
	], Bubble.BookendTextStyle.RECAP)
	bubble_add_welcome_text([
		"[center]" + atr("You get an overview of the engine's four pillars: [b]Scenes[/b], [b]Nodes[/b], [b]Scripts[/b], and [b]Signals[/b].") + "[/center]",
	], Bubble.BookendTextStyle.KEY)
	bubble_add_welcome_text([
		"[center]" + atr("In the next tour, you'll get to assemble your first game from premade parts and put all this into practice.") + "[/center]",
	], Bubble.BookendTextStyle.INFO)
	queue_welcome_command(func() -> void: bubble._avatar.do_wink())


func steps_010_intro() -> void:
	var canvas_item_editor: Control = EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR)
	var run_bar_play_button: Button = EditorInterfaceAccess.get_node(EditorNodePoints.RUN_BAR_PLAY_BUTTON)

	# 0010: First look at game you'll make
	context_set_2d()
	scene_open(SCENE_COMPLETED_PROJECT)
	highlight_editor_nodes([EditorNodePoints.RUN_BAR_PLAY_BUTTON], true)
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_add_task_press_button(run_bar_play_button)
	bubble_set_title(atr("Try the game"))
	bubble_add_text(
		[
			atr("When a project is first opened in Godot, we land on the [b]Main Scene[/b]. It is the entry point of a Godot game."),
			atr("Click the play icon in the top right of the editor to run the Godot project."),
			atr("Then, press [b]%s[/b] on your keyboard or close the game window to stop the game.") % shortcuts.stop,
		],
	)
	complete_step()

	# 0020: Start of editor tour
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("Editor tour"))
	bubble_add_text(
		[atr("Great! Now let's take a quick tour of the editor.")],
	)
	queue_command(func close_bottom_dock_container():
		var bottom_dock_container: TabContainer = EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_DOCK_MIDDLE_BOTTOM)
		bottom_dock_container.current_tab = -1
	)
	complete_step()


func steps_020_first_look() -> void:
	var canvas_item_editor: Control = EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR)
	var inspector_dock: Control = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK)
	var local_scene_tree: Tree = EditorInterfaceAccess.get_node(EditorNodePoints.SCENE_TREE_LOCAL_TREE)

	# 0040: central viewport
	highlight_editor_nodes([EditorNodePoints.CANVAS_ITEM_EDITOR])
	bubble_move_and_anchor(inspector_dock, Bubble.At.BOTTOM_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(atr("The viewport"))
	bubble_add_text(
		[atr("The central part of the editor outlined in purple is the viewport. It's a view of the currently open [b]scene[/b].")],
	)
	complete_step()

	# 0041: scene explanation
	highlight_editor_nodes([EditorNodePoints.CANVAS_ITEM_EDITOR])
	bubble_set_title(atr("A scene is a reusable template"))
	bubble_add_text(
		[
			atr("In Godot, a scene is a template that can represent anything: A character, a chest, an entire level, a menu, or even a complete game!"),
			atr("We are currently looking at a scene file called [b]%s[/b]. This scene consists of a complete game.") % SCENE_COMPLETED_PROJECT.get_file(),
		],
	)
	complete_step()

	# 0041: looking around
	highlight_editor_nodes([
		EditorNodePoints.SCENE_DOCK,
		EditorNodePoints.FILE_SYSTEM_DOCK,
		EditorNodePoints.INSPECTOR_DOCK,
		EditorNodePoints.MAIN_VIEW_SWITCHER,
		EditorNodePoints.RUN_BAR,
		EditorNodePoints.LAYOUT_DOCK_MIDDLE_BOTTOM,
	])
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("Let's look around"))
	bubble_add_text(
		[atr("We're going to explore the interface next, so you get a good feel for it.")],
	)
	complete_step()

	# 0042: playback controls/game preview buttons
	highlight_editor_nodes([EditorNodePoints.RUN_BAR], true)
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("Runner Buttons"))
	bubble_add_text([atr("Those buttons in the top-right are the Runner Buttons. You can [b]play[/b] and [b]stop[/b] the game with them.")])
	complete_step()

	# 0042: main screen buttons / "context switcher"
	highlight_editor_nodes([EditorNodePoints.MAIN_VIEW_SWITCHER], true)
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("Context Switcher"))
	bubble_add_text(
		[
			atr("Centered at the top of the editor, you find the Godot [b]Context Switcher[/b]."),
			atr("You can change between the different [b]Editor[/b] views here. We are currently on the [b]2D View[/b]. Later, we will switch to the [b]Script Editor[/b]!"),
		],
	)
	complete_step()

	# 0042: scene dock
	context_set_2d()
	highlight_editor_nodes([EditorNodePoints.SCENE_DOCK])
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_LEFT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(atr("Scene Dock"))
	bubble_add_text(
		[
			atr("At the top-left, you have the [b]Scene Dock[/b]. You can see all the building blocks of a scene here."),
			atr("In Godot, these building blocks are called [b]nodes[/b]."),
			atr("A scene is made up of one or more nodes."),
			atr("There are nodes to draw images, play sounds, design animations, and more."),
		],
	)
	complete_step()

	# 0042: Filesystem dock
	highlight_editor_nodes([EditorNodePoints.FILE_SYSTEM_DOCK])
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.BOTTOM_LEFT)
	bubble_set_title(atr("FileSystem Dock"))
	bubble_add_text([atr("At the bottom-left, you can see the [b]FileSystem Dock[/b]. It lists all the files used in your project (all the scenes, images, scripts...).")])
	complete_step()

	# 0044: inspector dock
	highlight_editor_nodes([EditorNodePoints.INSPECTOR_DOCK])
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.CENTER_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("The Inspector"))
	bubble_add_text(
		[
			atr("On the right, we have the [b]Inspector Dock[/b]. In this dock, you can view and edit the properties of selected nodes."),
		],
	)
	complete_step()

	# 0045: inspector test
	scene_deselect_all_nodes()
	highlight_editor_nodes([EditorNodePoints.INSPECTOR_DOCK, EditorNodePoints.SCENE_DOCK])
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	queue_command(
		func set_avatar_surprised() -> void:
			bubble._avatar.set_expression(Gobot.Expressions.SURPRISED)
	)
	bubble_set_title(atr("Try the Inspector"))
	bubble_add_text(
		[
			atr("Try the [b]Inspector[/b]! Click on the different nodes in the [b]Scene Dock[/b] on the left to see their properties in the [b]Inspector[/b] on the right."),
		],
	)
	mouse_click()
	mouse_move_by_callable(
		get_tree_item_center_by_path.bind(local_scene_tree, ("Main")),
		get_tree_item_center_by_path.bind(local_scene_tree, ("Main/Bridges")),
	)
	mouse_click()
	mouse_move_by_callable(
		get_tree_item_center_by_path.bind(local_scene_tree, ("Main/Bridges")),
		get_tree_item_center_by_path.bind(local_scene_tree, ("Main/Player")),
	)
	mouse_click()
	complete_step()

	# 0046: bottom panels
	highlight_editor_nodes([EditorNodePoints.DEBUGGER_DOCK, EditorNodePoints.LAYOUT_DOCK_MIDDLE_BOTTOM])
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.BOTTOM_CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("The Bottom Panels"))
	bubble_add_text(
		[
			atr("At the bottom, you'll find editors like the [b]Output[/b] and [b]Debugger[/b] panels."),
			atr("That's where you'll edit animations, write visual effects code (shaders), and more."),
			atr("These editors are contextual. We'll see what that means in the next tour."),
		],
	)
	complete_step()


func steps_030_opening_scene() -> void:
	var canvas_item_editor: Control = EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR)
	var inspector_dock: Control = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK)

	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_LEFT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	highlight_scene_nodes_by_path(["Main", "Main/Bridges", "Main/InvisibleWalls", "Main/UILayer"])
	bubble_set_title(atr("The complete scene's nodes"))
	bubble_add_text(
		[
			atr("This completed game scene has four [b]nodes[/b]: [b]Main[/b], [b]Bridges[/b], [b]InvisibleWalls[/b], and [b]UILayer[/b]."),
			atr("We can see that in the [b]Scene Dock[/b] at the top-left."),
		],
	)
	complete_step()

	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_LEFT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	highlight_scene_nodes_by_path(["Main/Player"])
	bubble_set_title(atr("Scene instances"))
	bubble_add_text(
		[
			atr("Other elements, like the [b]Player[/b], have an [b]Open In Editor[/b] %s icon.") % bbcode_generate_icon_image_by_name(ICONS_MAP.open_in_editor),
			atr("When you see this icon, you are looking at a [b]scene instance[/b]. It's a copy of another scene. You can think of it as a scene that uses another scene as its template. In Godot, we nest scene instances to create complete games."),
			atr("Click the [b]Open in Editor[/b] %s icon next to the [b]Player[/b] node in the [b]Scene Dock[/b] to open the Player scene.") % bbcode_generate_icon_image_by_name(ICONS_MAP.open_in_editor),
		],
	)
	bubble_add_task(
		(atr("Open the Player scene.")),
		1,
		func task_open_start_scene(_task: Task) -> int:
			var scene_root: Node = EditorInterface.get_edited_scene_root()
			if scene_root == null:
				return 0
			return 1 if scene_root.name == "Player" else 0
	)
	complete_step()

	context_set_2d()
	canvas_item_editor_center_at(Vector2.ZERO)
	canvas_item_editor_zoom_reset()
	highlight_editor_nodes([EditorNodePoints.SCENE_DOCK, EditorNodePoints.CANVAS_ITEM_EDITOR])
	bubble_move_and_anchor(inspector_dock, Bubble.At.BOTTOM_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(atr("The Player scene"))
	bubble_add_text(
		[
			atr("When opening a scene, the [b]Scene Dock[/b] and the viewport update to display the scene's contents."),
			atr("In the Scene Dock at the top-left, you can see all the nodes that form the player's character."),
		],
	)
	complete_step()


func steps_040_scripts() -> void:
	var canvas_item_editor: Control = EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR)
	var inspector_dock: Control = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK)

	bubble_move_and_anchor(canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("Scripts bring nodes to life"))
	bubble_add_text(
		[
			atr("By themselves, nodes and scenes don't interact."),
			atr("To bring them to life, you need to give them instructions by writing code in a script and connecting it to the node or scene."),
			atr("Let's have a look at an example of a script."),
		],
	)
	complete_step()

	highlight_scene_nodes_by_path(["Player"])
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_LEFT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("Open the Player script"))
	bubble_add_text(
		[
			atr("The [b]Player[/b] node has a script file attached to it. We can see this thanks to the [b]Attached Script[/b] %s icon located to the right of the node in the [b]Scene Dock[/b].") % bbcode_generate_icon_image_by_name(ICONS_MAP.script),
			atr("Click the script icon to open the [b]Player Script[/b] in the [b]Script Editor[/b]."),
		],
	)
	bubble_add_task(
		atr("Open the script attached to the [b]Player[/b] node."),
		1,
		func(_task: Task) -> int:
			if not EditorInterfaceAccess.is_script_editor_active():
				return 0
			var open_script: String = EditorInterface.get_script_editor().get_current_script().resource_path
			return 1 if open_script == SCRIPT_PLAYER else 0,
	)
	complete_step()

	highlight_editor_nodes([EditorNodePoints.SCRIPT_EDITOR_CONTAINER])
	bubble_move_and_anchor(inspector_dock, Bubble.At.BOTTOM_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(atr("The scripting context"))
	bubble_add_text(
		[
			atr("We're now in the scripting context, which displays all the code in the open script file."),
			atr("This code gives instructions to the computer about how to move the character, when to play sounds, and more."),
			atr("Don't worry if you can't read the code yet: We made a FREE app to help you [color=#ffd500][b][url=https://gdquest.com/tutorial/godot/learning-paths/learn-gdscript-from-zero/]Learn GDScript from Zero[/url][/b][/color]. It's a free part of our complete course Learn Gamedev From Zero."),
			atr("Use your [b]Mouse Wheel[/b] to scroll up and down the file or click and drag the scrollbar on the right."),
		],
	)
	complete_step()

	highlight_scene_nodes_by_path(["Player", "Player/GodotArmor", "Player/WeaponHolder", "Player/ShakingCamera2D"])
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_LEFT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(atr("Any node can have a script"))
	bubble_add_text(
		[
			atr("If we look back at the [b]Scene Dock[/b] at the top-left, we can see multiple nodes with script icons."),
			atr("You can attach scripts to as many nodes as you need to control their behavior."),
		],
	)
	complete_step()


func steps_050_signals() -> void:
	var canvas_item_editor: Control = EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR)
	var inspector_dock: Control = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK)
	var signals_dock: Control = EditorInterfaceAccess.get_node(EditorNodePoints.SIGNALS_DOCK)
	var run_bar_play_button: Button = EditorInterfaceAccess.get_node(EditorNodePoints.RUN_BAR_PLAY_BUTTON)

	highlight_editor_nodes([EditorNodePoints.MAIN_VIEW_SWITCHER], true)
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("Go back to the 2D view"))
	bubble_add_text(
		[
			atr("We have one more essential pillar of Godot to look at: [b]Signals[/b]."),
			atr("Let's head back to the completed project scene. First, click the 2D workspace at the top of the editor to change the center view back to the viewport."),
			atr("This will show you the player character once again."),
		],
	)
	bubble_add_task(
		atr("Navigate to the [b]2D[/b] view."),
		1,
		func task_navigate_to_2d_view(_task: Task) -> int:
			return 1 if canvas_item_editor.visible else 0
	)
	complete_step()

	context_set_2d()
	highlight_editor_nodes([EditorNodePoints.SCENE_TABS], true)
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(atr("Change the active scene"))
	bubble_add_text(
		[
			atr("Let's change the active scene to the completed project scene."),
			atr("Click on the [b]completed_project[/b] tab above the central viewport to change the scene."),
		],
	)
	bubble_add_task(
		atr("Navigate to the Completed Project scene."),
		1,
		func task_open_completed_project_scene(_task: Task) -> int:
			var scene_root: Node = EditorInterface.get_edited_scene_root()
			if scene_root == null:
				return 0
			return 1 if scene_root.name == "Main" else 0
	)
	complete_step()

	context_set_2d()
	scene_open(SCENE_COMPLETED_PROJECT)
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("Signals"))
	bubble_add_text(
		[
			atr("Games have buttons, doors, chests and a myriad of other elements you interact with and that you expect to respond in a specific way."),
			atr("To do what you need them to do, these elements need to report events to the game to trigger the action you expect them to trigger."),
			atr("We call that a signal."),
		],
	)
	complete_step()

	highlight_scene_nodes_by_path(["Main/Player"])
	highlight_editor_nodes([EditorNodePoints.SIGNALS_DOCK])
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("Click the signal icon"))
	bubble_add_text(
		[
			atr("In the [b]Scene Dock[/b] at the top-left, look at the [b]Player[/b] node."),
			atr("You can see the [b]Signal Emission[/b] %s icon emitting little waves. This icon tells you that the node has a signal connection.") % bbcode_generate_icon_image_by_name(ICONS_MAP.node_signal_connected),
			atr("Click the icon to open the [b]Signals Dock[/b] at the right of the editor."),
		],
	)
	# TODO: Should the check instead be that the user actually activates the "signals" button in the Scene dock?
	bubble_add_task(
		atr("Click the signal emission icon next to the [b]Player[/b] node and open the [b]Signals Dock[/b]."),
		1,
		func(_task: Task) -> int:
			return 1 if signals_dock.is_visible_in_tree() else 0
	)
	complete_step()

	highlight_editor_nodes([EditorNodePoints.SIGNALS_DOCK], true)
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.CENTER_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("The Signals Dock"))
	bubble_add_text(
		[
			atr("On the right, you can see the [b]Signals Dock[/b]. It lists all the signals of the selected node. In this case, it's the [b]Player[/b] node."),
			atr("The signal list is long: nodes emit many signals, because there are many kinds of events we need to react to in a game."),
		],
	)
	complete_step()

	highlight_signals(["health_changed"], true)
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("The health_changed signal"))
	bubble_add_text(
		[
			atr("The player node has one especially useful signal: [b]health_changed[/b]."),
			atr("The [b]health_changed[/b] signal tells us when the player takes damage or heals up."),
		],
	)
	complete_step()

	# Highlights the signal connection line
	highlight_signals(["../UILayer"], true)
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("The signal connection"))
	bubble_add_text(
		[
			atr("Notice the [b]Connected Signal[/b] %s icon below the signal: it shows that the signal is connected to a piece of code.") % bbcode_generate_icon_image_by_name(ICONS_MAP.script_signal_connected),
			atr("It means that each time the player health changes, Godot will run the connected piece of code."),
			atr("We can double-click the line with the green icon to open the connected piece of code."),
		],
	)
	bubble_add_task(
		atr("Double-click the signal connection in the Signals dock."),
		1,
		func task_open_health_changed_signal_connection(_task: Task) -> int:
			if not EditorInterfaceAccess.is_script_editor_active():
				return 0
			var open_script: String = EditorInterface.get_script_editor().get_current_script().resource_path
			return 1 if open_script == SCRIPT_HEALTH_BAR else 0,
	)
	complete_step()

	highlight_code(17, 24)
	bubble_move_and_anchor(inspector_dock, Bubble.At.BOTTOM_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(atr("The connected code"))
	bubble_add_text(
		[
			atr("The script editor reopens and focuses the view on the [b]set_health[/b] function."),
			atr("A function is a name we give to multiple lines of code for easy reuse: in other game code, we can then use the function name to execute all the lines of code in the function."),
		],
	)
	complete_step()

	# Highlight the set_health function, don't re-center on it to avoid a jump after the previous
	# slide.
	highlight_code(17, 17, 0, false, false)
	bubble_move_and_anchor(inspector_dock, Bubble.At.BOTTOM_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_set_title(atr("The set_health function"))
	bubble_add_text(
		[
			atr("This function updates the display of the player health bar."),
			atr("Notice the green [b]Connected Signal[/b] %s icon in the left margin of the script editor. When coding a game, it reminds you of existing signal connections.") % bbcode_generate_icon_image_by_name(ICONS_MAP.script_signal_connected),
			atr("So, each time the player health changes, the [b]Player[/b] node emits the [b]health_changed[/b] signal and, in turn, Godot runs the [b]set_health[/b] function that updates the health bar in the running game."),
		],
	)
	complete_step()

	highlight_editor_nodes([EditorNodePoints.RUN_BAR_PLAY_BUTTON], true)
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.TOP_RIGHT)
	bubble_set_avatar_at(Bubble.AvatarAt.LEFT)
	bubble_add_task_press_button(run_bar_play_button)
	bubble_set_title(atr("Run the game"))
	bubble_add_text(
		[
			atr("Run the game again and pay attention to the health bar in the top-left."),
			atr("Move the player character to an enemy and touch them to lose health. You will see the health bar lose one point."),
			atr("This happens thanks to the [b]health_changed[/b] signal connection."),
		],
	)
	complete_step()


func steps_090_conclusion() -> void:
	var canvas_item_editor: Control = EditorInterfaceAccess.get_node(EditorNodePoints.CANVAS_ITEM_EDITOR)

	context_set_2d()
	bubble_move_and_anchor(canvas_item_editor, Bubble.At.CENTER)
	bubble_set_avatar_at(Bubble.AvatarAt.CENTER)
	bubble_set_title(atr("In summary"))
	bubble_add_text(
		[
			atr("Godot has four essential concepts on which your games rely: scenes, nodes, scripts, and signals."),
			atr("[b]Scenes[/b] are reusable templates that represent anything in your game."),
			atr("[b]Nodes[/b] are the building blocks of scenes. They are the elements you see in the viewport."),
			atr("[b]Scripts[/b] are text files that give instructions to the computer. You can attach them to nodes to control their behavior."),
			atr("And [b]Signals[/b] are events that nodes emit to report what's happening in the game. You can connect signals to scripts to run code when an event occurs."),
		],
	)
	complete_step()


func steps_finale() -> void:
	bubble_set_finale_title(atr("Congratulations on your first Godot Tour!"))
	bubble_set_finale_button_text(atr("CONTINUE LEARNING ON GDSCHOOL"))
	bubble_add_finale_text([
		"[center]" + atr("That's it for your first steps with the Godot editor. Ready to keep learning?") + "[/center]",
	], Bubble.BookendTextStyle.RECAP)
	bubble_add_finale_text([
		"[center]" + atr("If you haven't already, check out the free app [color=#ffd500][b][url=https://gdquest.com/tutorial/godot/learning-paths/learn-gdscript-from-zero/]Learn GDScript from Zero[/url][/b][/color]. It teaches you the basics of coding through 20+ lessons with dozens of interactive exercises where you can immediately practice what you've learned.") + "[/center]",
		"[center]" + atr("You can also explore our courses to [color=#ffd500][b][url=https://school.gdquest.com/products/godot-4-early-access]Pick Up Gamedev From Zero[/url][/b][/color], which offer a comprehensive path to build a game developer's mindset and become independent.") + "[/center]",
	], Bubble.BookendTextStyle.KEY)
	bubble_add_finale_text([
		"[center][b]" + atr("I hope to see you around the GDQuest community!") + "[/b][/center]",
	], Bubble.BookendTextStyle.INFO)
	queue_finale_command(func() -> void: bubble._avatar.set_expression(Gobot.Expressions.HAPPY))
