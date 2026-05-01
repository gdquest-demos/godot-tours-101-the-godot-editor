@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


class ThemeDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "ThemeEditor"
		base_reference = Enums.NodePoint.EDITOR_NODE

		resolver_steps = [
			Types.GetSignalTypeStep.new("scene_closed", "ThemeEditor"),
		]
