extends "editor_interface_access.gd"


func _test_spriteframes_buttons() -> void:
	check_button_icons_dynamic_nodes(
		{
			DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_ADD_ANIMATION_BUTTON: "New",
			DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_DELETE_ANIMATION_BUTTON: "Remove",
			DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_AUTOPLAY_BUTTON: "AutoPlay",
			DynamicEditorNodes.SPRITEFRAMES_ANIMATION_TOOLBAR_LOOPING_BUTTON: "Loop",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_BACK_BUTTON: "PlayBackwards",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_BACK_FROM_END_BUTTON: "PlayStartBackwards",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_STOP_BUTTON: "Stop",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_FROM_START_BUTTON: "PlayStart",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_PLAY_BUTTON: "Play",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_ADD_FROM_FILE_BUTTON: "Load",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_ADD_FROM_SHEET_BUTTON: "SpriteSheet",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_COPY_BUTTON: "ActionCopy",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_PASTE_BUTTON: "ActionPaste",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_INSERT_BEFORE_BUTTON: "InsertBefore",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_INSERT_AFTER_BUTTON: "InsertAfter",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_MOVE_LEFT_BUTTON: "MoveLeft",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_MOVE_RIGHT_BUTTON: "MoveRight",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_DELETE_BUTTON: "Remove",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_ZOOM_OUT_BUTTON: "ZoomLess",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_ZOOM_RESET_BUTTON: "ZoomReset",
			DynamicEditorNodes.SPRITEFRAMES_FRAMES_TOOLBAR_ZOOM_IN_BUTTON: "ZoomMore",
		},
	)


func _test_tilemap_tileset_buttons() -> void:
	check_button_icons_dynamic_nodes(
		{
			DynamicEditorNodes.TILEMAP_PREVIOUS_BUTTON: "MoveUp",
			DynamicEditorNodes.TILEMAP_NEXT_BUTTON: "MoveDown",
			DynamicEditorNodes.TILEMAP_HIGHLIGHT_BUTTON: "TileMapHighlightSelected",
			DynamicEditorNodes.TILEMAP_GRID_BUTTON: "Grid",
			DynamicEditorNodes.TILEMAP_MENU_BUTTON: "Tools",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_SELECT_BUTTON: "ToolSelect",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_PAINT_BUTTON: "Edit",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_LINE_BUTTON: "Line",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_RECT_BUTTON: "Rectangle",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_BUCKET_BUTTON: "Bucket",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_PICKER_BUTTON: "ColorPick",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_ERASER_BUTTON: "Eraser",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_ROTATE_LEFT_BUTTON: "RotateLeft",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_ROTATE_RIGHT_BUTTON: "RotateRight",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_FLIP_H_BUTTON: "MirrorX",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_FLIP_V_BUTTON: "MirrorY",
			DynamicEditorNodes.TILEMAP_TILES_TOOLBAR_RANDOM_BUTTON: "RandomNumberGenerator",
			DynamicEditorNodes.TILEMAP_TILES_ATLAS_VIEW_ZOOM_OUT_BUTTON: "ZoomLess",
			DynamicEditorNodes.TILEMAP_TILES_ATLAS_VIEW_ZOOM_IN_BUTTON: "ZoomMore",
			DynamicEditorNodes.TILEMAP_TILES_ATLAS_VIEW_CENTER_BUTTON: "CenterView",
			DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_PAINT_BUTTON: "Edit",
			DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_LINE_BUTTON: "Line",
			DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_RECT_BUTTON: "Rectangle",
			DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_BUCKET_BUTTON: "Bucket",
			DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_PICKER_BUTTON: "ColorPick",
			DynamicEditorNodes.TILEMAP_TERRAINS_TOOLBAR_ERASER_BUTTON: "Eraser",
			DynamicEditorNodes.TILESET_TILES_TOOLS_DELETE_BUTTON: "Remove",
			DynamicEditorNodes.TILESET_TILES_TOOLS_ADD_BUTTON: "Add",
			DynamicEditorNodes.TILESET_TILES_TOOLS_MENU_BUTTON: "GuiTabMenuHl",
			DynamicEditorNodes.TILESET_TILES_TOOLS_SORT_BUTTON: "Sort",
			DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_TOOLS_SETUP_BUTTON: "Tools",
			DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_TOOLS_SELECT_BUTTON: "ToolSelect",
			DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_TOOLS_PAINT_BUTTON: "Paint",
			DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_SETUP_TOOLBAR_ERASE_BUTTON: "Eraser",
			DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_SETUP_TOOLBAR_MENU_BUTTON: "GuiTabMenuHl",
			DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_ZOOM_OUT_BUTTON: "ZoomLess",
			DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_ZOOM_IN_BUTTON: "ZoomMore",
			DynamicEditorNodes.TILESET_TILES_ATLAS_EDITOR_ATLAS_VIEW_CENTER_BUTTON: "CenterView",
			DynamicEditorNodes.TILESET_TILES_SCENE_EDITOR_LIST_TOOLS_ADD_BUTTON: "Add",
			DynamicEditorNodes.TILESET_TILES_SCENE_EDITOR_LIST_TOOLS_DELETE_BUTTON: "Remove",
		},
	)


## This testing function is a stub to test that buttons have a specific icon
## attached specifically for dynamic editors that are not available immediately
## in Godot.
##
## TODO: For this to work, this needs to be part of an integration test
## component where we open the corresponding editors first and wait for them to
## be populated before calling any of this. This will then be applicable to
## testing these parts of the editor.
##
## The buttons_info dictionary maps an enum member for one of the nodes to the icon name.
func check_button_icons_dynamic_nodes(buttons_info: Dictionary[DynamicEditorNodes, String]) -> void:
	var editor_theme := EditorInterface.get_editor_theme()
	var enum_names: Array[String] = DynamicEditorNodes.keys()

	for enum_member: DynamicEditorNodes in buttons_info:
		var button := get_dynamic_editor_node(enum_member) as Button
		var button_name: StringName = enum_names[enum_member]
		assert(
			button != null,
			"Trying to check a button's icon, but the node we got and passed to the function is actually not an icon: " +
			button_name,
		)
		var icon_name: StringName = buttons_info[enum_member]
		var editor_has_icon := editor_theme.has_icon(icon_name, "EditorIcons")
		if editor_has_icon and button != null and button.icon != editor_theme.get_icon(icon_name, "EditorIcons"):
			push_warning("Button `%s` should have `%s` icon, but doesn't!" % [button_name, icon_name])
		elif button == null:
			push_warning("Button `%s` is null!" % button_name)
		elif not editor_has_icon:
			push_warning("Icon `%s` doesn't exist in the `EditorIcons` theme type! Check for typos." % icon_name)
