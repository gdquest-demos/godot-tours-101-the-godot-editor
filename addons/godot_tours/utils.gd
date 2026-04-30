## A collection of static utility functions used by tours and GDTour infrastructure.
@tool

const TRANSLATION_LOCAL_DIR := "locale"
const TRANSLATION_PLUGIN_DOMAIN := "gdquest.gdtour.%s"
const TRANSLATION_TOUR_DOMAIN := "gdquest.gdtour.tour_%s"
const TranslationDomains := {
	BUBBLE_UI = "bubble_ui",
}

static var _tour_translation_domains: Array[String] = []

const ThemeUtils := preload("res://addons/gdquest_theme_utils/theme_utils.gd")
const DEFAULT_THEME := preload("assets/gdtour_theme.tres")

static var _scaled_theme: Theme = null
static var _scaled_icons_cache: Dictionary[String, DPITexture] = {}


static func _static_init() -> void:
	_scaled_theme = ThemeUtils.request_fallback_font(DEFAULT_THEME)
	_scaled_theme = ThemeUtils.generate_scaled_theme(_scaled_theme)


# File system helpers.

## Finds files matching the String.match [code]pattern[/code] in the given directory [code]path[/code], recursively.
static func fs_find(pattern: String = "*", path: String = "res://") -> Array[String]:
	const SEP := "/"

	var result: Array[String] = []
	var is_file := not pattern.ends_with(SEP)

	var dir := DirAccess.open(path)
	var error := DirAccess.get_open_error()
	if error != OK:
		push_error("fs_find: Could not open folder at '%s' for listing (code %d)." % [ path, error ])
		return result

	error = dir.list_dir_begin()
	if error != OK:
		push_error("fs_find: Could not list contents of folder at '%s' (code %d)." % [ path, error ])
		return result

	path = dir.get_next()
	while path.is_valid_filename():
		var new_path: String = dir.get_current_dir().path_join(path)
		if dir.current_is_dir():
			if path.match(pattern.rstrip(SEP)) and not is_file:
				result.push_back(new_path)
			result += fs_find(pattern, new_path)
		elif path.match(pattern):
			result.push_back(new_path)
		path = dir.get_next()
	return result


# Node tree helpers.

static func find_children_by_path(from: Node, paths: Array[String]) -> Array[Node]:
	var result: Array[Node] = []
	if from == null:
		return result

	if from.name in paths:
		result.push_back(from)

	for child in from.find_children("*"):
		if child.owner == from and from.name.path_join(from.get_path_to(child)) in paths:
			result.push_back(child)
	return result


## Finds the owner [EditorDock] node, if the given [param control] is in a dock. Returns
## [code]null[/code] otherwise.
static func get_control_dock_owner(control: Control) -> EditorDock:
	var control_dock: Node = control
	while control_dock:
		if control_dock is EditorDock:
			return control_dock

		control_dock = control_dock.get_parent()

	return null


# Tree helpers.

static func get_tree_item_path(item: TreeItem, column: int = 0) -> String:
	var partial_result: Array[String] = [item.get_text(column)]
	var parent: TreeItem = item.get_parent()
	while parent != null:
		partial_result.push_front(parent.get_text(0))
		parent = parent.get_parent()
	return partial_result.reduce(func(accum: String, p: String) -> String: return accum.path_join(p))


static func filter_tree_items(item: TreeItem, predicate: Callable) -> Array[TreeItem]:
	var go := func(go: Callable, root: TreeItem) -> Array[TreeItem]:
		var result: Array[TreeItem] = []
		if predicate.call(root):
			result.push_back(root)
		for child in root.get_children():
			result.append_array(go.call(go, child))
		return result
	return go.call(go, item)


## Searches children of the root [TreeItem] recursively and returns the first
## one with the given name. Stops at the first match found.
static func find_tree_item_by_name(tree: Tree, name: String) -> TreeItem:
	var root: TreeItem = tree.get_root()
	if root.get_text(0) == name:
		return root

	var result: TreeItem = null
	var stack: Array[TreeItem] = [root]
	while not stack.is_empty():
		var item: TreeItem = stack.pop_back()
		if item.get_text(0) == name:
			result = item
			break

		if item.get_child_count() > 0:
			stack += item.get_children()
	return result


static func unfold_tree_item(item: TreeItem) -> void:
	var parent := item.get_parent()
	if parent != null:
		item = parent

	var tree := item.get_tree()
	while item != tree.get_root():
		item.collapsed = false
		item = item.get_parent()


# ItemList helpers.

## Finds the menu option in the given [PopupMenu] associated with the editor
## shortcut of the given [param shortcut_name]. This matching works even if
## the shortcut has no events associated with it. Returns the option index,
## or [code]-1[/code] if nothing was found.
static func find_menu_option_by_shortcut(popup_menu: PopupMenu, shortcut_name: String) -> int:
	var editor_settings = EditorInterface.get_editor_settings()
	var editor_shortcut := editor_settings.get_shortcut(shortcut_name)
	if not editor_shortcut:
		return -1

	for i in popup_menu.item_count:
		if popup_menu.get_item_shortcut(i) == editor_shortcut:
			return i

	return -1


## Finds and activates the menu option in the given [PopupMenu] associated with
## the editor shortcut of the given [param shortcut_name]. This matching works
## even if the shortcut has no events associated with it.
static func activate_menu_option_by_shortcut(popup_menu: PopupMenu, shortcut_name: String) -> void:
	var editor_settings = EditorInterface.get_editor_settings()
	var editor_shortcut := editor_settings.get_shortcut(shortcut_name)
	if not editor_shortcut:
		return

	for i in popup_menu.item_count:
		if popup_menu.get_item_shortcut(i) == editor_shortcut:
			popup_menu.id_pressed.emit(popup_menu.get_item_id(i))
			break


# Inspector helpers.

## Finds and expands a resource property using the associated property name. This
## is useful when you need to access sub-properties of a resource that are hidden
## when the resource is collapsed in the inspector. Call this methods before using
## [method highlight_inspector_properties].
static func expand_inspector_resource_property(inspector: EditorInspector, property_name: StringName) -> void:
	var all_properties := inspector.find_children("", "EditorProperty", true, false)
	var predicate_name_matches := func predicate_name_matches(p: EditorProperty) -> bool:
		return p.get_edited_property() == property_name

	var matching_index := all_properties.find_custom(predicate_name_matches)
	if matching_index < 0:
		push_warning(
			"expand_inspector_resource_property: Could not find resource property with name '%s' in Inspector. The property could not be expanded." % property_name,
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


# Translation utilities.

## Loads translation resources from the specified path and associates them with
## the given domain name. The domain name specified is turned into a full qualified
## name in the plugin namespace. See [constant TRANSLATION_PLUGIN_DOMAIN].
## Used to load bundled plugin-specific translations.
static func load_plugin_translation(dir_path: String, domain_name: String) -> void:
	var domain := TranslationServer.get_or_add_domain(TRANSLATION_PLUGIN_DOMAIN % domain_name)
	_load_translation(dir_path, domain)


## Loads translation resources from the specified path and associates them with
## the given domain name. The domain name specified is turned into a full qualified
## name in the tour namespace. See [constant TRANSLATION_TOUR_DOMAIN].
## Used to load translations for tours.
static func load_tour_translation(dir_path: String, domain_name: String) -> void:
	var domain := TranslationServer.get_or_add_domain(TRANSLATION_TOUR_DOMAIN % domain_name)
	_load_translation(dir_path, domain)
	_tour_translation_domains.push_back(domain_name)


static func _load_translation(dir_path: String, domain: TranslationDomain) -> void:
	var locale_dir_path := dir_path.path_join(TRANSLATION_LOCAL_DIR)
	if not DirAccess.dir_exists_absolute(locale_dir_path):
		return

	const VALID_EXTENSIONS := ["mo", "po"]

	for file_name in DirAccess.get_files_at(locale_dir_path):
		if file_name.get_extension() not in VALID_EXTENSIONS:
			continue

		var file_path := locale_dir_path.path_join(file_name)
		var locale_translation: Translation = load(file_path)
		if locale_translation:
			domain.add_translation(locale_translation)


## Removes all GDTour translation domains and resources.
static func unload_all_translations() -> void:
	# Unload all plugin translations.
	for key in TranslationDomains:
		var domain_name: String = TranslationDomains[key]
		TranslationServer.remove_domain(TRANSLATION_PLUGIN_DOMAIN % domain_name)

	# Unload all tour translations.
	for domain_name in _tour_translation_domains:
		TranslationServer.remove_domain(TRANSLATION_TOUR_DOMAIN % domain_name)


## Updates project settings to include tour scripts for translation template
## generation.
static func register_translation_pot_files(tour_paths: Array[String]) -> void:
	const SETTING_KEY := "internationalization/locale/translations_pot_files"
	var pot_files_setting := ProjectSettings.get_setting(SETTING_KEY, PackedStringArray())

	for file_path in tour_paths:
		if file_path.is_empty() or file_path in pot_files_setting:
			continue

		pot_files_setting.push_back(file_path)

	ProjectSettings.set_setting(SETTING_KEY, pot_files_setting)
	ProjectSettings.save()


## Updates the given node to use a translation domain from the plugin namespace.
static func set_plugin_translation_domain(node: Node, domain_name: String) -> void:
	node.set_translation_domain(TRANSLATION_PLUGIN_DOMAIN % domain_name)


## Updates the given node to use a translation domain from the tour namespace.
static func set_tour_translation_domain(node: Node, domain_name: String) -> void:
	node.set_translation_domain(TRANSLATION_TOUR_DOMAIN % domain_name)


## Returns a translation remapping for the given path, if available. Otherwise,
## returns the original path.
static func get_translation_remapped_path(path: String) -> String:
	# FIXME: For some reasons remaps do not work in editor. I can't find any code
	# that would prevent them from working in the editor, so this might be fixable
	# to remove these manual checks.

	var translation_remaps := ProjectSettings.get_setting("internationalization/locale/translation_remaps")
	var suffix := ":%s" % TranslationServer.get_locale()

	var path_remaps: Array = translation_remaps.get(path, [])
	for remap_key: String in path_remaps:
		if remap_key.ends_with(suffix):
			return remap_key.trim_suffix(suffix)

	return path


# Theme utilities.

static func get_default_theme() -> Theme:
	return _scaled_theme


## Associates the icon with a fake resource path for RichTextLabel to use.
## This should work for the foreseeable future, as long as resources are
## allowed to take over paths before saving. In case this no longer works,
## this can be changed to actually save the file (e.g. to res://.godot/
## somewhere).
static func precache_icon_image(icon_name: String) -> bool:
	const EDITOR_ICONS := "EditorIcons"

	var editor_theme := EditorInterface.get_editor_theme()
	if not editor_theme.has_icon(icon_name, EDITOR_ICONS):
		return false

	var icon_path := "editor://theme_icons/%s" % icon_name
	if not ResourceLoader.exists(icon_path):
		# Making a copy allows us to change the base scale, so the icon looks
		# crisp at any size we need.
		var icon := editor_theme.get_icon(icon_name, EDITOR_ICONS)
		var scaled_icon := icon.duplicate()
		(scaled_icon as DPITexture).base_scale = 3.0

		_scaled_icons_cache[icon_name] = scaled_icon # Keeping a reference alive.
		scaled_icon.resource_path = icon_path
		scaled_icon.take_over_path(scaled_icon.resource_path)

	return true
