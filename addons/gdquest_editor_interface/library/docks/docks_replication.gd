@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


class ReplicationDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorDock"
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
				for dock in dock_container.get_children():
					if dock is not EditorDock:
						continue
					if dock.get_child_count() != 1:
						continue

					# This is an obsolete dock, which is automatically wrapped in EditorDock.
					# We need to check the child to be sure. Note that this can be "fixed"
					# even in a minor version (which will be good for us).
					var dock_child := dock.get_child(0)
					if ClassDB.is_parent_class(dock_child.get_class(), "ReplicationEditor"):
						return dock

			return null

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class ReplicationEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "ReplicationEditor"
		base_reference = Enums.NodePoint.REPLICATION_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("ReplicationEditor"),
		]
