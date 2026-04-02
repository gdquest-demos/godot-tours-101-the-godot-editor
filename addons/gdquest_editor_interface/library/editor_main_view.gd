@tool

const Enums := preload("../utils/eia_enums.gd")
const Types := preload("../utils/eia_resolver_types.gd")


## Main view switcher container, where 2D, 3D, Script, etc
## buttons live.
class MainViewSwitcherDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.LAYOUT_TITLE_BAR

		resolver_steps = [
			Types.GetNodePathStep.new("EditorMainScreenButtons"),
		]


class MainViewSwitcher2dButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.MAIN_VIEW_SWITCHER

		resolver_steps = [
			Types.GetNodePathStep.new("2D")
		]


class MainViewSwitcher3dButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.MAIN_VIEW_SWITCHER

		resolver_steps = [
			Types.GetNodePathStep.new("3D")
		]


class MainViewSwitcherScriptButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.MAIN_VIEW_SWITCHER

		resolver_steps = [
			Types.GetNodePathStep.new("Script")
		]


class MainViewSwitcherGameButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.MAIN_VIEW_SWITCHER

		resolver_steps = [
			Types.GetNodePathStep.new("Game")
		]


class MainViewSwitcherAssetLibButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.MAIN_VIEW_SWITCHER

		resolver_steps = [
			Types.GetNodePathStep.new("AssetLib")
		]


## Container node for main views.
class MainViewContainerDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorMainScreen"
		base_reference = Enums.NodePoint.MAIN_VIEW_CONTAINER_BOX

		resolver_steps = [
			Types.GetParentCountStep.new(1),
		]


## Box layout container for main view panels.
class MainViewContainerBoxDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"

		var custom_script := func(base_node: Node) -> Node:
			return EditorInterface.get_editor_main_screen()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]
