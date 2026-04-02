@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


## The root node of the interactive game view. Even if it is disabled
## via engine feature profiles, the node is present in the tree, at
## the exact same spot.
class GameViewDef extends Types.Definition:
	func _init() -> void:
		node_type = "GameView"
		base_reference = Enums.NodePoint.MAIN_VIEW_CONTAINER_BOX

		resolver_steps = [
			Types.GetChildTypeStep.new("WindowWrapper", 1),
			Types.GetWindowWrappedTypeStep.new("GameView"),
		]
