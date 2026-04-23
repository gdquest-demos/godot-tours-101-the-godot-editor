@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


class GroupsDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "GroupsDock"
		prefetch_references = [
			Enums.NodePoint.LAYOUT_ROOT,
			Enums.NodePoint.LAYOUT_DOCK_LEFT_LEFT_TOP,
			Enums.NodePoint.LAYOUT_DOCK_LEFT_LEFT_BOTTOM,
			Enums.NodePoint.LAYOUT_DOCK_LEFT_RIGHT_TOP,
			Enums.NodePoint.LAYOUT_DOCK_LEFT_RIGHT_BOTTOM,
			Enums.NodePoint.LAYOUT_DOCK_RIGHT_LEFT_TOP,
			Enums.NodePoint.LAYOUT_DOCK_RIGHT_LEFT_BOTTOM,
			Enums.NodePoint.LAYOUT_DOCK_RIGHT_RIGHT_TOP,
			Enums.NodePoint.LAYOUT_DOCK_RIGHT_RIGHT_BOTTOM,
			Enums.NodePoint.LAYOUT_DOCK_MIDDLE_BOTTOM,
			Enums.NodePoint.LAYOUT_DOCK_HIDDEN_CONTAINER,
		]

		var custom_script := func(base_node: Node) -> Node:
			var dock_locations := Utils.dock_get_locations()
			for dock_container in dock_locations:
				var dock := dock_container.find_child("Groups", false, false)
				if dock:
					return dock

			return null

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class GroupsEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "GroupsEditor"
		base_reference = Enums.NodePoint.GROUPS_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("GroupsEditor"),
		]
