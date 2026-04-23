@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")


class HistoryDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "HistoryDock"
		base_reference = Enums.NodePoint.EDITOR_NODE

		resolver_steps = [
			Types.GetSignalTypeStep.new("scene_changed", "HistoryDock"),
		]
