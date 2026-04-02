## Utility functions for the node point resolver utility and point definitions.
@tool

const Enums := preload("./eia_enums.gd")
const Resolver := preload("./eia_resolver.gd")

static var _editor_icon_list: PackedStringArray = []


static func _static_init() -> void:
	EditorInterface.get_base_control().theme_changed.connect(_build_icon_list)
	_build_icon_list()


static func _build_icon_list() -> void:
	var editor_theme := EditorInterface.get_editor_theme()
	_editor_icon_list = editor_theme.get_icon_list("EditorIcons")


# Signal utilities.

static func object_get_signal_type(base_object: Object, signal_name: String, type_name: String, strict: bool = false) -> Object:
	var signal_ref: Signal = base_object[signal_name]
	if not signal_ref:
		if strict:
			push_warning("[EIA] Expected signal '%s' on object." % [ signal_name ])
		return null

	for connection_info in signal_ref.get_connections():
		var object_ref := (connection_info["callable"] as Callable).get_object()

		if ClassDB.is_parent_class(object_ref.get_class(), type_name):
			return object_ref

	if strict:
		push_warning("[EIA] Expected '%s' object connected to signal '%s'." % [ type_name, signal_name ])
	return null


static func _check_node_signal_callable(base_node: Node, signal_name: String, callable_name: String, strict: bool = false) -> bool:
	var signal_ref: Signal = base_node[signal_name]
	if not signal_ref:
		if strict:
			push_warning("[EIA] Expected signal '%s' on node %s." % [ signal_name, base_node ])
		return false

	var signal_connections := signal_ref.get_connections()
	for connect_info: Dictionary in signal_connections:
		var callable := connect_info["callable"] as Callable
		if not callable || not callable.is_valid():
			continue

		if callable.get_method() == callable_name:
			return true

	return false


static func node_has_signal_callable(base_node: Node, signal_name: String, callable_name: String, strict: bool = false) -> bool:
	if _check_node_signal_callable(base_node, signal_name, callable_name):
		return true

	if strict:
		push_warning("[EIA] Expected callable '%s' connected to signal '%s' on node %s." % [ callable_name, signal_name, base_node ])
	return false


static func node_has_any_signal_callable(base_node: Node, callable_name: String, strict: bool = false) -> bool:
	for signal_info: Dictionary in base_node.get_signal_list():
		if _check_node_signal_callable(base_node, signal_info.name, callable_name):
			return true

	if strict:
		push_warning("[EIA] Expected callable '%s' connected to any signal on node %s." % [ callable_name, base_node ])
	return false


# Shortcut utilities.

static func popup_menu_has_shortcut_item(base_node: PopupMenu, shortcut_name: String, strict: bool = false) -> bool:
	var editor_shortcut: Shortcut = null
	if not shortcut_name.is_empty():
		editor_shortcut = EditorInterface.get_editor_settings().get_shortcut(shortcut_name)

	if not editor_shortcut:
		if strict:
			push_warning("[EIA] Shortcut '%s' doesn't exist in the editor." % [ shortcut_name ])
		return false

	for i in base_node.get_item_count():
		var item_shortcut := base_node.get_item_shortcut(i)
		if item_shortcut == editor_shortcut:
			return true

	if strict:
		push_warning("[EIA] Expected shortcut '%s' item on node '%s'." % [ shortcut_name, base_node.get_class() ])

	return false


# Theme utilities.

static func node_get_editor_icon(base_node: Node, strict: bool = false) -> String:
	var node_icon: Texture2D = null
	if base_node is Button:
		node_icon = base_node.icon

	if not node_icon:
		if strict:
			push_warning("[EIA] Node '%s' doesn't have an icon or not supported." % [ base_node.get_class() ])
		return ""

	var editor_theme := EditorInterface.get_editor_theme()
	for icon_name in _editor_icon_list:
		var editor_icon := editor_theme.get_icon(icon_name, "EditorIcons")
		if editor_icon == node_icon:
			return icon_name

	return ""


static func node_has_editor_icon(base_node: Node, icon_name: String, strict: bool = false) -> bool:
	var node_icon: Texture2D = null
	if base_node is Button:
		node_icon = base_node.icon

	if not node_icon:
		if strict:
			push_warning("[EIA] Node '%s' doesn't have an icon or not supported." % [ base_node.get_class() ])
		return false

	var editor_theme := EditorInterface.get_editor_theme()
	if not editor_theme.has_icon(icon_name, "EditorIcons"):
		if strict:
			push_warning("[EIA] Icon '%s' not present in the editor theme." % [ icon_name ])
		return false

	var editor_icon := editor_theme.get_icon(icon_name, "EditorIcons")
	if node_icon != editor_icon:
		if strict:
			push_warning("[EIA] Expected icon '%s' on node '%s'." % [ icon_name, base_node.get_class() ])
		return false

	return true


# Multi-window utilities.

static func dock_get_locations() -> Array[Node]:
	var dock_locations: Array[Node] = []

	# First, collect static containers with docks.

	var static_points: Array[Enums.NodePoint] = [
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
	for node_point in static_points:
		var resolved_node := Resolver.get_node_cached(node_point)
		if resolved_node:
			dock_locations.push_back(resolved_node)

	# Then, check dynamic ones. Dynamic places are windows when
	# the dock is made floating. These exist in WindowWrapper nodes
	# at the root of layout base. They always have a margin container
	# (after mandatory nodes), and within is the dock.

	var layout_base := Resolver.get_node_cached(Enums.NodePoint.LAYOUT_ROOT)
	if layout_base:
		var wrappers := layout_base.find_children("", "WindowWrapper", false, false)
		for wrapper: Control in wrappers:
			var window := wrapper.get_child(0)
			if window.get_child_count() != 3:
				continue # Must be exactly 3 children (2 mandatory + 1 for margin)

			var floating_container := window.get_child(2)
			if floating_container is not MarginContainer:
				continue

			dock_locations.push_back(floating_container)

	return dock_locations
