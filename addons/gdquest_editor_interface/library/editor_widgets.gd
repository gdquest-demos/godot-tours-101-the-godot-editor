# These are primarily reusable components, which can be found
# across the editor UI.
@tool

const Enums := preload("../utils/eia_enums.gd")
const Types := preload("../utils/eia_resolver_types.gd")
const Utils := preload("../utils/eia_resolver_utils.gd")


class EditorZoomWidgetZoomOutButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		relative_node_type = "EditorZoomWidget"

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 0),
		]


class EditorZoomWidgetZoomInButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		relative_node_type = "EditorZoomWidget"

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 2),
		]


class EditorZoomWidgetResetButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		relative_node_type = "EditorZoomWidget"

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 1),
		]
