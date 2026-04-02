## Node point resolver utility for the editor interface access system.
## It takes definitions from the library folder and tries its best to
## turn them into node references. If a definition depends on another
## definition, this utility will cascadingly resolve all of them.
@tool

const Enums := preload("./eia_enums.gd")
const Types := preload("./eia_resolver_types.gd")

const LIBRARY_ROOT := "../library"

# Library is a collection of GDScript classes extending Types.Definition or
# its subtypes. There must be one definition per Enums.NodePoint value, though
# there can be auxiliary definitions which can be used as a basis for other
# definitions, like in the case of Types.MultiDefinition.
#
# Each definition must be named after the enum value it maps to. If the enum
# has a value
#   CANVAS_ITEM_EDITOR
# its corresponding definition must be called
#   CanvasItemEditorDef
# "Def" at the end is added to avoid naming conflicts with existing Godot types,
# although it's not strictly necessary.
#
# The order of definitions or files in the file system is not important. At the
# load time the files are simply collected with no resolution being done. Naturally,
# scripts must be valid and internally consistent in their dependencies. In
# practical reality, Godot will already load and parse them by the time we prepare
# our cache here.
#
# However, you should be mindful of cyclic dependencies when defining resolution
# steps. There are currently no checks to ensure that any given definition doesn't
# rely on another definition which in turn needs the first definition, directly or
# indirectly. In some cases this is not possible to determine at all. Just make sure
# to run EIA.test_resolve() regularly. This problem, if introduced, would never appear
# only on user machines.

static var _library_cache: Array[GDScript] = [] # Keeps scripts' reference count up.
static var _library_definition_map: Dictionary[String, GDScript] = {}
static var _node_cache: Dictionary[Enums.NodePoint, Node] = {}
static var _context_node_cache: Dictionary[int, Dictionary] = {} # InstanceID, Dictionary[Enums.NodePoint, Node]


static func _static_init() -> void:
	_reload_node_point_definitions()


static func resolve_node(node_point: Enums.NodePoint, context_node: Node = null, skip_cache: bool = false) -> Node:
	# Check the cache for existing entries to avoid expensive resolution.

	if context_node:
		var context_cache := _get_context_cache(context_node)
		if context_cache.has(node_point):
			return context_cache[node_point]
	else:
		if _node_cache.has(node_point):
			return _node_cache[node_point]

	# Convert node point into a string identifier.

	var node_point_name := Enums.get_node_point_name(node_point)
	if node_point_name.is_empty():
		push_error("[EIA] Unknown node point value (%d)." % [ node_point ])
		return null

	# Find the definition by name (definitions are preloaded).

	var definition := _get_node_point_definition(node_point_name)
	if not definition:
		push_error("[EIA] Unknown node point definition (%s)." % [ node_point_name ])
		return null

	# Valide the definition.

	if definition.resolver_steps.is_empty():
		push_error("[EIA] Node point definition (%s) has no resolver steps." % [ node_point_name ])
		return null

	if skip_cache && not definition.prefetch_references.is_empty():
		push_error("[EIA] Node point definition (%s) has pre-fetch references, which requires caching." % [ node_point_name ])
		return null

	for prefetch_point in definition.prefetch_references:
		# Caching is forced here because that's the only way pre-fetching makes sense.
		var prefetch_node := resolve_node(prefetch_point, null, false)
		if not prefetch_node:
			push_error("[EIA] Node point definition (%s) couldn't satisfy its prerequisites." % [ node_point_name ])
			return null

	# Note that the context node can be passed even for definitions which
	# do not mandate a relative base. In that case we do not check them for
	# any validity, but they are still used for base reference resolution.
	if not definition.relative_node_type.is_empty():
		if not context_node:
			push_error("[EIA] Node point definition (%s) expects a relative base node." % [ node_point_name ])
			return null

		if not ClassDB.is_parent_class(context_node.get_class(), definition.relative_node_type):
			push_error("[EIA] Node point definition (%s) expects base to be '%s', but '%s' was given." % [ node_point_name, definition.relative_node_type, context_node.get_class() ])
			return null

	# Resolve the node point using the definition.

	if definition is Types.MultiDefinition:
		return _resolve_multi_node(definition, node_point, context_node, skip_cache)
	else:
		return _resolve_single_node(definition, node_point, context_node, skip_cache)

	return null


static func _resolve_single_node(definition: Types.Definition, node_point: Enums.NodePoint, context_node: Node, skip_cache: bool) -> Node:
	# If there is a context node, use it as base. If there is a base reference,
	# resolve it using current base (either null or the context node).

	var current_node: Node = null
	if context_node:
		current_node = context_node
	if definition.base_reference != -1:
		current_node = resolve_node(definition.base_reference, current_node, skip_cache)

	# Resolve the node.
	for i in definition.resolver_steps.size():
		var step := definition.resolver_steps[i]
		current_node = step.resolve(current_node, i)

	# Validate the result.

	if not current_node:
		var node_point_name := Enums.get_node_point_name(node_point)
		push_error("[EIA] Failed to resolve node point value (%d) via definition (%s)." % [ node_point, node_point_name ])
		return null

	var current_node_type := current_node.get_class()
	var expected_node_type := definition.node_type
	if not ClassDB.is_parent_class(current_node_type, expected_node_type):
		push_error("[EIA] Resolved node (%s) doesn't match or inherit expected type (%s)." % [ current_node_type, expected_node_type ])
		return null

	# Cache the result, if necessary.
	if not skip_cache:
		if context_node:
			var context_cache := _get_context_cache(context_node)
			context_cache[node_point] = current_node
		else:
			_node_cache[node_point] = current_node

	return current_node


static func _resolve_multi_node(definition: Types.MultiDefinition, node_point: Enums.NodePoint, context_node: Node, skip_cache: bool) -> Node:
	if definition.node_type_map.is_empty() || node_point not in definition.node_type_map:
		var node_point_name := Enums.get_node_point_name(node_point)
		push_error("[EIA] Expected node point value (%d) is missing from multi-node definition (%s)." % [ node_point, node_point_name ])
		return null

	# If there is a context node, use it as base. If there is a base reference,
	# resolve it using current base (either null or the context node).
	# Only one node may be the output of all this.

	var base_node: Node = null
	if context_node:
		base_node = context_node
	if definition.base_reference != -1:
		base_node = resolve_node(definition.base_reference, base_node, skip_cache)

	var current_nodes: Array[Node] = []
	if base_node:
		current_nodes.push_back(base_node)

	# Resolve nodes together.

	for i in definition.resolver_steps.size():
		var step := definition.resolver_steps[i]
		current_nodes = step.resolve_multi(current_nodes, i)

	# Validate results.

	if current_nodes.size() != definition.node_type_map.size():
		push_error("[EIA] Number of resolved nodes (%d) doesn't match expected number (%d)." % [ current_nodes.size(), definition.node_type_map.size() ])
		return null

	# Validate each resulting node.

	var result_index := 0
	var target_node: Node = null

	for expected_node_point in definition.node_type_map:
		var current_node := current_nodes[result_index]
		result_index += 1

		# Track the one node we want directly.
		if expected_node_point == node_point:
			target_node = current_node

		if not current_node:
			var node_point_name := Enums.get_node_point_name(expected_node_point)
			push_error("[EIA] Failed to resolve node point value (%d) via definition (%s)." % [ expected_node_point, node_point_name ])
			continue

		var current_node_type := current_node.get_class()
		var expected_node_type := definition.node_type_map[expected_node_point]
		if not ClassDB.is_parent_class(current_node_type, expected_node_type):
			push_error("[EIA] Resolved node (%s) doesn't match or inherit expected type (%s)." % [ current_node_type, expected_node_type ])
			continue

		# Cache the result, if necessary.
		if not skip_cache:
			if context_node:
				var context_cache := _get_context_cache(context_node)
				context_cache[node_point] = current_node
			else:
				_node_cache[expected_node_point] = current_node

	return target_node


static func get_node_cached(node_point: Enums.NodePoint, context_node: Node = null) -> Node:
	if context_node:
		var context_cache := _get_context_cache(context_node)
		if context_cache.has(node_point):
			return context_cache[node_point]
	else:
		if _node_cache.has(node_point):
			return _node_cache[node_point]

	return null


static func is_node_relative(node_point: Enums.NodePoint) -> bool:
	var node_point_name := Enums.get_node_point_name(node_point)
	if node_point_name.is_empty():
		push_error("[EIA] Unknown node point value (%d)." % [ node_point ])
		return false

	# Find the definition by name (definitions are preloaded).

	var definition := _get_node_point_definition(node_point_name)
	if not definition:
		push_error("[EIA] Unknown node point definition (%s)." % [ node_point_name ])
		return false

	return not definition.relative_node_type.is_empty()


# Helpers.

static func _get_library_root() -> String:
	## HACK: A simple hack to get current path from a static context.
	var library_root := (Types as Script).resource_path
	library_root = library_root.get_base_dir()
	library_root = library_root.path_join(LIBRARY_ROOT)

	return library_root.simplify_path()


static func _reload_node_point_definitions() -> void:
	_library_cache.clear()
	_library_definition_map.clear()

	# NOTE: Sometimes during testing the editor failed to properly load some scripts,
	# including only some library files. Unclear what the issue might be, but at least
	# for the library we can fall back onto using a hardcoded "include" file with
	# every library file listed. Not doing that for now, as the issue might as well
	# be with the testing environment on my end.

	var library_root := _get_library_root()
	var fs := DirAccess.open("res://")
	var error := DirAccess.get_open_error()
	if error != OK:
		push_error("[EIA] Failed to open project root for reading (code %d)." % [ error ])
		return

	var paths_to_explore: Array[String] = [ library_root ]
	while not paths_to_explore.is_empty():
		var path_root: String = paths_to_explore.pop_front()

		error = fs.change_dir(path_root)
		if error != OK:
			push_error("[EIA] Failed to open path '%s' for reading (code %d)." % [ path_root, error ])
			continue

		error = fs.list_dir_begin()
		if error != OK:
			push_error("[EIA] Failed to start file listing at path '%s' (code %d)." % [ path_root, error ])
			continue

		# Automatically load every GDScript file from the library folder.
		var file_name := fs.get_next()
		while not file_name.is_empty():
			var file_path := path_root.path_join(file_name)
			print_verbose("[EIA] Reading library path '%s'..." % [ file_path ])

			if fs.current_is_dir(): # The search is recursive.
				paths_to_explore.push_back(file_path)
				print_verbose("[EIA] Path at '%s' is a folder, added to lookup stack." % [ file_path ])
				file_name = fs.get_next()
				continue

			if not file_name.ends_with(".gd"): # Only consider GDScript files.
				file_name = fs.get_next()
				continue

			var script: GDScript = load(file_path)
			if not script:
				push_error("[EIA] Failed to load library file at '%s'." % [ file_path ])
				file_name = fs.get_next()
				continue

			# Keep a reference around so it doesn't get freed by accident.
			_library_cache.push_back(script)
			var added_def_count := 0

			# Get all inner classes via the constant map.
			for name: String in script.get_script_constant_map():
				if script[name] is not Script:
					continue
				if not _is_node_point_definition(script[name]):
					continue

				# Classes have a suffix to avoid naming collisions, but enum values
				# do not because they need to be clean, as a part of the public API
				# for this library.
				var clean_name := name.trim_suffix("Def")
				_library_definition_map[clean_name] = script[name]
				added_def_count += 1

			print_verbose("[EIA] Path at '%s' is a valid script, added %d new definitions." % [ file_path, added_def_count ])
			file_name = fs.get_next()


static func _get_node_point_definition(name: String) -> Types.Definition:
	if not _library_definition_map.has(name):
		return null

	return _library_definition_map[name].new()


static func _is_node_point_definition(script: Script) -> bool:
	if not script:
		return false
	if script == Types.Definition:
		return true # Weird, but true.

	var base_script := script.get_base_script()
	while base_script:
		if base_script == Types.Definition:
			return true

		base_script = base_script.get_base_script()

	return false


static func _get_context_cache(context_node: Node) -> Dictionary[Enums.NodePoint, Node]:
	var context_id := context_node.get_instance_id()

	if context_id not in _context_node_cache:
		var cache: Dictionary[Enums.NodePoint, Node] = {} # Force typing.
		_context_node_cache[context_id] = cache

	return _context_node_cache[context_id]
