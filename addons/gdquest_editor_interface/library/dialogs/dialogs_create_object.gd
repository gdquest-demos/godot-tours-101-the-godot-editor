@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


class CreateObjectDialogOkButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		relative_node_type = "CreateDialog"

		var custom_script := func(base_node: Node) -> Node:
			return (base_node as ConfirmationDialog).get_ok_button()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class CreateObjectDialogCancelButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		relative_node_type = "CreateDialog"

		var custom_script := func(base_node: Node) -> Node:
			return (base_node as ConfirmationDialog).get_cancel_button()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


# Dialog panels. The view is split into 4 segments using nested split
# containers. One splits everything into two columns, the other two
# split their columns in two.

class CreateObjectDialogPanelsDef extends Types.Definition:
	func _init() -> void:
		node_type = "HSplitContainer"
		relative_node_type = "CreateDialog"

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
		]


class CreateObjectDialogFavoritesPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		relative_node_type = "CreateDialog"
		base_reference = Enums.NodePoint.CREATE_OBJECT_DIALOG_PANELS

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("VBoxContainer", 0),
		]


class CreateObjectDialogFavoritesListDef extends Types.Definition:
	func _init() -> void:
		node_type = "Tree"
		relative_node_type = "CreateDialog"
		base_reference = Enums.NodePoint.CREATE_OBJECT_DIALOG_FAVORITES_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer"),
			Types.GetChildTypeStep.new("Tree"),
		]


class CreateObjectDialogRecentPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		relative_node_type = "CreateDialog"
		base_reference = Enums.NodePoint.CREATE_OBJECT_DIALOG_PANELS

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("VBoxContainer", 1),
		]


class CreateObjectDialogRecentListDef extends Types.Definition:
	func _init() -> void:
		node_type = "ItemList"
		relative_node_type = "CreateDialog"
		base_reference = Enums.NodePoint.CREATE_OBJECT_DIALOG_RECENT_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer"),
			Types.GetChildTypeStep.new("ItemList"),
		]


class CreateObjectDialogSearchPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		relative_node_type = "CreateDialog"
		base_reference = Enums.NodePoint.CREATE_OBJECT_DIALOG_PANELS

		resolver_steps = [
			Types.GetChildIndexStep.new(1),
			Types.GetChildTypeStep.new("VBoxContainer", 0),
		]


class CreateObjectDialogSearchTextFilterDef extends Types.Definition:
	func _init() -> void:
		node_type = "LineEdit"
		relative_node_type = "CreateDialog"
		base_reference = Enums.NodePoint.CREATE_OBJECT_DIALOG_SEARCH_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("LineEdit"),
		]


class CreateObjectDialogSearchFavoriteButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		relative_node_type = "CreateDialog"
		base_reference = Enums.NodePoint.CREATE_OBJECT_DIALOG_SEARCH_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("Button"),
		]


class CreateObjectDialogSearchMatchesListDef extends Types.Definition:
	func _init() -> void:
		node_type = "Tree"
		relative_node_type = "CreateDialog"
		base_reference = Enums.NodePoint.CREATE_OBJECT_DIALOG_SEARCH_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer", 1),
			Types.GetChildTypeStep.new("Tree"),
		]


class CreateObjectDialogDescriptionPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		relative_node_type = "CreateDialog"
		base_reference = Enums.NodePoint.CREATE_OBJECT_DIALOG_PANELS

		resolver_steps = [
			Types.GetChildIndexStep.new(1),
			Types.GetChildTypeStep.new("VBoxContainer", 1),
		]


class CreateObjectDialogDescriptionBitDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorHelpBit"
		relative_node_type = "CreateDialog"
		base_reference = Enums.NodePoint.CREATE_OBJECT_DIALOG_DESCRIPTION_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("MarginContainer"),
			Types.GetChildTypeStep.new("EditorHelpBit"),
		]
