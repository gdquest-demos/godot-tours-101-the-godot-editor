@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")


## NOTE: Not available in Android and Web builds.
class FbxImporterManagerDef extends Types.Definition:
	func _init() -> void:
		node_type = "FBXImporterManager"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		resolver_steps = [
			Types.GetChildTypeStep.new("FBXImporterManager")
		]
