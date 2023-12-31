## Displays and controls dimmers.
## Can dim areas of the editor and block mouse clicks, or allow mouse clicks within a restricted area.
## Dimmers and dimmers start hidden by default. See toggle_dimmers() to make
## them visible.
extends Node

const Highlight := preload("highlight/highlight.gd")
const Dimmer := preload("dimmer/dimmer.gd")
const EditorInterfaceAccess := preload("../editor_interface_access.gd")
const Utils := preload("../utils.gd")

const HighlightPackedScene := preload("highlight/highlight.tscn")
const DimmerPackedScene := preload("dimmer/dimmer.tscn")

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
	_highlight_style_scaled = load("res://addons/godot_tours/core/overlays/highlight/highlight.tres").duplicate(true)

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
func add_highlight_to_control(control: Control, rect_getter := Callable(), play_flash := false) -> void:
	var dimmer := ensure_get_dimmer_for(control)

	# Calculate overlapping highlights to avoid stacking highlights and outlines.
	var overlaps := []
	if rect_getter.is_null():
		rect_getter = control.get_global_rect

	var rect := rect_getter.call()
	for child in dimmer.get_children():
		if child is Highlight:
			child.refresh()
			var child_rect := Rect2(child.global_position, child.custom_minimum_size)
			if rect.grow(RECT_GROW).intersects(child_rect):
				overlaps.push_back(child)

	var highlight := HighlightPackedScene.instantiate()
	dimmer.add_child(highlight)
	if play_flash:
		highlight.flash()

	highlight.setup(control, rect_getter, dimmer, _highlight_style_scaled)
	if overlaps.is_empty() and control is TabBar:
		control.tab_changed.connect(highlight.refresh_tabs)
	elif not overlaps.is_empty():
		for other_highlight: Highlight in overlaps:
			highlight.rect_getters.append_array(other_highlight.rect_getters)
			other_highlight.queue_free()
	control.draw.connect(highlight.refresh)
	control.visibility_changed.connect(highlight.refresh)


func clean_up() -> void:
	for dimmer: Dimmer in dimmers:
		dimmer.free()
	dimmers = []


func toggle_dimmers(is_on: bool) -> void:
	for dimmer: Dimmer in dimmers:
		dimmer.visible = is_on


func ensure_get_dimmer_for(control: Control) -> Dimmer:
	var viewport := control.get_viewport()
	var result: Dimmer = viewport.get_node_or_null("Dimmer")
	if result == null:
		result = DimmerPackedScene.instantiate()
		viewport.add_child(result)
		dimmers.push_back(result)
	return result


func highlight_tree_items(tree: Tree, predicate: Callable, play_flash := false, button_index := -1) -> void:
	var root := tree.get_root()
	if root == null:
		return

	for item in Utils.filter_tree_items(root, predicate):
		interface.unfold_tree_item(item)
		tree.scroll_to_item(item)

		var item_path := Utils.get_tree_item_path(item)
		var rect_getter := func() -> Rect2:
			const height_fix := 6
			for the_item in Utils.filter_tree_items(
				tree.get_root(),
				func(ti: TreeItem) -> bool: return item_path == Utils.get_tree_item_path(ti),
			):
				var rect := tree.get_global_transform() * tree.get_item_area_rect(the_item, 0, button_index)
				rect.position.y += height_fix - tree.get_scroll().y
				return rect.intersection(tree.get_global_rect())
			return Rect2()
		add_highlight_to_control.call_deferred(tree, rect_getter, play_flash)


func highlight_scene_node_by_name(n: String, play_flash := false, button_index := -1) -> void:
	highlight_tree_items(
		interface.scene_tree,
		func(item: TreeItem) -> bool: return n == item.get_text(0),
		play_flash,
		button_index,
	)


func highlight_scene_nodes_by_name(names: Array[String], play_flash := false, button_index := -1) -> void:
	for n in names:
		highlight_scene_node_by_name(n, play_flash, button_index)


func highlight_scene_node_by_path(path: String, play_flash := false, button_index := -1) -> void:
	highlight_tree_items(
		interface.scene_tree,
		func(item: TreeItem) -> bool: return path == Utils.get_tree_item_path(item),
		play_flash,
		button_index,
	)


func highlight_scene_nodes_by_path(paths: Array[String], play_flash := false, button_index := -1) -> void:
	for path in paths:
		highlight_scene_node_by_path(path, play_flash, button_index)


func highlight_filesystem_paths(paths: Array[String], play_flash := false) -> void:
	for path in paths:
		if path.is_empty():
			return
		highlight_tree_items(
			interface.filesystem_tree,
			func(item: TreeItem) -> bool: return path == Utils.get_tree_item_path(item),
			play_flash,
		)


func highlight_inspector_properties(names: Array[StringName], play_flash := false) -> void:
	for name in names:
		var property: EditorProperty = Utils.find_child(
			interface.inspector_editor,
			"EditorProperty",
			"",
			func(ep: EditorProperty) -> bool: return ep.get_edited_property() == name,
		)
		if property != null:
			# Unfold parent sections recursively if necessary.
			var current_parent: Node = property.get_parent()
			var last_section = null
			const MAX_ITERATION_COUNT := 10
			for i in MAX_ITERATION_COUNT:
				if current_parent.get_class() == "EditorInspectorSection":
					current_parent.unfold()
				current_parent = current_parent.get_parent()
				if current_parent == interface.inspector_editor:
					break

			if last_section:
				await last_section.draw

			interface.inspector_editor.ensure_control_visible(property)
			var dimmer := ensure_get_dimmer_for(interface.inspector_dock)
			var rect_getter := func() -> Rect2:
				var rect := property.get_global_rect()
				rect.position.x = interface.inspector_editor.global_position.x
				rect.size.x = interface.inspector_editor.size.x
				return rect
			add_highlight_to_control.call_deferred(interface.inspector_editor, rect_getter, play_flash)


func highlight_signals(signal_names: Array[String], play_flash := false) -> void:
	for signal_name in signal_names:
		if signal_name.is_empty():
			continue

		highlight_tree_items(
			interface.node_dock_signals_tree,
			func(item: TreeItem) -> bool: return item.get_text(0).begins_with(signal_name),
			play_flash,
		)


# TODO: add flash if play_flash is true.
func highlight_code(start: int, end := 0, caret := 0, play_flash := false, do_center := true) -> void:
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
	add_highlight_to_control.call_deferred(code_editor, rect_getter)


func highlight_controls(controls: Array[Control], play_flash := false) -> void:
	for control in controls:
		if control == null:
			continue
		add_highlight_to_control(control, control.get_global_rect, play_flash)


func highlight_tab_index(tabs: Control, index := -1) -> void:
	var tab_bar: TabBar = Utils.find_child(tabs, "TabBar") if tabs is TabContainer else tabs
	var dimmer := ensure_get_dimmer_for(tab_bar)
	if dimmer == null or tab_bar == null or index < -1 or index >= tab_bar.tab_count:
		return

	var rect_getter := func() -> Rect2:
		return tab_bar.get_global_rect() if index == -1 else tab_bar.get_global_transform() * tab_bar.get_tab_rect(index)
	add_highlight_to_control(tabs, rect_getter)


func highlight_tab_title(tabs: Control, title: String) -> void:
	if not (tabs is TabContainer or tabs is TabBar):
		return

	for index in range(tabs.get_tab_count()):
		var tab_title: String = tabs.get_tab_title(index)
		if title == tab_title or tabs == interface.main_screen_tabs and "%s(*)" % title == tab_title:
			highlight_tab_index(tabs, index)


## Highlights a ListItem in the TileMap dock, such as a tile or a terrain's drawing mode or terrain
## tile.
func highlight_tilemap_list_item(item_list: ItemList, item_index: int) -> void:
	if item_list == null or item_index < 0 or item_index >= item_list.item_count:
		return

	var dimmer := ensure_get_dimmer_for(interface.tilemap)
	var rect_getter := func() -> Rect2:
			var rect := item_list.get_item_rect(item_index)
			rect.position += item_list.global_position
			return rect
	add_highlight_to_control(interface.tilemap, rect_getter)
