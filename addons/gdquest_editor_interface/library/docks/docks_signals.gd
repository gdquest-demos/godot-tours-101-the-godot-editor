@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


class SignalsDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "SignalsDock"
		prefetch_references = [
			Enums.NodePoint.LAYOUT_ROOT,
			Enums.NodePoint.LAYOUT_DOCK_LEFT_LEFT_TOP,
			Enums.NodePoint.LAYOUT_DOCK_LEFT_LEFT_BOTTOM,
			Enums.NodePoint.LAYOUT_DOCK_LEFT_RIGHT_TOP,
			Enums.NodePoint.LAYOUT_DOCK_LEFT_RIGHT_BOTTOM,
			Enums.NodePoint.LAYOUT_DOCK_RIGHT_LEFT_TOP,
			Enums.NodePoint.LAYOUT_DOCK_RIGHT_LEFT_BOTTOM,
			Enums.NodePoint.LAYOUT_DOCK_RIGHT_RIGHT_TOP,
			Enums.NodePoint.LAYOUT_DOCK_RIGHT_RIGHT_BOTTOM,
			Enums.NodePoint.LAYOUT_DOCK_MIDDLE_BOTTOM,
			Enums.NodePoint.LAYOUT_DOCK_HIDDEN_CONTAINER,
		]

		var custom_script := func(base_node: Node) -> Node:
			var dock_locations := Utils.dock_get_locations()
			for dock_container in dock_locations:
				var dock := dock_container.find_child("Signals", false, false)
				if dock:
					return dock

			return null

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class SignalsEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "ConnectionsDock" # A remnant of a past...
		base_reference = Enums.NodePoint.SIGNALS_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("ConnectionsDock"),
		]


class SignalsEditorTextFilterDef extends Types.Definition:
	func _init() -> void:
		node_type = "LineEdit"
		base_reference = Enums.NodePoint.SIGNALS_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("LineEdit"),
		]


class SignalsEditorTreeDef extends Types.Definition:
	func _init() -> void:
		node_type = "Tree"
		base_reference = Enums.NodePoint.SIGNALS_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("MarginContainer"),
			Types.GetChildTypeStep.new("Tree"),
		]


class SignalsEditorConnectButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SIGNALS_EDITOR

		# NOTE: This button can change its icon, or have no icon at all.
		# So for extra check we validate using the callable.

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("HBoxContainer", -1),
			Types.GetChildTypeStep.new("Button", 0),
			Types.HasSignalCallableStep.new("pressed", "ConnectionsDock::_connect_pressed"),
		]


## Connect dialog for the signal editor.
class SignalsDialogDef extends Types.Definition:
	func _init() -> void:
		node_type = "ConnectDialog"
		base_reference = Enums.NodePoint.SIGNALS_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("ConnectDialog"),
		]


class SignalsDialogOkButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG

		var custom_script := func(base_node: Node) -> Node:
			return (base_node as ConfirmationDialog).get_ok_button()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class SignalsDialogCancelButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG

		var custom_script := func(base_node: Node) -> Node:
			return (base_node as ConfirmationDialog).get_cancel_button()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class SignalsDialogPanelsDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
		]


class SignalsDialogBasicPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG_PANELS

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
		]


class SignalsDialogAdvancedPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG_PANELS

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 1),
		]


# Basic panel elements.

class SignalsDialogSignalEditDef extends Types.Definition:
	func _init() -> void:
		node_type = "LineEdit"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG_BASIC_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildTypeStep.new("LineEdit"),
		]


class SignalsDialogMethodEditDef extends Types.Definition:
	func _init() -> void:
		node_type = "LineEdit"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG_BASIC_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", -1),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("LineEdit"),
		]


class SignalsDialogMethodEditPickButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG_BASIC_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", -1),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("Button"),
			Types.HasEditorIconStep.new("Edit"),
		]


class SignalsDialogNodeTreeDef extends Types.Definition:
	func _init() -> void:
		node_type = "Tree"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG_BASIC_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("SceneTreeEditor"),
			Types.GetChildTypeStep.new("Tree"),
		]


class SignalsDialogNodeTextFilterDef extends Types.Definition:
	func _init() -> void:
		node_type = "LineEdit"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG_BASIC_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 1),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("LineEdit"),
		]


class SignalsDialogNodeToSourceButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG_BASIC_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 1),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("Button"),
		]


class SignalsDialogAdvancedCheckDef extends Types.Definition:
	func _init() -> void:
		node_type = "CheckButton"
		base_reference = Enums.NodePoint.SIGNALS_DIALOG_BASIC_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("CheckButton"),
		]
