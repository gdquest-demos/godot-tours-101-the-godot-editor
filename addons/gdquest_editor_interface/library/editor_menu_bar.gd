@tool

const Enums := preload("../utils/eia_enums.gd")
const Types := preload("../utils/eia_resolver_types.gd")


## Editor's top menu bar (can be a native bar on some platforms).
class MenuBarDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuBar"
		base_reference = Enums.NodePoint.LAYOUT_TITLE_BAR

		resolver_steps = [
			Types.GetChildTypeStep.new("MenuBar"),
		]


class MenuBarSceneMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR

		resolver_steps = [
			Types.GetNodePathStep.new("Scene"),
		]


class MenuBarSceneOpenRecentMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR_SCENE_MENU

		resolver_steps = [
			Types.GetChildTypeStep.new("PopupMenu", 0),
			Types.HasSignalCallableStep.new("id_pressed", "EditorNode::_open_recent_scene"),
		]


class MenuBarSceneExportAsMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR_SCENE_MENU

		resolver_steps = [
			Types.GetChildTypeStep.new("PopupMenu", 1),
			Types.HasSignalCallableStep.new("index_pressed", "EditorNode::_export_as_menu_option"),
		]


class MenuBarProjectMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR

		resolver_steps = [
			Types.GetNodePathStep.new("Project"),
		]


class MenuBarProjectToolMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR_PROJECT_MENU

		resolver_steps = [
			Types.GetChildTypeStep.new("PopupMenu", 1),
			Types.HasSignalCallableStep.new("index_pressed", "EditorNode::_tool_menu_option"),
		]


class MenuBarProjectVersionControlMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR_PROJECT_MENU

		resolver_steps = [
			Types.GetChildTypeStep.new("PopupMenu", 0),
			Types.HasSignalCallableStep.new("index_pressed", "EditorNode::_version_control_menu_option"),
		]


class MenuBarDebugMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR

		resolver_steps = [
			Types.GetNodePathStep.new("Debug"),
		]


class MenuBarEditorMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR

		resolver_steps = [
			Types.GetNodePathStep.new("Editor"),
		]


class MenuBarEditorDocksMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR_EDITOR_MENU

		resolver_steps = [
			Types.GetChildTypeStep.new("PopupMenu", 0),
			Types.HasSignalCallableStep.new("id_pressed", "EditorDockManager::_docks_menu_option"),
		]


class MenuBarEditorLayoutMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR_EDITOR_MENU

		resolver_steps = [
			Types.GetChildTypeStep.new("PopupMenu", 1),
			Types.HasSignalCallableStep.new("id_pressed", "EditorNode::_layout_menu_option"),
		]


class MenuBarHelpMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "PopupMenu"
		base_reference = Enums.NodePoint.MENU_BAR

		resolver_steps = [
			Types.GetNodePathStep.new("Help"),
		]
