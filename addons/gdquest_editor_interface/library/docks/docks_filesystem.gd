@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")


class FileSystemDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "FileSystemDock"

		var custom_script := func(base_node: Node) -> Node:
			return EditorInterface.get_file_system_dock()

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class FileSystemTreeDef extends Types.Definition:
	func _init() -> void:
		node_type = "Tree"
		base_reference = Enums.NodePoint.FILE_SYSTEM_DOCK

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("Tree"),
		]


class FileSystemListDef extends Types.Definition:
	func _init() -> void:
		node_type = "FileSystemList"
		base_reference = Enums.NodePoint.FILE_SYSTEM_DOCK

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildIndexStep.new(1),
			Types.GetChildTypeStep.new("MarginContainer", 0),
			Types.GetChildTypeStep.new("FileSystemList"),
		]
