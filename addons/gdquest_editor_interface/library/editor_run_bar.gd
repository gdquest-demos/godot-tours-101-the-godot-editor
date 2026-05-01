@tool

const Enums := preload("../utils/eia_enums.gd")
const Types := preload("../utils/eia_resolver_types.gd")
const Utils := preload("../utils/eia_resolver_utils.gd")


## Run bar panel in the top-right corner of the editor window.
class RunBarDef extends Types.Definition:
	func _init() -> void:
		node_type = "EditorRunBar"
		base_reference = Enums.NodePoint.LAYOUT_TITLE_BAR

		resolver_steps = [
			Types.GetChildTypeStep.new("EditorRunBar"),
		]


## All buttons present in the run bar, resolved together.
class RunBarButtonsDef extends Types.MultiDefinition:
	func _init() -> void:
		node_type_map = {
			Enums.NodePoint.RUN_BAR_PLAY_BUTTON:           "Button",
			Enums.NodePoint.RUN_BAR_PAUSE_BUTTON:          "Button",
			Enums.NodePoint.RUN_BAR_STOP_BUTTON:           "Button",
			Enums.NodePoint.RUN_BAR_PLAY_CURRENT_BUTTON:   "Button", # Can be MenuButton in XR projects
			Enums.NodePoint.RUN_BAR_PLAY_CUSTOM_BUTTON:    "Button", # Can be MenuButton in XR projects
			Enums.NodePoint.RUN_BAR_MOVIE_MODE_BUTTON:     "MenuButton",
		}
		base_reference = Enums.NodePoint.RUN_BAR

		# Resolve all buttons at the same time using custom heuristics.
		var custom_script := func(base_nodes: Array[Node]) -> Array[Node]:
			if base_nodes.is_empty():
				return []

			var results: Array[Node] = []
			results.resize(node_type_map.size())
			results.fill(null)

			var run_bar := base_nodes[0]
			var run_bar_buttons := run_bar.find_children("", "Button", true, false)

			# Our main tool to resolve buttons is checking signal connections and
			# referencing unique methods connected to them. Works for MenuButton
			# popups too.

			for button: Button in run_bar_buttons:
				if button is MenuButton:
					var popup_menu := (button as MenuButton).get_popup()

					if Utils.node_has_signal_callable(popup_menu, "id_pressed", "EditorRunBar::_play_current_pressed"):
						results[3] = button
					elif Utils.node_has_signal_callable(popup_menu, "id_pressed", "EditorRunBar::_play_custom_pressed"):
						results[4] = button
					elif Utils.node_has_signal_callable(popup_menu, "id_pressed", "EditorRunBar::_movie_maker_item_pressed"):
						results[5] = button

				else:
					if Utils.node_has_signal_callable(button, "pressed", "EditorRunBar::play_main_scene"):
						results[0] = button
					elif Utils.node_has_signal_callable(button, "pressed", "EditorDebuggerNode::_paused"):
						results[1] = button
					elif Utils.node_has_signal_callable(button, "pressed", "EditorRunBar::stop_playing"):
						results[2] = button
					elif Utils.node_has_signal_callable(button, "pressed", "EditorRunBar::_play_current_pressed"):
						results[3] = button
					elif Utils.node_has_signal_callable(button, "pressed", "EditorRunBar::_play_custom_pressed"):
						results[4] = button

			return results

		resolver_steps = [
			Types.DoCustomMultiStep.new(custom_script),
		]

class RunBarPlayButtonDef          extends RunBarButtonsDef: pass
class RunBarPauseButtonDef         extends RunBarButtonsDef: pass
class RunBarStopButtonDef          extends RunBarButtonsDef: pass
class RunBarPlayCurrentButtonDef   extends RunBarButtonsDef: pass
class RunBarPlayCustomButtonDef    extends RunBarButtonsDef: pass
class RunBarMovieModeButtonDef     extends RunBarButtonsDef: pass
