@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


## Root node of the asset library.
class AssetLibraryDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorAssetLibrary"
		base_reference = Enums.NodePoint.MAIN_VIEW_CONTAINER_BOX

		resolver_steps = [
			Types.GetChildTypeStep.new("EditorAssetLibrary"),
		]
