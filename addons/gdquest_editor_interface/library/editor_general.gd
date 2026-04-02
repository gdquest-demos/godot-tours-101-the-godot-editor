@tool

const Enums := preload("../utils/eia_enums.gd")
const Types := preload("../utils/eia_resolver_types.gd")
const Utils := preload("../utils/eia_resolver_utils.gd")
const Resolver := preload("../utils/eia_resolver.gd")


## The main Window node of the editor, the root node.
class EditorMainWindowDef extends Types.Definition:
	func _init() -> void:
		node_type = "Window"

		var custom_script := func(base_node: Node) -> Node:
			return EditorInterface.get_base_control().get_window()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


## Main logical node of the editor.
class EditorNodeDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorNode"
		base_reference = Enums.NodePoint.EDITOR_MAIN_WINDOW

		resolver_steps = [
			Types.GetChildTypeStep.new("EditorNode"),
		]


## Editor virtual file system object, which happens to be a node
## (likely for processing).
class EditorFileSystemDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorFileSystem"

		var custom_script := func(base_node: Node) -> Node:
			return EditorInterface.get_resource_filesystem()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


## Editor export manager object, which happens to be a node
## (likely for processing).
class EditorExportDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorExport"
		base_reference = Enums.NodePoint.EDITOR_NODE

		resolver_steps = [
			Types.GetChildTypeStep.new("EditorExport"),
		]


## Root Control node for the editor GUI.
class LayoutRootDef extends Types.Definition:
	func _init() -> void:
		node_type = "Panel"

		var custom_script := func(base_node: Node) -> Node:
			return EditorInterface.get_base_control()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class LayoutTitleBarDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorTitleBar"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		# Parent node can be either VBoxContainer or HBoxContainer, depending on platform,
		# but title bar is always directly there.
		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("EditorTitleBar"),
		]


class LayoutDockLeftLeftTopDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabContainer"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("DockHSplitMain/DockVSplitLeftL/DockSlotLeftUL"),
		]


class LayoutDockLeftLeftBottomDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabContainer"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("DockHSplitMain/DockVSplitLeftL/DockSlotLeftBL"),
		]


class LayoutDockLeftRightTopDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabContainer"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("DockHSplitMain/DockVSplitLeftR/DockSlotLeftUR"),
		]


class LayoutDockLeftRightBottomDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabContainer"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("DockHSplitMain/DockVSplitLeftR/DockSlotLeftBR"),
		]


class LayoutDockRightLeftTopDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabContainer"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("DockHSplitMain/DockVSplitRightL/DockSlotRightUL"),
		]


class LayoutDockRightLeftBottomDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabContainer"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("DockHSplitMain/DockVSplitRightL/DockSlotRightBL"),
		]


class LayoutDockRightRightTopDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabContainer"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("DockHSplitMain/DockVSplitRightR/DockSlotRightUR"),
		]


class LayoutDockRightRightBottomDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabContainer"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("DockHSplitMain/DockVSplitRightR/DockSlotRightBR"),
		]


class LayoutDockMiddleBottomDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorBottomPanel"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("DockHSplitMain"),
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetNodePathStep.new("DockVSplitCenter"),
			Types.GetChildTypeStep.new("EditorBottomPanel"),
		]


class LayoutDockHiddenContainerDef extends Types.Definition:
	func _init() -> void:
		node_type = "Control"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		# To reinforce the fetch here we can check that there is at least one
		# EditorDock child. It's very unlikely that the control will be empty,
		# especially at launch. But at this time its order is fixed, so eh.
		resolver_steps = [
			Types.GetChildIndexStep.new(1),
		]


# Layout-affecting buttons.

class LayoutDistractionFreeButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		prefetch_references = [
			Enums.NodePoint.SCENE_TABS_TAB_BAR,
			Enums.NodePoint.LAYOUT_EXPAND_BOTTOM_BUTTON,
		]

		# NOTE: When the bottom panel is expanded, this button is moved inside of it.
		# The button instance is the same, so once resolved, this is not an issue.
		# The bottom panel also cannot be expanded on editor start (so far), but we
		# don't know when the node is going to be resolved by user code.
		# So check everything!

		var custom_script := func(base_node: Node) -> Node:
			var button_siblings: Array[Node] = [
				Resolver.get_node_cached(Enums.NodePoint.SCENE_TABS_TAB_BAR),
				Resolver.get_node_cached(Enums.NodePoint.LAYOUT_EXPAND_BOTTOM_BUTTON),
			]

			for sibling in button_siblings:
				if not sibling:
					continue # Resolver failed?

				var owner_node := sibling.get_parent()
				var buttons := owner_node.find_children("", "Button", false, false)
				for button: Button in buttons:
					if Utils.node_has_signal_callable(button, "pressed", "EditorNode::_toggle_distraction_free_mode"):
						return button

			return null

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
			Types.HasEditorIconStep.new("DistractionFree"),
		]


class LayoutExpandBottomButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.LAYOUT_DOCK_MIDDLE_BOTTOM

		var get_tab_bar := func(base_node: Node) -> Node:
			return (base_node as TabContainer).get_tab_bar()

		var custom_script := func(base_node: Node) -> Node:
			var buttons := base_node.find_children("", "Button", false, false)
			for button: Button in buttons:
				if Utils.node_has_signal_callable(button, "toggled", "EditorBottomPanel::_expand_button_toggled"):
					return button

			return null

		resolver_steps = [
			Types.DoCustomStep.new(get_tab_bar),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.DoCustomStep.new(custom_script),
			Types.HasEditorIconStep.new("ExpandBottomDock"),
		]


class LayoutPinBottomButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.LAYOUT_DOCK_MIDDLE_BOTTOM

		var get_tab_bar := func(base_node: Node) -> Node:
			return (base_node as TabContainer).get_tab_bar()

		var custom_script := func(base_node: Node) -> Node:
			var buttons := base_node.find_children("", "Button", false, false)
			for button: Button in buttons:
				if Utils.node_has_signal_callable(button, "toggled", "EditorBottomPanel::_pin_button_toggled"):
					return button

			return null

		resolver_steps = [
			Types.DoCustomStep.new(get_tab_bar),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.DoCustomStep.new(custom_script),
			Types.HasEditorIconStep.new("Pin"),
		]


# Extra editor elements.

class RenderingModeButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "OptionButton"
		base_reference = Enums.NodePoint.LAYOUT_TITLE_BAR

		resolver_steps = [
			Types.GetChildTypeStep.new("HBoxContainer", -1),
			Types.GetChildTypeStep.new("OptionButton", 0),
		]


class EditorUpdateSpinnerDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuButton"
		base_reference = Enums.NodePoint.LAYOUT_TITLE_BAR

		resolver_steps = [
			Types.GetChildTypeStep.new("HBoxContainer", -1),
			Types.GetChildTypeStep.new("MenuButton", 0),
		]


class EditorToasterDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorToaster"

		var custom_script := func(base_node: Node) -> Node:
			return EditorInterface.get_editor_toaster()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class EditorVersionButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorVersionButton"
		base_reference = Enums.NodePoint.LAYOUT_DOCK_MIDDLE_BOTTOM

		var get_tab_bar := func(base_node: Node) -> Node:
			return (base_node as TabContainer).get_tab_bar()

		resolver_steps = [
			Types.DoCustomStep.new(get_tab_bar),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.GetChildTypeStep.new("EditorVersionButton"),
		]
