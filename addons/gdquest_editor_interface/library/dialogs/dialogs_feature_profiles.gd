@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")


class FeatureProfileManagerDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorFeatureProfileManager"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildTypeStep.new("EditorFeatureProfileManager")
		]
