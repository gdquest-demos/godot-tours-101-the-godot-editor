## Finds and gives easy access to many key Control nodes of the Godot editor.
## Extend this script to add support for more areas of the Godot editor or Godot plugins.
const Utils := preload("utils.gd")

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
var distraction_free_button: Button = null

var canvas_item_editor: VBoxContainer = null
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
var spatial_editor_toolbar_select_button: Button = null
var spatial_editor_toolbar_move_button: Button = null
var spatial_editor_toolbar_rotate_button: Button = null
var spatial_editor_toolbar_scale_button: Button = null
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
var scene_dock: VBoxContainer = null
var scene_dock_add_button: Button = null
var scene_tree: Tree = null
var import_dock: VBoxContainer = null
var select_node_window: ConfirmationDialog = null

var node_create_window: ConfirmationDialog = null
var node_create_panel: HSplitContainer = null
var node_create_dialog_node_tree: Tree = null
var node_create_dialog_search_bar: LineEdit = null
var node_create_dialog_button_create: Button = null
var node_create_dialog_button_cancel: Button = null

# Left Bttom
var filesystem_tabs: TabBar = null
var filesystem_dock: VBoxContainer = null
var filesystem_tree: Tree = null

# Right
var inspector_tabs: TabBar = null
var inspector_dock: VBoxContainer = null
var inspector_editor: EditorInspector = null

var node_dock: VBoxContainer = null
var node_dock_buttons_box: HBoxContainer = null
var node_dock_signals_button: Button = null
var node_dock_groups_button: Button = null
var node_dock_signals_editor: VBoxContainer = null
var node_dock_signals_tree: Tree = null

var signals_dialog_window: ConfirmationDialog = null
var signals_dialog: HBoxContainer = null
var signals_dialog_tree: Tree = null
var signals_dialog_signal_line_edit: LineEdit = null
var signals_dialog_method_line_edit: LineEdit = null
var signals_dialog_cancel_button: Button = null
var signals_dialog_ok_button: Button = null
var node_dock_groups_editor: VBoxContainer = null
var history_dock: VBoxContainer = null

# Bottom
var bottom_panels_container: Control = null

var spriteframes: HSplitContainer = null
var spriteframes_animation: VBoxContainer = null
var spriteframes_animation_toolbar: HBoxContainer = null
var spriteframes_animation_toolbar_controls: Array[Control] = []
var spriteframes_animation_toolbar_add_animation_button: Button = null
var spriteframes_animation_toolbar_duplicate_animation_button: Button = null
var spriteframes_animation_toolbar_delete_animation_button: Button = null
var spriteframes_animation_toolbar_autoplay_button: Button = null
var spriteframes_animation_toolbar_looping_button: Button = null
var spriteframes_animation_toolbar_speed: SpinBox = null
var spriteframes_animation_filter: LineEdit = null
var spriteframes_animations: Tree= null
var spriteframes_frames: VBoxContainer = null
var spriteframes_frames_toolbar: HFlowContainer = null
var spriteframes_frames_toolbar_controls: Array[Control] = []
var spriteframes_frames_list: ItemList = null
var spriteframes_frames_toolbar_play_back_button: Button = null
var spriteframes_frames_toolbar_play_back_from_end_button: Button = null
var spriteframes_frames_toolbar_stop_button: Button = null
var spriteframes_frames_toolbar_play_from_start_button: Button = null
var spriteframes_frames_toolbar_play_button: Button = null
var spriteframes_frames_toolbar_add_from_file_button: Button = null
var spriteframes_frames_toolbar_add_from_sheet_button: Button = null
var spriteframes_frames_toolbar_copy_button: Button = null
var spriteframes_frames_toolbar_paste_button: Button = null
var spriteframes_frames_toolbar_insert_before_button: Button = null
var spriteframes_frames_toolbar_insert_after_button: Button = null
var spriteframes_frames_toolbar_move_left_button: Button = null
var spriteframes_frames_toolbar_move_right_button: Button = null
var spriteframes_frames_toolbar_delete_button: Button = null
var spriteframes_frames_toolbar_frame_duration: SpinBox = null
var spriteframes_frames_toolbar_zoom_out_button: Button = null
var spriteframes_frames_toolbar_zoom_reset_button: Button = null
var spriteframes_frames_toolbar_zoom_in_button: Button = null

var tilemap: Control = null
var tilemap_tabs: TabBar = null
var tilemap_layers_button: OptionButton = null
var tilemap_previous_button: Button = null
var tilemap_next_button: Button = null
var tilemap_highlight_button: Button = null
var tilemap_grid_button: Button = null
var tilemap_menu_button: MenuButton = null

var tilemap_tiles_panel: VBoxContainer = null
var tilemap_tiles: ItemList = null
var tilemap_tiles_tools_sort_button: MenuButton = null
var tilemap_tiles_toolbar: HBoxContainer = null
var tilemap_tiles_toolbar_buttons: Array[Control] = []
var tilemap_tiles_toolbar_select_button: Button = null
var tilemap_tiles_toolbar_paint_button: Button = null
var tilemap_tiles_toolbar_line_button: Button = null
var tilemap_tiles_toolbar_rect_button: Button = null
var tilemap_tiles_toolbar_bucket_button: Button = null
var tilemap_tiles_toolbar_picker_button: Button = null
var tilemap_tiles_toolbar_eraser_button: Button = null
var tilemap_tiles_toolbar_rotate_left_button: Button = null
var tilemap_tiles_toolbar_rotate_right_button: Button = null
var tilemap_tiles_toolbar_flip_h_button: Button = null
var tilemap_tiles_toolbar_flip_v_button: Button = null
var tilemap_tiles_toolbar_contiguous_button: CheckBox = null
var tilemap_tiles_toolbar_random_button: Button = null
var tilemap_tiles_atlas_view: Control = null
var tilemap_tiles_atlas_view_zoom_widget: HBoxContainer = null
var tilemap_tiles_atlas_view_zoom_out_button: Button = null
var tilemap_tiles_atlas_view_zoom_reset_button: Button = null
var tilemap_tiles_atlas_view_zoom_in_button: Button = null
var tilemap_tiles_atlas_view_center_button: Button = null

var tilemap_patterns_panel: VBoxContainer = null

var tilemap_terrains_panel: VBoxContainer = null
## The tree on the left to select terrains in the TileMap -> Terrains tab.
var tilemap_terrains_tree: Tree = null
## The list of terrain drawing mode and individual tiles on the right in the TileMap -> Terrains tab.
var tilemap_terrains_tiles: ItemList = null
var tilemap_terrains_toolbar: HBoxContainer = null
var tilemap_terrains_toolbar_buttons: Array[Button] = []
var tilemap_terrains_toolbar_paint_button: Button = null
var tilemap_terrains_toolbar_line_button: Button = null
var tilemap_terrains_toolbar_rect_button: Button = null
var tilemap_terrains_toolbar_bucket_button: Button = null
var tilemap_terrains_toolbar_picker_button: Button = null
var tilemap_terrains_toolbar_eraser_button: Button = null
var tilemap_terrains_toolbar_contiguous_button: CheckBox = null
var tilemap_panels: Array[Control] = []

var tileset: Control = null
var tileset_tabs: TabBar = null
var tileset_tiles_panel: HSplitContainer = null
var tileset_tiles: ItemList = null
var tileset_tiles_tools: HBoxContainer = null
var tileset_tiles_tool_buttons: Array[Button] = []
var tileset_tiles_tools_delete_button: Button = null
var tileset_tiles_tools_add_button: MenuButton = null
var tileset_tiles_tools_menu_button: MenuButton = null
var tileset_tiles_tools_sort_button: MenuButton = null

var tileset_tiles_atlas_editor: HSplitContainer = null
var tileset_tiles_atlas_editor_tools: HBoxContainer = null
var tileset_tiles_atlas_editor_tool_buttons: Array[Button]= []
var tileset_tiles_atlas_editor_tools_setup_button: Button = null
var tileset_tiles_atlas_editor_tools_select_button: Button = null
var tileset_tiles_atlas_editor_tools_paint_button: Button = null

var tileset_tiles_atlas_editor_setup: EditorInspector = null
var tileset_tiles_atlas_editor_select: EditorInspector = null
var tileset_tiles_atlas_editor_paint: ScrollContainer = null
var tileset_tiles_atlas_editor_toolbar: HBoxContainer = null
var tileset_tiles_atlas_editor_setup_toolbar_erase_button: Button = null
var tileset_tiles_atlas_editor_setup_toolbar_menu_button: MenuButton = null
var tileset_tiles_atlas_editor_atlas_view: Control = null
var tileset_tiles_atlas_editor_atlas_view_zoom_widget: HBoxContainer = null
var tileset_tiles_atlas_editor_atlas_view_zoom_out_button: Button = null
var tileset_tiles_atlas_editor_atlas_view_zoom_reset_button: Button = null
var tileset_tiles_atlas_editor_atlas_view_zoom_in_button: Button = null
var tileset_tiles_atlas_editor_atlas_view_center_button: Button = null

var tileset_tiles_scene_editor: HBoxContainer = null
var tileset_tiles_scene_editor_properties: ScrollContainer = null
var tileset_tiles_scene_editor_scene: EditorInspector = null
var tileset_tiles_scene_editor_tile: EditorInspector = null
var tileset_tiles_scene_editor_list: ItemList = null
var tileset_tiles_scene_editor_list_tools: HBoxContainer = null
var tileset_tiles_scene_editor_list_tool_buttons: Array[Button] = []
var tileset_tiles_scene_editor_list_tools_add_button: Button = null
var tileset_tiles_scene_editor_list_tools_delete_button: Button = null

var tileset_patterns_panel: ItemList = null
var tileset_panels: Array[Control] = []

var logger: HBoxContainer = null
var logger_rich_text_label: RichTextLabel = null
var debugger: MarginContainer = null
var find_in_files: Control = null
var audio_buses: VBoxContainer = null
var animation_player: VBoxContainer = null
var shader: MarginContainer = null

var bottom_buttons_container: HBoxContainer = null
var bottom_output_button: Button = null
var bottom_debugger_button: Button = null
var bottom_search_results_button: Button = null
var bottom_audio_button: Button = null
var bottom_animation_button: Button = null
var bottom_animation_tree_button: Button = null
var bottom_resource_preloader_button: Button = null
var bottom_shader_editor_button: Button = null
var bottom_shader_file_button: Button = null
var bottom_sprite_frames_button: Button = null
var bottom_theme_button: Button = null
var bottom_polygon_button: Button = null
var bottom_tileset_button: Button = null
var bottom_tilemap_button: Button = null
var bottom_replication_button: Button = null
var bottom_gridmap_button: Button = null
var bottom_buttons: Array[Button] = []
var bottom_pin_button: Button = null
var bottom_expand_button: Button = null

var scene_import_settings_window: ConfirmationDialog = null
var scene_import_settings: VBoxContainer = null
var scene_import_settings_ok_button: Button = null
var scene_import_settings_cancel_button: Button = null

var windows: Array[ConfirmationDialog] = []


func _init() -> void:
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
	canvas_item_editor_toolbar_smart_snap_button = canvas_item_editor_toolbar_buttons[8]
	canvas_item_editor_toolbar_grid_button = canvas_item_editor_toolbar_buttons[9]
	canvas_item_editor_toolbar_snap_options_button = canvas_item_editor_toolbar_buttons[10]
	canvas_item_editor_toolbar_lock_button = canvas_item_editor_toolbar_buttons[11]
	canvas_item_editor_toolbar_unlock_button = canvas_item_editor_toolbar_buttons[12]
	canvas_item_editor_toolbar_group_button = canvas_item_editor_toolbar_buttons[13]
	canvas_item_editor_toolbar_ungroup_button = canvas_item_editor_toolbar_buttons[14]
	canvas_item_editor_toolbar_skeleton_options_button = canvas_item_editor_toolbar_buttons[15]

	canvas_item_editor_zoom_widget = Utils.find_child_by_type(canvas_item_editor_viewport, "EditorZoomWidget" )
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
	var surfaces := {}
	for surface in spatial_editor.find_children("", "ViewportNavigationControl", true, false).map(
		func(c: Control) -> Control: return c.get_parent()
	):
		surfaces[surface] = null
	spatial_editor_surfaces.assign(surfaces.keys())
	for surface in spatial_editor_surfaces:
		spatial_editor_surfaces_menu_buttons.append_array(
			surface.find_children("", "MenuButton", true, false)
		)
	spatial_editor_toolbar = spatial_editor.get_child(0).get_child(0).get_child(0)
	var spatial_editor_toolbar_buttons := spatial_editor_toolbar.find_children("", "Button", false, false)
	spatial_editor_toolbar_select_button = spatial_editor_toolbar_buttons[0]
	spatial_editor_toolbar_move_button = spatial_editor_toolbar_buttons[1]
	spatial_editor_toolbar_rotate_button = spatial_editor_toolbar_buttons[2]
	spatial_editor_toolbar_scale_button = spatial_editor_toolbar_buttons[3]
	spatial_editor_toolbar_selectable_button = spatial_editor_toolbar_buttons[4]
	spatial_editor_toolbar_lock_button = spatial_editor_toolbar_buttons[5]
	spatial_editor_toolbar_unlock_button = spatial_editor_toolbar_buttons[6]
	spatial_editor_toolbar_group_button = spatial_editor_toolbar_buttons[7]
	spatial_editor_toolbar_ungroup_button = spatial_editor_toolbar_buttons[8]
	spatial_editor_toolbar_ruler_button = spatial_editor_toolbar_buttons[9]
	spatial_editor_toolbar_local_button = spatial_editor_toolbar_buttons[10]
	spatial_editor_toolbar_snap_button = spatial_editor_toolbar_buttons[11]
	spatial_editor_toolbar_sun_button = spatial_editor_toolbar_buttons[12]
	spatial_editor_toolbar_environment_button = spatial_editor_toolbar_buttons[13]
	spatial_editor_toolbar_sun_environment_button = spatial_editor_toolbar_buttons[14]
	spatial_editor_toolbar_transform_menu_button = spatial_editor_toolbar_buttons[15]
	spatial_editor_toolbar_view_menu_button = spatial_editor_toolbar_buttons[16]

	script_editor = EditorInterface.get_script_editor()
	script_editor_window_wrapper = script_editor.get_parent()
	script_editor_code_panel = script_editor.get_child(0).get_child(1).get_child(1)
	script_editor_top_bar = script_editor.get_child(0).get_child(0)
	script_editor_items = Utils.find_child_by_type(script_editor, "ItemList")
	script_editor_items_panel = script_editor_items.get_parent()
	script_editor_functions_panel = script_editor_items_panel.get_parent().get_child(1)
	asset_lib = Utils.find_child_by_type(main_screen, "EditorAssetLibrary")

	# Left Upper
	scene_dock = Utils.find_child_by_type(base_control, "SceneTreeDock")
	scene_dock_add_button = scene_dock.get_child(0).get_child(0)
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
	import_dock = Utils.find_child_by_type(base_control, "ImportDock")

	# Left Bottom
	filesystem_dock = Utils.find_child_by_type(base_control, "FileSystemDock")
	filesystem_tabs = Utils.find_child_by_type(filesystem_dock.get_parent(), "TabBar")
	filesystem_tree = Utils.find_child_by_type(Utils.find_child_by_type(filesystem_dock, "SplitContainer"), "Tree")

	# Right
	inspector_dock = Utils.find_child_by_type(base_control, "InspectorDock")
	inspector_tabs = Utils.find_child_by_type(inspector_dock.get_parent(), "TabBar")
	inspector_editor = EditorInterface.get_inspector()
	node_dock = Utils.find_child_by_type(base_control, "NodeDock")
	node_dock_buttons_box = node_dock.get_child(0)
	var node_dock_buttons := node_dock_buttons_box.get_children()
	node_dock_signals_button = node_dock_buttons[0]
	node_dock_groups_button = node_dock_buttons[1]
	node_dock_signals_editor = Utils.find_child_by_type(node_dock, "ConnectionsDock")
	node_dock_signals_tree = Utils.find_child_by_type(node_dock_signals_editor, "Tree")

	signals_dialog_window = Utils.find_child_by_type(node_dock_signals_editor, "ConnectDialog")
	signals_dialog = signals_dialog_window.get_child(0)
	signals_dialog_tree = Utils.find_child_by_type(signals_dialog, "Tree")
	var signals_dialog_line_edits := signals_dialog.get_child(0).find_children("", "LineEdit", true, false)
	signals_dialog_signal_line_edit = signals_dialog_line_edits[0]
	signals_dialog_method_line_edit = signals_dialog_line_edits[-1]
	signals_dialog_cancel_button = signals_dialog_window.get_cancel_button()
	signals_dialog_ok_button = signals_dialog_window.get_ok_button()
	node_dock_groups_editor = Utils.find_child_by_type(node_dock, "GroupsEditor")
	history_dock = Utils.find_child_by_type(base_control, "HistoryDock")

	# Bottom
	logger = Utils.find_child_by_type(base_control, "EditorLog")
	logger_rich_text_label = Utils.find_child_by_type(logger, "RichTextLabel")

	bottom_panels_container = logger.get_parent().get_parent()
	var bottom_panels_vboxcontainer: VBoxContainer = logger.get_parent()

	debugger = Utils.find_child_by_type(bottom_panels_vboxcontainer, "EditorDebuggerNode", false)
	find_in_files = Utils.find_child_by_type(bottom_panels_vboxcontainer, "FindInFilesPanel", false)
	audio_buses = Utils.find_child_by_type(bottom_panels_vboxcontainer, "EditorAudioBuses", false)
	animation_player = Utils.find_child_by_type(bottom_panels_vboxcontainer, "AnimationPlayerEditor", false)
	shader = Utils.find_child_by_type(bottom_panels_vboxcontainer, "WindowWrapper", false)
	var editor_toaster := Utils.find_child_by_type(bottom_panels_vboxcontainer, "EditorToaster")
	var bottom_h_box_container: HBoxContainer = editor_toaster.get_parent()
	bottom_buttons_container = Utils.find_child_by_type(Utils.find_child_by_type(bottom_h_box_container, "ScrollContainer", false), "HBoxContainer", false)

	bottom_buttons.assign(bottom_buttons_container.get_children())
	bottom_output_button = bottom_buttons[0]
	bottom_debugger_button = bottom_buttons[1]
	bottom_search_results_button = bottom_buttons[2]
	bottom_audio_button = bottom_buttons[3]
	bottom_animation_button = bottom_buttons[4]
	bottom_animation_tree_button = bottom_buttons[5]
	bottom_resource_preloader_button = bottom_buttons[6]
	bottom_shader_editor_button = bottom_buttons[7]
	bottom_shader_file_button = bottom_buttons[8]
	bottom_sprite_frames_button = bottom_buttons[9]
	bottom_theme_button = bottom_buttons[10]
	bottom_polygon_button = bottom_buttons[11]
	bottom_tileset_button = bottom_buttons[12]
	bottom_tilemap_button = bottom_buttons[13]
	bottom_replication_button = bottom_buttons[14]
	bottom_gridmap_button = bottom_buttons[-1]

	bottom_pin_button = bottom_h_box_container.get_child(-2)
	bottom_expand_button = bottom_h_box_container.get_child(-1)

	spriteframes = Utils.find_child_by_type(bottom_panels_vboxcontainer, "SpriteFramesEditor", false)
	var spriteframes_containers := spriteframes.find_children("", "VBoxContainer", false, false)

	# Left VBoxContainer
	spriteframes_animation = spriteframes_containers[0].get_child(1).get_child(0)
	spriteframes_animation_toolbar = spriteframes_animation.get_child(0)
	spriteframes_animation_toolbar_controls.assign(spriteframes_animation_toolbar.find_children("", "Button", true, false) + spriteframes_animation_toolbar.find_children("", "SpinBox", true, false))
	spriteframes_animation_toolbar_add_animation_button = spriteframes_animation_toolbar_controls[0]
	spriteframes_animation_toolbar_duplicate_animation_button = spriteframes_animation_toolbar_controls[1]
	spriteframes_animation_toolbar_delete_animation_button = spriteframes_animation_toolbar_controls[2]
	spriteframes_animation_toolbar_autoplay_button = spriteframes_animation_toolbar_controls[3]
	spriteframes_animation_toolbar_looping_button = spriteframes_animation_toolbar_controls[4]
	spriteframes_animation_toolbar_speed = spriteframes_animation_toolbar_controls[5]
	spriteframes_animation_filter = Utils.find_child_by_type(spriteframes_animation, "LineEdit", true)
	spriteframes_animations = Utils.find_child_by_type(spriteframes_animation, "Tree", false)

	# Right VBoxContainer
	spriteframes_frames = spriteframes_containers[1].get_child(1).get_child(0)
	spriteframes_frames_toolbar = spriteframes_frames.get_child(0)
	spriteframes_frames_list = spriteframes_frames.get_child(1)
	var spriteframes_frames_toolbar_hboxes :=  spriteframes_frames_toolbar.find_children("", "HBoxContainer", false, false)
	spriteframes_frames_toolbar_controls.assign(spriteframes_frames_toolbar_hboxes
		.slice(0, spriteframes_frames_toolbar_hboxes.size() - 1)
		.reduce(func(acc, h: HBoxContainer) -> Array: return acc + h.find_children("", "Button", true, false), [])
	)
	spriteframes_frames_toolbar_controls.append_array(spriteframes_frames_toolbar.find_children("", "SpinBox", true, false))
	spriteframes_frames_toolbar_controls.append_array(spriteframes_frames_toolbar_hboxes[-1].find_children("", "Button", true, false))
	spriteframes_frames_toolbar_play_back_button = spriteframes_frames_toolbar_controls[0]
	spriteframes_frames_toolbar_play_back_from_end_button = spriteframes_frames_toolbar_controls[1]
	spriteframes_frames_toolbar_stop_button = spriteframes_frames_toolbar_controls[2]
	spriteframes_frames_toolbar_play_from_start_button = spriteframes_frames_toolbar_controls[3]
	spriteframes_frames_toolbar_play_button = spriteframes_frames_toolbar_controls[4]
	spriteframes_frames_toolbar_add_from_file_button = spriteframes_frames_toolbar_controls[5]
	spriteframes_frames_toolbar_add_from_sheet_button = spriteframes_frames_toolbar_controls[6]
	spriteframes_frames_toolbar_copy_button = spriteframes_frames_toolbar_controls[7]
	spriteframes_frames_toolbar_paste_button = spriteframes_frames_toolbar_controls[8]
	spriteframes_frames_toolbar_insert_before_button = spriteframes_frames_toolbar_controls[9]
	spriteframes_frames_toolbar_insert_after_button = spriteframes_frames_toolbar_controls[10]
	spriteframes_frames_toolbar_move_left_button = spriteframes_frames_toolbar_controls[11]
	spriteframes_frames_toolbar_move_right_button = spriteframes_frames_toolbar_controls[12]
	spriteframes_frames_toolbar_delete_button = spriteframes_frames_toolbar_controls[13]
	spriteframes_frames_toolbar_frame_duration = spriteframes_frames_toolbar_controls[14]
	spriteframes_frames_toolbar_zoom_out_button = spriteframes_frames_toolbar_controls[15]
	spriteframes_frames_toolbar_zoom_reset_button = spriteframes_frames_toolbar_controls[16]
	spriteframes_frames_toolbar_zoom_in_button = spriteframes_frames_toolbar_controls[17]

	tilemap = Utils.find_child_by_type(bottom_panels_vboxcontainer, "TileMapLayerEditor", false)
	var tilemap_flow_container: HFlowContainer = Utils.find_child_by_type(tilemap, "HFlowContainer", false)
	tilemap_tabs = tilemap_flow_container.get_child(0)
	var tilemap_flow_layers_hbox := tilemap_flow_container.get_child(4)
	tilemap_layers_button = tilemap_flow_layers_hbox.get_child(0)
	tilemap_previous_button = tilemap_flow_layers_hbox.get_child(1)
	tilemap_next_button = tilemap_flow_layers_hbox.get_child(2)
	tilemap_highlight_button = tilemap_flow_container.get_child(5)
	tilemap_grid_button = tilemap_flow_container.get_child(7)
	tilemap_menu_button = tilemap_flow_container.get_child(8)

	tilemap_tiles_panel = tilemap.get_child(2)
	var tilemap_tiles_hsplitcontainer: HSplitContainer = Utils.find_child_by_type(tilemap_tiles_panel, "HSplitContainer", false)
	tilemap_tiles = Utils.find_child_by_type(tilemap_tiles_hsplitcontainer.get_child(0), "ItemList")
	tilemap_tiles_tools_sort_button = tilemap_tiles_hsplitcontainer.get_child(0).get_child(1).get_child(0)
	tilemap_tiles_toolbar = tilemap_flow_container.get_child(1)
	tilemap_tiles_toolbar_buttons.assign(tilemap_tiles_toolbar.find_children("", "Button", true, false))
	tilemap_tiles_toolbar_select_button = tilemap_tiles_toolbar_buttons[0]
	tilemap_tiles_toolbar_paint_button = tilemap_tiles_toolbar_buttons[1]
	tilemap_tiles_toolbar_line_button = tilemap_tiles_toolbar_buttons[2]
	tilemap_tiles_toolbar_rect_button = tilemap_tiles_toolbar_buttons[3]
	tilemap_tiles_toolbar_bucket_button = tilemap_tiles_toolbar_buttons[4]
	tilemap_tiles_toolbar_picker_button = tilemap_tiles_toolbar_buttons[5]
	tilemap_tiles_toolbar_eraser_button = tilemap_tiles_toolbar_buttons[6]
	tilemap_tiles_toolbar_rotate_left_button = tilemap_tiles_toolbar_buttons[7]
	tilemap_tiles_toolbar_rotate_right_button = tilemap_tiles_toolbar_buttons[8]
	tilemap_tiles_toolbar_flip_h_button = tilemap_tiles_toolbar_buttons[9]
	tilemap_tiles_toolbar_flip_v_button = tilemap_tiles_toolbar_buttons[10]
	tilemap_tiles_toolbar_contiguous_button = tilemap_tiles_toolbar_buttons[11]
	tilemap_tiles_toolbar_random_button = tilemap_tiles_toolbar_buttons[12]
	tilemap_tiles_atlas_view = Utils.find_child_by_type(tilemap_tiles_hsplitcontainer, "TileAtlasView", false)
	tilemap_tiles_atlas_view_zoom_widget = Utils.find_child_by_type(tilemap_tiles_atlas_view, "EditorZoomWidget")
	tilemap_tiles_atlas_view_zoom_out_button = tilemap_tiles_atlas_view_zoom_widget.get_child(0)
	tilemap_tiles_atlas_view_zoom_reset_button = tilemap_tiles_atlas_view_zoom_widget.get_child(1)
	tilemap_tiles_atlas_view_zoom_in_button = tilemap_tiles_atlas_view_zoom_widget.get_child(2)
	tilemap_tiles_atlas_view_center_button = tilemap_tiles_atlas_view.get_child(2)

	tilemap_patterns_panel = tilemap.get_child(3)
	tilemap_terrains_panel = tilemap.get_child(4)
	var tilemap_terrains_hsplitcontainer: HSplitContainer = tilemap_terrains_panel.get_child(0)
	tilemap_terrains_tree = Utils.find_child_by_type(tilemap_terrains_hsplitcontainer, "Tree")
	tilemap_terrains_tiles = Utils.find_child_by_type(tilemap_terrains_hsplitcontainer, "ItemList")
	tilemap_terrains_toolbar = tilemap_flow_container.get_child(2)
	tilemap_terrains_toolbar_buttons.assign(tilemap_terrains_toolbar.find_children("", "Button", true, false))
	tilemap_terrains_toolbar_paint_button = tilemap_terrains_toolbar_buttons[0]
	tilemap_terrains_toolbar_line_button = tilemap_terrains_toolbar_buttons[1]
	tilemap_terrains_toolbar_rect_button = tilemap_terrains_toolbar_buttons[2]
	tilemap_terrains_toolbar_bucket_button = tilemap_terrains_toolbar_buttons[3]
	tilemap_terrains_toolbar_picker_button = tilemap_terrains_toolbar_buttons[4]
	tilemap_terrains_toolbar_eraser_button = tilemap_terrains_toolbar_buttons[5]
	tilemap_terrains_toolbar_contiguous_button = tilemap_terrains_toolbar_buttons[6]

	tilemap_panels = [tilemap_tiles_panel, tilemap_patterns_panel, tilemap_terrains_panel]

	tileset = Utils.find_child_by_type(bottom_panels_vboxcontainer, "TileSetEditor", false)
	tileset_tabs = Utils.find_child_by_type(tileset, "TabBar")
	tileset_tiles_panel = tileset.get_child(0).get_child(1)
	tileset_tiles = Utils.find_child_by_type(tileset_tiles_panel.get_child(0), "ItemList", false)
	tileset_tiles_tools = Utils.find_child_by_type(tileset_tiles_panel.get_child(0), "HBoxContainer", false)
	tileset_tiles_tool_buttons.assign(tileset_tiles_tools.get_children())
	tileset_tiles_tools_delete_button = tileset_tiles_tool_buttons[0]
	tileset_tiles_tools_add_button = tileset_tiles_tool_buttons[1]
	tileset_tiles_tools_menu_button = tileset_tiles_tool_buttons[2]
	tileset_tiles_tools_sort_button = tileset_tiles_tool_buttons[3]

	tileset_tiles_atlas_editor = Utils.find_child_by_type(tileset_tiles_panel, "TileSetAtlasSourceEditor")
	tileset_tiles_atlas_editor_tools = tileset_tiles_atlas_editor.get_child(0).get_child(0)
	tileset_tiles_atlas_editor_tool_buttons.assign(tileset_tiles_atlas_editor_tools.get_children())
	tileset_tiles_atlas_editor_tools_setup_button = tileset_tiles_atlas_editor_tool_buttons[0]
	tileset_tiles_atlas_editor_tools_select_button = tileset_tiles_atlas_editor_tool_buttons[1]
	tileset_tiles_atlas_editor_tools_paint_button = tileset_tiles_atlas_editor_tool_buttons[2]
	tileset_tiles_atlas_editor_setup = tileset_tiles_atlas_editor.get_child(0).get_child(4)
	tileset_tiles_atlas_editor_select = tileset_tiles_atlas_editor.get_child(0).get_child(1)
	tileset_tiles_atlas_editor_paint = tileset_tiles_atlas_editor.get_child(0).get_child(3)
	var tileset_tiles_atlas_editor_right: VBoxContainer = tileset_tiles_atlas_editor.get_child(1)
	tileset_tiles_atlas_editor_toolbar = tileset_tiles_atlas_editor_right.get_child(0)
	tileset_tiles_atlas_editor_setup_toolbar_erase_button = tileset_tiles_atlas_editor_toolbar.get_child(1)
	tileset_tiles_atlas_editor_setup_toolbar_menu_button = tileset_tiles_atlas_editor_toolbar.get_child(2)
	tileset_tiles_atlas_editor_atlas_view = Utils.find_child_by_type(tileset_tiles_atlas_editor_right, "TileAtlasView")
	tileset_tiles_atlas_editor_atlas_view_zoom_widget = Utils.find_child_by_type(tileset_tiles_atlas_editor_atlas_view, "EditorZoomWidget")
	tileset_tiles_atlas_editor_atlas_view_zoom_out_button = tileset_tiles_atlas_editor_atlas_view_zoom_widget.get_child(0)
	tileset_tiles_atlas_editor_atlas_view_zoom_reset_button = tileset_tiles_atlas_editor_atlas_view_zoom_widget.get_child(1)
	tileset_tiles_atlas_editor_atlas_view_zoom_in_button = tileset_tiles_atlas_editor_atlas_view_zoom_widget.get_child(2)
	tileset_tiles_atlas_editor_atlas_view_center_button = tileset_tiles_atlas_editor_atlas_view.get_child(2)

	tileset_tiles_scene_editor = Utils.find_child_by_type(tileset_tiles_panel, "TileSetScenesCollectionSourceEditor")
	tileset_tiles_scene_editor_properties = tileset_tiles_scene_editor.get_child(0).get_child(0)
	var tileset_tiles_scene_editor_inspectors := tileset_tiles_scene_editor.find_children("", "EditorInspector", true, false)
	tileset_tiles_scene_editor_scene = tileset_tiles_scene_editor_inspectors[0]
	tileset_tiles_scene_editor_tile = tileset_tiles_scene_editor_inspectors[1]
	tileset_tiles_scene_editor_list = tileset_tiles_scene_editor.get_child(0).get_child(1).get_child(0)
	tileset_tiles_scene_editor_list_tools = tileset_tiles_scene_editor.get_child(0).get_child(1).get_child(1)
	tileset_tiles_scene_editor_list_tool_buttons.assign(tileset_tiles_scene_editor_list_tools.get_children())
	tileset_tiles_scene_editor_list_tools_add_button = tileset_tiles_scene_editor_list_tool_buttons[0]
	tileset_tiles_scene_editor_list_tools_delete_button = tileset_tiles_scene_editor_list_tool_buttons[1]

	tileset_patterns_panel = tileset.get_child(0).get_child(2)
	tileset_panels = [tileset_tiles_panel, tileset_patterns_panel]

	scene_import_settings_window = Utils.find_child_by_type(base_control, "SceneImportSettingsDialog")
	scene_import_settings = scene_import_settings_window.get_child(0)
	scene_import_settings_cancel_button = scene_import_settings_window.get_cancel_button()
	scene_import_settings_ok_button = scene_import_settings_window.get_ok_button()

	windows.assign([signals_dialog_window, node_create_window, scene_import_settings_window])
	for window in windows:
		window_toggle_tour_mode(window, true)

	# TODO: move to a build system step instead of running it on every plugin load
	check_button_icons({
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
		scene_dock_add_button: ["scene_dock_add_button", "Add"],
		node_dock_signals_button: ["node_dock_signals_button", "Signals"],
		node_dock_groups_button: ["node_dock_groups_button", "Groups"],
		spriteframes_animation_toolbar_add_animation_button: ["spriteframes_animation_toolbar_add_animation_button", "New"],
		spriteframes_animation_toolbar_duplicate_animation_button: ["spriteframes_animation_toolbar_duplicate_animation_button", "Duplicate"],
		spriteframes_animation_toolbar_delete_animation_button: ["spriteframes_animation_toolbar_delete_animation_button", "Remove"],
		spriteframes_animation_toolbar_autoplay_button: ["spriteframes_animation_toolbar_autoplay_button", "AutoPlay"],
		spriteframes_animation_toolbar_looping_button: ["spriteframes_animation_toolbar_looping_button", "Loop"],
		spriteframes_frames_toolbar_play_back_button: ["spriteframes_frames_toolbar_play_back_button", "PlayBackwards"],
		spriteframes_frames_toolbar_play_back_from_end_button: ["spriteframes_frames_toolbar_play_back_from_end_button", "PlayStartBackwards"],
		spriteframes_frames_toolbar_stop_button: ["spriteframes_frames_toolbar_stop_button", "Stop"],
		spriteframes_frames_toolbar_play_from_start_button: ["spriteframes_frames_toolbar_play_from_start_button", "PlayStart"],
		spriteframes_frames_toolbar_play_button: ["spriteframes_frames_toolbar_play_button", "Play"],
		spriteframes_frames_toolbar_add_from_file_button: ["spriteframes_frames_toolbar_add_from_file_button", "Load"],
		spriteframes_frames_toolbar_add_from_sheet_button: ["spriteframes_frames_toolbar_add_from_sheet_button", "SpriteSheet"],
		spriteframes_frames_toolbar_copy_button: ["spriteframes_frames_toolbar_copy_button", "ActionCopy"],
		spriteframes_frames_toolbar_paste_button: ["spriteframes_frames_toolbar_paste_button", "ActionPaste"],
		spriteframes_frames_toolbar_insert_before_button: ["spriteframes_frames_toolbar_insert_before_button", "InsertBefore"],
		spriteframes_frames_toolbar_insert_after_button: ["spriteframes_frames_toolbar_insert_after_button", "InsertAfter"],
		spriteframes_frames_toolbar_move_left_button: ["spriteframes_frames_toolbar_move_left_button", "MoveLeft"],
		spriteframes_frames_toolbar_move_right_button: ["spriteframes_frames_toolbar_move_right_button", "MoveRight"],
		spriteframes_frames_toolbar_delete_button: ["spriteframes_frames_toolbar_delete_button", "Remove"],
		spriteframes_frames_toolbar_zoom_out_button: ["spriteframes_frames_toolbar_zoom_out_button", "ZoomLess"],
		spriteframes_frames_toolbar_zoom_reset_button: ["spriteframes_frames_toolbar_zoom_reset_button", "ZoomReset"],
		spriteframes_frames_toolbar_zoom_in_button: ["spriteframes_frames_toolbar_zoom_in_button", "ZoomMore"],
		tilemap_previous_button: ["tilemap_previous_button", "MoveUp"],
		tilemap_next_button: ["tilemap_next_button", "MoveDown"],
		tilemap_highlight_button: ["tilemap_highlight_button", "TileMapHighlightSelected"],
		tilemap_grid_button: ["tilemap_grid_button", "Grid"],
		tilemap_menu_button: ["tilemap_menu_button", "Tools"],
		tilemap_tiles_toolbar_select_button: ["tilemap_tiles_toolbar_select_button", "ToolSelect"],
		tilemap_tiles_toolbar_paint_button: ["tilemap_tiles_toolbar_paint_button", "Edit"],
		tilemap_tiles_toolbar_line_button: ["tilemap_tiles_toolbar_line_button", "Line"],
		tilemap_tiles_toolbar_rect_button: ["tilemap_tiles_toolbar_rect_button", "Rectangle"],
		tilemap_tiles_toolbar_bucket_button: ["tilemap_tiles_toolbar_bucket_button", "Bucket"],
		tilemap_tiles_toolbar_picker_button: ["tilemap_tiles_toolbar_picker_button", "ColorPick"],
		tilemap_tiles_toolbar_eraser_button: ["tilemap_tiles_toolbar_eraser_button", "Eraser"],
		tilemap_tiles_toolbar_rotate_left_button: ["tilemap_tiles_toolbar_rotate_left_button", "RotateLeft"],
		tilemap_tiles_toolbar_rotate_right_button: ["tilemap_tiles_toolbar_rotate_right_button", "RotateRight"],
		tilemap_tiles_toolbar_flip_h_button: ["tilemap_tiles_toolbar_flip_h_button", "MirrorX"],
		tilemap_tiles_toolbar_flip_v_button: ["tilemap_tiles_toolbar_flip_v_button", "MirrorY"],
		tilemap_tiles_toolbar_random_button: ["tilemap_tiles_toolbar_random_button", "RandomNumberGenerator"],
		tilemap_tiles_atlas_view_zoom_out_button: ["tilemap_tiles_atlas_view_zoom_out_button", "ZoomLess"],
		tilemap_tiles_atlas_view_zoom_in_button: ["tilemap_tiles_atlas_view_zoom_in_button", "ZoomMore"],
		tilemap_tiles_atlas_view_center_button: ["tilemap_tiles_atlas_view_center_button", "CenterView"],
		tilemap_terrains_toolbar_paint_button: ["tilemap_terrains_toolbar_paint_button", "Edit"],
		tilemap_terrains_toolbar_line_button: ["tilemap_terrains_toolbar_line_button", "Line"],
		tilemap_terrains_toolbar_rect_button: ["tilemap_terrains_toolbar_rect_button", "Rectangle"],
		tilemap_terrains_toolbar_bucket_button: ["tilemap_terrains_toolbar_bucket_button", "Bucket"],
		tilemap_terrains_toolbar_picker_button: ["tilemap_terrains_toolbar_picker_button", "ColorPick"],
		tilemap_terrains_toolbar_eraser_button: ["tilemap_terrains_toolbar_eraser_button", "Eraser"],
		tileset_tiles_tools_delete_button: ["tileset_tiles_tools_delete_button", "Remove"],
		tileset_tiles_tools_add_button: ["tileset_tiles_tools_add_button", "Add"],
		tileset_tiles_tools_menu_button: ["tileset_tiles_tools_menu_button", "GuiTabMenuHl"],
		tileset_tiles_tools_sort_button: ["tileset_tiles_tools_sort_button", "Sort"],
		tileset_tiles_atlas_editor_tools_setup_button: ["tileset_tiles_atlas_editor_tools_setup_button", "Tools"],
		tileset_tiles_atlas_editor_tools_select_button: ["tileset_tiles_atlas_editor_tools_select_button", "ToolSelect"],
		tileset_tiles_atlas_editor_tools_paint_button: ["tileset_tiles_atlas_editor_tools_paint_button", "Paint"],
		tileset_tiles_atlas_editor_setup_toolbar_erase_button: ["tileset_tiles_atlas_editor_setup_toolbar_erase_button", "Eraser"],
		tileset_tiles_atlas_editor_setup_toolbar_menu_button: ["tileset_tiles_atlas_editor_setup_toolbar_menu_button", "GuiTabMenuHl"],
		tileset_tiles_atlas_editor_atlas_view_zoom_out_button: ["tileset_tiles_atlas_editor_atlas_view_zoom_out_button", "ZoomLess"],
		tileset_tiles_atlas_editor_atlas_view_zoom_in_button: ["tileset_tiles_atlas_editor_atlas_view_zoom_in_button", "ZoomMore"],
		tileset_tiles_atlas_editor_atlas_view_center_button: ["tileset_tiles_atlas_editor_atlas_view_center_button", "CenterView"],
		tileset_tiles_scene_editor_list_tools_add_button: ["tileset_tiles_scene_editor_list_tools_add_button", "Add"],
		tileset_tiles_scene_editor_list_tools_delete_button: ["tileset_tiles_scene_editor_list_tools_delete_button", "Remove"],
		bottom_pin_button: ["bottom_pin_button", "Pin"],
		bottom_expand_button: ["bottom_expand_button", "ExpandBottomDock"],
})


func clean_up() -> void:
	for window in windows:
		window_toggle_tour_mode(window, false)


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
