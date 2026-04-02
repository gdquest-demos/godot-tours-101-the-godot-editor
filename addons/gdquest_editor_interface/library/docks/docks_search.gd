@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


# NOTE: Search and replace result panels themselves are reusable components,
# and thus cannot be resolved statically.

class SearchResultsDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "FindInFilesContainer"
		base_reference = Enums.NodePoint.LAYOUT_ROOT

		# NOTE: The fact that this node is listening to `theme_changed` somewhere
		# is a poor implementation in engine source, and so we should expect this to
		# disappear one day. Then it's the regular brute-force way.

		resolver_steps = [
			Types.GetSignalTypeStep.new("theme_changed", "FindInFilesContainer"),
		]
