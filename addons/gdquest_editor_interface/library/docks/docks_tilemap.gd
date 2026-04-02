@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


## The dock is only visible after the user has selected a TileMapLayer
## node.
class TileMapDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "TileMapLayerEditor"

		var custom_script := func(base_node: Node) -> Node:
			var st := EditorInterface.get_base_control().get_tree()
			return Utils.object_get_signal_type(st, "node_removed", "TileMapLayerEditor")

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class TileMapDockTabsDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabBar"
		base_reference = Enums.NodePoint.TILE_MAP_DOCK

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("FlowContainer", 0),
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("TabBar", 0),
			Types.HasTabsNamesStep.new([ "Tiles", "Patterns", "Terrains" ], true),
		]


# Handle all toolbars together, due to the complex layout of the panel.
class TileMapToolbarsDef extends Types.MultiDefinition:
	func _init() -> void:
		node_type_map = {
			Enums.NodePoint.TILE_MAP_COMMON_TOOLBAR_PREVIOUS_BUTTON:      "Button",
			Enums.NodePoint.TILE_MAP_COMMON_TOOLBAR_NEXT_BUTTON:          "Button",
			Enums.NodePoint.TILE_MAP_COMMON_TOOLBAR_SELECT_LAYER_BUTTON:  "OptionButton", # For the deprecated TileMap node.
			Enums.NodePoint.TILE_MAP_COMMON_TOOLBAR_SELECT_ALL_BUTTON:    "Button",
			Enums.NodePoint.TILE_MAP_COMMON_TOOLBAR_HIGHLIGHT_BUTTON:     "Button",
			Enums.NodePoint.TILE_MAP_COMMON_TOOLBAR_GRID_BUTTON:          "Button",
			Enums.NodePoint.TILE_MAP_COMMON_TOOLBAR_MENU_BUTTON:          "MenuButton",

			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_SELECT_BUTTON:        "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_PAINT_BUTTON:         "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_LINE_BUTTON:          "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_RECT_BUTTON:          "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_BUCKET_BUTTON:        "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_PICKER_BUTTON:        "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_ERASER_BUTTON:        "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_ROTATE_LEFT_BUTTON:   "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_ROTATE_RIGHT_BUTTON:  "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_FLIP_H_BUTTON:        "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_FLIP_V_BUTTON:        "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_CONTIGUOUS_BUTTON:    "Button",
			Enums.NodePoint.TILE_MAP_TILES_TOOLBAR_RANDOM_BUTTON:        "Button",

			Enums.NodePoint.TILE_MAP_TERRAINS_TOOLBAR_PAINT_BUTTON:       "Button",
			Enums.NodePoint.TILE_MAP_TERRAINS_TOOLBAR_LINE_BUTTON:        "Button",
			Enums.NodePoint.TILE_MAP_TERRAINS_TOOLBAR_RECT_BUTTON:        "Button",
			Enums.NodePoint.TILE_MAP_TERRAINS_TOOLBAR_BUCKET_BUTTON:      "Button",
			Enums.NodePoint.TILE_MAP_TERRAINS_TOOLBAR_PICKER_BUTTON:      "Button",
			Enums.NodePoint.TILE_MAP_TERRAINS_TOOLBAR_ERASER_BUTTON:      "Button",
			Enums.NodePoint.TILE_MAP_TERRAINS_TOOLBAR_CONTIGUOUS_BUTTON:  "CheckBox",
		}
		base_reference = Enums.NodePoint.TILE_MAP_DOCK

		# Resolve all buttons at the same time using custom heuristics.
		var custom_script := func(base_nodes: Array[Node]) -> Array[Node]:
			if base_nodes.is_empty():
				return []

			var results: Array[Node] = []
			results.resize(node_type_map.size())
			results.fill(null)

			# Sift through all buttons in the main container (and descendants),
			# and organize them into 3 piles. We use everything we can, — order,
			# editor theme icons, and signal connections, — to disambiguate them.

			var editor_theme := EditorInterface.get_editor_theme()
			var editor_icon_names := editor_theme.get_icon_list("EditorIcons")
			var button_signals: Array[String] = ["pressed", "toggled", "item_selected", "id_pressed"]

			var toolbar_container := base_nodes[0]
			var toolbar_buttons := toolbar_container.find_children("", "Button", true, false)
			var toolbar_context := ""

			var tilemap_layers_buttons: Dictionary[String, Button] = { }
			var tilemap_tiles_buttons: Dictionary[String, Button] = { }
			var tilemap_terrains_buttons: Dictionary[String, Button] = { }

			# The main sorting routine.
			for button: Button in toolbar_buttons:
				# Resolve button key for reference.
				# First, check the icon against the theme.
				var button_key := ""
				if button.icon:
					for icon_name in editor_icon_names:
						if editor_theme.get_icon(icon_name, "EditorIcons") == button.icon:
							button_key = icon_name
							break
				# Then handle special cases.
				if button is CheckBox:
					button_key = "Contiguous"
				if button is OptionButton:
					button_key = "SelectLayer"

				# Resolve context name for reference.
				# Find the owner class via signal connections.
				var context_key := ""
				var signal_connections: Array[Dictionary] = []
				for signal_name in button_signals:
					if button.has_signal(signal_name):
						signal_connections.append_array(button[signal_name].get_connections())

				for connection_info in signal_connections:
					var related_object := (connection_info.callable as Callable).get_object()
					var related_type := related_object.get_class()
					if related_type.begins_with("TileMap"):
						context_key = related_type
						break

				if not context_key.is_empty():
					toolbar_context = context_key

				match toolbar_context:
					"TileMapLayerEditor":
						tilemap_layers_buttons[button_key] = button
					"TileMapLayerEditorTilesPlugin":
						tilemap_tiles_buttons[button_key] = button
					"TileMapLayerEditorTerrainsPlugin":
						tilemap_terrains_buttons[button_key] = button

			# Now map sorted buttons to the results.

			results[0] = tilemap_layers_buttons["MoveUp"]
			results[1] = tilemap_layers_buttons["MoveDown"]
			results[2] = tilemap_layers_buttons["SelectLayer"]
			results[3] = tilemap_layers_buttons["FileList"]
			results[4] = tilemap_layers_buttons["TileMapHighlightSelected"]
			results[5] = tilemap_layers_buttons["Grid"]
			results[6] = tilemap_layers_buttons["Tools"]

			results[7] = tilemap_tiles_buttons["ToolSelect"]
			results[8] = tilemap_tiles_buttons["Edit"]
			results[9] = tilemap_tiles_buttons["Line"]
			results[10] = tilemap_tiles_buttons["Rectangle"]
			results[11] = tilemap_tiles_buttons["Bucket"]
			results[12] = tilemap_tiles_buttons["ColorPick"]
			results[13] = tilemap_tiles_buttons["Eraser"]
			results[14] = tilemap_tiles_buttons["RotateLeft"]
			results[15] = tilemap_tiles_buttons["RotateRight"]
			results[16] = tilemap_tiles_buttons["MirrorX"]
			results[17] = tilemap_tiles_buttons["MirrorY"]
			results[18] = tilemap_tiles_buttons["Contiguous"]
			results[19] = tilemap_tiles_buttons["RandomNumberGenerator"]

			results[20] = tilemap_terrains_buttons["Edit"]
			results[21] = tilemap_terrains_buttons["Line"]
			results[22] = tilemap_terrains_buttons["Rectangle"]
			results[23] = tilemap_terrains_buttons["Bucket"]
			results[24] = tilemap_terrains_buttons["ColorPick"]
			results[25] = tilemap_terrains_buttons["Eraser"]
			results[26] = tilemap_terrains_buttons["Contiguous"]

			return results

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("FlowContainer", 0),
			Types.DoCustomMultiStep.new(custom_script),
		]

class TileMapCommonToolbarPreviousButtonDef      extends TileMapToolbarsDef: pass
class TileMapCommonToolbarNextButtonDef          extends TileMapToolbarsDef: pass
class TileMapCommonToolbarSelectLayerButtonDef   extends TileMapToolbarsDef: pass
class TileMapCommonToolbarSelectAllButtonDef     extends TileMapToolbarsDef: pass
class TileMapCommonToolbarHighlightButtonDef     extends TileMapToolbarsDef: pass
class TileMapCommonToolbarGridButtonDef          extends TileMapToolbarsDef: pass
class TileMapCommonToolbarMenuButtonDef          extends TileMapToolbarsDef: pass

class TileMapTilesToolbarSelectButtonDef         extends TileMapToolbarsDef: pass
class TileMapTilesToolbarPaintButtonDef          extends TileMapToolbarsDef: pass
class TileMapTilesToolbarLineButtonDef           extends TileMapToolbarsDef: pass
class TileMapTilesToolbarRectButtonDef           extends TileMapToolbarsDef: pass
class TileMapTilesToolbarBucketButtonDef         extends TileMapToolbarsDef: pass
class TileMapTilesToolbarPickerButtonDef         extends TileMapToolbarsDef: pass
class TileMapTilesToolbarEraserButtonDef         extends TileMapToolbarsDef: pass
class TileMapTilesToolbarRotateLeftButtonDef     extends TileMapToolbarsDef: pass
class TileMapTilesToolbarRotateRightButtonDef    extends TileMapToolbarsDef: pass
class TileMapTilesToolbarFlipHButtonDef          extends TileMapToolbarsDef: pass
class TileMapTilesToolbarFlipVButtonDef          extends TileMapToolbarsDef: pass
class TileMapTilesToolbarContiguousButtonDef     extends TileMapToolbarsDef: pass
class TileMapTilesToolbarRandomButtonDef         extends TileMapToolbarsDef: pass

class TileMapTerrainsToolbarPaintButtonDef       extends TileMapToolbarsDef: pass
class TileMapTerrainsToolbarLineButtonDef        extends TileMapToolbarsDef: pass
class TileMapTerrainsToolbarRectButtonDef        extends TileMapToolbarsDef: pass
class TileMapTerrainsToolbarBucketButtonDef      extends TileMapToolbarsDef: pass
class TileMapTerrainsToolbarPickerButtonDef      extends TileMapToolbarsDef: pass
class TileMapTerrainsToolbarEraserButtonDef      extends TileMapToolbarsDef: pass
class TileMapTerrainsToolbarContiguousButtonDef  extends TileMapToolbarsDef: pass


# Content roots of the TileMap editor's tabs.

class TileMapTilesPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.TILE_MAP_DOCK

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("Tiles", true),
		]


class TileMapPatternsPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "MarginContainer"
		base_reference = Enums.NodePoint.TILE_MAP_DOCK

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("Patterns", true),
		]


class TileMapTerrainsPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "BoxContainer"
		base_reference = Enums.NodePoint.TILE_MAP_DOCK

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetNodePathStep.new("Terrains", true),
		]


# The tiles tab of the TileMap editor. On the left there is a list of
# sources, and on the right there is a panel for viewing and selecting
# the tile set.

class TileMapTilesSourcesListDef extends Types.Definition:
	func _init() -> void:
		node_type = "TileSetSourceItemList"
		base_reference = Enums.NodePoint.TILE_MAP_TILES_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("BoxContainer", 0),
			Types.GetChildTypeStep.new("TileSetSourceItemList", 0),
		]


class TileMapTilesSourcesListSortButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuButton"
		base_reference = Enums.NodePoint.TILE_MAP_TILES_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("BoxContainer", 0),
			Types.GetChildTypeStep.new("Button", 0),
		]


class TileMapTilesAtlasViewDef extends Types.Definition:
	func _init() -> void:
		node_type = "TileAtlasView"
		base_reference = Enums.NodePoint.TILE_MAP_TILES_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("TileAtlasView", 0),
		]


class TileMapTilesAtlasViewZoomWidgetDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorZoomWidget"
		base_reference = Enums.NodePoint.TILE_MAP_TILES_ATLAS_VIEW

		resolver_steps = [
			Types.GetChildTypeStep.new("EditorZoomWidget", 0),
		]


class TileMapTilesAtlasViewCenterButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.TILE_MAP_TILES_ATLAS_VIEW

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 0),
			Types.HasEditorIconStep.new("CenterView"),
		]


class TileMapTilesScenesListDef extends Types.Definition:
	func _init() -> void:
		node_type = "ItemList"
		base_reference = Enums.NodePoint.TILE_MAP_TILES_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("SplitContainer", 0),
			Types.GetChildTypeStep.new("ItemList", 0),
		]


# The patterns tab of the TileMap editor. There is only the main panel
# in this view.

class TileMapPatternsListDef extends Types.Definition:
	func _init() -> void:
		node_type = "ItemList"
		base_reference = Enums.NodePoint.TILE_MAP_PATTERNS_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("ItemList"),
		]


# The terrains tab of the TileMap editor. On the left there is a list of
# terrains, and on the right there is a panel for viewing and selecting
# the tile set.

class TileMapTerrainsSetsListDef extends Types.Definition:
	func _init() -> void:
		node_type = "Tree"
		base_reference = Enums.NodePoint.TILE_MAP_TERRAINS_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("SplitContainer"),
			Types.GetChildTypeStep.new("Tree"),
		]


class TileMapTerrainsTilesListDef extends Types.Definition:
	func _init() -> void:
		node_type = "ItemList"
		base_reference = Enums.NodePoint.TILE_MAP_TERRAINS_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("SplitContainer"),
			Types.GetChildTypeStep.new("ItemList"),
		]
