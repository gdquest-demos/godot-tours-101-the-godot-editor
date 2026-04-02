@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


class DebuggerDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorDebuggerNode"
		base_reference = Enums.NodePoint.SCENE_DOCK

		resolver_steps = [
			Types.GetSignalTypeStep.new("remote_tree_selected", "EditorDebuggerNode"),
		]
