@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


## The dock is only visible after the user has selected an AnimatedSprite2D
## or 3D node with a valid SpriteFrames resource, or opened/expanded a
## SpriteFrames resource directly in the Inspector.
class SpriteFramesDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpriteFramesEditor"

		var custom_script := func(base_node: Node) -> Node:
			var st := EditorInterface.get_base_control().get_tree()
			return Utils.object_get_signal_type(st, "node_removed", "SpriteFramesEditor")

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class SpriteFramesAnimationsPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("VBoxContainer", 0),
		]


class SpriteFramesFramesPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("VBoxContainer", 1),
		]


# Animation panel elements.

class SpriteFramesAnimationsToolbarDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("HBoxContainer"),
		]


class SpriteFramesAnimationsToolbarButtonsDef extends Types.MultiDefinition:
	func _init() -> void:
		# NOTE: There is also a duplicate button, but it has been hidden when
		# cut/copy/paste were introduced. It cannot be accessed by users at any
		# point and the PR author wanted to remove it but was not given an
		# answer whether they should: https://github.com/godotengine/godot/pull/107887.
		node_type_map = {
			Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_TOOLBAR_ADD_BUTTON:        "Button",
			Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_TOOLBAR_CUT_BUTTON:        "Button",
			Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_TOOLBAR_COPY_BUTTON:       "Button",
			Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_TOOLBAR_PASTE_BUTTON:      "Button",
			Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_TOOLBAR_DELETE_BUTTON:     "Button",
			Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_TOOLBAR_AUTOPLAY_BUTTON:   "Button",
			Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_TOOLBAR_LOOPING_BUTTON:    "Button",
		}
		base_reference = Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_TOOLBAR

		var custom_script := func(base_nodes: Array[Node]) -> Array[Node]:
			if base_nodes.is_empty():
				return []

			var results: Array[Node] = []
			results.resize(node_type_map.size())
			results.fill(null)

			var toolbar := base_nodes[0]
			var toolbar_buttons := toolbar.find_children("", "Button", true, false)
			var toolbar_buttons_map: Dictionary[String, Button] = {}

			for button: Button in toolbar_buttons:
				var button_key := ""
				if button.icon:
					button_key = Utils.node_get_editor_icon(button)

				if button_key.is_empty():
					continue

				toolbar_buttons_map[button_key] = button

			results[0] = toolbar_buttons_map["New"]           if "New"           in toolbar_buttons_map else null
			results[1] = toolbar_buttons_map["ActionCut"]     if "ActionCut"     in toolbar_buttons_map else null
			results[2] = toolbar_buttons_map["ActionCopy"]    if "ActionCopy"    in toolbar_buttons_map else null
			results[3] = toolbar_buttons_map["ActionPaste"]   if "ActionPaste"   in toolbar_buttons_map else null
			results[4] = toolbar_buttons_map["Remove"]        if "Remove"        in toolbar_buttons_map else null
			results[5] = toolbar_buttons_map["AutoPlay"]      if "AutoPlay"      in toolbar_buttons_map else null
			results[6] = toolbar_buttons_map["Loop"]          if "Loop"          in toolbar_buttons_map else null

			return results

		resolver_steps = [
			Types.DoCustomMultiStep.new(custom_script),
		]

class SpriteFramesAnimationsToolbarAddButtonDef        extends SpriteFramesAnimationsToolbarButtonsDef: pass
class SpriteFramesAnimationsToolbarCutButtonDef        extends SpriteFramesAnimationsToolbarButtonsDef: pass
class SpriteFramesAnimationsToolbarCopyButtonDef       extends SpriteFramesAnimationsToolbarButtonsDef: pass
class SpriteFramesAnimationsToolbarPasteButtonDef      extends SpriteFramesAnimationsToolbarButtonsDef: pass
class SpriteFramesAnimationsToolbarDeleteButtonDef     extends SpriteFramesAnimationsToolbarButtonsDef: pass
class SpriteFramesAnimationsToolbarAutoplayButtonDef   extends SpriteFramesAnimationsToolbarButtonsDef: pass
class SpriteFramesAnimationsToolbarLoopingButtonDef    extends SpriteFramesAnimationsToolbarButtonsDef: pass


class SpriteFramesAnimationsToolbarSpeedEditDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("SpinBox", 0),
		]


class SpriteFramesAnimationsTextFilterDef extends Types.Definition:
	func _init() -> void:
		node_type = "LineEdit"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("LineEdit"),
		]


class SpriteFramesAnimationsListDef extends Types.Definition:
	func _init() -> void:
		node_type = "Tree"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_ANIMATIONS_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("Tree"),
		]


# Frames panel elements.

class SpriteFramesFramesToolbarDef extends Types.Definition:
	func _init() -> void:
		node_type = "HFlowContainer"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_FRAMES_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("HFlowContainer"),
		]


class SpriteFramesFramesToolbarButtonsDef extends Types.MultiDefinition:
	func _init() -> void:
		node_type_map = {
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_PLAY_FORWARDS_BUTTON:         "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_PLAY_FORWARDS_FULL_BUTTON:    "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_PLAY_BACKWARDS_BUTTON:        "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_PLAY_BACKWARDS_FULL_BUTTON:   "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_STOP_BUTTON:                  "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_ADD_FILE_BUTTON:              "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_ADD_SPRITE_SHEET_BUTTON:      "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_COPY_BUTTON:                  "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_PASTE_BUTTON:                 "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_INSERT_BEFORE_BUTTON:         "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_INSERT_AFTER_BUTTON:          "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_MOVE_LEFT_BUTTON:             "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_MOVE_RIGHT_BUTTON:            "Button",
			Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR_DELETE_BUTTON:                "Button",
		}
		base_reference = Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR

		var custom_script := func(base_nodes: Array[Node]) -> Array[Node]:
			if base_nodes.is_empty():
				return []

			var results: Array[Node] = []
			results.resize(node_type_map.size())
			results.fill(null)

			var toolbar := base_nodes[0]
			var toolbar_buttons := toolbar.find_children("", "Button", true, false)
			var toolbar_buttons_map: Dictionary[String, Button] = {}

			for button: Button in toolbar_buttons:
				var button_key := ""

				# First, try to identify using the icon.
				if button.icon:
					button_key = Utils.node_get_editor_icon(button)

				# Then, handle special cases.

				# Stop button can change its icon, so we use the signal.
				if Utils.node_has_signal_callable(button, "pressed", "SpriteFramesEditor::_stop_pressed"):
					button_key = "Stop"

				# Couldn't identify, skipping.
				if button_key.is_empty():
					continue

				toolbar_buttons_map[button_key] = button

			results[0]  = toolbar_buttons_map["Play"]                 if "Play"                 in toolbar_buttons_map else null
			results[1]  = toolbar_buttons_map["PlayStart"]            if "PlayStart"            in toolbar_buttons_map else null
			results[2]  = toolbar_buttons_map["PlayBackwards"]        if "PlayBackwards"        in toolbar_buttons_map else null
			results[3]  = toolbar_buttons_map["PlayStartBackwards"]   if "PlayStartBackwards"   in toolbar_buttons_map else null
			results[4]  = toolbar_buttons_map["Stop"]                 if "Stop"                 in toolbar_buttons_map else null
			results[5]  = toolbar_buttons_map["Load"]                 if "Load"                 in toolbar_buttons_map else null
			results[6]  = toolbar_buttons_map["SpriteSheet"]          if "SpriteSheet"          in toolbar_buttons_map else null
			results[7]  = toolbar_buttons_map["ActionCopy"]           if "ActionCopy"           in toolbar_buttons_map else null
			results[8]  = toolbar_buttons_map["ActionPaste"]          if "ActionPaste"          in toolbar_buttons_map else null
			results[9]  = toolbar_buttons_map["InsertBefore"]         if "InsertBefore"         in toolbar_buttons_map else null
			results[10] = toolbar_buttons_map["InsertAfter"]          if "InsertAfter"          in toolbar_buttons_map else null
			results[11] = toolbar_buttons_map["MoveLeft"]             if "MoveLeft"             in toolbar_buttons_map else null
			results[12] = toolbar_buttons_map["MoveRight"]            if "MoveRight"            in toolbar_buttons_map else null
			results[13] = toolbar_buttons_map["Remove"]               if "Remove"               in toolbar_buttons_map else null

			return results

		resolver_steps = [
			Types.DoCustomMultiStep.new(custom_script),
		]

class SpriteFramesFramesToolbarPlayForwardsButtonDef        extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarPlayForwardsFullButtonDef    extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarPlayBackwardsButtonDef       extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarPlayBackwardsFullButtonDef   extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarStopButtonDef                extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarAddFileButtonDef             extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarAddSpriteSheetButtonDef      extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarCopyButtonDef                extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarPasteButtonDef               extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarInsertBeforeButtonDef        extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarInsertAfterButtonDef         extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarMoveLeftButtonDef            extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarMoveRightButtonDef           extends SpriteFramesFramesToolbarButtonsDef: pass
class SpriteFramesFramesToolbarDeleteButtonDef              extends SpriteFramesFramesToolbarButtonsDef: pass


class SpriteFramesFramesToolbarFrameDurationEditDef extends Types.Definition:
	func _init() -> void:
		node_type = "SpinBox"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR

		# NOTE: It's in a sub-container, so to be sure, we look for the
		# first occurence in the entire toolbar.

		resolver_steps = [
			Types.FindNodeTypeStep.new("SpinBox"),
		]


class SpriteFramesFramesZoomBoxDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_FRAMES_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("HBoxContainer", -1),
		]


class SpriteFramesFramesZoomBoxZoomOutButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_FRAMES_ZOOM_BOX

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 0),
			Types.HasEditorIconStep.new("ZoomLess"),
		]


class SpriteFramesFramesZoomBoxZoomInButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_FRAMES_ZOOM_BOX

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 2),
			Types.HasEditorIconStep.new("ZoomMore"),
		]


class SpriteFramesFramesZoomBoxResetButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_FRAMES_ZOOM_BOX

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 1),
			Types.HasEditorIconStep.new("ZoomReset"),
		]


class SpriteFramesFramesListDef extends Types.Definition:
	func _init() -> void:
		node_type = "ItemList"
		base_reference = Enums.NodePoint.SPRITE_FRAMES_FRAMES_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("ItemList"),
		]
