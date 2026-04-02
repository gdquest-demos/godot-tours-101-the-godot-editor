@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


class SceneDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "SceneTreeDock"

		var custom_script := func(base_node: Node) -> Node:
			var es := EditorInterface.get_selection()
			return Utils.object_get_signal_type(es, "selection_changed", "SceneTreeDock")

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class SceneDockCreateDialogDef extends Types.Definition:
	func _init() -> void:
		node_type = "CreateDialog"
		base_reference = Enums.NodePoint.SCENE_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("CreateDialog"),
		]


class SceneDockRenameDialogDef extends Types.Definition:
	func _init() -> void:
		node_type = "RenameDialog"
		base_reference = Enums.NodePoint.SCENE_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("RenameDialog"),
		]


class SceneDockReparentDialogDef extends Types.Definition:
	func _init() -> void:
		node_type = "ReparentDialog"
		base_reference = Enums.NodePoint.SCENE_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("ReparentDialog"),
		]


class SceneDockScriptCreateDialogDef extends Types.Definition:
	func _init() -> void:
		node_type = "ScriptCreateDialog"
		base_reference = Enums.NodePoint.SCENE_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("ScriptCreateDialog"),
		]


class SceneDockShaderCreateDialogDef extends Types.Definition:
	func _init() -> void:
		node_type = "ShaderCreateDialog"
		base_reference = Enums.NodePoint.SCENE_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("ShaderCreateDialog"),
		]


# Toolbar elements.

class SceneTreeToolbarDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.SCENE_DOCK

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
		]


class SceneTreeToolbarButtonsDef extends Types.MultiDefinition:
	func _init() -> void:
		node_type_map = {
			Enums.NodePoint.SCENE_TREE_ADD_NODE_BUTTON:        "Button",
			Enums.NodePoint.SCENE_TREE_ADD_INSTANCE_BUTTON:    "Button",
			Enums.NodePoint.SCENE_TREE_ATTACH_SCRIPT_BUTTON:   "Button",
			Enums.NodePoint.SCENE_TREE_DETACH_SCRIPT_BUTTON:   "Button",
			Enums.NodePoint.SCENE_TREE_EXTEND_SCRIPT_BUTTON:   "Button",
			Enums.NodePoint.SCENE_TREE_EXTRA_OPTIONS_BUTTON:   "MenuButton",
		}
		base_reference = Enums.NodePoint.SCENE_TREE_TOOLBAR

		# Resolve all buttons at the same time using custom heuristics.
		var custom_script := func(base_nodes: Array[Node]) -> Array[Node]:
			if base_nodes.is_empty():
				return []

			var results: Array[Node] = []
			results.resize(node_type_map.size())
			results.fill(null)

			var toolbar := base_nodes[0]
			var toolbar_buttons := toolbar.find_children("", "Button", false, false)
			var toolbar_buttons_map: Dictionary[String, Button] = {}

			for button: Button in toolbar_buttons:
				var button_key := ""
				if button.icon:
					button_key = Utils.node_get_editor_icon(button)

				if button_key.is_empty():
					continue

				toolbar_buttons_map[button_key] = button

			results[0] = toolbar_buttons_map["Add"]            if "Add"            in toolbar_buttons_map else null
			results[1] = toolbar_buttons_map["Instance"]       if "Instance"       in toolbar_buttons_map else null
			results[2] = toolbar_buttons_map["ScriptCreate"]   if "ScriptCreate"   in toolbar_buttons_map else null
			results[3] = toolbar_buttons_map["ScriptRemove"]   if "ScriptRemove"   in toolbar_buttons_map else null
			results[4] = toolbar_buttons_map["ScriptExtend"]   if "ScriptExtend"   in toolbar_buttons_map else null
			results[5] = toolbar_buttons_map["GuiTabMenuHl"]   if "GuiTabMenuHl"   in toolbar_buttons_map else null

			return results

		resolver_steps = [
			Types.DoCustomMultiStep.new(custom_script),
		]

class SceneTreeAddNodeButtonDef        extends SceneTreeToolbarButtonsDef: pass
class SceneTreeAddInstanceButtonDef    extends SceneTreeToolbarButtonsDef: pass
class SceneTreeAttachScriptButtonDef   extends SceneTreeToolbarButtonsDef: pass
class SceneTreeDetachScriptButtonDef   extends SceneTreeToolbarButtonsDef: pass
class SceneTreeExtendScriptButtonDef   extends SceneTreeToolbarButtonsDef: pass
class SceneTreeExtraOptionsButtonDef   extends SceneTreeToolbarButtonsDef: pass


class SceneTreeTextFilterDef extends Types.Definition:
	func _init() -> void:
		node_type = "LineEdit"
		base_reference = Enums.NodePoint.SCENE_TREE_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("LineEdit", 0),
		]


# Create scene panel.

class SceneTreeCreatePanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.SCENE_DOCK

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildTypeStep.new("VBoxContainer", 0),
		]


class SceneTreeCreateButtonsDef extends Types.MultiDefinition:
	func _init() -> void:
		node_type_map = {
			Enums.NodePoint.SCENE_TREE_CREATE_ADD_2D_NODE_BUTTON:     "Button",
			Enums.NodePoint.SCENE_TREE_CREATE_ADD_3D_NODE_BUTTON:     "Button",
			Enums.NodePoint.SCENE_TREE_CREATE_ADD_UI_NODE_BUTTON:     "Button",
			Enums.NodePoint.SCENE_TREE_CREATE_ADD_OTHER_NODE_BUTTON:  "Button",
			Enums.NodePoint.SCENE_TREE_CREATE_PASTE_CLIPBOARD_BUTTON: "Button",
		}
		base_reference = Enums.NodePoint.SCENE_TREE_CREATE_PANEL

		# Resolve all buttons at the same time using custom heuristics.
		var custom_script := func(base_nodes: Array[Node]) -> Array[Node]:
			if base_nodes.is_empty():
				return []

			var results: Array[Node] = []
			results.resize(node_type_map.size())
			results.fill(null)

			var panel := base_nodes[0]
			var panel_buttons := panel.find_children("", "Button", true, false)
			var panel_buttons_map: Dictionary[String, Button] = {}

			for button: Button in panel_buttons:
				# Buttons from the favorites list are mixed into this. Thankfully,
				# we can ignore them based on their unique callable.
				if Utils.node_has_signal_callable(button, "pressed", "SceneTreeDock::_favorite_root_selected"):
					continue

				var button_key := ""
				if button.icon:
					button_key = Utils.node_get_editor_icon(button)

				if button_key.is_empty():
					continue

				panel_buttons_map[button_key] = button

			results[0] = panel_buttons_map["Node2D"]        if "Node2D"        in panel_buttons_map else null
			results[1] = panel_buttons_map["Node3D"]        if "Node3D"        in panel_buttons_map else null
			results[2] = panel_buttons_map["Control"]       if "Control"       in panel_buttons_map else null
			results[3] = panel_buttons_map["Add"]           if "Add"           in panel_buttons_map else null
			results[4] = panel_buttons_map["ActionPaste"]   if "ActionPaste"   in panel_buttons_map else null

			return results

		resolver_steps = [
			Types.GetChildTypeStep.new("ScrollContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.DoCustomMultiStep.new(custom_script),
		]

class SceneTreeCreateAdd2dNodeButtonDef        extends SceneTreeCreateButtonsDef: pass
class SceneTreeCreateAdd3dNodeButtonDef        extends SceneTreeCreateButtonsDef: pass
class SceneTreeCreateAddUiNodeButtonDef        extends SceneTreeCreateButtonsDef: pass
class SceneTreeCreateAddOtherNodeButtonDef     extends SceneTreeCreateButtonsDef: pass
class SceneTreeCreatePasteClipboardButtonDef   extends SceneTreeCreateButtonsDef: pass


class SceneTreeCreateFavoritesButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SCENE_TREE_CREATE_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.GetChildTypeStep.new("Button", 0),
			Types.HasEditorIconStep.new("Favorites"),
		]


class SceneTreeCreateFavoritesListDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.SCENE_TREE_CREATE_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("ScrollContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("VBoxContainer", 1),
		]


# Scene trees.

class SceneTreeEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "SceneTreeEditor"

		var custom_script := func(base_node: Node) -> Node:
			var es := EditorInterface.get_selection()
			return Utils.object_get_signal_type(es, "selection_changed", "SceneTreeEditor")

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class SceneTreeLocalTreeDef extends Types.Definition:
	func _init() -> void:
		node_type = "Tree"
		base_reference = Enums.NodePoint.SCENE_TREE_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("Tree"),
		]


class SceneTreeRemoteTreeDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorDebuggerTree"
		base_reference = Enums.NodePoint.SCENE_TREE_EDITOR

		resolver_steps = [
			Types.GetParentCountStep.new(1),
			Types.GetChildTypeStep.new("EditorDebuggerTree"),
		]


class SceneTreeLocalToggleDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SCENE_DOCK

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("HBoxContainer", 1),
			Types.GetChildTypeStep.new("Button", 1),
			Types.HasSignalCallableStep.new("pressed", "SceneTreeDock::_local_tree_selected"),
		]


class SceneTreeRemoteToggleDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SCENE_DOCK

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("HBoxContainer", 1),
			Types.GetChildTypeStep.new("Button", 0),
			Types.HasSignalCallableStep.new("pressed", "SceneTreeDock::_remote_tree_selected"),
		]
