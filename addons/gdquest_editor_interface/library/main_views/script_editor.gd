@tool

const Enums := preload("../../utils/eia_enums.gd")
const Types := preload("../../utils/eia_resolver_types.gd")
const Utils := preload("../../utils/eia_resolver_utils.gd")


## The root node of the script editor and class reference view.
## Even if it is disabled via engine feature profiles, the node
## is present in the tree, at the exact same spot.
class ScriptEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "ScriptEditor"
		base_reference = Enums.NodePoint.MAIN_VIEW_CONTAINER_BOX

		resolver_steps = [
			Types.GetChildTypeStep.new("WindowWrapper", 0),
			Types.GetWindowWrappedTypeStep.new("ScriptEditor"),
		]


# Toolbar elements.

class ScriptEditorToolbarDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR

		resolver_steps = [
			Types.GetChildIndexStep.new(0), # Layout root.
			Types.GetChildTypeStep.new("HBoxContainer", 0),
		]

# NOTE: Menu buttons exist as individual buttons and not a menu bar
# control. So unlike the main editor menu bar, we resolve buttons here
# and not popups. Popups, of course, can also be resolved, if needed.

class ScriptEditorToolbarFileMenuButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuButton"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 0),
		]


# NOTE: This "Search" button is the default one, but depending on the
# currently open tab of the script editor it may be hidden, and a different
# set of menu buttons is displayed in its place (including another button
# also called "Search"). These secondary sets of buttons are dynamic and
# managed by existing script/text editors, and cannot be resolved statically.
class ScriptEditorToolbarSearchMenuButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuButton"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 1),
		]


class ScriptEditorToolbarDebugMenuButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "MenuButton"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 2),
		]


class ScriptEditorToolbarCurrentLabelDef extends Types.Definition:
	func _init() -> void:
		node_type = "Label"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("Label", 0),
		]


class ScriptEditorToolbarOnlineDocsButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 3),
			Types.HasEditorIconStep.new("ExternalLink"),
		]


class ScriptEditorToolbarSearchHelpButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 4),
			Types.HasEditorIconStep.new("HelpSearch"),
		]


# NOTE: Back and forth buttons inverse their icons in the RTL mode, so we
# cannot rely on that.

class ScriptEditorToolbarNavigateBackButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 5),
			Types.HasSignalCallableStep.new("pressed", "ScriptEditor::_history_back"),
		]


class ScriptEditorToolbarNavigateForwardButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 6),
			Types.HasSignalCallableStep.new("pressed", "ScriptEditor::_history_forward"),
		]


class ScriptEditorToolbarMakeFloatingButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "ScreenSelect"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_TOOLBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("ScreenSelect"),
		]


# Sidebar elements.

class ScriptEditorSidebarDef extends Types.Definition:
	func _init() -> void:
		node_type = "VSplitContainer"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR

		resolver_steps = [
			Types.GetChildIndexStep.new(0), # Layout root.
			Types.GetChildTypeStep.new("HSplitContainer", 0),
			Types.GetChildTypeStep.new("VSplitContainer", 0),
		]


class ScriptEditorScriptListDef extends Types.Definition:
	func _init() -> void:
		node_type = "ItemList"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_SIDEBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("ItemList"),
		]


class ScriptEditorScriptListFilterDef extends Types.Definition:
	func _init() -> void:
		node_type = "LineEdit"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_SIDEBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 0),
			Types.GetChildTypeStep.new("LineEdit"),
		]


class ScriptEditorCurrentScriptIndexDef extends Types.Definition:
	func _init() -> void:
		node_type = "ItemList"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_SIDEBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 1),
			Types.GetChildTypeStep.new("ItemList", 0),
		]


class ScriptEditorCurrentScriptIndexFilterDef extends Types.Definition:
	func _init() -> void:
		node_type = "LineEdit"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_SIDEBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 1),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.GetChildTypeStep.new("LineEdit"),
		]


class ScriptEditorCurrentScriptIndexSortButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_SIDEBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 1),
			Types.GetChildTypeStep.new("HBoxContainer", 0),
			Types.GetChildTypeStep.new("Button"),
		]


class ScriptEditorCurrentDocsIndexDef extends Types.Definition:
	func _init() -> void:
		node_type = "ItemList"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_SIDEBAR

		resolver_steps = [
			Types.GetChildTypeStep.new("VBoxContainer", 1),
			Types.GetChildTypeStep.new("ItemList", 1),
		]


# Script editor content.

class ScriptEditorContainerDef extends Types.Definition:
	func _init() -> void:
		node_type = "VBoxContainer"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR

		resolver_steps = [
			Types.GetChildIndexStep.new(0), # Layout root.
			Types.GetChildTypeStep.new("HSplitContainer", 0),
			Types.GetChildTypeStep.new("VBoxContainer", 0),
		]


class ScriptEditorContainerTabsDef extends Types.Definition:
	func _init() -> void:
		node_type = "TabContainer"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_CONTAINER

		resolver_steps = [
			Types.GetChildTypeStep.new("TabContainer"),
		]


class ScriptEditorContainerFindReplaceBarDef extends Types.Definition:
	func _init() -> void:
		node_type = "FindReplaceBar"
		base_reference = Enums.NodePoint.SCRIPT_EDITOR_CONTAINER

		resolver_steps = [
			Types.GetChildTypeStep.new("FindReplaceBar"),
		]


# Reusable components.

class ScriptTextEditorCodeEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "CodeTextEditor"
		relative_node_type = "ScriptTextEditor"

		resolver_steps = [
			Types.GetChildTypeStep.new("VSplitContainer", 0),
			Types.GetChildTypeStep.new("CodeTextEditor"),
		]


class ScriptTextEditorCodeEditorCodeEditDef extends Types.Definition:
	func _init() -> void:
		node_type = "CodeEdit"
		relative_node_type = "ScriptTextEditor"
		base_reference = Enums.NodePoint.SCRIPT_TEXT_EDITOR_CODE_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("CodeEdit"),
		]


class ScriptTextEditorCodeEditorFooterBarDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		relative_node_type = "ScriptTextEditor"
		base_reference = Enums.NodePoint.SCRIPT_TEXT_EDITOR_CODE_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("HBoxContainer", 0),
		]


class TextEditorCodeEditorDef extends Types.Definition:
	func _init() -> void:
		node_type = "CodeTextEditor"
		relative_node_type = "TextEditor"

		resolver_steps = [
			Types.GetChildTypeStep.new("CodeTextEditor"),
		]


class TextEditorCodeEditorCodeEditDef extends Types.Definition:
	func _init() -> void:
		node_type = "CodeEdit"
		relative_node_type = "TextEditor"
		base_reference = Enums.NodePoint.TEXT_EDITOR_CODE_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("CodeEdit"),
		]


class TextEditorCodeEditorFooterBarDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		relative_node_type = "TextEditor"
		base_reference = Enums.NodePoint.TEXT_EDITOR_CODE_EDITOR

		resolver_steps = [
			Types.GetChildTypeStep.new("HBoxContainer", 0),
		]


class EditorHelpRichTextDef extends Types.Definition:
	func _init() -> void:
		node_type = "RichTextLabel"
		relative_node_type = "EditorHelp"

		resolver_steps = [
			Types.GetChildTypeStep.new("RichTextLabel"),
		]


class EditorHelpFindBarDef extends Types.Definition:
	func _init() -> void:
		node_type = "FindBar"
		relative_node_type = "EditorHelp"

		resolver_steps = [
			Types.GetChildTypeStep.new("FindBar"),
		]


class EditorHelpFooterBarDef extends Types.Definition:
	func _init() -> void:
		node_type = "HBoxContainer"
		relative_node_type = "EditorHelp"

		resolver_steps = [
			Types.GetChildTypeStep.new("HBoxContainer", -1),
		]


class EditorHelpFooterSidebarButtonDef extends Types.Definition:
	func _init() -> void:
		node_type = "Button"
		relative_node_type = "EditorHelp"
		base_reference = Enums.NodePoint.EDITOR_HELP_FOOTER_BAR

		resolver_steps = [
			Types.GetChildTypeStep.new("Button", 0),
			Types.HasSignalCallableStep.new("pressed", "EditorHelp::_toggle_files_pressed"),
		]
