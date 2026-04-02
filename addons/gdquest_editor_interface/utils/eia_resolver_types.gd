## Types used by the node point resolver utility. These server as base types
## for specific node point definitions and provide ready-made resolver steps
## used by said definitions.
@tool

const Enums := preload("./eia_enums.gd")

### Definition sub-types ###

## Standard definition that points to a single node through a series
## of resolver steps.
class Definition:
	# NOTE: Built-in types can be stored directly (as a GDScriptNativeClass
	# object), but that doesn't work for some valid types which are not exposed
	# to scripting, like CanvasItemEditor. So we use strings instead, which,
	# ironically, gives us better type safety in the end.

	## Expected node type of the last resolved node. Can be any valid ClassDB
	## type.
	var node_type: String = "Node"
	## Node points which must be resolved before resolver can attempt to
	## go after the target node. Unlike the base reference, these are not
	## passed to the steps.
	var prefetch_references: Array[Enums.NodePoint] = []

	## Base node point value from which the resolver should start. This
	## value is passed to the first step as input. Can be -1 if no base
	## reference is needed (then the first step must be a custom one).
	var base_reference: int = -1
	## If not empty, this definition is for a reusable component and can
	## only be resolved if a context node provided using EIA.get_node_relative().
	## The type of the provided node is validated against this value. If
	## base_reference is a valid value, it is then resolved (using the same
	## context node) and passed to the first step as input. If not, the
	## context node is provided as input instead.
	var relative_node_type: String = ""

	## Steps for the resolver to transform the base reference into the
	## target node or nodes.
	var resolver_steps: Array[Step] = []


## Multi-node definition that allows to resolve several nodes
## together in one go. Resolver steps operate on an array of nodes.
## The final step must return an array that maps exactly to the
## node_type_map property.
class MultiDefinition extends Definition:
	## Mapping between node point values and expected resulting node types.
	## Replaces the node_type property in multi-node definitions, and also
	## establishes the shape of the resulting array.
	var node_type_map: Dictionary[Enums.NodePoint, String] = {}


### Step sub-types. ###

class Step:
	# Resolver used by standard definitions.
	func resolve(_base_node: Node, step_index: int = 0) -> Node:
		push_warning("[EIA] Step %d: Resolver not implemented." % [ step_index ])
		return null

	# Resolver used by multi-node definitions.
	func resolve_multi(base_nodes: Array[Node], step_index: int = 0) -> Array[Node]:
		var results: Array[Node] = []
		for base_node in base_nodes:
			results.push_back(resolve(base_node, step_index))

		return results


## Resolves a node using the passed callable. The callable must accept
## a node reference and return a node reference.
class DoCustomStep extends Step:
	var custom_callback: Callable = Callable()

	func _init(callback: Callable) -> void:
		custom_callback = callback

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not custom_callback.is_valid():
			push_error("[EIA] Step %d: Custom resolver has invalid callback." % [ step_index ])
			return null

		return custom_callback.call(base_node)


## Same as above, but for multi-node definitions. The callable must accept
## an array of node references and return a new array of node references.
class DoCustomMultiStep extends Step:
	var custom_callback: Callable = Callable()

	func _init(callback: Callable) -> void:
		custom_callback = callback

	func resolve_multi(base_nodes: Array[Node], step_index: int = 0) -> Array[Node]:
		if not custom_callback.is_valid():
			push_error("[EIA] Step %d: Custom multi-resolver has invalid callback." % [ step_index ])
			return []

		return custom_callback.call(base_nodes)


# Resolving steps turn node references into other node references.

## Finds a child node of the specified type. Optionally, can find the
## N-th child for the given type (only counting successful matches).
## If the given index is negative, searches from the end.
class GetChildTypeStep extends Step:
	var type_name: String = ""
	var type_index: int = 0

	func _init(name: String, index: int = 0) -> void:
		type_name = name
		type_index = index

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not base_node:
			return null

		var counter := -1

		if type_index >= 0:
			for child_node in base_node.get_children():
				if ClassDB.is_parent_class(child_node.get_class(), type_name):
					counter += 1
					if counter == type_index:
						return child_node

			push_error("[EIA] Step %d: Expected at least %d '%s' child node(s), found %d." % [ step_index, (type_index + 1), type_name, (counter + 1) ])

		else:
			var child_index := base_node.get_child_count() - 1
			var target_index := absi(type_index) - 1

			while child_index >= 0:
				var child_node := base_node.get_child(child_index)
				if ClassDB.is_parent_class(child_node.get_class(), type_name):
					counter += 1
					if counter == target_index:
						return child_node
				child_index -= 1

			push_error("[EIA] Step %d: Expected at least %d '%s' child node(s), found %d." % [ step_index, (target_index + 1), type_name, (counter + 1) ])

		return null


## Returns the N-th child node of any type. If the given index is
## negative, searches from the end.
class GetChildIndexStep extends Step:
	var child_index: int = 0

	func _init(index: int) -> void:
		child_index = index

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not base_node:
			return null

		if child_index >= 0:
			if base_node.get_child_count() <= child_index:
				push_error("[EIA] Step %d: Expected at least %d child node(s), found %d." % [ step_index, (child_index + 1), base_node.get_child_count() ])
				return null

		else:
			if (base_node.get_child_count() + child_index) < 0:
				push_error("[EIA] Step %d: Expected at least %d child node(s), found %d." % [ step_index, absi(child_index), base_node.get_child_count() ])
				return null

		return base_node.get_child(child_index)


## Finds a descendant node of the specified type. Optionally, can find
## the N-th node for the given type (only counting successful matches).
class FindNodeTypeStep extends Step:
	var type_name: String = ""
	var type_index: int = 0

	func _init(name: String, index: int = 0) -> void:
		type_name = name
		type_index = index

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not base_node:
			return null

		var found_nodes := base_node.find_children("", type_name, true, false)
		if found_nodes.size() <= type_index:
			push_error("[EIA] Step %d: Expected at least %d '%s' descendant node(s), found %d." % [ step_index, (type_index + 1), type_name, found_nodes.size() ])
			return null

		return found_nodes[type_index]


## Returns a descendant node according to the specified node path.
class GetNodePathStep extends Step:
	var node_path: NodePath = ""
	var translate_path: bool = false

	func _init(path: NodePath, translate: bool = false) -> void:
		node_path = path
		translate_path = translate

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not base_node:
			return null

		# Some nodes may be named with translatable names, which change depending on
		# the language. So we check for both names. This only works if the entire
		# path is a translatable string.
		var tred_path: NodePath = ""

		var fetched_node := base_node.get_node_or_null(node_path)
		if not fetched_node && translate_path:
			var editor_domain := TranslationServer.get_or_add_domain("godot.editor")
			tred_path = String(editor_domain.translate(String(node_path)))
			fetched_node = base_node.get_node_or_null(tred_path)

		if not fetched_node:
			if translate_path:
				push_error("[EIA] Step %d: Expected a node at path '%s' or '%s'." % [ step_index, node_path, tred_path ])
			else:
				push_error("[EIA] Step %d: Expected a node at path '%s'." % [ step_index, node_path ])
			return null

		return fetched_node


## Returns the N-th parent node.
class GetParentCountStep extends Step:
	var parent_count: int = 0

	func _init(count: int) -> void:
		parent_count = count

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not base_node:
			return null

		var current_node: Node = base_node
		for i in parent_count:
			current_node = current_node.get_parent()
			if not current_node:
				push_error("[EIA] Step %d: Expected at least %d parent node(s), found %d." % [ step_index, parent_count, i ])
				return null

		return current_node


## Finds a node using previous node's signal and the specified
## connected object type.
class GetSignalTypeStep extends Step:
	var signal_name: String = ""
	var object_type_name: String = ""

	func _init(name: String, type: String) -> void:
		signal_name = name
		object_type_name = type

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not base_node:
			return null

		var signal_ref: Signal = base_node[signal_name]
		if not signal_ref:
			push_error("[EIA] Step %d: Expected node to have signal '%s'." % [ step_index, signal_name ])
			return null

		for connection_info in signal_ref.get_connections():
			var object_ref := (connection_info["callable"] as Callable).get_object()

			if ClassDB.is_parent_class(object_ref.get_class(), object_type_name):
				return object_ref

		push_error("[EIA] Step %d: Expected '%s' node connected to signal '%s'." % [ step_index, object_type_name, signal_name ])
		return null


## Finds a node inside of a WindowWrapper container, checking all
## potential locations and matching with the given type.
class GetWindowWrappedTypeStep extends Step:
	var object_type_name: String = ""

	func _init(type: String) -> void:
		object_type_name = type

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not base_node:
			return null

		if not ClassDB.is_parent_class(base_node.get_class(), "WindowWrapper"):
			push_error("[EIA] Step %d: Expected a WindowWrapper node.")
			return null

		var unwrapped_nodes := base_node.find_children("", object_type_name, false, false)
		if not unwrapped_nodes.is_empty():
			return unwrapped_nodes[0]

		var window := base_node.get_child(0)
		var windowed_nodes := window.find_children("", object_type_name, false, false)
		if not windowed_nodes.is_empty():
			return windowed_nodes[0]

		if window.get_child_count() == 3:
			var margin_container := window.get_child(2)
			if margin_container is MarginContainer:
				var wrapped_nodes := margin_container.find_children("", object_type_name, false, false)
				if not wrapped_nodes.is_empty():
					return wrapped_nodes[0]

		push_error("[EIA] Step %d: Expected '%s' node inside WindowWrapper container." % [ step_index, object_type_name ])
		return null


# Validating steps operate on the same node reference and return
# null if it doesn't satisfy the condition.

## Checks if the current node has the specified editor icon.
class HasEditorIconStep extends Step:
	var icon_name: String = ""

	func _init(name: String) -> void:
		icon_name = name

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not base_node:
			return null

		var editor_theme := EditorInterface.get_editor_theme()
		if not editor_theme.has_icon(icon_name, "EditorIcons"):
			push_error("[EIA] Step %d: Icon '%s' not present in the editor theme." % [ step_index, icon_name ])
			return null

		var editor_icon := editor_theme.get_icon(icon_name, "EditorIcons")

		if base_node is Button:
			if base_node.icon != editor_icon:
				push_warning("[EIA] Step %d: Button expected to have icon '%s'." % [ step_index, icon_name ])
				return null
		else:
			push_warning("[EIA] Step %d: Node type '%s' not supported by editor icon resolver." % [ step_index, base_node.get_class() ])
			return null

		return base_node


## Checks if the current node has the specified callable connected
## to the specified signal.
class HasSignalCallableStep extends Step:
	var signal_name: String = ""
	var callable_name: String = ""

	func _init(name: String, callable: String) -> void:
		signal_name = name
		callable_name = callable

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not base_node:
			return null

		var signal_ref: Signal = base_node[signal_name]
		if not signal_ref:
			push_error("[EIA] Step %d: Expected node to have signal '%s'." % [ step_index, signal_name ])
			return null

		for connection_info in signal_ref.get_connections():
			var method_name := (connection_info["callable"] as Callable).get_method()

			if method_name == callable_name:
				return base_node

		push_error("[EIA] Step %d: Expected callable '%s' connected to signal '%s'." % [ step_index, callable_name, signal_name ])
		return null


## Checks if the tab container or tab bar has tabs with specified
## names in the specified order. Optionally checks if there are
## only these tabs.
class HasTabsNamesStep extends Step:
	var tab_names: PackedStringArray = []
	var check_strict_count: bool = false

	func _init(names: PackedStringArray, strict_count: bool = false) -> void:
		tab_names = names
		check_strict_count = strict_count

	func resolve(base_node: Node, step_index: int = 0) -> Node:
		if not base_node:
			return null

		var tab_bar: TabBar = null
		if base_node is TabBar:
			tab_bar = base_node
		elif base_node is TabContainer:
			tab_bar = base_node.get_tab_bar()
		else:
			push_warning("[EIA] Step %d: Node type '%s' not supported by tabs names resolver." % [ step_index, base_node.get_class() ])
			return null

		if check_strict_count && tab_bar.tab_count != tab_names.size():
			push_warning("[EIA] Step %d: Expected node to have exactly %d tabs, found %d." % [ step_index, tab_names.size(), tab_bar.tab_count ])
			return null

		# We check the name against current editor translation. This works for a fresh
		# editor start (which is requested when you change the language), but may not
		# work between changing the language and a restart. For our purposes, that's
		# sufficiently reliable.
		var editor_domain := TranslationServer.get_or_add_domain("godot.editor")

		var failed_check := false
		for i in tab_names.size():
			var translated_tab_name := editor_domain.translate(tab_names[i])
			var found_tab_name := tab_bar.get_tab_title(i)

			# Actually, we check for both untranslated and translated strings. Godot
			# editor is a bit inconsistent when it comes to applying translations. In
			# 2/3 of the cases it uses TTR() and in 1/3 — TTRC(), for no obvious reason
			# a lot of time. The latter doesn't go through the translation server, but
			# the final editor widget will still appear translated due to automatic
			# translation in controls, through atr().
			if found_tab_name != translated_tab_name && found_tab_name != tab_names[i]:
				push_warning("[EIA] Step %d: Expected tab %d name '%s', found '%s'." % [ step_index, i, translated_tab_name, tab_names[i], found_tab_name ])
				failed_check = true

		if failed_check:
			return null

		return base_node
