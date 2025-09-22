## Displays and controls dimmers.
## Can dim areas of the editor and block mouse clicks, or allow mouse clicks within a restricted area.
extends Node

signal cleaned_up

const Highlight := preload("highlight/highlight.gd")
const Dimmer := preload("dimmer/dimmer.gd")
const EditorInterfaceAccess := preload("../editor_interface_access.gd")
const Utils := preload("../utils.gd")

const HighlightPackedScene := preload("highlight/highlight.tscn")
const DimmerPackedScene := preload("dimmer/dimmer.tscn")

## Used to grow the [TreeItem] rectangle to calculate overlaps for highlights.
const RECT_GROW := 5

var interface: EditorInterfaceAccess = null
var dimmers: Array[Dimmer] = []

# We duplicate and scale the highlight stylebox so the outline scales with the editor scale.
# Duplicating here allows us to pass the style to each created highlight.
var _highlight_style_scaled: StyleBoxFlat = null


func _init(interface: EditorInterfaceAccess) -> void:
	self.interface = interface

	# Scale highlight stylebox based on editor scale.
	# TODO: use theme utils instead.
	_highlight_style_scaled = load("res://addons/godot_tours/overlays/highlight/highlight.tres").duplicate(true)

	var editor_scale := EditorInterface.get_editor_scale()
	_highlight_style_scaled.border_width_bottom *= editor_scale
	_highlight_style_scaled.border_width_left *= editor_scale
	_highlight_style_scaled.border_width_right *= editor_scale
	_highlight_style_scaled.border_width_top *= editor_scale

	_highlight_style_scaled.corner_radius_bottom_left *= editor_scale
	_highlight_style_scaled.corner_radius_bottom_right *= editor_scale
	_highlight_style_scaled.corner_radius_top_left *= editor_scale
	_highlight_style_scaled.corner_radius_top_right *= editor_scale

	_highlight_style_scaled.expand_margin_left *= editor_scale
	_highlight_style_scaled.expand_margin_right *= editor_scale
	_highlight_style_scaled.expand_margin_top *= editor_scale
	_highlight_style_scaled.expand_margin_bottom *= editor_scale


func _process(_delta: float) -> void:
	for dimmer: Dimmer in dimmers:
		dimmer.film_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		for node: Node in dimmer.get_children():
			if node is Highlight and node.get_global_rect().has_point(dimmer.get_global_mouse_position()):
				dimmer.film_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Highlights a control, allowing the end user to interact with it using the mouse, and carving into the dimmers.
func add_highlight_to_control(control: Control, rect_getter := Callable(), play_flash := false, do_grow := false) -> void:
	var dimmer := ensure_get_dimmer_for(control)

	# Calculate overlapping highlights to avoid stacking highlights and outlines.
	var overlaps := []
	if rect_getter.is_null():
		if interface.inspector_editor.is_ancestor_of(control):
			rect_getter = func() -> Rect2: return control.get_global_rect().intersection(interface.inspector_editor.get_global_rect())
		else:
			rect_getter = control.get_global_rect

	var editor_scale := EditorInterface.get_editor_scale()
	var rect := rect_getter.call()
	for child in dimmer.get_children():
		if child is Highlight:
			child.refresh()
			var child_rect := Rect2(child.global_position, child.custom_minimum_size)
			if (rect.grow(RECT_GROW * editor_scale) if do_grow else rect).intersects(child_rect):
				overlaps.push_back(child)

	var highlight := HighlightPackedScene.instantiate()
	dimmer.add_child(highlight)
	if play_flash:
		highlight.flash()

	highlight.setup(rect_getter, dimmer, _highlight_style_scaled)
	highlight.controls.push_back(control)
	if overlaps.is_empty() and control is TabBar:
		control.tab_changed.connect(highlight.refresh_tabs)
	elif not overlaps.is_empty():
		for other_highlight: Highlight in overlaps:
			highlight.controls.append_array(other_highlight.controls)
			highlight.rect_getters.append_array(other_highlight.rect_getters)
			other_highlight.queue_free()


## Removes all dimmers and consequently highlights from the editor.
func clean_up() -> void:
	for dimmer: Dimmer in dimmers:
		dimmer.queue_free()
	dimmers = []
	cleaned_up.emit()


## Toggle dimmers visibility on/off.
func toggle_dimmers(is_on: bool) -> void:
	for dimmer: Dimmer in dimmers:
		dimmer.visible = is_on


## Get the dimmer associated with a [Control]. There is only one dimmer per [Viewport] so the dimmer is really
## associated with the Control's Viewport. If there is no such dimmer, create one on the fly and return it.
func ensure_get_dimmer_for(control: Control) -> Dimmer:
	var window := control.get_window()
	var result: Dimmer = window.get_node_or_null("Dimmer")

	# Ensure that when we create a new Dimmer, the name Dimmer won't be taken.
	if result != null and result.is_queued_for_deletion():
		result.name = "Deleted"

	if result == null or result.is_queued_for_deletion():
		result = DimmerPackedScene.instantiate()
		window.add_child(result)
		dimmers.push_back(result)
	return result


## Highlight [TreeItem]s from the given [code]tree[/code] that match the [code]predicate[/code]. The highlight can
## also play a flash animation if [code]play_flash[/code] is [code]true[/code]. [code]button_index[/code] specifies
## which button to highlight from the [TreeItem] instead of the whole item.
func highlight_tree_items(tree: Tree, predicate: Callable, button_index := -1, do_center := true, play_flash := false) -> void:
	var root := tree.get_root()
	if root == null:
		return

	var height_fix := 6 * EditorInterface.get_editor_scale()
	for item in Utils.filter_tree_items(root, predicate):
		interface.unfold_tree_item(item)
		tree.scroll_to_item(item, do_center)

		var item_path := Utils.get_tree_item_path(item)
		var rect_getter := func() -> Rect2:
			for the_item in Utils.filter_tree_items(
				tree.get_root(),
				func(ti: TreeItem) -> bool: return item_path == Utils.get_tree_item_path(ti),
			):
				var rect := tree.get_global_transform() * tree.get_item_area_rect(the_item, 0, button_index)
				# TODO: following line mithgt not be necessary in Godot 4.4
				# rect.position.y += height_fix - tree.get_scroll().y
				return rect.intersection(tree.get_global_rect())
			return Rect2()
		add_highlight_to_control.call_deferred(tree, rect_getter, play_flash, true)


## Highlights multiple Scene dock [TreeItem]s by [code]names[/code]. See [method highlight_tree_items]
## for details on the other parameters.
func highlight_scene_nodes_by_name(names: Array[String], button_index := -1, do_center := true, play_flash := false) -> void:
	highlight_tree_items(
		interface.scene_tree,
		func(item: TreeItem) -> bool: return item.get_text(0) in names,
		button_index,
		do_center,
		play_flash,
	)


## Highlights multiple Scene dock [TreeItem]s by [code]paths[/code]. See [method highlight_tree_items]
## for details on the other parameters.
func highlight_scene_nodes_by_path(paths: Array[String], button_index := -1, do_center := true, play_flash := false) -> void:
	highlight_tree_items(
		interface.scene_tree,
		func(item: TreeItem) -> bool: return Utils.get_tree_item_path(item) in paths,
		button_index,
		do_center,
		play_flash,
	)


## Highlights FileSystem dock [TreeItem]s by [code]paths[/code]. See [method highlight_tree_items]
## for [code]play_flash[/code].
func highlight_filesystem_paths(paths: Array[String], do_center := true, play_flash := false) -> void:
	highlight_tree_items(
		interface.filesystem_tree,
		func(item: TreeItem) -> bool: return Utils.get_tree_item_path(item) in paths,
		-1,
		do_center,
		play_flash,
	)


## Expands a resource property in the Inspector dock by finding it by [code]name[/code].
## This is useful when you need to access sub-properties of a resource that are hidden
## when the resource is collapsed in the inspector. Call this method with the
## [code]name[/code] of the resource property you want to expand first, then call
## [method highlight_inspector_properties] to highlight the expanded property.
func expand_inspector_resource(resource_property_name: StringName) -> void:
	var all_properties := interface.inspector_editor.find_children("", "EditorProperty", true, false)
	var predicate_name_matches := func predicate_name_matches(p: EditorProperty) -> bool:
		return p.get_edited_property() == resource_property_name

	var matching_index := all_properties.find_custom(predicate_name_matches)
	if matching_index < 0:
		push_warning(
			"expand_inspector_resource: Could not find resource property with name '%s' in Inspector. The property could not be expanded." % resource_property_name
		)
		return
	var matching_property: EditorProperty = all_properties[matching_index]
	if matching_property.get_class() == "EditorPropertyResource":
		# Find the EditorResourcePicker child
		for child in matching_property.get_children():
			if child is not EditorResourcePicker or child.edited_resource == null:
				continue

			# Find the button that expands/collapses the resource
			for resource_child in child.get_children():
				if resource_child is not Button:
					continue
				if resource_child.button_pressed:
					# If the button is already pressed, we assume the resource
					# is expanded and we don't need to do anything
					return
				resource_child.button_pressed = true
				resource_child.pressed.emit()
				return


## Highlights Inspector dock properties by (programmatic) [code]name[/code]. See
## [method highlight_tree_items] for [code]play_flash[/code].
##
## [b]Warning:[/b] This does not support properties that are now inspector sections
## (properties with checkboxes). For those, use [method highlight_inspector_section_property].
func highlight_inspector_property(name: StringName, do_center := true, play_flash := false) -> void:
	var scroll_offset := 200 * EditorInterface.get_editor_scale()
	var all_properties := interface.inspector_editor.find_children("", "EditorProperty", true, false)

	var predicate_name_matches := func predicate_name_matches(p: EditorProperty) -> bool:
		return p.get_edited_property() == name

	var matching_index := all_properties.find_custom(predicate_name_matches)
	if matching_index < 0:
		return

	var matching_property: EditorProperty = all_properties[matching_index]
	# Unfold parent sections recursively if necessary.
	var current_parent := matching_property.get_parent()
	const MAX_ITERATION_COUNT := 10
	for i in MAX_ITERATION_COUNT:
		var parent_class := current_parent.get_class()
		if parent_class == "EditorInspectorSection":
			current_parent.unfold()

		current_parent = current_parent.get_parent()
		if current_parent == interface.inspector_editor:
			break

	if do_center:
		interface.inspector_editor.scroll_vertical += (
			matching_property.global_position.y + scroll_offset
			- interface.inspector_editor.global_position.y
			- interface.inspector_editor.size.y / 2.0
		)
	else:
		interface.inspector_editor.ensure_control_visible(matching_property)

	var dimmer := ensure_get_dimmer_for(interface.inspector_dock)
	# We need to find the property again in case the inspector changed (e.g. the
	# user selected another node or deselected the node).
	# TODO: this could be perhaps cached in the future. For now, we want to
	# ensure we always highlight the right property and re-run this frequently.
	var rect_getter := func inspector_property_rect_getter() -> Rect2:
		all_properties = interface.inspector_editor.find_children("", "EditorProperty", true, false)
		var matching_property_index := all_properties.find_custom(predicate_name_matches)
		if matching_property_index < 0:
			return Rect2()
		var editor_property: EditorProperty = all_properties[matching_index]
		if editor_property.is_visible_in_tree():
			var rect := editor_property.get_global_rect()
			rect.position.x = interface.inspector_editor.global_position.x
			rect.size.x = interface.inspector_editor.size.x
			return rect.intersection(interface.inspector_editor.get_global_rect())
		return Rect2()

	add_highlight_to_control.call_deferred(interface.inspector_editor, rect_getter, play_flash, true)


## Highlights Inspector dock sections by the [code]first_property_name[/code] of
## the section's first child property.
##
## This is useful for highlighting inspector sections that contain multiple
## related properties. See [method highlight_tree_items] for
## [code]play_flash[/code].
func highlight_inspector_section_property(first_property_name: StringName, do_center := true, play_flash := false) -> void:
	var scroll_offset := 200 * EditorInterface.get_editor_scale()
	var matching_section := _find_inspector_section_by_first_property(first_property_name)

	if matching_section == null:
		push_warning("highlight_inspector_section_property: Could not find inspector section with first property name '%s' in Inspector." % first_property_name)
		return

	if do_center:
		interface.inspector_editor.scroll_vertical += ( matching_section.global_position.y + scroll_offset - interface.inspector_editor.global_position.y - interface.inspector_editor.size.y / 2.0 )
	else:
		interface.inspector_editor.ensure_control_visible(matching_section)

	var dimmer := ensure_get_dimmer_for(interface.inspector_dock)
	# We need to find the property again in case the inspector changed (e.g. the
	# user selected another node or deselected the node).
	# TODO: this could be perhaps cached in the future. For now, we want to
	# ensure we always highlight the right property and re-run this frequently.
	var rect_getter := func inspector_section_rect_getter() -> Rect2:
		var section := _find_inspector_section_by_first_property(first_property_name)
		if section == null:
			return Rect2()

		if section.is_visible_in_tree():
			var rect: Rect2 = section.get_global_rect()
			rect.position.x = interface.inspector_editor.global_position.x
			rect.size.x = interface.inspector_editor.size.x
			return rect.intersection(interface.inspector_editor.get_global_rect())
		return Rect2()

	add_highlight_to_control.call_deferred(interface.inspector_editor, rect_getter, play_flash, true)


## Highlights Node > Signals dock [TreeItem]s by [code]signal_names[/code]. See [method highlight_tree_items]
## for details on the other parameters.
func highlight_signals(signal_names: Array[String], do_center := true, play_flash := false) -> void:
	highlight_tree_items(
		interface.node_dock_signals_tree,
		func(item: TreeItem) -> bool:
			var predicate := func(sn: String) -> bool: return item.get_text(0).begins_with(sn)
			return signal_names.any(predicate),
		-1,
		do_center,
		play_flash,
	)


## Higlights code lines in the current [ScriptEditor] in the range from [code]start[/code] to [code]end[/code].
## [code]end[/code] is optional in which case only the [code]start[/code] line gets highlighted.
## [code]do_center[/code] forces the [ScriptEditor] to center veritcally on the given
## [code]start[/code]-[code]end[/code] line range. See [method highlight_tree_items] for [code]play_flash[/code].
func highlight_code(start: int, end := 0, caret := 0, do_center := true, play_flash := false) -> void:
	start -= 1
	end = start if end < 1 else (end - 1)
	if caret == 0:
		caret = end
	var script_editor := interface.script_editor
	var code_editor: CodeEdit = script_editor.get_current_editor().get_base_editor()
	if start < 0 or end > code_editor.get_line_count() or start > end:
		return

	script_editor.goto_line(start)
	code_editor.grab_focus()
	if do_center:
		code_editor.set_line_as_center_visible((start + end) / 2)
	code_editor.scroll_horizontal = 0
	code_editor.set_caret_line.call_deferred(caret)
	code_editor.set_caret_column.call_deferred(code_editor.get_line(caret).length())
	var dimmer := ensure_get_dimmer_for(interface.script_editor_code_panel)
	var rect_getter := func() -> Rect2:
		var rect_start := code_editor.get_rect_at_line_column(start, 0)
		var rect_end := code_editor.get_rect_at_line_column(end, 0)
		var rect := Rect2()
		if rect_start.position != -Vector2i.ONE and rect_end.position != -Vector2i.ONE:
			rect = code_editor.get_global_transform() * Rect2(rect_start.merge(rect_end))
			rect.position.x = code_editor.global_position.x
			rect.size.x = code_editor.size.x
		return rect
	add_highlight_to_control.call_deferred(code_editor, rect_getter, play_flash)


## Highlights arbitrary [code]controls[/code]. See [method highlight_tree_items] for [code]play_flash[/code].
func highlight_controls(controls: Array[Control], play_flash := false) -> void:
	for control in controls:
		if control == null:
			continue
		add_highlight_to_control(control, Callable(), play_flash)


## Highlights either the whole [code]tabs[/code] [TabBar] if [code]index == -1[/code] or the given [TabContainer] tab
## by [code]index[/code].
func highlight_tab_index(tabs: Control, index := -1, play_flash := true) -> void:
	var tab_bar: TabBar = Utils.find_child_by_type(tabs, "TabBar") if tabs is TabContainer else tabs
	var dimmer := ensure_get_dimmer_for(tab_bar)
	if dimmer == null or tab_bar == null or index < -1 or index >= tab_bar.tab_count:
		return

	var rect_getter := func() -> Rect2:
		return tab_bar.get_global_rect() if index == -1 else tab_bar.get_global_transform() * tab_bar.get_tab_rect(index)
	add_highlight_to_control(tabs, rect_getter, play_flash)


## Highlights a [TabContainer] tab for the given [code]tabs[/code] [TabBar] by its [code]title[/code].
func highlight_tab_title(tabs: Control, title: String, play_flash := true) -> void:
	if not (tabs is TabContainer or tabs is TabBar):
		return

	for index in range(tabs.get_tab_count()):
		var tab_title: String = tabs.get_tab_title(index)
		if title == tab_title or tabs == interface.main_screen_tabs and "%s(*)" % title == tab_title:
			highlight_tab_index(tabs, index, play_flash)


## Highlights a [Itemlist] in the TileMap dock, such as a tile or a terrain's drawing mode or terrain
## tile.
func highlight_tilemap_list_item(item_list: ItemList, item_index: int, play_flash := true) -> void:
	if item_list == null or item_index < 0 or item_index >= item_list.item_count:
		return

	var dimmer := ensure_get_dimmer_for(interface.tilemap)
	var rect_getter := func() -> Rect2:
		var rect := item_list.get_item_rect(item_index)
		rect.position += item_list.global_position
		return rect
	add_highlight_to_control(interface.tilemap, rect_getter, play_flash)


## Inspector: Finds and returns an EditorProperty by name
func _find_editor_property_by_name(property_name: StringName) -> EditorProperty:
	var all_properties := interface.inspector_editor.find_children("", "EditorProperty", true, false)
	var predicate_name_matches := func predicate_name_matches(p: EditorProperty) -> bool:
		return p.get_edited_property() == property_name

	var matching_index := all_properties.find_custom(predicate_name_matches)
	if matching_index < 0:
		return null
	return all_properties[matching_index]


## Inspector: finds a section by its first child EditorProperty name. Use this
## for the new properties in Godot 4.5 that are wrapped into inspector sections
## (the type and its methods are not exposed to the API so we need this workaround)
func _find_inspector_section_by_first_property(first_property_name: StringName) -> Control:
	var all_property_children := interface.inspector_editor.get_child(0).get_child(2).get_children()

	for child in all_property_children:
		if child.get_class() != "EditorInspectorSection":
			continue

		# Check if this container has a VBoxContainer child (if so it's likely
		# an inspector section representing a property)
		var vbox_container: VBoxContainer = null
		for grandchild in child.get_children():
			if grandchild is VBoxContainer:
				vbox_container = grandchild
				break

		if vbox_container == null:
			continue

		# Check if the first EditorProperty in the VBoxContainer matches our target
		for property_child in vbox_container.get_children():
			if property_child is EditorProperty:
				if property_child.get_edited_property() == first_property_name:
					return child

	return null
