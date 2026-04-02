@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")


class InspectorDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "InspectorDock"
		base_reference = Enums.NodePoint.FILE_SYSTEM_DOCK

		resolver_steps = [
			Types.GetSignalTypeStep.new("files_moved", "InspectorDock"),
		]


class InspectorDockInspectorDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorInspector"

		var custom_script := func(base_node: Node) -> Node:
			return EditorInterface.get_inspector()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class InspectorDockInspectorBeginBoxDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.INSPECTOR_DOCK_INSPECTOR

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("VBoxContainer", 0)
		]


class InspectorDockInspectorFavoritesDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.INSPECTOR_DOCK_INSPECTOR

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("VBoxContainer", 1)
		]


class InspectorDockInspectorPropertiesDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.INSPECTOR_DOCK_INSPECTOR

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("VBoxContainer", 2)
		]
