@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")


class ImportSceneSettingsDialogDef extends Types.Definition:
	func _init() -> void:
		node_type = "SceneImportSettingsDialog"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildTypeStep.new("SceneImportSettingsDialog")
		]


class ImportSceneSettingsDialogOkButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.IMPORT_SCENE_SETTINGS_DIALOG

		var custom_script := func(base_node: Node) -> Node:
			return (base_node as ConfirmationDialog).get_ok_button()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class ImportSceneSettingsDialogCancelButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.IMPORT_SCENE_SETTINGS_DIALOG

		var custom_script := func(base_node: Node) -> Node:
			return (base_node as ConfirmationDialog).get_cancel_button()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class ImportSceneSettingsDialogPanelsDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.IMPORT_SCENE_SETTINGS_DIALOG

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
		]
