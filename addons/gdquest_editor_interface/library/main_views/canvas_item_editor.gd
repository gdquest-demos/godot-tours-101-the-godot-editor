@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


## Root node of the canvas item editor (main 2D view).
class CanvasItemEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "CanvasItemEditor"
		base_reference = Enums.NodePoint.MAIN_VIEW_CONTAINER_BOX

		resolver_steps = [
			Types.GetChildTypeStep.new("CanvasItemEditor"),
		]


## Main toolbar container of the canvas item editor.
class CanvasItemEditorMainToolbarDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildTypeStep.new("FlowContainer", 0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
		]


## All buttons present in the toolbar, resolved together.
class CanvasItemEditorMainToolbarButtonsDef extends Types.MultiDefinition:
	func _init() -> void:
		node_type_map = {
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_SELECT_BUTTON:             "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_MOVE_BUTTON:               "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_ROTATE_BUTTON:             "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_SCALE_BUTTON:              "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_SELECTABLE_BUTTON:         "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_PIVOT_BUTTON:              "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_PAN_BUTTON:                "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_RULER_BUTTON:              "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_LOCAL_SPACE_BUTTON:        "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_SMART_SNAP_BUTTON:         "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_GRID_BUTTON:               "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_SNAP_OPTIONS_BUTTON:       "MenuButton",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_LOCK_BUTTON:               "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_UNLOCK_BUTTON:             "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_GROUP_BUTTON:              "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_UNGROUP_BUTTON:            "Button",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_SKELETON_OPTIONS_BUTTON:   "MenuButton",
			Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR_VIEW_OPTIONS_BUTTON:       "MenuButton",
		}
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_MAIN_TOOLBAR

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
						if Utils.node_has_signal_callable(popup_menu, "about_to_popup", "CanvasItemEditor::_prepare_view_menu"):
							button_key = "ViewMenu"

				# Couldn't identify, skipping.
				if button_key.is_empty():
					continue

				toolbar_buttons_map[button_key] = button

			results[0]  = toolbar_buttons_map["ToolSelect"]     if "ToolSelect"     in toolbar_buttons_map else null
			results[1]  = toolbar_buttons_map["ToolMove"]       if "ToolMove"       in toolbar_buttons_map else null
			results[2]  = toolbar_buttons_map["ToolRotate"]     if "ToolRotate"     in toolbar_buttons_map else null
			results[3]  = toolbar_buttons_map["ToolScale"]      if "ToolScale"      in toolbar_buttons_map else null
			results[4]  = toolbar_buttons_map["ListSelect"]     if "ListSelect"     in toolbar_buttons_map else null
			results[5]  = toolbar_buttons_map["EditPivot"]      if "EditPivot"      in toolbar_buttons_map else null
			results[6]  = toolbar_buttons_map["ToolPan"]        if "ToolPan"        in toolbar_buttons_map else null
			results[7]  = toolbar_buttons_map["Ruler"]          if "Ruler"          in toolbar_buttons_map else null
			results[8]  = toolbar_buttons_map["Object"]         if "Object"         in toolbar_buttons_map else null
			results[9]  = toolbar_buttons_map["Snap"]           if "Snap"           in toolbar_buttons_map else null
			results[10] = toolbar_buttons_map["SnapGrid"]       if "SnapGrid"       in toolbar_buttons_map else null
			results[11] = toolbar_buttons_map["GuiTabMenuHl"]   if "GuiTabMenuHl"   in toolbar_buttons_map else null
			results[12] = toolbar_buttons_map["Lock"]           if "Lock"           in toolbar_buttons_map else null
			results[13] = toolbar_buttons_map["Unlock"]         if "Unlock"         in toolbar_buttons_map else null
			results[14] = toolbar_buttons_map["Group"]          if "Group"          in toolbar_buttons_map else null
			results[15] = toolbar_buttons_map["Ungroup"]        if "Ungroup"        in toolbar_buttons_map else null
			results[16] = toolbar_buttons_map["Bone"]           if "Bone"           in toolbar_buttons_map else null
			results[17] = toolbar_buttons_map["ViewMenu"]       if "ViewMenu"       in toolbar_buttons_map else null

			return results

		resolver_steps = [
			Types.DoCustomMultiStep.new(custom_script),
		]

class CanvasItemEditorMainToolbarSelectButtonDef            extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarMoveButtonDef              extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarRotateButtonDef            extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarScaleButtonDef             extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarSelectableButtonDef        extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarPivotButtonDef             extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarPanButtonDef               extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarRulerButtonDef             extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarLocalSpaceButtonDef        extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarSmartSnapButtonDef         extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarGridButtonDef              extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarSnapOptionsButtonDef       extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarLockButtonDef              extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarUnlockButtonDef            extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarGroupButtonDef             extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarUngroupButtonDef           extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarSkeletonOptionsButtonDef   extends CanvasItemEditorMainToolbarButtonsDef: pass
class CanvasItemEditorMainToolbarViewOptionsButtonDef       extends CanvasItemEditorMainToolbarButtonsDef: pass


## Toolbar container for contextual toolbars, populated by editor plugins.
class CanvasItemEditorContextualToolbarsDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildTypeStep.new("FlowContainer", 0),
			Types.GetChildTypeStep.new("PanelContainer", 0),
			Types.GetChildIndexStep.new(0),
		]


# Viewport.

# NOTE: Organization in the canvas item editor is pretty messy, the
# node called "viewport" is actually a container for editor overlays,
# and the actual Viewport "viewport" is its sibling. Their collective
# parent is not typed or named at all.
#
# The structure, however, is exactly the same as spatial/3d editor.
# There is a root control node, then there is a subviewport container
# with the actual subviewport, and then there is another control for
# overlays.
#
# So, for consistency and clearer logical structure we're naming
# nodes here in the exact same manner. Which means the node with the
# internal type of "CanvasItemEditorViewport" is NOT the one we
# define with CanvasItemEditorViewportDef, it's the one we define
# with CanvasItemEditorViewportOverlaysDef. And the enums are, of
# cource, named accordingly.

class CanvasItemEditorViewportDef extends Types.Definition:
	func _init() -> void:
		node_type = "Control"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("Control"),
		]


class CanvasItemEditorViewportSceneRootDef extends Types.Definition:
	func _init() -> void:
		node_type = "SubViewport"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_VIEWPORT

		resolver_steps = [
			Types.GetChildTypeStep.new("SubViewportContainer"),
			Types.GetChildTypeStep.new("SubViewport"),
		]


class CanvasItemEditorViewportOverlaysDef extends Types.Definition:
	func _init() -> void:
		node_type = "CanvasItemEditorViewport"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_VIEWPORT

		resolver_steps = [
			Types.GetChildTypeStep.new("CanvasItemEditorViewport", 0),
		]


class CanvasItemEditorViewportZoomWidgetDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorZoomWidget"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_VIEWPORT_OVERLAYS

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.GetChildTypeStep.new("EditorZoomWidget", 0),
		]


class CanvasItemEditorViewportCenterButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_VIEWPORT_OVERLAYS

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.GetChildTypeStep.new("Button", 0),
			Types.HasEditorIconStep.new("CenterView"),
		]


class CanvasItemEditorViewportTranslationPreviewButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorTranslationPreviewButton"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_VIEWPORT_OVERLAYS

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.GetChildTypeStep.new("EditorTranslationPreviewButton"),
		]


# Snap options dialog.

class CanvasItemEditorSnapDialogDef extends Types.Definition:
	func _init() -> void:
		node_type = "SnapDialog"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("SnapDialog"),
		]


class CanvasItemEditorSnapDialogOkButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG

		var custom_script := func(base_node: Node) -> Node:
			return (base_node as ConfirmationDialog).get_ok_button()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class CanvasItemEditorSnapDialogCancelButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG

		var custom_script := func(base_node: Node) -> Node:
			return (base_node as ConfirmationDialog).get_cancel_button()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class CanvasItemEditorSnapDialogOptionsDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
		]


# Snap option groups.

class CanvasItemEditorSnapDialogGridOptionsDef extends Types.Definition:
	func _init() -> void:
		node_type = "GridContainer"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("GridContainer", 0),
		]


class CanvasItemEditorSnapDialogGridOffsetXDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_GRID_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("SpinBox", 0),
		]


class CanvasItemEditorSnapDialogGridOffsetYDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_GRID_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("SpinBox", 1),
		]


class CanvasItemEditorSnapDialogGridStepXDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_GRID_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("SpinBox", 2),
		]


class CanvasItemEditorSnapDialogGridStepYDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_GRID_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("SpinBox", 3),
		]


class CanvasItemEditorSnapDialogGridPrimaryXDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_GRID_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("SpinBox", 4),
		]


class CanvasItemEditorSnapDialogGridPrimaryYDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_GRID_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("SpinBox", 5),
		]


class CanvasItemEditorSnapDialogRotationOptionsDef extends Types.Definition:
	func _init() -> void:
		node_type = "GridContainer"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("GridContainer", 1),
		]


class CanvasItemEditorSnapDialogRotationOffsetDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_ROTATION_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("SpinBox", 0),
		]


class CanvasItemEditorSnapDialogRotationStepDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_ROTATION_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("SpinBox", 1),
		]


class CanvasItemEditorSnapDialogScaleOptionsDef extends Types.Definition:
	func _init() -> void:
		node_type = "GridContainer"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("GridContainer", 2),
		]


class CanvasItemEditorSnapDialogScaleStepDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.CANVAS_ITEM_EDITOR_SNAP_DIALOG_SCALE_OPTIONS

		resolver_steps = [
			Types.GetChildTypeStep.new("SpinBox", 0),
		]
