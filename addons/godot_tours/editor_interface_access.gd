# Finds and provides easy access to key Control nodes in the Godot editor.
# Extend this script to support additional editor areas or Godot plugins.
#
# This acts as a platform abstraction layer between the Godot editor and GDTour.
# Note that it's still tied to the editor, which can change and break this code.
#
# This version was built quickly for GDTour to experiment with accessing different
# editor parts and test version compatibility. It will be replaced with a more
# robust solution later.
#
# Finding nodes requires different strategies since some nodes can be located
# anywhere. For example, docks can be docked on the sides, in the bottom panel,
# or floating as separate windows. We often have to search for editor elements
# that aren't exposed through the plugin API.
#
# We want avoid positional lookups (child indices, specific node paths, label
# text) when possible since they break easily. However, they're often the most
# straightforward approach and they're pretty much guaranteed to work for a
# specific Godot version.
const Utils := preload("utils.gd")

## Enum for identifying bottom panel tabs. Starting in Godot 4.6, the bottom
## panel's toggle buttons are tabs in a tab bar instead of individual button
## nodes.
enum BottomTabs {
	OUTPUT,
	DEBUGGER,
	AUDIO,
	ANIMATION,
	SHADER_EDITOR,
	SPRITE_FRAMES,
	THEME,
	TILESET,
	TILEMAP,
}

## Maps BottomTabs enum values to their English tab titles as they appear in the
## TabBar.
##
## When the editor is set to a language other than English, at least in Godot
## 4.6, the title property of the tabs in the toolbar remain in English, even if
## the display is in the target language.
const BOTTOM_TAB_TITLES := {
	BottomTabs.OUTPUT: "Output",
	BottomTabs.DEBUGGER: "Debugger",
	BottomTabs.AUDIO: "Audio",
	BottomTabs.ANIMATION: "Animation",
	BottomTabs.SHADER_EDITOR: "Shader Editor",
	BottomTabs.SPRITE_FRAMES: "SpriteFrames",
	BottomTabs.THEME: "Theme",
	BottomTabs.TILESET: "TileSet",
	BottomTabs.TILEMAP: "TileMap",
}

## Enum for identifying editor nodes that may not be available all the time.
## These nodes only exist when specific conditions are met (e.g., selecting a
## TileMapLayer brings up the tilemap editor).
##
## Use with get_dynamic_editor_node() to turn enum values into Control
## references. Also APIs in GDTour use this.
##
## TEMPORARY: to merge/replace with the new cascade editor interface accessor.
enum DynamicEditorNodes {
	SPRITEFRAMES = 0,
	SPRITEFRAMES_ANIMATION,
	SPRITEFRAMES_ANIMATION_TOOLBAR,
	SPRITEFRAMES_ANIMATION_TOOLBAR_ADD_ANIMATION_BUTTON,
	SPRITEFRAMES_ANIMATION_TOOLBAR_COPY_ANIMATION_BUTTON,
	SPRITEFRAMES_ANIMATION_TOOLBAR_PASTE_ANIMATION_BUTTON,
	SPRITEFRAMES_ANIMATION_TOOLBAR_DELETE_ANIMATION_BUTTON,
	SPRITEFRAMES_ANIMATION_TOOLBAR_AUTOPLAY_BUTTON,
	SPRITEFRAMES_ANIMATION_TOOLBAR_LOOPING_BUTTON,
	SPRITEFRAMES_ANIMATION_TOOLBAR_SPEED,
	SPRITEFRAMES_ANIMATION_FILTER,
	SPRITEFRAMES_ANIMATIONS,
	SPRITEFRAMES_FRAMES,
	SPRITEFRAMES_FRAMES_TOOLBAR,
	SPRITEFRAMES_FRAMES_LIST,
	SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_BACK_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_BACK_FROM_END_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_STOP_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_FROM_START_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_ADD_FROM_FILE_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_ADD_FROM_SHEET_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_COPY_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_PASTE_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_INSERT_BEFORE_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_INSERT_AFTER_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_MOVE_LEFT_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_MOVE_RIGHT_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_DELETE_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_FRAME_DURATION,
	SPRITEFRAMES_FRAMES_TOOLBAR_ZOOM_OUT_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_ZOOM_RESET_BUTTON,
	SPRITEFRAMES_FRAMES_TOOLBAR_ZOOM_IN_BUTTON,
	TILEMAP = 50,
	TILEMAP_TABS,
	TILEMAP_LAYERS_BUTTON,
	TILEMAP_PREVIOUS_BUTTON,
	TILEMAP_NEXT_BUTTON,
	TILEMAP_HIGHLIGHT_BUTTON,
	TILEMAP_GRID_BUTTON,
	TILEMAP_MENU_BUTTON,
	TILEMAP_TILES_PANEL,
	TILEMAP_TILES,
	TILEMAP_TILES_TOOLS_SORT_BUTTON,
	TILEMAP_TILES_TOOLBAR,
	TILEMAP_TILES_TOOLBAR_SELECT_BUTTON,
	TILEMAP_TILES_TOOLBAR_PAINT_BUTTON,
	TILEMAP_TILES_TOOLBAR_LINE_BUTTON,
	TILEMAP_TILES_TOOLBAR_RECT_BUTTON,
	TILEMAP_TILES_TOOLBAR_BUCKET_BUTTON,
	TILEMAP_TILES_TOOLBAR_PICKER_BUTTON,
	TILEMAP_TILES_TOOLBAR_ERASER_BUTTON,
	TILEMAP_TILES_TOOLBAR_ROTATE_LEFT_BUTTON,
	TILEMAP_TILES_TOOLBAR_ROTATE_RIGHT_BUTTON,
	TILEMAP_TILES_TOOLBAR_FLIP_H_BUTTON,
	TILEMAP_TILES_TOOLBAR_FLIP_V_BUTTON,
	TILEMAP_TILES_TOOLBAR_CONTIGUOUS_BUTTON,
	TILEMAP_TILES_TOOLBAR_RANDOM_BUTTON,
	TILEMAP_TILES_ATLAS_VIEW,
	TILEMAP_TILES_ATLAS_VIEW_ZOOM_WIDGET,
	TILEMAP_TILES_ATLAS_VIEW_ZOOM_OUT_BUTTON,
	TILEMAP_TILES_ATLAS_VIEW_ZOOM_RESET_BUTTON,
	TILEMAP_TILES_ATLAS_VIEW_ZOOM_IN_BUTTON,
	TILEMAP_TILES_ATLAS_VIEW_CENTER_BUTTON,
	TILEMAP_PATTERNS_PANEL,
	TILEMAP_TERRAINS_PANEL,
	TILEMAP_TERRAINS_TREE,
	TILEMAP_TERRAINS_TILES,
	TILEMAP_TERRAINS_TOOLBAR,
	TILEMAP_TERRAINS_TOOLBAR_PAINT_BUTTON,
	TILEMAP_TERRAINS_TOOLBAR_LINE_BUTTON,
	TILEMAP_TERRAINS_TOOLBAR_RECT_BUTTON,
	TILEMAP_TERRAINS_TOOLBAR_BUCKET_BUTTON,
	TILEMAP_TERRAINS_TOOLBAR_PICKER_BUTTON,
	TILEMAP_TERRAINS_TOOLBAR_ERASER_BUTTON,
	TILEMAP_TERRAINS_TOOLBAR_CONTIGUOUS_BUTTON,
	TILESET = 100,
	TILESET_TABS,
	TILESET_TILES_PANEL,
	TILESET_TILES,
	TILESET_TILES_TOOLS,
	TILESET_TILES_TOOLS_DELETE_BUTTON,
	TILESET_TILES_TOOLS_ADD_BUTTON,
	TILESET_TILES_TOOLS_MENU_BUTTON,
	TILESET_TILES_TOOLS_SORT_BUTTON,
	TILESET_TILES_ATLAS_EDITOR,
	TILESET_TILES_ATLAS_EDITOR_TOOLS,
	TILESET_TILES_ATLAS_EDITOR_TOOLS_SETUP_BUTTON,
	TILESET_TILES_ATLAS_EDITOR_TOOLS_SELECT_BUTTON,
	TILESET_TILES_ATLAS_EDITOR_TOOLS_PAINT_BUTTON,
	TILESET_TILES_ATLAS_EDITOR_SETUP,
	TILESET_TILES_ATLAS_EDITOR_SELECT,
	TILESET_TILES_ATLAS_EDITOR_PAINT,
	TILESET_TILES_ATLAS_EDITOR_TOOLBAR,
	TILESET_TILES_ATLAS_EDITOR_SETUP_TOOLBAR_ERASE_BUTTON,
	TILESET_TILES_ATLAS_EDITOR_SETUP_TOOLBAR_MENU_BUTTON,
	TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW,
	TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_ZOOM_WIDGET,
	TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_ZOOM_OUT_BUTTON,
	TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_ZOOM_RESET_BUTTON,
	TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_ZOOM_IN_BUTTON,
	TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_CENTER_BUTTON,
	TILESET_TILES_SCENE_EDITOR,
	TILESET_TILES_SCENE_EDITOR_PROPERTIES,
	TILESET_TILES_SCENE_EDITOR_SCENE,
	TILESET_TILES_SCENE_EDITOR_TILE,
	TILESET_TILES_SCENE_EDITOR_LIST,
	TILESET_TILES_SCENE_EDITOR_LIST_TOOLS,
	TILESET_TILES_SCENE_EDITOR_LIST_TOOLS_ADD_BUTTON,
	TILESET_TILES_SCENE_EDITOR_LIST_TOOLS_DELETE_BUTTON,
	TILESET_PATTERNS_PANEL,
}

## Array storing references to dynamic editor nodes, indexed by DynamicEditorNodes enum values.
## Nodes are null until their respective editor is populated (e.g., via populate_spriteframes_editor()).
var _dynamic_nodes: Array[Control] = []

## This is the base control of the Godot editor, the parent to all UI nodes in the entire
## application.
var base_control: Control = null

# Title Bar
var menu_bar: MenuBar = null
## The "main screen" buttons centered at the top of the editor (2D, 3D, Script, and AssetLib).
var context_switcher: HBoxContainer = null
var context_switcher_2d_button: Button = null
var context_switcher_3d_button: Button = null
var context_switcher_script_button: Button = null
var context_switcher_game_button: Button = null
var context_switcher_asset_lib_button: Button = null

var run_bar: MarginContainer = null
var run_bar_play_button: Button = null
var run_bar_pause_button: Button = null
var run_bar_stop_button: Button = null
var run_bar_play_current_button: Button = null
var run_bar_play_custom_button: Button = null
var run_bar_movie_mode_button: Button = null
var rendering_options: OptionButton = null

# Main Screen
var main_screen: VBoxContainer = null
var main_screen_tabs: TabBar = null
var main_screen_tabs_add_tab_button: Button = null
var distraction_free_button: Button = null

var canvas_item_editor: Control = null
## The 2D viewport in the 2D editor. Its bounds stop right before the toolbar.
var canvas_item_editor_viewport: Control = null
var canvas_item_editor_toolbar: Control = null
var canvas_item_editor_toolbar_select_button: Button = null
var canvas_item_editor_toolbar_move_button: Button = null
var canvas_item_editor_toolbar_rotate_button: Button = null
var canvas_item_editor_toolbar_scale_button: Button = null
var canvas_item_editor_toolbar_selectable_button: Button = null
var canvas_item_editor_toolbar_pivot_button: Button = null
var canvas_item_editor_toolbar_pan_button: Button = null
var canvas_item_editor_toolbar_ruler_button: Button = null
var canvas_item_editor_toolbar_use_local_button: Button = null
var canvas_item_editor_toolbar_smart_snap_button: Button = null
var canvas_item_editor_toolbar_grid_button: Button = null
var canvas_item_editor_toolbar_snap_options_button: MenuButton = null
var canvas_item_editor_toolbar_lock_button: Button = null
var canvas_item_editor_toolbar_unlock_button: Button = null
var canvas_item_editor_toolbar_group_button: Button = null
var canvas_item_editor_toolbar_ungroup_button: Button = null
var canvas_item_editor_toolbar_skeleton_options_button: Button = null
var canvas_item_editor_center_button: Button = null
## Parent container of the zoom buttons in the top-left of the 2D editor.
var canvas_item_editor_zoom_widget: Control = null
## Lower zoom button in the top-left of the 2D viewport.
var canvas_item_editor_zoom_out_button: Button = null
## Button showing the current zoom percentage in the top-left of the 2D viewport. Pressing it resets
## the zoom to 100%.
var canvas_item_editor_zoom_reset_button: Button = null
## Increase zoom button in the top-left of the 2D viewport.
var canvas_item_editor_zoom_in_button: Button = null

var spatial_editor: Control = null
var spatial_editor_surfaces: Array[Control] = []
var spatial_editor_surfaces_menu_buttons: Array[MenuButton] = []
var spatial_editor_viewports: Array[Control] = []
var spatial_editor_preview_check_boxes: Array[CheckBox] = []
var spatial_editor_cameras: Array[Camera3D] = []
var spatial_editor_toolbar: Control = null
var spatial_editor_toolbar_transform_button: Button = null
var spatial_editor_toolbar_move_button: Button = null
var spatial_editor_toolbar_rotate_button: Button = null
var spatial_editor_toolbar_scale_button: Button = null
var spatial_editor_toolbar_select_button: Button = null
var spatial_editor_toolbar_selectable_button: Button = null
var spatial_editor_toolbar_lock_button: Button = null
var spatial_editor_toolbar_unlock_button: Button = null
var spatial_editor_toolbar_group_button: Button = null
var spatial_editor_toolbar_ruler_button: Button = null
var spatial_editor_toolbar_ungroup_button: Button = null
var spatial_editor_toolbar_local_button: Button = null
var spatial_editor_toolbar_snap_button: Button = null
var spatial_editor_toolbar_camera_button: Button = null
var spatial_editor_toolbar_sun_button: Button = null
var spatial_editor_toolbar_environment_button: Button = null
var spatial_editor_toolbar_sun_environment_button: Button = null
var spatial_editor_toolbar_transform_menu_button: MenuButton = null
var spatial_editor_toolbar_view_menu_button: MenuButton = null

var script_editor: ScriptEditor = null
## Parent node of the script editor, used to pop out the editor and controls the script editor's
## visibility. Used to check if students are in the scripting context.
var script_editor_window_wrapper: Node = null
var script_editor_top_bar: HBoxContainer = null
var script_editor_items: ItemList = null
var script_editor_items_panel: VBoxContainer = null
var script_editor_functions_panel: VBoxContainer = null
var script_editor_code_panel: VBoxContainer = null
var asset_lib: PanelContainer = null

# Snap Dialog, AKA Configure Snap window
var snap_options_window: ConfirmationDialog = null
var snap_options_cancel_button: Button = null
var snap_options_ok_button: Button = null
var snap_options: VBoxContainer = null
var snap_options_grid_offset_controls: Array[Control] = []
var snap_options_grid_step_controls: Array[Control] = []
var snap_options_primary_line_controls: Array[Control] = []
var snap_options_rotation_offset_controls: Array[Control] = []
var snap_options_rotation_step_controls: Array[Control] = []
var snap_options_scale_step_controls: Array[Control] = []

# Left Upper
var scene_tabs: TabBar = null
# Type is SceneTreeDock internally, but it's not exposed
var scene_dock: Control = null
# Below are the panel and buttons for new empty scenes that says create root
# node, where you can create a 2D scene, 3D scene, etc.
var scene_dock_create_root_panel: VBoxContainer = null:
	get = _display_error_and_return_null
var scene_dock_create_root_2d_scene_button: Button = null:
	get = _display_error_and_return_null
var scene_dock_create_root_3d_scene_button: Button = null:
	get = _display_error_and_return_null
var scene_dock_create_root_user_interface_button: Button = null:
	get = _display_error_and_return_null
var scene_dock_create_root_other_node_button: Button = null:
	get = _display_error_and_return_null

# Button to add a node
var scene_dock_add_button: Button = null
var scene_dock_add_script_button: Button = null
var scene_tree: Tree = null
var import_dock: Control = null
var select_node_window: ConfirmationDialog = null

var node_create_window: ConfirmationDialog = null
var node_create_panel: HSplitContainer = null
var node_create_dialog_node_tree: Tree = null
var node_create_dialog_search_bar: LineEdit = null
var node_create_dialog_button_create: Button = null
var node_create_dialog_button_cancel: Button = null

# Left Bttom
var filesystem_tabs: TabBar = null
var filesystem_dock: FileSystemDock = null
var filesystem_tree: Tree = null

# Right
var inspector_tabs: TabBar = null
var inspector_dock: Control = null
var inspector_editor: EditorInspector = null

# Formerly a tab of the Node dock, from Godot 4.6 Signals live in a dedicated dock.
var signals_dock: Control = null
var signals_dock_tree: Tree = null

var signals_dialog_window: ConfirmationDialog = null
var signals_dialog: HBoxContainer = null
var signals_dialog_tree: Tree = null
var signals_dialog_signal_line_edit: LineEdit = null
var signals_dialog_method_line_edit: LineEdit = null
var signals_dialog_cancel_button: Button = null
var signals_dialog_ok_button: Button = null

var groups_dock: Control = null
var groups_dock_groups_editor: VBoxContainer = null
var history_dock: Control = null

# Bottom
# This is the EditorBottomPanel node, which contains the bottom panels TabBar
# and the individually docked bottom panels.
var bottom_panels_container: Control = null

## Array of TileMap editor panels for tab navigation (used by tour.gd).
## Populated by populate_tilemap_and_tileset_editors().
var tilemap_panels: Array[Control] = []

## Array of TileSet editor panels for tab navigation (used by tour.gd).
## Populated by populate_tilemap_and_tileset_editors().
var tileset_panels: Array[Control] = []

var logger: Control = null
var logger_rich_text_label: RichTextLabel = null
var debugger: Control = null
var find_in_files: Control = null
var audio_buses: Control = null
var animation_player: Control = null
var shader: MarginContainer = null

# Up until version 4.6, the bottom panels were accessible through buttons that
# were always present in the editor scene tree. Starting in version 4.6, this
# was replaced with a dynamic tab bar.
## @deprecated: Call get_bottom_tab_index(BottomTab.OUTPUT) and related APIs instead.
var bottom_output_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: Call get_bottom_tab_index(BottomTab.DEBUGGER) and related APIs instead.
var bottom_debugger_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: This button no longer exists in Godot 4.6+.
var bottom_search_results_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: Call get_bottom_tab_index(BottomTab.AUDIO) and related APIs instead.
var bottom_audio_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: Call get_bottom_tab_index(BottomTab.ANIMATION) and related APIs instead.
var bottom_animation_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: This button no longer exists in Godot 4.6+.
var bottom_animation_tree_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: This button no longer exists in Godot 4.6+.
var bottom_resource_preloader_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: Call get_bottom_tab_index(BottomTab.SHADER_EDITOR) and related APIs instead.
var bottom_shader_editor_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: This button no longer exists in Godot 4.6+.
var bottom_shader_file_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: Call get_bottom_tab_index(BottomTab.SPRITE_FRAMES) and related APIs instead.
var bottom_sprite_frames_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: Call get_bottom_tab_index(BottomTab.THEME) and related APIs instead.
var bottom_theme_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: This button no longer exists in Godot 4.6+.
var bottom_polygon_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: Call get_bottom_tab_index(BottomTab.TILESET) and related APIs instead.
var bottom_tileset_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: Call get_bottom_tab_index(BottomTab.TILEMAP) and related APIs instead.
var bottom_tilemap_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: This button no longer exists in Godot 4.6+.
var bottom_replication_button: Button:
	get = _display_error_bottom_button_and_return_null
## @deprecated: This button no longer exists in Godot 4.6+.
var bottom_gridmap_button: Button:
	get = _display_error_bottom_button_and_return_null

var bottom_panels_tab_bar: TabBar = null
var bottom_pin_button: Button = null
var bottom_expand_button: Button = null

var scene_import_settings_window: ConfirmationDialog = null
var scene_import_settings: VBoxContainer = null
var scene_import_settings_ok_button: Button = null
var scene_import_settings_cancel_button: Button = null

var windows: Array[ConfirmationDialog] = []


func _init() -> void:
	# Initialize the dynamic nodes array with null values for all possible enum indices
	_dynamic_nodes.resize(DynamicEditorNodes.size())
	_dynamic_nodes.fill(null)

	var language_offset := (Engine.get_script_language_count() - 1) % 2
	base_control = EditorInterface.get_base_control()

	# Top
	var editor_title_bar := Utils.find_child_by_type(base_control, "EditorTitleBar")
	menu_bar = Utils.find_child_by_type(editor_title_bar, "MenuBar")

	context_switcher = Utils.find_child_by_type(editor_title_bar, "HBoxContainer", true, func(c: HBoxContainer) -> bool: return c.get_child_count() > 1)
	var context_switcher_buttons := context_switcher.get_children()
	context_switcher_2d_button = context_switcher_buttons[0]
	context_switcher_3d_button = context_switcher_buttons[1]
	context_switcher_script_button = context_switcher_buttons[2]
	context_switcher_game_button = context_switcher_buttons[3]
	context_switcher_asset_lib_button = context_switcher_buttons[4]

	run_bar = Utils.find_child_by_type(editor_title_bar, "EditorRunBar")
	var run_bar_buttons = Utils.find_child_by_type(run_bar.get_child(0), "HBoxContainer").find_children("", "Button", true, false)
	# TODO: Find a better way to check for C# engine instead of using scripting language count
	run_bar_play_button = run_bar_buttons[0 + language_offset]
	run_bar_pause_button = run_bar_buttons[1 + language_offset]
	run_bar_stop_button = run_bar_buttons[2 + language_offset]
	run_bar_play_current_button = run_bar_buttons[-3]
	run_bar_play_custom_button = run_bar_buttons[-2]
	run_bar_movie_mode_button = run_bar_buttons[-1]
	rendering_options = Utils.find_child_by_type(editor_title_bar, "OptionButton")

	# Main Screen
	main_screen = EditorInterface.get_editor_main_screen()
	main_screen_tabs = Utils.find_child_by_type(main_screen.get_parent().get_parent(), "TabBar")
	main_screen_tabs_add_tab_button = main_screen_tabs.get_child(0)
	distraction_free_button = main_screen_tabs.get_parent().find_children("", "Button", true, false).back()
	canvas_item_editor = Utils.find_child_by_type(main_screen, "CanvasItemEditor")
	canvas_item_editor_viewport = Utils.find_child_by_type(canvas_item_editor, "CanvasItemEditorViewport")
	canvas_item_editor_toolbar = canvas_item_editor.get_child(0).get_child(0).get_child(0)
	var canvas_item_editor_toolbar_buttons := canvas_item_editor_toolbar.find_children("", "Button", false, false)
	canvas_item_editor_toolbar_select_button = canvas_item_editor_toolbar_buttons[0]
	canvas_item_editor_toolbar_move_button = canvas_item_editor_toolbar_buttons[1]
	canvas_item_editor_toolbar_rotate_button = canvas_item_editor_toolbar_buttons[2]
	canvas_item_editor_toolbar_scale_button = canvas_item_editor_toolbar_buttons[3]
	canvas_item_editor_toolbar_selectable_button = canvas_item_editor_toolbar_buttons[4]
	canvas_item_editor_toolbar_pivot_button = canvas_item_editor_toolbar_buttons[5]
	canvas_item_editor_toolbar_pan_button = canvas_item_editor_toolbar_buttons[6]
	canvas_item_editor_toolbar_ruler_button = canvas_item_editor_toolbar_buttons[7]
	canvas_item_editor_toolbar_use_local_button = canvas_item_editor_toolbar_buttons[8]
	canvas_item_editor_toolbar_smart_snap_button = canvas_item_editor_toolbar_buttons[9]
	canvas_item_editor_toolbar_grid_button = canvas_item_editor_toolbar_buttons[10]
	canvas_item_editor_toolbar_snap_options_button = canvas_item_editor_toolbar_buttons[11]
	canvas_item_editor_toolbar_lock_button = canvas_item_editor_toolbar_buttons[12]
	canvas_item_editor_toolbar_unlock_button = canvas_item_editor_toolbar_buttons[13]
	canvas_item_editor_toolbar_group_button = canvas_item_editor_toolbar_buttons[14]
	canvas_item_editor_toolbar_ungroup_button = canvas_item_editor_toolbar_buttons[15]
	canvas_item_editor_toolbar_skeleton_options_button = canvas_item_editor_toolbar_buttons[16]

	canvas_item_editor_zoom_widget = Utils.find_child_by_type(canvas_item_editor_viewport, "EditorZoomWidget")
	canvas_item_editor_zoom_out_button = canvas_item_editor_zoom_widget.get_child(0)
	canvas_item_editor_zoom_reset_button = canvas_item_editor_zoom_widget.get_child(1)
	canvas_item_editor_zoom_in_button = canvas_item_editor_zoom_widget.get_child(2)
	canvas_item_editor_center_button = canvas_item_editor_zoom_widget.get_parent().get_child(0)

	snap_options_window = Utils.find_child_by_type(base_control, "SnapDialog")
	snap_options = snap_options_window.get_child(0)
	snap_options_cancel_button = snap_options_window.get_cancel_button()
	snap_options_ok_button = snap_options_window.get_ok_button()
	var snap_options_controls: Array[Node] = snap_options.get_child(0).get_children()
	snap_options_grid_offset_controls.assign(snap_options_controls.slice(0, 3))
	snap_options_grid_step_controls.assign(snap_options_controls.slice(3, 6))
	snap_options_primary_line_controls.assign(snap_options_controls.slice(6, 9))
	snap_options_controls = snap_options.get_child(2).get_children()
	snap_options_rotation_offset_controls.assign(snap_options_controls.slice(0, 2))
	snap_options_rotation_step_controls.assign(snap_options_controls.slice(2, 4))
	snap_options_scale_step_controls.assign(snap_options.get_child(4).get_children())

	spatial_editor = Utils.find_child_by_type(main_screen, "Node3DEditor")
	spatial_editor_viewports.assign(spatial_editor.find_children("", "Node3DEditorViewport", true, false))
	spatial_editor_preview_check_boxes.assign(spatial_editor.find_children("", "CheckBox", true, false))
	spatial_editor_cameras.assign(spatial_editor.find_children("", "Camera3D", true, false))
	var surfaces := { }
	for surface in spatial_editor.find_children("", "ViewportNavigationControl", true, false).map(
		func(c: Control) -> Control: return c.get_parent()
	):
		surfaces[surface] = null
	spatial_editor_surfaces.assign(surfaces.keys())
	for surface in spatial_editor_surfaces:
		spatial_editor_surfaces_menu_buttons.append_array(
			surface.find_children("", "MenuButton", true, false),
		)
	spatial_editor_toolbar = spatial_editor.get_child(0).get_child(0).get_child(0)
	var spatial_editor_toolbar_buttons := spatial_editor_toolbar.find_children("", "Button", false, false)
	spatial_editor_toolbar_transform_button = spatial_editor_toolbar_buttons[0]
	spatial_editor_toolbar_move_button = spatial_editor_toolbar_buttons[1]
	spatial_editor_toolbar_rotate_button = spatial_editor_toolbar_buttons[2]
	spatial_editor_toolbar_scale_button = spatial_editor_toolbar_buttons[3]
	spatial_editor_toolbar_select_button = spatial_editor_toolbar_buttons[4]
	spatial_editor_toolbar_selectable_button = spatial_editor_toolbar_buttons[5]
	spatial_editor_toolbar_lock_button = spatial_editor_toolbar_buttons[6]
	spatial_editor_toolbar_unlock_button = spatial_editor_toolbar_buttons[7]
	spatial_editor_toolbar_group_button = spatial_editor_toolbar_buttons[8]
	spatial_editor_toolbar_ungroup_button = spatial_editor_toolbar_buttons[9]
	spatial_editor_toolbar_ruler_button = spatial_editor_toolbar_buttons[10]
	spatial_editor_toolbar_local_button = spatial_editor_toolbar_buttons[11]
	spatial_editor_toolbar_snap_button = spatial_editor_toolbar_buttons[12]
	spatial_editor_toolbar_sun_button = spatial_editor_toolbar_buttons[13]
	spatial_editor_toolbar_environment_button = spatial_editor_toolbar_buttons[14]
	spatial_editor_toolbar_sun_environment_button = spatial_editor_toolbar_buttons[15]
	spatial_editor_toolbar_transform_menu_button = spatial_editor_toolbar_buttons[16]
	spatial_editor_toolbar_view_menu_button = spatial_editor_toolbar_buttons[17]

	script_editor = EditorInterface.get_script_editor()
	script_editor_window_wrapper = script_editor.get_parent()
	script_editor_code_panel = script_editor.get_child(0).get_child(1).get_child(1)
	script_editor_top_bar = script_editor.get_child(0).get_child(0)
	script_editor_items = Utils.find_child_by_type(script_editor, "ItemList")
	script_editor_items_panel = script_editor_items.get_parent()
	script_editor_functions_panel = script_editor_items_panel.get_parent().get_child(1)
	asset_lib = Utils.find_child_by_type(main_screen, "EditorAssetLibrary")

	# Left Upper
	scene_dock = Utils.find_child_by_type(base_control, "SceneTreeDock") as Control

	# TODO: These are community contributed nodes. Access to those broke with
	# release 4.6 as the scene creation panel has a different UI and support for
	# favorited nodes. Re-implement if needed.

	# scene_dock_create_root_panel = scene_dock.get_child(2)
	# var scene_dock_create_root_buttons_container: Control = scene_dock_create_root_panel.get_child(1).get_child(0).get_child(0)
	# scene_dock_create_root_2d_scene_button = scene_dock_create_root_buttons_container.get_child(0)
	# scene_dock_create_root_3d_scene_button = scene_dock_create_root_buttons_container.get_child(1)
	# scene_dock_create_root_user_interface_button = scene_dock_create_root_buttons_container.get_child(2)
	# scene_dock_create_root_other_node_button = scene_dock_create_root_panel.get_child(1).get_child(0).get_child(2)

	# The scene dock has a VBox container, and the buttons to add nodes,
	# instantiate scenes, filter nodes, etc. are now contained in an
	# HBoxContainer.
	var scene_dock_tob_bar: HBoxContainer = scene_dock.get_child(0).get_child(0)
	scene_dock_add_button = scene_dock_tob_bar.get_child(0)
	scene_dock_add_script_button = scene_dock_tob_bar.get_child(3)
	node_create_window = Utils.find_child_by_type(scene_dock, "CreateDialog")
	node_create_panel = Utils.find_child_by_type(node_create_window, "HSplitContainer")
	var node_create_dialog_vboxcontainer: VBoxContainer = Utils.find_child_by_type(node_create_panel, "VBoxContainer", false)
	node_create_dialog_node_tree = Utils.find_child_by_type(node_create_dialog_vboxcontainer, "Tree")
	node_create_dialog_search_bar = Utils.find_child_by_type(node_create_dialog_vboxcontainer, "LineEdit")
	node_create_dialog_button_create = node_create_window.get_ok_button()
	node_create_dialog_button_cancel = node_create_window.get_cancel_button()
	scene_tabs = Utils.find_child_by_type(scene_dock.get_parent(), "TabBar")
	var scene_tree_editor := Utils.find_child_by_type(scene_dock, "SceneTreeEditor")
	scene_tree = Utils.find_child_by_type(scene_tree_editor, "Tree")
	select_node_window = Utils.find_child_by_type(base_control, "SceneTreeDialog")
	import_dock = Utils.find_child_by_type(base_control, "ImportDock") as Control

	# Left Bottom
	filesystem_dock = Utils.find_child_by_type(base_control, "FileSystemDock")
	filesystem_tabs = Utils.find_child_by_type(filesystem_dock.get_parent(), "TabBar")
	filesystem_tree = Utils.find_child_by_type(Utils.find_child_by_type(filesystem_dock, "SplitContainer"), "Tree")

	# Right
	inspector_dock = Utils.find_child_by_type(base_control, "InspectorDock") as Control
	inspector_tabs = Utils.find_child_by_type(inspector_dock.get_parent(), "TabBar")
	inspector_editor = EditorInterface.get_inspector()

	signals_dock = Utils.find_child_by_type(base_control, "SignalsDock") as Control
	signals_dock_tree = Utils.find_child_by_type(signals_dock, "Tree")
	signals_dialog_window = Utils.find_child_by_type(signals_dock, "ConnectDialog")
	signals_dialog = signals_dialog_window.get_child(0)
	signals_dialog_tree = Utils.find_child_by_type(signals_dialog, "Tree")
	var signals_dialog_line_edits := signals_dialog.get_child(0).find_children("", "LineEdit", true, false)
	signals_dialog_signal_line_edit = signals_dialog_line_edits[0]
	signals_dialog_method_line_edit = signals_dialog_line_edits[-1]
	signals_dialog_cancel_button = signals_dialog_window.get_cancel_button()
	signals_dialog_ok_button = signals_dialog_window.get_ok_button()

	groups_dock = Utils.find_child_by_type(base_control, "GroupsDock") as Control
	groups_dock_groups_editor = Utils.find_child_by_type(groups_dock, "GroupsEditor")
	history_dock = Utils.find_child_by_type(base_control, "HistoryDock")

	# Bottom
	bottom_panels_container = Utils.find_child_by_type(base_control, "EditorBottomPanel") as Control

	logger = Utils.find_child_by_type(base_control, "EditorLog") as Control
	logger_rich_text_label = Utils.find_child_by_type(logger, "RichTextLabel")

	debugger = Utils.find_child_by_type(bottom_panels_container, "EditorDebuggerNode", false) as Control
	find_in_files = Utils.find_child_by_type(bottom_panels_container, "FindInFilesPanel", false) as Control
	audio_buses = Utils.find_child_by_type(bottom_panels_container, "EditorAudioBuses", false) as Control
	animation_player = Utils.find_child_by_type(bottom_panels_container, "AnimationPlayerEditor", false) as Control
	shader = Utils.find_child_by_type(bottom_panels_container, "WindowWrapper", false)
	bottom_panels_tab_bar = Utils.find_child_by_type(bottom_panels_container, "TabBar", false)
	var editor_toaster := Utils.find_child_by_type(bottom_panels_container, "EditorToaster")
	var bottom_h_box_container: HBoxContainer = editor_toaster.get_parent()
	bottom_pin_button = bottom_h_box_container.get_child(-2)
	bottom_expand_button = bottom_h_box_container.get_child(-1)

	scene_import_settings_window = Utils.find_child_by_type(base_control, "SceneImportSettingsDialog")
	scene_import_settings = scene_import_settings_window.get_child(0)
	scene_import_settings_cancel_button = scene_import_settings_window.get_cancel_button()
	scene_import_settings_ok_button = scene_import_settings_window.get_ok_button()

	windows.assign([signals_dialog_window, node_create_window, scene_import_settings_window])
	for window in windows:
		window_toggle_tour_mode(window, true)

	_test_buttons()


## Populates references for the SpriteFrames editor.
##
## Call this after the user has selected an AnimatedSprite2D or 3D node with a
## valid SpriteFrames resource or the user just created and expanded a
## SpriteFrames resource in the Inspector.
##
## Returns true if successful, false if the editor is not yet available.
##
## Also, this function caches the nodes and just returns true after successfully
## getting all the nodes.
func populate_spriteframes_editor() -> bool:
	if _dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES] != null:
		return true

	var spriteframes := Utils.find_child_by_type(bottom_panels_container, "SpriteFramesEditor", false)
	if spriteframes == null:
		# Nathan: suppressing the warning because it's for us for debug purposes
		# in development but we don't want students to see/worry about that.
		#
		# push_warning(
		# 	"The SpriteFrames editor could not be found. " +
		# 	"Make sure a SpriteFrames resource is being edited before calling populate_spriteframes_editor(). " +
		# 	"The SpriteFrames editor is only dynamically added to the Godot editor starting in version 4.6, " +
		# 	"so you need to access and cache references to it when a SpriteFrames resource is expanded in the Inspector.",
		# )
		return false

	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES] = spriteframes

	# In 4.6, the structure is one H-split container that contains two VBox
	# Containers that correspond to the left animations pane and the right
	# animation frames pane.
	var hsplit := spriteframes.get_child(0) as HSplitContainer
	var spriteframes_containers := hsplit.find_children("", "VBoxContainer", false, false)

	# Left VBoxContainer
	# This is a VBoxContainer that has a first label child followed by a
	# margin container. The margin container contains a VBox which has a first
	# HBox child which contains the list of animation buttons to add animations
	# etc. This is followed by the filter bar line edit and the tree of
	# animations.
	var spriteframes_animation: VBoxContainer = spriteframes_containers[0].get_child(1).get_child(0)
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATION] = spriteframes_animation

	var spriteframes_animation_toolbar: HBoxContainer = spriteframes_animation.get_child(0)
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR] = spriteframes_animation_toolbar

	var toolbar_buttons := spriteframes_animation_toolbar.find_children("", "Button", true, false)
	var toolbar_spinboxes := spriteframes_animation_toolbar.find_children("", "SpinBox", true, false)
	var animation_toolbar_controls: Array[Control] = []
	animation_toolbar_controls.assign(toolbar_buttons + toolbar_spinboxes)

	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_ADD_ANIMATION_BUTTON] = animation_toolbar_controls[0]
	# Currently we skip over one hidden button and the cut animation button, straight to duplicate.
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_COPY_ANIMATION_BUTTON] = animation_toolbar_controls[3]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_PASTE_ANIMATION_BUTTON] = animation_toolbar_controls[4]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_DELETE_ANIMATION_BUTTON] = animation_toolbar_controls[5]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_AUTOPLAY_BUTTON] = animation_toolbar_controls[6]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_LOOPING_BUTTON] = animation_toolbar_controls[7]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_SPEED] = animation_toolbar_controls[8]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATION_FILTER] = Utils.find_child_by_type(spriteframes_animation, "LineEdit", true)
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_ANIMATIONS] = Utils.find_child_by_type(spriteframes_animation, "Tree", false)

	# Right VBoxContainer
	var spriteframes_frames: VBoxContainer = spriteframes_containers[1].get_child(1).get_child(0)
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES] = spriteframes_frames

	var spriteframes_frames_toolbar: HFlowContainer = spriteframes_frames.get_child(0)
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR] = spriteframes_frames_toolbar

	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_LIST] = spriteframes_frames.get_child(1)

	var spriteframes_frames_toolbar_hboxes := spriteframes_frames_toolbar.find_children("", "HBoxContainer", false, false)
	var frames_buttons_from_hboxes: Array = spriteframes_frames_toolbar_hboxes.slice(
		0,
		spriteframes_frames_toolbar_hboxes.size() - 1,
	).reduce(
		func(acc, h: HBoxContainer) -> Array:
			return acc + h.find_children("", "Button", true, false),
		[],
	)
	var frames_toolbar_controls: Array[Control] = []
	frames_toolbar_controls.assign(frames_buttons_from_hboxes)
	var frames_spinboxes := spriteframes_frames_toolbar.find_children("", "SpinBox", true, false)
	frames_toolbar_controls.append_array(frames_spinboxes)
	var last_hbox_buttons := spriteframes_frames_toolbar_hboxes[-1].find_children("", "Button", true, false)
	frames_toolbar_controls.append_array(last_hbox_buttons)

	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_BACK_BUTTON] = frames_toolbar_controls[0]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_BACK_FROM_END_BUTTON] = frames_toolbar_controls[1]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_STOP_BUTTON] = frames_toolbar_controls[2]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_FROM_START_BUTTON] = frames_toolbar_controls[3]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_BUTTON] = frames_toolbar_controls[4]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_ADD_FROM_FILE_BUTTON] = frames_toolbar_controls[5]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_ADD_FROM_SHEET_BUTTON] = frames_toolbar_controls[6]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_COPY_BUTTON] = frames_toolbar_controls[7]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_PASTE_BUTTON] = frames_toolbar_controls[8]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_INSERT_BEFORE_BUTTON] = frames_toolbar_controls[9]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_INSERT_AFTER_BUTTON] = frames_toolbar_controls[10]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_MOVE_LEFT_BUTTON] = frames_toolbar_controls[11]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_MOVE_RIGHT_BUTTON] = frames_toolbar_controls[12]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_DELETE_BUTTON] = frames_toolbar_controls[13]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_FRAME_DURATION] = frames_toolbar_controls[14]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_ZOOM_OUT_BUTTON] = frames_toolbar_controls[15]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_ZOOM_RESET_BUTTON] = frames_toolbar_controls[16]
	_dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_ZOOM_IN_BUTTON] = frames_toolbar_controls[17]

	return true


## Populates references for the TileSet and TileMap editors.
##
## Call this after the user has selected a TileMapLayer node. The TileMap and
## TileSet editors are added dynamically to the Godot editor starting in version
## 4.6 so we also need to get them dynamically.
##
## Returns true if successful, false if the editor is not yet available.
##
## Also, this function caches the nodes and just returns true after successfully
## getting all the nodes.
func populate_tilemap_and_tileset_editors() -> bool:
	if _dynamic_nodes[DynamicEditorNodes.TILEMAP] != null:
		return true

	var tilemap := Utils.find_child_by_type(bottom_panels_container, "TileMapLayerEditor", false)
	var tileset := Utils.find_child_by_type(bottom_panels_container, "TileSetEditor", false)
	if tilemap == null or tileset == null:
		push_warning(
			"The TileMap or TileSet editor could not be found. " +
			"Make sure a TileMapLayer node is selected before calling populate_tilemap_and_tileset_editors(). " +
			"These editors are only dynamically added to the Godot editor starting in version 4.6, " +
			"so you need to access and cache references to them when a TileMapLayer node is selected in the Scene dock.",
		)
		return false

	_dynamic_nodes[DynamicEditorNodes.TILEMAP] = tilemap
	_dynamic_nodes[DynamicEditorNodes.TILESET] = tileset

	# TileMap Editor
	var tilemap_flow_container: HFlowContainer = Utils.find_child_by_type(tilemap, "HFlowContainer", false)
	print("[DEBUG] TileMap flow_container children: %d" % tilemap_flow_container.get_child_count())
	for i in tilemap_flow_container.get_child_count():
		var child = tilemap_flow_container.get_child(i)
		print("[DEBUG]   FlowContainer[%d]: %s" % [i, child.get_class()])

	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TABS] = tilemap_flow_container.get_child(0)
	print("[DEBUG] tilemap_tabs: %s" % _dynamic_nodes[DynamicEditorNodes.TILEMAP_TABS].get_class())

	var tilemap_flow_layers_hbox := tilemap_flow_container.get_child(4)
	print("[DEBUG] tilemap_flow_layers_hbox: %s (children: %d)" % [tilemap_flow_layers_hbox.get_class(), tilemap_flow_layers_hbox.get_child_count()])
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_LAYERS_BUTTON] = tilemap_flow_layers_hbox.get_child(0)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_PREVIOUS_BUTTON] = tilemap_flow_layers_hbox.get_child(1)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_NEXT_BUTTON] = tilemap_flow_layers_hbox.get_child(2)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_HIGHLIGHT_BUTTON] = tilemap_flow_container.get_child(5)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_GRID_BUTTON] = tilemap_flow_container.get_child(7)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_MENU_BUTTON] = tilemap_flow_container.get_child(8)

	print("[DEBUG] TileMap children count: %d" % tilemap.get_child_count())
	var tilemap_tiles_panel := tilemap.get_child(2)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_PANEL] = tilemap_tiles_panel
	print("[DEBUG] tilemap_tiles_panel: %s" % tilemap_tiles_panel.get_class())

	var tilemap_tiles_hsplitcontainer: HSplitContainer = Utils.find_child_by_type(tilemap_tiles_panel, "HSplitContainer", false)
	print("[DEBUG] tilemap_tiles_hsplitcontainer: %s (children: %d)" % [tilemap_tiles_hsplitcontainer.get_class(), tilemap_tiles_hsplitcontainer.get_child_count()])
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES] = Utils.find_child_by_type(tilemap_tiles_hsplitcontainer.get_child(0), "ItemList")
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLS_SORT_BUTTON] = tilemap_tiles_hsplitcontainer.get_child(0).get_child(1).get_child(0)

	var tilemap_tiles_toolbar := tilemap_flow_container.get_child(1)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR] = tilemap_tiles_toolbar
	print("[DEBUG] tilemap_tiles_toolbar: %s" % tilemap_tiles_toolbar.get_class())

	var tilemap_toolbar_buttons := tilemap_tiles_toolbar.find_children("", "Button", true, false)
	print("[DEBUG] TileMap tiles toolbar buttons found: %d (need 13)" % tilemap_toolbar_buttons.size())
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_SELECT_BUTTON] = tilemap_toolbar_buttons[0]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_PAINT_BUTTON] = tilemap_toolbar_buttons[1]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_LINE_BUTTON] = tilemap_toolbar_buttons[2]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_RECT_BUTTON] = tilemap_toolbar_buttons[3]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_BUCKET_BUTTON] = tilemap_toolbar_buttons[4]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_PICKER_BUTTON] = tilemap_toolbar_buttons[5]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_ERASER_BUTTON] = tilemap_toolbar_buttons[6]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_ROTATE_LEFT_BUTTON] = tilemap_toolbar_buttons[7]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_ROTATE_RIGHT_BUTTON] = tilemap_toolbar_buttons[8]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_FLIP_H_BUTTON] = tilemap_toolbar_buttons[9]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_FLIP_V_BUTTON] = tilemap_toolbar_buttons[10]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_CONTIGUOUS_BUTTON] = tilemap_toolbar_buttons[11]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_RANDOM_BUTTON] = tilemap_toolbar_buttons[12]

	var tilemap_tiles_atlas_view := Utils.find_child_by_type(tilemap_tiles_hsplitcontainer, "TileAtlasView", false)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_ATLAS_VIEW] = tilemap_tiles_atlas_view
	var tilemap_tiles_atlas_view_zoom_widget := Utils.find_child_by_type(tilemap_tiles_atlas_view, "EditorZoomWidget")
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_ATLAS_VIEW_ZOOM_WIDGET] = tilemap_tiles_atlas_view_zoom_widget
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_ATLAS_VIEW_ZOOM_OUT_BUTTON] = tilemap_tiles_atlas_view_zoom_widget.get_child(0)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_ATLAS_VIEW_ZOOM_RESET_BUTTON] = tilemap_tiles_atlas_view_zoom_widget.get_child(1)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_ATLAS_VIEW_ZOOM_IN_BUTTON] = tilemap_tiles_atlas_view_zoom_widget.get_child(2)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_ATLAS_VIEW_CENTER_BUTTON] = tilemap_tiles_atlas_view.get_child(2)

	_dynamic_nodes[DynamicEditorNodes.TILEMAP_PATTERNS_PANEL] = tilemap.get_child(3)

	var tilemap_terrains_panel := tilemap.get_child(4)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_PANEL] = tilemap_terrains_panel
	print("[DEBUG] tilemap_terrains_panel: %s (children: %d)" % [tilemap_terrains_panel.get_class(), tilemap_terrains_panel.get_child_count()])

	var tilemap_terrains_hsplitcontainer: HSplitContainer = tilemap_terrains_panel.get_child(0)
	print("[DEBUG] tilemap_terrains_hsplitcontainer: %s" % tilemap_terrains_hsplitcontainer.get_class())
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_TREE] = Utils.find_child_by_type(tilemap_terrains_hsplitcontainer, "Tree")
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_TILES] = Utils.find_child_by_type(tilemap_terrains_hsplitcontainer, "ItemList")

	var tilemap_terrains_toolbar := tilemap_flow_container.get_child(2)
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR] = tilemap_terrains_toolbar
	print("[DEBUG] tilemap_terrains_toolbar: %s" % tilemap_terrains_toolbar.get_class())

	var tilemap_terrains_buttons := tilemap_terrains_toolbar.find_children("", "Button", true, false)
	print("[DEBUG] TileMap terrains toolbar buttons found: %d (need 7)" % tilemap_terrains_buttons.size())
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_PAINT_BUTTON] = tilemap_terrains_buttons[0]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_LINE_BUTTON] = tilemap_terrains_buttons[1]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_RECT_BUTTON] = tilemap_terrains_buttons[2]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_BUCKET_BUTTON] = tilemap_terrains_buttons[3]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_PICKER_BUTTON] = tilemap_terrains_buttons[4]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_ERASER_BUTTON] = tilemap_terrains_buttons[5]
	_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_CONTIGUOUS_BUTTON] = tilemap_terrains_buttons[6]

	# TileSet Editor
	print("[DEBUG] TileSet children count: %d" % tileset.get_child_count())
	_dynamic_nodes[DynamicEditorNodes.TILESET_TABS] = Utils.find_child_by_type(tileset, "TabBar")
	print("[DEBUG] tileset_tabs: %s" % _dynamic_nodes[DynamicEditorNodes.TILESET_TABS].get_class())

	print("[DEBUG] TileSet.get_child(0) children: %d" % tileset.get_child(0).get_child_count())
	var tileset_tiles_panel := tileset.get_child(0).get_child(1)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_PANEL] = tileset_tiles_panel
	print("[DEBUG] tileset_tiles_panel: %s (children: %d)" % [tileset_tiles_panel.get_class(), tileset_tiles_panel.get_child_count()])

	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES] = Utils.find_child_by_type(tileset_tiles_panel.get_child(0), "ItemList", false)
	var tileset_tiles_tools := Utils.find_child_by_type(tileset_tiles_panel.get_child(0), "HBoxContainer", false)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_TOOLS] = tileset_tiles_tools
	print("[DEBUG] tileset_tiles_tools: %s (children: %d)" % [tileset_tiles_tools.get_class(), tileset_tiles_tools.get_child_count()])

	var tileset_tiles_tool_buttons := tileset_tiles_tools.get_children()
	print("[DEBUG] TileSet tiles tool buttons: %d (need 4)" % tileset_tiles_tool_buttons.size())
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_TOOLS_DELETE_BUTTON] = tileset_tiles_tool_buttons[0]
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_TOOLS_ADD_BUTTON] = tileset_tiles_tool_buttons[1]
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_TOOLS_MENU_BUTTON] = tileset_tiles_tool_buttons[2]
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_TOOLS_SORT_BUTTON] = tileset_tiles_tool_buttons[3]

	var tileset_tiles_atlas_editor := Utils.find_child_by_type(tileset_tiles_panel, "TileSetAtlasSourceEditor")
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR] = tileset_tiles_atlas_editor
	print("[DEBUG] tileset_tiles_atlas_editor: %s (children: %d)" % [tileset_tiles_atlas_editor.get_class(), tileset_tiles_atlas_editor.get_child_count()])

	print("[DEBUG] atlas_editor.get_child(0) children: %d" % tileset_tiles_atlas_editor.get_child(0).get_child_count())
	var tileset_tiles_atlas_editor_tools := tileset_tiles_atlas_editor.get_child(0).get_child(0)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_TOOLS] = tileset_tiles_atlas_editor_tools
	print("[DEBUG] tileset_tiles_atlas_editor_tools: %s (children: %d)" % [tileset_tiles_atlas_editor_tools.get_class(), tileset_tiles_atlas_editor_tools.get_child_count()])

	var tileset_tiles_atlas_editor_tool_buttons := tileset_tiles_atlas_editor_tools.get_children()
	print("[DEBUG] Atlas editor tool buttons: %d (need 3)" % tileset_tiles_atlas_editor_tool_buttons.size())
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_TOOLS_SETUP_BUTTON] = tileset_tiles_atlas_editor_tool_buttons[0]
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_TOOLS_SELECT_BUTTON] = tileset_tiles_atlas_editor_tool_buttons[1]
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_TOOLS_PAINT_BUTTON] = tileset_tiles_atlas_editor_tool_buttons[2]
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_SETUP] = tileset_tiles_atlas_editor.get_child(0).get_child(4)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_SELECT] = tileset_tiles_atlas_editor.get_child(0).get_child(1)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_PAINT] = tileset_tiles_atlas_editor.get_child(0).get_child(3)

	print("[DEBUG] Accessing tileset_tiles_atlas_editor.get_child(1)")
	var tileset_tiles_atlas_editor_right: VBoxContainer = tileset_tiles_atlas_editor.get_child(1)
	print("[DEBUG] tileset_tiles_atlas_editor_right: %s (children: %d)" % [tileset_tiles_atlas_editor_right.get_class(), tileset_tiles_atlas_editor_right.get_child_count()])

	var tileset_tiles_atlas_editor_toolbar := tileset_tiles_atlas_editor_right.get_child(0)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_TOOLBAR] = tileset_tiles_atlas_editor_toolbar
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_SETUP_TOOLBAR_ERASE_BUTTON] = tileset_tiles_atlas_editor_toolbar.get_child(1)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_SETUP_TOOLBAR_MENU_BUTTON] = tileset_tiles_atlas_editor_toolbar.get_child(2)

	var tileset_tiles_atlas_editor_atlas_view := Utils.find_child_by_type(tileset_tiles_atlas_editor_right, "TileAtlasView")
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW] = tileset_tiles_atlas_editor_atlas_view
	var tileset_tiles_atlas_editor_atlas_view_zoom_widget := Utils.find_child_by_type(tileset_tiles_atlas_editor_atlas_view, "EditorZoomWidget")
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_ZOOM_WIDGET] = tileset_tiles_atlas_editor_atlas_view_zoom_widget
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_ZOOM_OUT_BUTTON] = tileset_tiles_atlas_editor_atlas_view_zoom_widget.get_child(0)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_ZOOM_RESET_BUTTON] = tileset_tiles_atlas_editor_atlas_view_zoom_widget.get_child(1)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_ZOOM_IN_BUTTON] = tileset_tiles_atlas_editor_atlas_view_zoom_widget.get_child(2)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_CENTER_BUTTON] = tileset_tiles_atlas_editor_atlas_view.get_child(2)

	var tileset_tiles_scene_editor := Utils.find_child_by_type(tileset_tiles_panel, "TileSetScenesCollectionSourceEditor")
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_SCENE_EDITOR] = tileset_tiles_scene_editor
	print("[DEBUG] tileset_tiles_scene_editor: %s (children: %d)" % [tileset_tiles_scene_editor.get_class(), tileset_tiles_scene_editor.get_child_count()])
	print("[DEBUG] scene_editor.get_child(0) children: %d" % tileset_tiles_scene_editor.get_child(0).get_child_count())

	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_SCENE_EDITOR_PROPERTIES] = tileset_tiles_scene_editor.get_child(0).get_child(0)
	var tileset_tiles_scene_editor_inspectors := tileset_tiles_scene_editor.find_children("", "EditorInspector", true, false)
	print("[DEBUG] Scene editor EditorInspectors found: %d (need 2)" % tileset_tiles_scene_editor_inspectors.size())
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_SCENE_EDITOR_SCENE] = tileset_tiles_scene_editor_inspectors[0]
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_SCENE_EDITOR_TILE] = tileset_tiles_scene_editor_inspectors[1]
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_SCENE_EDITOR_LIST] = tileset_tiles_scene_editor.get_child(0).get_child(1).get_child(0)

	var tileset_tiles_scene_editor_list_tools := tileset_tiles_scene_editor.get_child(0).get_child(1).get_child(1)
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_SCENE_EDITOR_LIST_TOOLS] = tileset_tiles_scene_editor_list_tools
	print("[DEBUG] tileset_tiles_scene_editor_list_tools: %s (children: %d)" % [tileset_tiles_scene_editor_list_tools.get_class(), tileset_tiles_scene_editor_list_tools.get_child_count()])

	var tileset_tiles_scene_editor_list_tool_buttons := tileset_tiles_scene_editor_list_tools.get_children()
	print("[DEBUG] Scene editor list tool buttons: %d (need 2)" % tileset_tiles_scene_editor_list_tool_buttons.size())
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_SCENE_EDITOR_LIST_TOOLS_ADD_BUTTON] = tileset_tiles_scene_editor_list_tool_buttons[0]
	_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_SCENE_EDITOR_LIST_TOOLS_DELETE_BUTTON] = tileset_tiles_scene_editor_list_tool_buttons[1]

	_dynamic_nodes[DynamicEditorNodes.TILESET_PATTERNS_PANEL] = tileset.get_child(0).get_child(2)

	# Populate panels arrays for external use (used by tour.gd)
	tilemap_panels = [
		_dynamic_nodes[DynamicEditorNodes.TILEMAP_TILES_PANEL],
		_dynamic_nodes[DynamicEditorNodes.TILEMAP_PATTERNS_PANEL],
		_dynamic_nodes[DynamicEditorNodes.TILEMAP_TERRAINS_PANEL],
	]
	tileset_panels = [
		_dynamic_nodes[DynamicEditorNodes.TILESET_TILES_PANEL],
		_dynamic_nodes[DynamicEditorNodes.TILESET_PATTERNS_PANEL],
	]

	return true


# TODO: move to a build system step instead of running it on every plugin load
func _test_buttons() -> void:
	check_button_icons(
		{
			context_switcher_2d_button: ["context_switcher_2d_button", "2D"],
			context_switcher_3d_button: ["context_switcher_3d_button", "3D"],
			context_switcher_script_button: ["context_switcher_script_button", "Script"],
			context_switcher_game_button: ["context_switcher_game_button", "Game"],
			context_switcher_asset_lib_button: ["context_switcher_asset_lib_button", "AssetLib"],
			run_bar_play_button: ["run_bar_play_button", "MainPlay"],
			run_bar_pause_button: ["run_bar_pause_button", "Pause"],
			run_bar_stop_button: ["run_bar_stop_button", "Stop"],
			run_bar_play_current_button: ["run_bar_play_current_button", "PlayScene"],
			run_bar_play_custom_button: ["run_bar_play_custom_button", "PlayCustom"],
			run_bar_movie_mode_button: ["run_bar_movie_mode_button", "MainMovieWrite"],
			distraction_free_button: ["distraction_free_button", "DistractionFree"],
			canvas_item_editor_toolbar_select_button: ["canvas_item_editor_toolbar_select_button", "ToolSelect"],
			canvas_item_editor_toolbar_move_button: ["canvas_item_editor_toolbar_move_button", "ToolMove"],
			canvas_item_editor_toolbar_rotate_button: ["canvas_item_editor_toolbar_rotate_button", "ToolRotate"],
			canvas_item_editor_toolbar_scale_button: ["canvas_item_editor_toolbar_scale_button", "ToolScale"],
			canvas_item_editor_toolbar_selectable_button: ["canvas_item_editor_toolbar_selectable_button", "ListSelect"],
			canvas_item_editor_toolbar_pivot_button: ["canvas_item_editor_toolbar_pivot_button", "EditPivot"],
			canvas_item_editor_toolbar_pan_button: ["canvas_item_editor_toolbar_pan_button", "ToolPan"],
			canvas_item_editor_toolbar_ruler_button: ["canvas_item_editor_toolbar_ruler_button", "Ruler"],
			canvas_item_editor_toolbar_use_local_button: ["canvas_item_editor_toolbar_use_local_button", "Object"],
			canvas_item_editor_toolbar_smart_snap_button: ["canvas_item_editor_toolbar_smart_snap_button", "Snap"],
			canvas_item_editor_toolbar_grid_button: ["canvas_item_editor_toolbar_grid_button", "SnapGrid"],
			canvas_item_editor_toolbar_snap_options_button: ["canvas_item_editor_toolbar_snap_options_button", "GuiTabMenuHl"],
			canvas_item_editor_toolbar_lock_button: ["canvas_item_editor_toolbar_lock_button", "Lock"],
			canvas_item_editor_toolbar_unlock_button: ["canvas_item_editor_toolbar_unlock_button", "Unlock"],
			canvas_item_editor_toolbar_group_button: ["canvas_item_editor_toolbar_group_button", "Group"],
			canvas_item_editor_toolbar_ungroup_button: ["canvas_item_editor_toolbar_ungroup_button", "Ungroup"],
			canvas_item_editor_toolbar_skeleton_options_button: ["canvas_item_editor_toolbar_skeleton_options_button", "Bone"],
			canvas_item_editor_center_button: ["canvas_item_editor_center_button", "CenterView"],
			canvas_item_editor_zoom_out_button: ["canvas_item_editor_zoom_out_button", "ZoomLess"],
			canvas_item_editor_zoom_in_button: ["canvas_item_editor_zoom_in_button", "ZoomMore"],
			spatial_editor_toolbar_select_button: ["spatial_editor_toolbar_select_button", "ToolSelect"],
			spatial_editor_toolbar_move_button: ["spatial_editor_toolbar_move_button", "ToolMove"],
			spatial_editor_toolbar_rotate_button: ["spatial_editor_toolbar_rotate_button", "ToolRotate"],
			spatial_editor_toolbar_scale_button: ["spatial_editor_toolbar_scale_button", "ToolScale"],
			spatial_editor_toolbar_selectable_button: ["spatial_editor_toolbar_selectable_button", "ListSelect"],
			spatial_editor_toolbar_lock_button: ["spatial_editor_toolbar_lock_button", "Lock"],
			spatial_editor_toolbar_unlock_button: ["spatial_editor_toolbar_unlock_button", "Unlock"],
			spatial_editor_toolbar_group_button: ["spatial_editor_toolbar_group_button", "Group"],
			spatial_editor_toolbar_ungroup_button: ["spatial_editor_toolbar_ungroup_button", "Ungroup"],
			spatial_editor_toolbar_ruler_button: ["spatial_editor_toolbar_ruler_button", "Ruler"],
			spatial_editor_toolbar_local_button: ["spatial_editor_toolbar_local_button", "Object"],
			spatial_editor_toolbar_snap_button: ["spatial_editor_toolbar_snap_button", "Snap"],
			spatial_editor_toolbar_sun_button: ["spatial_editor_toolbar_sun_button", "PreviewSun"],
			spatial_editor_toolbar_environment_button: ["spatial_editor_toolbar_environment_button", "PreviewEnvironment"],
			spatial_editor_toolbar_sun_environment_button: ["spatial_editor_toolbar_sun_environment_button", "GuiTabMenuHl"],
			main_screen_tabs_add_tab_button: ["main_screen_tabs_add_tab_button", "Add"],
			scene_dock_add_button: ["scene_dock_add_button", "Add"],
			scene_dock_add_script_button: ["scene_dock_add_script_button", "Script"],
			bottom_pin_button: ["bottom_pin_button", "Pin"],
			bottom_expand_button: ["bottom_expand_button", "ExpandBottomDock"],
		},
	)


func clean_up() -> void:
	for window in windows:
		window_toggle_tour_mode(window, false)
	_editor_requests.clear()
	_disconnect_editor_selection_changed()


func window_toggle_tour_mode(window: ConfirmationDialog, is_in_tour: bool) -> void:
	window.dialog_close_on_escape = not is_in_tour
	window.transient = is_in_tour
	window.exclusive = not is_in_tour
	window.physics_object_picking = is_in_tour
	window.physics_object_picking_sort = is_in_tour


## Applies the Default layout to the editor.
## This is the equivalent of going to Editor -> Editor Layout -> Default.
##
## We call this at the start of a tour, so that every tour starts from the same base layout.
## This can't be done in the _init() function because upon opening Godot, loading previously opened
## scenes and restoring the user's editor layout can take several seconds.
func restore_default_layout() -> void:
	var editor_popup_menu := menu_bar.get_menu_popup(3)
	for layouts_popup_menu: PopupMenu in editor_popup_menu.get_children():
		var id: int = layouts_popup_menu.get_item_id(3)
		layouts_popup_menu.id_pressed.emit(id)


func unfold_tree_item(item: TreeItem) -> void:
	var parent := item.get_parent()
	if parent != null:
		item = parent

	var tree := item.get_tree()
	while item != tree.get_root():
		item.collapsed = false
		item = item.get_parent()


func is_in_scripting_context() -> bool:
	return script_editor_window_wrapper.visible


func check_button_icons(buttons_info: Dictionary[Button, Array]) -> void:
	var editor_theme := EditorInterface.get_editor_theme()
	for button: Button in buttons_info:
		var button_name: StringName = buttons_info[button][0]
		var icon_name: StringName = buttons_info[button][1]
		var editor_has_icon := editor_theme.has_icon(icon_name, "EditorIcons")
		if editor_has_icon and button != null and button.icon != editor_theme.get_icon(icon_name, "EditorIcons"):
			push_warning("Button `%s` should have `%s` icon, but doesn't!" % [button_name, icon_name])
		elif button == null:
			push_warning("Button `%s` is null!" % button_name)
		elif not editor_has_icon:
			push_warning("Icon `%s` doesn't exist in the `EditorIcons` theme type! Check for typos." % icon_name)


## Returns the index of the specified bottom panel tab, or -1 if not found.
##
## The tab may not be found if it's a dynamic tab (like TileSet, TileMap, or
## SpriteFrames) and the corresponding node is not selected, or if it's hidden.
func get_bottom_tab_index(tab: BottomTabs) -> int:
	var target_title: String = BOTTOM_TAB_TITLES.get(tab, "")
	if target_title.is_empty():
		push_error("Trying to find bottom tabs with invalid BottomTabs enum value: %d" % tab)
		return -1

	for i in range(bottom_panels_tab_bar.tab_count):
		if bottom_panels_tab_bar.get_tab_title(i) == target_title:
			return i
	return -1


# TODO: consider moving the next 2 helpers to the overlays module as they arent'
# about access.
## Returns the global Rect2 of the specified bottom panel tab,
## or an empty Rect2 if the tab is not found.
##
## Use this for highlighting tabs in tutorials with overlays.
func get_bottom_tab_global_rect(tab: BottomTabs) -> Rect2:
	var tab_index := get_bottom_tab_index(tab)
	if tab_index == -1:
		return Rect2()

	var local_rect := bottom_panels_tab_bar.get_tab_rect(tab_index)
	if local_rect == Rect2():
		return Rect2()

	return Rect2(
		bottom_panels_tab_bar.global_position + local_rect.position,
		local_rect.size,
	)


## Selects the specified bottom panel tab. Returns true if successful,
## false if the tab was not found.
func select_bottom_tab(tab: BottomTabs) -> bool:
	var tab_index := get_bottom_tab_index(tab)
	if tab_index == -1:
		var tab_name: String = BOTTOM_TAB_TITLES.get(tab, "Unknown")
		push_warning("Cannot select bottom tab '%s': tab not found. It may be a dynamic tab that requires selecting a specific node first." % tab_name)
		return false
	bottom_panels_tab_bar.current_tab = tab_index
	return true


func _display_error_and_return_null():
	# This function is here to warn about accessing unsupported nodes that need
	# code updates in your versions of Godot.
	push_error(
		"You cannot access this node in the current version of GDTour. " +
		"The Godot editor changed in Godot 4.6 and the code to access this node needs to be updated to support it. " +
		"If you'd like to help restore support for this node, please head to https://github.com/GDQuest/GDTour/",
	)
	return null


func _display_error_bottom_button_and_return_null():
	push_error(
		"You cannot access this node in the current version of GDTour. " +
		"Bottom panel buttons do not exist anymore. They were replaced by are now tabs in a TabBar node. " +
		"Use get_bottom_tab_index(), get_bottom_tab_rect() or select_bottom_tab() instead.",
	)
	return null


func _display_error_nonexistent_and_return_null():
	push_error(
		"You cannot access this node in the current version of GDTour. " +
		"The Godot editor changed in Godot 4.6 and this node does not exist anymore. " +
		"Please review the editor interface access API to find available nodes in godot 4.6.",
	)
	return null

# ------------------------------------------------------------------------
# DYNAMIC EDITORS API
# ------------------------------------------------------------------------
#
# These editors only appear when specific nodes are selected and may take
# several frames to appear in the editor UI. At first these are bottom panels.
enum DynamicEditors {
	SPRITEFRAMES,
	TILEMAP,
	TILESET,
}

# Mapping of {DynamicEditors = {callback = Callable, is_polling = bool}}
var _editor_requests: Dictionary[DynamicEditors, Dictionary] = { }
# Tracks if the editor's selection changed signal is currently connected.
var _is_selection_changed_connected := false

## emitted when an editor access requested by calling request editor was
## populated. This passes the editor that was made accessible as an argument.
##
## Usually you don't need to listen to this signal because GDTour polls node
## references and will, for example, automatically highlight a UI node as soon
## as it becomes available.
signal requested_editor_was_populated(editor_type: DynamicEditors)

## Call this when you need to access one of the dynamic editors. Starting in
## version 4.6, some bottom panel editors are added to the Godot editor
## dynamically.
##
## Dynamic editors (SpriteFrames, TileMap, TileSet) only appear when specific
## nodes are selected and may take several frames to appear in the editor UI.
##
## Use it like that from your tour's _build() function:
## interface.request_editor(interface.DynamicEditors.SPRITEFRAMES)
## Optionally pass a signal to be notified when the editor is ready.
func request_editor(editor_type: DynamicEditors) -> void:
	if _is_editor_ready(editor_type):
		requested_editor_was_populated.emit(editor_type)
		return

	_editor_requests[editor_type] = {
		"is_polling": false,
	}

	var selection := EditorInterface.get_selection()
	if not selection.selection_changed.is_connected(_on_editor_selection_changed):
		selection.selection_changed.connect(_on_editor_selection_changed)
		_is_selection_changed_connected = true

	_check_editor_preconditions_and_poll(editor_type)


func _is_editor_ready(editor_type: DynamicEditors) -> bool:
	match editor_type:
		DynamicEditors.SPRITEFRAMES:
			return _dynamic_nodes[DynamicEditorNodes.SPRITEFRAMES] != null
		DynamicEditors.TILEMAP:
			return _dynamic_nodes[DynamicEditorNodes.TILEMAP] != null
		DynamicEditors.TILESET:
			return _dynamic_nodes[DynamicEditorNodes.TILESET] != null
	return false


func _disconnect_editor_selection_changed() -> void:
	if not _is_selection_changed_connected:
		return

	var selection := EditorInterface.get_selection()
	if selection.selection_changed.is_connected(_on_editor_selection_changed):
		selection.selection_changed.disconnect(_on_editor_selection_changed)
	_is_selection_changed_connected = false


func _on_editor_selection_changed() -> void:
	for editor_type in _editor_requests.keys():
		_check_editor_preconditions_and_poll(editor_type)


func _check_editor_preconditions_and_poll(editor_type: DynamicEditors) -> void:
	var request = _editor_requests.get(editor_type)
	if request.is_polling:
		return

	if not _check_editor_preconditions(editor_type):
		return

	request.is_polling = true
	_start_editor_polling(editor_type)


## This function checks if the precondition for finding one of the special
## editors is met, which is often a combination of selecting one specific node
## and this node having a specific resource.
func _check_editor_preconditions(editor_type: DynamicEditors) -> bool:
	var selected := EditorInterface.get_selection().get_selected_nodes()

	if selected.size() != 1:
		return false

	var node: Node = selected[0]
	match editor_type:
		DynamicEditors.SPRITEFRAMES:
			if node is AnimatedSprite2D:
				return node.sprite_frames != null
			return false
		DynamicEditors.TILEMAP:
			return node is TileMapLayer
		DynamicEditors.TILESET:
			if node is TileMapLayer:
				return node.tile_set != null
			return false

	return false


func _start_editor_polling(editor_type: DynamicEditors) -> void:
	var editor_scene_tree := Engine.get_main_loop() as SceneTree

	const POLL_INTERVAL_FRAMES := 3
	const MAX_ATTEMPTS := 500

	var attempt_count := 0
	while attempt_count < MAX_ATTEMPTS:
		for i in POLL_INTERVAL_FRAMES:
			await editor_scene_tree.process_frame
		attempt_count += 1

		var request = _editor_requests.get(editor_type)
		if request == null:
			return

		var success := false
		match editor_type:
			DynamicEditors.SPRITEFRAMES:
				success = populate_spriteframes_editor()
			DynamicEditors.TILEMAP, DynamicEditors.TILESET:
				success = populate_tilemap_and_tileset_editors()

		if success:
			# Nathan: suppressing this for now because we only want this for
			# tour development purposes and we don't have a mechanism to
			# automatically suppress that when distributing to students yet.
			#
			# print(
			# 	"[EditorInterfaceAccess] %s editor populated after %d attempts" % [
			# 		DynamicEditors.keys()[editor_type],
			# 		attempt_count,
			# 	],
			# )

			# The user can pass their own signal to subscribe and get notified
			# when the editor is ready.
			_editor_requests.erase(editor_type)
			requested_editor_was_populated.emit(editor_type)
			break

	if attempt_count >= MAX_ATTEMPTS:
		push_warning(
			"[EditorInterfaceAccess] Timeout waiting for %s editor to appear after %d attempts. " % [
				DynamicEditors.keys()[editor_type],
				MAX_ATTEMPTS,
			] +
			"Make sure the correct node is selected and has the required resources.",
		)
		_editor_requests.erase(editor_type)

	if _editor_requests.is_empty():
		_disconnect_editor_selection_changed()


## Resolves a DynamicEditorNodes enum value to its corresponding Control reference.
## Returns null if the node is not available yet.
##
## Use this function in combination with request_editor() to access dynamic
## editor nodes that may not be available at tour build time.
func get_dynamic_editor_node(node_enum: DynamicEditorNodes) -> Control:
	return _dynamic_nodes[node_enum]


## Returns true if the specified dynamic editor node is currently available.
func is_dynamic_editor_node_available(node_enum: DynamicEditorNodes) -> bool:
	var node := get_dynamic_editor_node(node_enum)
	return node != null and node.is_inside_tree()
