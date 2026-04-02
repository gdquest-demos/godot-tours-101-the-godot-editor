@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


class AnimationDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "AnimationPlayerEditor"

		var custom_script := func(base_node: Node) -> Node:
			var st := EditorInterface.get_base_control().get_tree()
			return Utils.object_get_signal_type(st, "node_removed", "AnimationPlayerEditor")

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]
