@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


## Root node of the node 3D (a.k.a. spatial) editor (main 3D view).
class Node3dEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "Node3DEditor"
		base_reference = Enums.NodePoint.MAIN_VIEW_CONTAINER_BOX

		resolver_steps = [
			Types.GetChildTypeStep.new("Node3DEditor"),
		]


## Main toolbar container of the node 3D editor.
class Node3dEditorMainToolbarDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.NODE_3D_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildTypeStep.new("FlowContainer", 0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
		]


## All buttons present in the toolbar, resolved together.
class Node3dEditorMainToolbarButtonsDef extends Types.MultiDefinition:
	func _init() -> void:
		node_type_map = {
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_TRANSFORM_BUTTON:                  "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_MOVE_BUTTON:                       "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_ROTATE_BUTTON:                     "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_SCALE_BUTTON:                      "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_SELECT_BUTTON:                     "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_SELECTABLE_BUTTON:                 "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_LOCK_BUTTON:                       "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_UNLOCK_BUTTON:                     "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_GROUP_BUTTON:                      "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_UNGROUP_BUTTON:                    "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_RULER_BUTTON:                      "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_LOCAL_SPACE_BUTTON:                "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_SNAP_BUTTON:                       "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_PREVIEW_SUN_BUTTON:                "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_PREVIEW_ENVIRONMENT_BUTTON:        "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_SUN_ENVIRONMENT_SETTINGS_BUTTON:   "Button",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_TRANSFORM_OPTIONS_BUTTON:          "MenuButton",
			Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR_VIEW_OPTIONS_BUTTON:               "MenuButton",
		}
		base_reference = Enums.NodePoint.NODE_3D_EDITOR_MAIN_TOOLBAR

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

				# First, try to identify using the icon.
				if button.icon:
					button_key = Utils.node_get_editor_icon(button)

				# Then, handle special cases.
				if button_key.is_empty():
					if button is MenuButton:
						var popup_menu := (button as MenuButton).get_popup()
						if Utils.popup_menu_has_shortcut_item(popup_menu, "spatial_editor/transform_dialog"):
							button_key = "TransformMenu"
						if Utils.popup_menu_has_shortcut_item(popup_menu, "spatial_editor/1_viewport"):
							button_key = "ViewMenu"

				# Couldn't identify, skipping.
				if button_key.is_empty():
					continue

				toolbar_buttons_map[button_key] = button

			results[0]  = toolbar_buttons_map["ToolTransform"]        if "ToolTransform"        in toolbar_buttons_map else null
			results[1]  = toolbar_buttons_map["ToolMove"]             if "ToolMove"             in toolbar_buttons_map else null
			results[2]  = toolbar_buttons_map["ToolRotate"]           if "ToolRotate"           in toolbar_buttons_map else null
			results[3]  = toolbar_buttons_map["ToolScale"]            if "ToolScale"            in toolbar_buttons_map else null
			results[4]  = toolbar_buttons_map["ToolSelect"]           if "ToolSelect"           in toolbar_buttons_map else null
			results[5]  = toolbar_buttons_map["ListSelect"]           if "ListSelect"           in toolbar_buttons_map else null
			results[6]  = toolbar_buttons_map["Lock"]                 if "Lock"                 in toolbar_buttons_map else null
			results[7]  = toolbar_buttons_map["Unlock"]               if "Unlock"               in toolbar_buttons_map else null
			results[8]  = toolbar_buttons_map["Group"]                if "Group"                in toolbar_buttons_map else null
			results[9]  = toolbar_buttons_map["Ungroup"]              if "Ungroup"              in toolbar_buttons_map else null
			results[10] = toolbar_buttons_map["Ruler"]                if "Ruler"                in toolbar_buttons_map else null
			results[11] = toolbar_buttons_map["Object"]               if "Object"               in toolbar_buttons_map else null
			results[12] = toolbar_buttons_map["Snap"]                 if "Snap"                 in toolbar_buttons_map else null
			results[13] = toolbar_buttons_map["PreviewSun"]           if "PreviewSun"           in toolbar_buttons_map else null
			results[14] = toolbar_buttons_map["PreviewEnvironment"]   if "PreviewEnvironment"   in toolbar_buttons_map else null
			results[15] = toolbar_buttons_map["GuiTabMenuHl"]         if "GuiTabMenuHl"         in toolbar_buttons_map else null
			results[16] = toolbar_buttons_map["TransformMenu"]        if "TransformMenu"        in toolbar_buttons_map else null
			results[17] = toolbar_buttons_map["ViewMenu"]             if "ViewMenu"             in toolbar_buttons_map else null

			return results

		resolver_steps = [
			Types.DoCustomMultiStep.new(custom_script),
		]

class Node3dEditorMainToolbarTransformButtonDef                extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarMoveButtonDef                     extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarRotateButtonDef                   extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarScaleButtonDef                    extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarSelectButtonDef                   extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarSelectableButtonDef               extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarLockButtonDef                     extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarUnlockButtonDef                   extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarGroupButtonDef                    extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarUngroupButtonDef                  extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarRulerButtonDef                    extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarLocalSpaceButtonDef               extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarSnapButtonDef                     extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarCameraButtonDef                   extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarPreviewSunButtonDef               extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarPreviewEnvironmentButtonDef       extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarSunEnvironmentSettingsButtonDef   extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarTransformOptionsButtonDef         extends Node3dEditorMainToolbarButtonsDef: pass
class Node3dEditorMainToolbarViewOptionsButtonDef              extends Node3dEditorMainToolbarButtonsDef: pass


## Toolbar container for contextual toolbars, populated by editor plugins.
class Node3dEditorContextualToolbarsDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.NODE_3D_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildTypeStep.new("FlowContainer", 0),
			Types.GetChildTypeStep.new("PanelContainer", 0),
			Types.GetChildIndexStep.new(0),
		]


# Viewports.

class Node3dEditorViewportsDef extends Types.Definition:
	func _init() -> void:
		node_type = "Node3DEditorViewportContainer"
		base_reference = Enums.NodePoint.NODE_3D_EDITOR

		# NOTE: These split containers are not what is responsible for
		# different viewport layout compositions. The Node3DEditorViewportContainer
		# is. Split containers exist for plugins to add sidebars, like
		# the original GridMap plugin's dock.

		resolver_steps = [
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("Node3DEditorViewportContainer"),
		]


# There are exactly 4 viewports in the node 3D editor at this time.
# This may or may not change, but since they are identical, we define
# them as reusable components.

# NOTE: The order of viewport nodes does not necessarily map to what
# is made visible by layouts first. I.e. layouts with only 2 viewports
# side by side do not necessarily make viewports 1 and 2 visible.

class Node3dEditorViewportSceneRootDef extends Types.Definition:
	func _init() -> void:
		node_type = "SubViewport"
		relative_node_type = "Node3DEditorViewport"

		resolver_steps = [
			Types.GetChildTypeStep.new("SubViewportContainer"),
			Types.GetChildTypeStep.new("SubViewport"),
		]


class Node3dEditorViewportCameraDef extends Types.Definition:
	func _init() -> void:
		node_type = "Camera3D"
		relative_node_type = "Node3DEditorViewport"
		base_reference = Enums.NodePoint.NODE_3D_EDITOR_VIEWPORT_SCENE_ROOT

		resolver_steps = [
			Types.GetChildTypeStep.new("Camera3D"),
		]


class Node3dEditorViewportOverlaysDef extends Types.Definition:
	func _init() -> void:
		node_type = "Control"
		relative_node_type = "Node3DEditorViewport"

		resolver_steps = [
			Types.GetChildTypeStep.new("Control", 1),
		]


class Node3dEditorViewportViewDisplayMenuDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuButton"
		relative_node_type = "Node3DEditorViewport"
		base_reference = Enums.NodePoint.NODE_3D_EDITOR_VIEWPORT_OVERLAYS

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.GetChildTypeStep.new("MenuButton", 0),
			Types.HasEditorIconStep.new("GuiTabMenuHlDarkBackground"),
		]


class Node3dEditorViewportTranslationPreviewButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorTranslationPreviewButton"
		relative_node_type = "Node3DEditorViewport"
		base_reference = Enums.NodePoint.NODE_3D_EDITOR_VIEWPORT_OVERLAYS

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.GetChildTypeStep.new("EditorTranslationPreviewButton"),
		]


class Node3dEditorViewportCameraPreviewCheckDef extends Types.Definition:
	func _init() -> void:
		node_type = "CheckBox"
		relative_node_type = "Node3DEditorViewport"
		base_reference = Enums.NodePoint.NODE_3D_EDITOR_VIEWPORT_OVERLAYS

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("CheckBox", 0),
			Types.HasEditorIconStep.new("Camera3DDarkBackground"),
		]


class Node3dEditorViewportRotationGizmoDef extends Types.Definition:
	func _init() -> void:
		node_type = "ViewportRotationControl"
		relative_node_type = "Node3DEditorViewport"
		base_reference = Enums.NodePoint.NODE_3D_EDITOR_VIEWPORT_OVERLAYS

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", -1),
			Types.GetChildTypeStep.new("ViewportRotationControl"),
		]
