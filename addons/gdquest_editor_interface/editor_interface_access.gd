## Editor interface access is a system for serializing, referencing, and
## retrieving editor GUI elements with persistent identifiers.
@tool

const Enums := preload("./utils/eia_enums.gd")
const Resolver := preload("./utils/eia_resolver.gd")


# Node access.

## Resolves and returns a node in the editor tree associated with the given
## node point value. Returns [code]null[/code] if the node, or one of its
## pre-requisites, cannot be resolved.
##
## Resolved node is cached for future calls, unless the [param skip_cache]
## flag is set.
static func get_node(node_point: Enums.NodePoint, skip_cache: bool = false) -> Node:
	return Resolver.resolve_node(node_point, null, skip_cache)


## Resolves and returns a node in the editor tree associated with the given
## node point value, relative to the given base node. Returns [code]null[/code]
## if the node, or one of its pre-requisites, cannot be resolved.
##
## Resolved node is cached for future calls, in association with the given
## base node, unless the [param skip_cache] flag is set.
static func get_node_relative(base_node: Node, node_point: Enums.NodePoint, skip_cache: bool = false) -> Node:
	return Resolver.resolve_node(node_point, base_node, skip_cache)


# Helpers.

## Returns one of the 3D viewports from the 3D editor.
##
## [b]Note:[/b] The index does not necessarily correspond to the order in
## which viewports are made visible. I.e. the viewport at index [code]1[/code]
## does not necessarily become visible in the 2-viewport split mode.
##
## These viewports also do not contain the edited scene. Instead, you can use
## [method EditorInterface.get_edited_scene_root] and go up from there. You'll
## end up in the viewport of the [CanvasItemEditor].
static func get_node_3d_viewport(viewport_index: int) -> Control:
	var viewports_container := get_node(Enums.NodePoint.NODE_3D_EDITOR_VIEWPORTS)
	var viewports := viewports_container.find_children("", "Node3DEditorViewport", false, false)

	if viewport_index < 0 || viewport_index >= viewports.size():
		return null

	return viewports[viewport_index]


## Returns [code]true[/code] if the script editor is currently in focus, whether
## it is embedded or floating.
static func is_script_editor_active() -> bool:
	var script_editor := get_node(Enums.NodePoint.SCRIPT_EDITOR)
	if not script_editor:
		return false # Should never happen.

	var script_window := script_editor.get_window()

	# The editor is embedded in the main window, just check if the script
	# editor is visible.
	if script_window == script_editor.get_tree().root:
		return script_editor.is_visible_in_tree()

	# The editor is floating, has its own window. Check if it's focused.
	if script_window == Window.get_focused_window():
		return true

	return false


## Returns one of the script editor tabs, which can be a [TextEditor], a
## [ScriptTextEditor], or an [EditorHelp] page.
static func get_script_editor_tab(tab_index: int) -> Control:
	# NOTE: Script editor tabs at first exist in an "uninstantiated" mode,
	# until the user clicks on it and the actual contents are spawned. It's
	# probably a performance/memory saving measure, but that means we cannot
	# be sure internal elements exist.

	var script_tabs: TabContainer = get_node(Enums.NodePoint.SCRIPT_EDITOR_CONTAINER_TABS)
	if tab_index < 0 || tab_index >= script_tabs.get_tab_count():
		return null

	return script_tabs.get_tab_control(tab_index)


## Returns the [TabBar] control of the container currently holding the
## given dock. Returns [code]null[/code] if the dock is currently hidden.
##
## [b]Note:[/b] As of Godot 4.6, even hidden docks are present inside of
## the editor node tree, in a special, invisible node.
static func get_dock_tabs(dock_node: EditorDock) -> TabBar:
	if not dock_node:
		return null

	var dock_owner := dock_node.get_parent()
	if not dock_owner || not ClassDB.is_parent_class(dock_owner.get_class(), "TabContainer"):
		return null

	return (dock_owner as TabContainer).get_tab_bar()


## Returns the tab index for the given dock in the container that currently
## holds it. Returns [code]-1[/code] if the dock is currently hidden.
## See also [method get_dock_tabs].
static func get_dock_tab_index(dock_node: EditorDock) -> int:
	if not dock_node:
		return -1

	var dock_owner := dock_node.get_parent()
	if not dock_owner || not ClassDB.is_parent_class(dock_owner.get_class(), "TabContainer"):
		return -1

	return (dock_owner as TabContainer).get_tab_idx_from_control(dock_node)


## Finds the [EditorProperty] node for the given property name. Returns
## [code]null[/code] if it cannot be found.
##
## [b]Note:[/b] When trying to access properties inside of a sub-inspector,
## make sure it is expanded. Properties inside of collapsed sections
## are always accessible. For properties merged with section headers, use
## [method find_inspector_section_by_first_property] instead.
static func find_inspector_property_by_name(inspector_node: EditorInspector, property_name: StringName) -> EditorProperty:
	# TODO: This is a brute force approach, so it's far from optimal. It would've been nice
	# if editor provided utilities to get the widget associated with the given property name.
	var all_properties := inspector_node.find_children("", "EditorProperty", true, false)
	var matching_index := all_properties.find_custom(func(prop: EditorProperty) -> bool:
		return prop.get_edited_property() == property_name
	)

	if matching_index < 0:
		return null
	return all_properties[matching_index]


## Finds an inspector section for the given property name of the first child
## [EditorProperty]. Returns [code]null[/code] if it cannot be found.
##
## [b]Note:[/b] When trying to access properties inside of a sub-inspector,
## make sure it is expanded. For regular properties use [method find_inspector_property_by_name].
## [b]Note:[/b] When the first property is pinned as favorite, this method
## returns the copy of this section inside of the favorites area.
static func find_inspector_section_by_first_property(inspector_node: EditorInspector, first_property_name: StringName) -> Control:
	# TODO: This is a brute force approach, so it's far from optimal. It would've been nice
	# if editor provided utilities to get the widget associated with the given property name.
	# On top of that, sections specifically have limited API compared to EditorProperty
	# (not to mention, EditorInspectorSection is not exposed), which is why we have to rely
	# on the first property.
	var all_sections := inspector_node.find_children("", "EditorInspectorSection", true, false)
	var matching_index := all_sections.find_custom(func(node: Node) -> bool:
		var property_box: VBoxContainer = node.call("get_vbox") # The class is hidden from the API, but method exists.
		if not property_box || property_box.get_child_count() == 0:
			return false

		var first_property: EditorProperty = property_box.get_child(0)
		if not first_property:
			return false

		return first_property.get_edited_property() == first_property_name
	)

	if matching_index < 0:
		return null
	return all_sections[matching_index]


# Testing.

## Runs resolution for every known node point and reports success status.
## Uses cache by default, which is necessary for some custom resolver
## steps. This means that sometimes errors for one node can appear in logs
## for another due to dependencies.
static func test_resolve(skip_cache: bool = false) -> void:
	print("[EIA] Running resolve test...")
	print("========================================")

	var total_count := Enums.NodePoint.size()
	var valid_count := 0
	var skipped_count := 0

	var last_node_point := -1
	var last_total_count := 0
	var last_valid_count := 0
	var last_skipped_count := 0

	for key: String in Enums.NodePoint:
		var node_point: int = Enums.NodePoint[key]
		if last_node_point != -1 && (last_node_point + 1) != node_point:
			print("")
			print_rich("\tin section resolved successfully: [b]%d / %d[/b]" % [ last_valid_count, last_total_count - last_skipped_count ])
			print_rich("\t                   excl. skipped: [b]%d[/b]" % [ last_skipped_count ])
			print("----------------------------------------")

			last_total_count = 0
			last_valid_count = 0
			last_skipped_count = 0

		last_node_point = node_point
		last_total_count += 1

		print("\t%s:" % [ key ])

		if Resolver.is_node_relative(node_point): # Reusable nodes cannot be tested without context.
			if _test_resolve_relative(node_point, skip_cache):
				valid_count += 1
				last_valid_count += 1
				print_rich("\t\t[b]OK[/b]")
			else:
				skipped_count += 1
				last_skipped_count += 1
				print_rich("\t\t[i]SKIPPED[/i] (reusable)")

			continue # Continue regardless.

		if Resolver.resolve_node(node_point, null, skip_cache):
			valid_count += 1
			last_valid_count += 1
			print_rich("\t\t[b]OK[/b]")

	print("")
	print_rich("\tin section resolved successfully: [b]%d / %d[/b]" % [ last_valid_count, last_total_count - last_skipped_count ])
	print_rich("\t                   excl. skipped: [b]%d[/b]" % [ last_skipped_count ])

	print("========================================")
	print_rich("[EIA] Resolved successfully: [b]%d / %d[/b]" % [ valid_count, total_count - skipped_count ])
	print_rich("              excl. skipped: [b]%d[/b]" % [ skipped_count ])


static func _test_resolve_relative(node_point: Enums.NodePoint, skip_cache: bool) -> Node:
	# Reusable nodes need some context point to test against. We
	# have to hardcode logic for each group to supply these contexts.
	# The editor also needs to be in a certain state for all nodes
	# to resolve successfully.

	# These should be implemented in a reverse order, to simplify
	# the checks.

	#
	if node_point >= Enums.NodePoint.CREATE_OBJECT_DIALOG_PANELS:
		var scene_create_dialog := get_node(Enums.NodePoint.SCENE_DOCK_CREATE_DIALOG, true) # Don't write to cache here.
		return get_node_relative(scene_create_dialog, node_point, skip_cache)

	#
	if node_point >= Enums.NodePoint.EDITOR_ZOOM_WIDGET_ZOOM_OUT_BUTTON:
		var zoom_widget := get_node(Enums.NodePoint.TILE_MAP_TILES_ATLAS_VIEW_ZOOM_WIDGET, true) # Don't write to cache here.
		return get_node_relative(zoom_widget, node_point, skip_cache)

	# Can fail if there is no help page or it's not fully initialized yet
	# (must be opened by the user at least once).
	if node_point >= Enums.NodePoint.EDITOR_HELP_RICH_TEXT:
		var script_tabs: TabContainer = get_node(Enums.NodePoint.SCRIPT_EDITOR_CONTAINER_TABS, true) # Don't write to cache here.
		for tab_index in script_tabs.get_tab_count():
			var tab_control := script_tabs.get_tab_control(tab_index)
			if ClassDB.is_parent_class(tab_control.get_class(), "EditorHelp"):
				return get_node_relative(tab_control, node_point, skip_cache)

		push_error("[EIA] No 'EditorHelp' node present in the Script editor view.")
		return null

	# Can fail if there is no text editor or it's not fully initialized yet
	# (must be opened by the user at least once).
	if node_point >= Enums.NodePoint.TEXT_EDITOR_CODE_EDITOR:
		var script_tabs: TabContainer = get_node(Enums.NodePoint.SCRIPT_EDITOR_CONTAINER_TABS, true) # Don't write to cache here.
		for tab_index in script_tabs.get_tab_count():
			var tab_control := script_tabs.get_tab_control(tab_index)
			if ClassDB.is_parent_class(tab_control.get_class(), "TextEditor"):
				return get_node_relative(tab_control, node_point, skip_cache)

		push_error("[EIA] No 'TextEditor' node present in the Script editor view.")
		return null

	# Can fail if there is no code editor or it's not fully initialized yet
	# (must be opened by the user at least once).
	if node_point >= Enums.NodePoint.SCRIPT_TEXT_EDITOR_CODE_EDITOR:
		var script_tabs: TabContainer = get_node(Enums.NodePoint.SCRIPT_EDITOR_CONTAINER_TABS, true) # Don't write to cache here.
		for tab_index in script_tabs.get_tab_count():
			var tab_control := script_tabs.get_tab_control(tab_index)
			if ClassDB.is_parent_class(tab_control.get_class(), "ScriptTextEditor"):
				return get_node_relative(tab_control, node_point, skip_cache)

		push_error("[EIA] No 'ScriptTextEditor' node present in the Script editor view.")
		return null

	#
	if node_point >= Enums.NodePoint.NODE_3D_EDITOR_VIEWPORT_SCENE_ROOT:
		var viewports_container := get_node(Enums.NodePoint.NODE_3D_EDITOR_VIEWPORTS, true) # Don't write to cache here.
		var viewports := viewports_container.find_children("", "Node3DEditorViewport", false, false)
		if viewports.is_empty():
			return null

		return get_node_relative(viewports[0], node_point, skip_cache)

	var node_point_name := Enums.get_node_point_name(node_point)
	push_error("[EIA] Invalid relative node point '%s'." % [ node_point_name ])
	return null
