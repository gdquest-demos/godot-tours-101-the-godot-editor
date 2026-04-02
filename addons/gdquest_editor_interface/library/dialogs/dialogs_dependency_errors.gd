@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")


class DependencyErrorDialogDef extends Types.Definition:
	func _init() -> void:
		node_type = "DependencyErrorDialog"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildTypeStep.new("DependencyErrorDialog")
		]
