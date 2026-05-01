## Displays and controls dimmers and highlights.
## Allows to selectively direct focus to parts of the editor GUI and flash over points of interest.
## Defines a handful of low-level highlighters for built-in controls, as well as a number of bespoke
## highlighters for some editor elements.
extends Node

signal cleaned_up

const EditorInterfaceAccess := preload("res://addons/gdquest_editor_interface/editor_interface_access.gd")
const EditorNodePoints := EditorInterfaceAccess.Enums.NodePoint

const Dimmer := preload("dimmer/dimmer.gd")
const Utils := preload("../utils.gd")

const DimmerPackedScene := preload("dimmer/dimmer.tscn")

var _dimmer_map: Dictionary[Window, Dimmer] = {}
var _dimmer_highlights: Array[HighlightData] = []
var _dimmer_update_queued: bool = false


## Resets the state of the overlays.
func clean_up() -> void:
	_remove_all_dimmers()
	cleaned_up.emit()


# Highlights and dimmers management.

## Returns a dimmer associated with the [Window] node that owns the given [Control]. If the dimmer
## doesn't exist yet, creates it implicitly.
func ensure_control_window_dimmer(from_control: Control) -> Dimmer:
	var window := from_control.get_window()
	if not window:
		return null

	var dimmer: Dimmer = null
	if _dimmer_map.has(window):
		dimmer = _dimmer_map[window]

	if not is_instance_valid(dimmer):
		dimmer = DimmerPackedScene.instantiate()
		window.add_child(dimmer)
		_dimmer_map[window] = dimmer

	return dimmer


## Removes all known dimmers from their windows and frees the nodes.
func _remove_all_dimmers() -> void:
	for dimmer in _dimmer_map.values():
		if dimmer.get_parent():
			dimmer.get_parent().remove_child(dimmer)
		dimmer.queue_free()

	for data in _dimmer_highlights:
		if data.ref_control and data.ref_control.visibility_changed.is_connected(queue_update_dimmers):
			data.ref_control.visibility_changed.disconnect(queue_update_dimmers)

	_dimmer_map.clear()
	_dimmer_highlights.clear()
	_dimmer_update_queued = false


## Toggles visibility on/off for all dimmers.
func toggle_dimmers(is_on: bool) -> void:
	for dimmer in _dimmer_map.values():
		dimmer.visible = is_on


## Requests an update to dimmers and highlights, one time per frame for any number of calls.
func queue_update_dimmers() -> void:
	if _dimmer_update_queued:
		return

	_dimmer_update_queued = true
	_update_dimmers.call_deferred()


## Fully updates dimmers and highlights, batching/merging them together anew. This is slower than just
## updating the rectangle of highlight areas, and should only be done when the context meaningfully changes.
##
## [b]Warning:[/b] Do NOT call this method directly. Use [method queue_update_dimmers] instead.
func _update_dimmers() -> void:
	_dimmer_update_queued = false

	# Group highlights by their window/dimmer owner.

	var dimmer_highlights_grouped: Dictionary[Dimmer, Array] = {}
	for data in _dimmer_highlights:
		var ref_control := data.get_ref_control()
		if not ref_control: # Assume the main window, though this should never happen.
			ref_control = EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_ROOT)

		var dimmer := ensure_control_window_dimmer(ref_control)
		if not dimmer_highlights_grouped.has(dimmer):
			var highlights_group: Array[HighlightData] = []
			dimmer_highlights_grouped[dimmer] = highlights_group

		dimmer_highlights_grouped[dimmer].push_back(data)

	# Reduce highlights in each dimmer by merging them together based on simple heuristics,
	# then display final highlights.

	var editor_scale := EditorInterface.get_editor_scale()

	for dimmer in dimmer_highlights_grouped:
		var highlight_getters_still: Array[Array] = []
		var highlight_rects_still: Array[Rect2] = []
		var highlight_getters_flash: Array[Array] = []
		var highlight_rects_flash: Array[Rect2] = []

		# Resolve and reduce highlights, grouping them by their style.

		var highlights: Array[HighlightData] = dimmer_highlights_grouped[dimmer]
		for data in highlights:
			var getters_arr := highlight_getters_flash if data.play_flash else highlight_getters_still
			var rects_arr := highlight_rects_flash if data.play_flash else highlight_rects_still

			var highlight_rect: Rect2 = data.get_area(true)
			if not highlight_rect.has_area():
				continue

			# First, check if this area can be merged with one of the existing ones.

			var merged := false
			var alignment_threshold := 2.0 * editor_scale
			var grow_amount_px := 4.0 * editor_scale if data.do_grow else 0.0

			for i in getters_arr.size():
				# We determine if highlights should merge based on their alignment
				# and proximity. There are two cases in which we want to merge
				# highlights:
				#
				# 1. They are roughly aligned horizontally and touching vertically.
				# 2. They are roughly aligned vertically and touching horizontally.

				var other_getters: Array[Callable] = getters_arr[i]
				var other_rect := rects_arr[i]

				var is_horizontally_aligned := (
					absf(highlight_rect.position.x - other_rect.position.x) < alignment_threshold and
					absf(highlight_rect.size.x - other_rect.size.x) < alignment_threshold
				)
				if is_horizontally_aligned:
					var rect_grown_vertically := highlight_rect.grow_individual(0, grow_amount_px, 0, grow_amount_px)
					if rect_grown_vertically.intersects(other_rect): # Should merge together.
						other_getters.push_back(data.get_area)
						rects_arr[i] = other_rect.merge(highlight_rect)
						merged = true
						break

				var is_vertically_aligned := (
					absf(highlight_rect.position.y - other_rect.position.y) < alignment_threshold and
					absf(highlight_rect.size.y - other_rect.size.y) < alignment_threshold
				)
				if is_vertically_aligned:
					var rect_grown_horizontally := highlight_rect.grow_individual(grow_amount_px, 0, grow_amount_px, 0)
					if rect_grown_horizontally.intersects(other_rect): # Should merge together.
						other_getters.push_back(data.get_area)
						rects_arr[i] = other_rect.merge(highlight_rect)
						merged = true
						break

			# Alas, this area is not mergeable with others, so we add it by itself.

			if not merged:
				var getters: Array[Callable] = [ data.get_area ]
				getters_arr.push_back(getters)
				rects_arr.push_back(highlight_rect)

		# Add highlighted areas to the dimmer.

		dimmer.clear_highlights()

		for getters in highlight_getters_still:
			dimmer.add_highlight(getters, false)

		for getters in highlight_getters_flash:
			dimmer.add_highlight(getters, true)


class HighlightData:
	var ref_control: Control = null
	var ref_control_getter: Callable = Callable()
	var rect_getter: Callable = Callable()
	var clamp_getter: Callable = Callable()

	var play_flash: bool = false
	var do_grow: bool = false

	var has_updater: bool = false
	var updater_signal: Signal = Signal()
	var updater_callback: Callable = Callable()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE and has_updater:
			updater_signal.disconnect(updater_callback)
			updater_signal = Signal()
			updater_callback = Callable()
			has_updater = false

	func get_ref_control() -> Control:
		var base := ref_control

		if not base and ref_control_getter.is_valid():
			base = ref_control_getter.call()

		return base

	func get_area(unclamped: bool = false) -> Rect2:
		var base := get_ref_control()
		if not base or not base.is_visible_in_tree():
			return Rect2()

		var area := Rect2()
		if rect_getter.is_valid():
			area = rect_getter.call()
		else:
			area = base.get_global_rect()

		if not unclamped and clamp_getter.is_valid():
			var clamp_area := clamp_getter.call()
			if clamp_area.has_area():
				area = area.intersection(clamp_area)

		return area

	func connect_updater(signal_ref: Signal, callback: Callable) -> void:
		if has_updater:
			return # There can be only one!

		has_updater = true
		updater_signal = signal_ref
		updater_callback = callback
		updater_signal.connect(updater_callback)


## Highlights the given [param control], carving into their owner dimmers. Multiple connected highlights
## will be merged opportunistically, and [param do_grow] can be used to make merging more greedy. Returns
## created internal [HighlightData] object for further customization.
func add_highlight_to_control(control: Control, rect_getter := Callable(), clamp_getter := Callable(), play_flash := false, do_grow := false) -> HighlightData:
	# If undefined, add automatic clamping based on ancestry.
	if not clamp_getter.is_valid():
		clamp_getter = _create_auto_clamp_getter(control)

	var data := HighlightData.new()
	data.ref_control = control
	data.rect_getter = rect_getter
	data.clamp_getter = clamp_getter
	data.play_flash = play_flash
	data.do_grow = do_grow

	_dimmer_highlights.push_back(data)
	queue_update_dimmers()

	if data.ref_control:
		if not data.ref_control.visibility_changed.is_connected(queue_update_dimmers):
			data.ref_control.visibility_changed.connect(queue_update_dimmers)

	return data


## Highlights the control resolved through the given [param control_getter]. See also [method add_highlight_to_control].
func add_highlight_to_dynamic_control(control_getter: Callable, rect_getter := Callable(), clamp_getter := Callable(), play_flash := false, do_grow := false) -> void:
	var data := HighlightData.new()
	data.ref_control_getter = control_getter
	data.rect_getter = rect_getter
	data.clamp_getter = clamp_getter
	data.play_flash = play_flash
	data.do_grow = do_grow

	_dimmer_highlights.push_back(data)
	queue_update_dimmers()


## Removes all highlights associated with the given [param control]. For highlights added via
## [method add_highlight_to_dynamic_control] use [method remove_highlights_from_dynamic_control] instead.
func remove_highlights_from_control(control: Control) -> void:
	# Iterate backwards so it's safe to modify the array.
	var i := _dimmer_highlights.size() - 1
	while i >= 0:
		var data := _dimmer_highlights[i]
		if data.ref_control == control:
			if data.ref_control.visibility_changed.is_connected(queue_update_dimmers):
				data.ref_control.visibility_changed.disconnect(queue_update_dimmers)

			_dimmer_highlights.remove_at(i)

		i -= 1

	queue_update_dimmers()


## Removes all highlights associated with the given [param control_getter]. See also [method remove_highlights_from_control].
func remove_highlights_from_dynamic_control(control_getter: Callable) -> void:
	# Iterate backwards so it's safe to modify the array.
	var i := _dimmer_highlights.size() - 1
	while i >= 0:
		var data := _dimmer_highlights[i]
		if data.ref_control_getter == control_getter:
			_dimmer_highlights.remove_at(i)

		i -= 1

	queue_update_dimmers()


## Creates a callable that clamps the given [param control] to the most suitable ancestor.
func _create_auto_clamp_getter(control: Control) -> Callable:
	# Inspector property editors and sections are clamped to it.
	var main_inspector: EditorInspector = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK_INSPECTOR)
	if main_inspector.is_ancestor_of(control):
		return main_inspector.get_global_rect

	# Children of dockable nodes are clamped to the dock's container.
	var control_dock := Utils.get_control_dock_owner(control)
	if control_dock:
		return func() -> Rect2:
			var dock_container := control_dock.get_parent()
			if dock_container is not TabContainer:
				return Rect2()
			return dock_container.get_global_rect()

	# No auto-clamping.
	return Callable()


# Public API and helpers.
# Generic highlights.

## Highlights arbitrary [param controls]. See [method highlight_tree_items] for [param play_flash].
##
## [b]Warning:[/b] Prefer using [method highlight_editor_nodes] for standardized editor nodes.
func highlight_controls(controls: Array[Control], play_flash := false) -> void:
	for control in controls:
		if control:
			add_highlight_to_control(control, Callable(), Callable(), play_flash)


## Highlights editor nodes for given enumeration values. See [method highlight_tree_items] for
## [param play_flash].
func highlight_editor_nodes(node_points: Array[EditorNodePoints], play_flash := false) -> void:
	for node_point in node_points:
		var control: Control = EditorInterfaceAccess.get_node(node_point)
		if control:
			add_highlight_to_control(control, Callable(), Callable(), play_flash)


## Adds a flashing rect around the specified area within the given control.
func flash_control_area(ref_control: Control, target_area: Rect2) -> void:
	var dimmer := ensure_control_window_dimmer(ref_control)
	dimmer.add_flash_area(ref_control, target_area)


## Adds a flashing rect around the specified area within the given editor node.
func flash_editor_node_area(node_point: EditorNodePoints, target_area: Rect2) -> void:
	var ref_control: Control = EditorInterfaceAccess.get_node(node_point)
	if not ref_control:
		return

	var dimmer := ensure_control_window_dimmer(ref_control)
	dimmer.add_flash_area(ref_control, target_area)


# Standard GUI highlights.

## Highlights a [TabBar] tab at the given [param index]. If [param index] is [code]-1[/code],
## highlights the entire [TabBar] instead. If the target [Control] is [TabContainer], uses
## its [TabBar]. See [method highlight_tree_items] for [param play_flash].
func highlight_tab_index(tabs: Control, index := -1, clamp_to: Control = null, play_flash := true) -> void:
	var tab_bar: TabBar = tabs.get_tab_bar() if tabs is TabContainer else tabs
	if tab_bar == null or index < -1 or index >= tab_bar.tab_count:
		return

	var rect_getter := Callable()
	if index == -1:
		rect_getter = tab_bar.get_global_rect
	else:
		rect_getter = func() -> Rect2:
			var tab_rect := tab_bar.get_tab_rect(index)

			# If the tab is not on screen, highlight offset buttons instead.
			if tab_bar.get_offset_buttons_visible():
				if index < tab_bar.get_tab_offset() or (index > tab_bar.get_tab_offset() and tab_rect.position.is_zero_approx()):
					var buttons_rect := Rect2()
					buttons_rect.size = Vector2(
						tab_bar.get_theme_icon("increment").get_width() + tab_bar.get_theme_icon("decrement").get_width(),
						tab_bar.size.y,
					)

					# In RTL they are directly on the left. In LTR they are directly on the right.
					if not tab_bar.is_layout_rtl():
						buttons_rect.position.x = tab_bar.size.x - buttons_rect.size.x

					return tab_bar.get_global_transform() * buttons_rect

			return tab_bar.get_global_transform() * tab_bar.get_tab_rect(index)

	var clamp_getter := tab_bar.get_global_rect
	if clamp_to:
		clamp_getter = clamp_to.get_global_rect

	var highlight_data := add_highlight_to_control(tabs, rect_getter, clamp_getter, play_flash)

	# Refresh highlights if the tabbar offset changes. This ensures that merging behaves well.
	# Alas, there is no dedicated signal for when the offset changes, so we react on redraws and
	# check if the offset is different now.

	var cache := {
		"offset": tab_bar.get_tab_offset(),
	}
	var updater := func() -> void:
		var new_offset := tab_bar.get_tab_offset()
		if cache.offset == new_offset:
			return

		cache.offset = new_offset
		queue_update_dimmers()

	highlight_data.connect_updater(tab_bar.draw, updater)


## Highlights a [TabBar] tab with the given [param title]. If the target [Control] is [TabContainer],
## uses its [TabBar]. See [method highlight_tree_items] for [param play_flash].
func highlight_tab_title(tabs: Control, title: String, clamp_to: Control = null, play_flash := true) -> void:
	var tab_bar: TabBar = tabs.get_tab_bar() if tabs is TabContainer else tabs
	if tab_bar == null:
		return

	var scene_tabs: TabBar = EditorInterfaceAccess.get_node(EditorNodePoints.SCENE_TABS_TAB_BAR)

	for index in tab_bar.tab_count:
		var tab_title: String = tab_bar.get_tab_title(index)

		if title == tab_title:
			highlight_tab_index(tab_bar, index, clamp_to, play_flash)
			break

		if tab_bar == scene_tabs and ("%s(*)" % title) == tab_title:
			highlight_tab_index(tab_bar, index, clamp_to, play_flash)
			break


## Highlights an [ItemList] item at the given [param item_index]. See [method highlight_tree_items]
## for [param play_flash].
func highlight_list_item(item_list: ItemList, item_index: int, clamp_to: Control = null, play_flash := true) -> void:
	if item_list == null or item_index < 0 or item_index >= item_list.item_count:
		return

	var rect_getter := func() -> Rect2:
		var rect := item_list.get_item_rect(item_index)
		rect.position += item_list.global_position
		return rect

	var clamp_getter := item_list.get_global_rect
	if clamp_to:
		clamp_getter = clamp_to.get_global_rect

	add_highlight_to_control(item_list, rect_getter, clamp_getter, play_flash)


## Highlight [TreeItem]s from the given [param tree] that match the [param predicate]. The highlight
## can also play a flash animation if [param play_flash] is [code]true[/code]. [param button_index]
## specifies which button to highlight from the [TreeItem] instead of the whole item.
func highlight_tree_items(tree: Tree, predicate: Callable, button_index := -1, do_center := true, play_flash := false) -> void:
	var root := tree.get_root()
	if root == null:
		return

	for item in Utils.filter_tree_items(root, predicate):
		Utils.unfold_tree_item(item)
		tree.scroll_to_item(item, do_center)

		var item_path := Utils.get_tree_item_path(item)
		# We cache the found property in a dict to be able to capture and modify it in the rect_getter lambda
		var cache := { "item": item }

		var rect_getter := func() -> Rect2:
			if not is_instance_valid(cache.item):
				var found := Utils.filter_tree_items(
					tree.get_root(),
					func(ti: TreeItem) -> bool: return item_path == Utils.get_tree_item_path(ti),
				)
				if found.is_empty():
					return Rect2()
				cache.item = found[0]

			return tree.get_global_transform() * tree.get_item_area_rect(cache.item, 0, button_index)
		var clamp_getter := tree.get_global_rect

		add_highlight_to_control(tree, rect_getter, clamp_getter, play_flash, true)


## Higlights code lines in the given [param code_editor], defined by the range from [param start] to
## [param end]. If [param end] is not specified, or set to [code]0[/code], only the start line is
## highlighted. Line numbers are 1-based, following their visual numeration. [param do_center] forces
## the [ScriptEditor] to center vertically on the given range. See [method highlight_tree_items] for
## [param play_flash].
func highlight_code(code_editor: CodeEdit, start: int, end := 0, caret := 0, do_center := true, play_flash := false) -> void:
	start -= 1
	end = start if end < 1 else (end - 1)
	if caret == 0:
		caret = end

	if start < 0 or end > code_editor.get_line_count() or start > end:
		return

	code_editor.grab_focus()
	if do_center:
		code_editor.set_line_as_center_visible((start + end) / 2)
	code_editor.scroll_horizontal = 0
	code_editor.set_caret_line.call_deferred(caret)
	code_editor.set_caret_column.call_deferred(code_editor.get_line(caret).length())

	var rect_getter := func() -> Rect2:
		var rect := Rect2()

		var rect_start := code_editor.get_rect_at_line_column(start, 0)
		var rect_end := code_editor.get_rect_at_line_column(end, 0)
		if rect_start.position != -Vector2i.ONE and rect_end.position != -Vector2i.ONE:
			rect = code_editor.get_global_transform() * Rect2(rect_start.merge(rect_end))
			rect.position.x = code_editor.global_position.x
			rect.size.x = code_editor.size.x

		return rect

	add_highlight_to_control(code_editor, rect_getter, Callable(), play_flash)


# Editor-specific highlights.
# NOTE: These should be methods that require some bespoke implementation. For general high-level API
# define methods in tour.gd instead.

## Highlights edited properties in the Inspector dock by their (programmatic) names. See
## [method highlight_tree_items] for [param play_flash].
##
## [b]Warning:[/b] This method does NOT support properties which are merged into inspector sections
## (boolean section toggles introduced in 4.6). For those, use [method highlight_inspector_section_property].
func highlight_inspector_property(property_name: StringName, do_center := true, play_flash := false) -> void:
	var main_inspector: EditorInspector = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK_INSPECTOR)
	var scroll_offset := 200 * EditorInterface.get_editor_scale()
	var matching_property := EditorInterfaceAccess.find_inspector_property_by_name(main_inspector, property_name)

	# Only scroll/unfold if the property exists now. If it doesn't exist yet
	# (wrong node selected), we still create the highlight below so it appears
	# when the user selects the correct node.
	if matching_property:
		# Unfold parent sections recursively if necessary.
		var current_parent := matching_property.get_parent()
		const MAX_ITERATION_COUNT := 10
		for i in MAX_ITERATION_COUNT:
			var parent_class := current_parent.get_class()
			if parent_class == "EditorInspectorSection":
				current_parent.unfold()

			current_parent = current_parent.get_parent()
			if current_parent == main_inspector:
				break

		if do_center:
			main_inspector.scroll_vertical += (
				matching_property.global_position.y + scroll_offset
				- main_inspector.global_position.y
				- main_inspector.size.y / 2.0
			)
		else:
			main_inspector.ensure_control_visible(matching_property)

	# We cache the found property in a dict to be able to capture and modify it in the rect_getter lambda
	var cache := { "property": matching_property }

	var rect_getter := func inspector_property_rect_getter() -> Rect2:
		# EditorProperty nodes can be recycled when the inspector rebuilds, so we
		# also check that the property name still matches.
		if not is_instance_valid(cache.property) or cache.property.get_edited_property() != name:
			cache.property = EditorInterfaceAccess.find_inspector_property_by_name(main_inspector, property_name)
			if cache.property == null:
				return Rect2()

		if cache.property.is_visible_in_tree():
			return cache.property.get_global_rect()
		return Rect2()
	var clamp_getter := main_inspector.get_global_rect

	add_highlight_to_control(main_inspector, rect_getter, clamp_getter, play_flash, true)


## Highlights toggleable section in the Inspector dock using (programmatic) names of their first properties.
## If the expected first property is marked as favorite, the section is split and only the one in the
## favorites box is highlighted. See [method highlight_tree_items] for [param play_flash].
func highlight_inspector_section_property(first_property_name: StringName, do_center := true, play_flash := false) -> void:
	var main_inspector: EditorInspector = EditorInterfaceAccess.get_node(EditorNodePoints.INSPECTOR_DOCK_INSPECTOR)
	var scroll_offset := 200 * EditorInterface.get_editor_scale()
	var matching_section := EditorInterfaceAccess.find_inspector_section_by_first_property(main_inspector, first_property_name)

	# The node might not be immediately available, but we still expect to find
	# it soon (user selects correct node or the editor updates). Do updates only
	# if the node is already here.
	if matching_section:
		if do_center:
			main_inspector.scroll_vertical += (matching_section.global_position.y + scroll_offset - main_inspector.global_position.y - main_inspector.size.y / 2.0)
		else:
			main_inspector.ensure_control_visible(matching_section)

	# We cache the found property in a dict to be able to capture and modify it in the rect_getter lambda
	var cache := { "section": matching_section }

	var rect_getter := func inspector_section_rect_getter() -> Rect2:
		if not is_instance_valid(cache.section):
			cache.section = EditorInterfaceAccess.find_inspector_section_by_first_property(main_inspector, first_property_name)
			if cache.section == null:
				return Rect2()

		if cache.section.is_visible_in_tree():
			var rect: Rect2 = cache.section.get_global_rect()
			var section_box: VBoxContainer = cache.section.call("get_vbox")
			if section_box and section_box.is_visible_in_tree():
				rect.end.y = section_box.global_position.y
			return rect

		return Rect2()
	var clamp_getter := main_inspector.get_global_rect

	add_highlight_to_control(main_inspector, rect_getter, clamp_getter, play_flash, true)
