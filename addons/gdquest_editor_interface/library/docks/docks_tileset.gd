@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


## The dock is only visible after the user has selected a TileMapLayer
## node with a valid TileSet resource, or opened/expanded a TileSet
## resource directly in the Inspector.
class TileSetDockDef extends Types.Definition:
	func _init() -> void:
		node_type = "TileSetEditor"
		prefetch_references = [
			Enums.NodePoint.LAYOUT_ROOT,
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

		var custom_script := func(base_node: Node) -> Node:
			var dock_locations := Utils.dock_get_locations()
			for dock_container in dock_locations:
				var dock := dock_container.find_child("TileSet", false, false)
				if dock:
					return dock

			return null

		resolver_steps = [
			Types.DoCustomStep.new(custom_script),
		]


class TileSetDockTabsDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabBar"
		base_reference = Enums.NodePoint.TILE_SET_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.GetChildTypeStep.new("PanelContainer", 0),
			Types.GetChildTypeStep.new("TabBar", 0),
			Types.HasTabsNamesStep.new([ "Tile Sources", "Patterns" ], true),
		]


# Content roots of the TileSet editor's tabs and dialogs.

class TileSetTilesPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "HSplitContainer"
		base_reference = Enums.NodePoint.TILE_SET_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetNodePathStep.new("Tiles", true),
		]


class TileSetPatternsPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "MarginContainer"
		base_reference = Enums.NodePoint.TILE_SET_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("MarginContainer", 0),
		]


class TileSetAtlasMergingDialogDef extends Types.Definition:
	func _init() -> void:
		node_type = "AtlasMergingDialog"
		base_reference = Enums.NodePoint.TILE_SET_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("AtlasMergingDialog", 0),
		]


class TileSetTileProxiesManagerDef extends Types.Definition:
	func _init() -> void:
		node_type = "TileProxiesManagerDialog"
		base_reference = Enums.NodePoint.TILE_SET_DOCK

		resolver_steps = [
			Types.GetChildTypeStep.new("TileProxiesManagerDialog", 0),
		]


# The tile sources tab of the TileSet editor. It is split into three
# panels. The left-most contains a list of sources, the middle one
# allows to select tools and configure selected source, and the right-
# most presents a visual mode for selecting and drawing.
#
# The second and third panels differ depending on the source kind, if
# it's an atlas or a scenes collection.

class TileSetTilesSourcesListDef extends Types.Definition:
	func _init() -> void:
		node_type = "TileSetSourceItemList"
		base_reference = Enums.NodePoint.TILE_SET_TILES_PANEL

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("TileSetSourceItemList"),
		]


class TileSetTilesSourcesListButtonsDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.TILE_SET_TILES_PANEL

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
		]


class TileSetTilesSourcesListDeleteButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SOURCES_LIST_BUTTONS

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 0),
		]


class TileSetTilesSourcesListAddButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuButton"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SOURCES_LIST_BUTTONS

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 1),
		]


class TileSetTilesSourcesListMenuButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuButton"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SOURCES_LIST_BUTTONS

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 2),
		]


class TileSetTilesSourcesListSortButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuButton"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SOURCES_LIST_BUTTONS

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 3),
		]


# Atlas editor.

class TileSetTilesAtlasEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "TileSetAtlasSourceEditor"
		base_reference = Enums.NodePoint.TILE_SET_TILES_PANEL

		resolver_steps = [
			Types.GetChildIndexStep.new(1),
			Types.GetChildTypeStep.new("TileSetAtlasSourceEditor"),
		]


# Atlas configuration panel.

class TileSetTilesAtlasEditorTabsDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
		]


class TileSetTilesAtlasEditorSetupButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR_TABS

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.HasEditorIconStep.new("Tools"),
		]


class TileSetTilesAtlasEditorSelectButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR_TABS

		resolver_steps = [
			Types.GetChildIndexStep.new(1),
			Types.HasEditorIconStep.new("ToolSelect"),
		]


class TileSetTilesAtlasEditorPaintButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR_TABS

		resolver_steps = [
			Types.GetChildIndexStep.new(2),
			Types.HasEditorIconStep.new("Paint"),
		]


class TileSetTilesAtlasEditorSetupPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorInspector"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("EditorInspector", 1),
		]


class TileSetTilesAtlasEditorSelectPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorInspector"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("EditorInspector", 0),
		]


class TileSetTilesAtlasEditorPaintPanelDef extends Types.Definition:
	func _init() -> void:
		node_type = "ScrollContainer"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("ScrollContainer", 0),
		]


# Atlas preview panel.

class TileSetTilesAtlasEditorToolbarsDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR

		resolver_steps = [
			Types.GetChildIndexStep.new(1),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
		]


class TileSetTilesAtlasEditorSetupToolbarEraseButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR_TOOLBARS

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 0),
		]


class TileSetTilesAtlasEditorSetupToolbarMenuButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuButton"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR_TOOLBARS

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 1),
		]


# NOTE: When the paint mode is selected, a bunch of toolbars with buttons,
# one for every property editor, I think, is added to the toolbar container.
# Toolbars are added the moment the paint mode is selected, but become visible
# when property/tile data editor is selected.
# Toolbars stay around after they first appear, but can also be removed later.
class TileSetTilesAtlasEditorPaintToolbarsDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR_TOOLBARS

		resolver_steps = [
			Types.GetChildTypeStep.new("HBoxContainer", 0),
		]


class TileSetTilesAtlasEditorAtlasViewDef extends Types.Definition:
	func _init() -> void:
		node_type = "TileAtlasView"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR

		resolver_steps = [
			Types.GetChildIndexStep.new(1),
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("TileAtlasView"),
		]


class TileSetTilesAtlasEditorAtlasViewZoomWidgetDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorZoomWidget"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR_ATLAS_VIEW

		resolver_steps = [
			Types.GetChildTypeStep.new("EditorZoomWidget", 0),
		]


class TileSetTilesAtlasEditorAtlasViewCenterButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.TILE_SET_TILES_ATLAS_EDITOR_ATLAS_VIEW

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 0),
			Types.HasEditorIconStep.new("CenterView"),
		]


# Scenes collection editor.

class TileSetTilesScenesCollectionEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "TileSetScenesCollectionSourceEditor"
		base_reference = Enums.NodePoint.TILE_SET_TILES_PANEL

		resolver_steps = [
			Types.GetChildIndexStep.new(1),
			Types.GetChildTypeStep.new("TileSetScenesCollectionSourceEditor"),
		]


# Scenes collection properties panel.

class TileSetTilesScenesCollectionEditorPropertiesDef extends Types.Definition:
	func _init() -> void:
		node_type = "ScrollContainer"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SCENES_COLLECTION_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("HSplitContainer", 0),
			Types.GetChildIndexStep.new(0),
		]


class TileSetTilesScenesCollectionEditorPropertiesSceneDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorInspector"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SCENES_COLLECTION_EDITOR_PROPERTIES

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("EditorInspector", 0),
		]


class TileSetTilesScenesCollectionEditorPropertiesTileDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorInspector"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SCENES_COLLECTION_EDITOR_PROPERTIES

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
			Types.GetChildTypeStep.new("EditorInspector", 1),
		]


# Scenes collection scene list.

class TileSetTilesScenesCollectionEditorScenesDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SCENES_COLLECTION_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("HSplitContainer", 0),
			Types.GetChildIndexStep.new(1),
		]


class TileSetTilesScenesCollectionEditorScenesListDef extends Types.Definition:
	func _init() -> void:
		node_type = "ItemList"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SCENES_COLLECTION_EDITOR_SCENES

		resolver_steps = [
			Types.GetChildTypeStep.new("ItemList"),
		]


class TileSetTilesScenesCollectionEditorScenesButtonsDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SCENES_COLLECTION_EDITOR_SCENES

		resolver_steps = [
			Types.GetChildTypeStep.new("HBoxContainer"),
		]


class TileSetTilesScenesCollectionEditorScenesAddButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SCENES_COLLECTION_EDITOR_SCENES_BUTTONS

		resolver_steps = [
			Types.GetChildIndexStep.new(0),
		]


class TileSetTilesScenesCollectionEditorScenesDeleteButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.TILE_SET_TILES_SCENES_COLLECTION_EDITOR_SCENES_BUTTONS

		resolver_steps = [
			Types.GetChildIndexStep.new(1),
		]


# The patterns tab of the TileSet editor. There is only the main panel
# in this view.

class TileSetPatternsListDef extends Types.Definition:
	func _init() -> void:
		node_type = "ItemList"
		base_reference = Enums.NodePoint.TILE_SET_PATTERNS_PANEL

		resolver_steps = [
			Types.GetChildTypeStep.new("ItemList"),
		]
