## Panel that appears when running Godot with a debug flag (see [CLI_OPTION_DEBUG] constant below).
## Provides controls to change the opacity and visibility of the overlays and dimmers,
## as well as a list of available tours.
@tool
extends PanelContainer

const GDTourMetadata := preload("../gdtour_metadata.gd")
const Overlays := preload("../overlays/overlays.gd")
const Tour := preload("../tour.gd")

var ResourceInvalidator := preload("resource_invalidator.gd")

## If Godot is run with this flag, the tour will be run in debug mode, displaying this debugger panel.
const CLI_OPTION_DEBUG := "--tour-debug"
const DIMMER_GROUP: StringName = "dimmer"

var series_metadata: GDTourMetadata = null
## Reference to the currently active tour running in debug mode.
var tour: Tour = null:
	set(new_tour):
		tour = new_tour
		if tour != null and button_toggle_tour_visible != null:
			button_toggle_tour_visible.disabled = tour == null
			button_toggle_tour_visible.toggled.connect(tour.toggle_visible)

var plugin_path := ""
var overlays: Overlays = null

@onready var toggle_dimmers_check_button: CheckButton = %ToggleDimmersCheckButton
@onready var toggle_bubble_check_button: CheckButton = %ToggleBubbleCheckButton
@onready var dimmers_alpha_h_slider: HSlider = %OverlaysAlphaHSlider
@onready var tours_item_list: ItemList = %ToursItemList
@onready var jump_button: Button = %JumpButton
@onready var jump_spin_box: SpinBox = %JumpSpinBox
@onready var button_toggle_tour_visible: CheckButton = %ButtonToggleTourVisible
@onready var button_start_tour: Button = %ButtonStartTour
@onready var debug_mode_check_button: CheckButton = %DebugModeCheckButton

var _debug_mode_toggled_signal: Signal


func setup(plugin_path: String, overlays: Overlays, series_metadata: GDTourMetadata, tour: Tour, debug_mode_toggled_signal: Signal) -> void:
	self.plugin_path = plugin_path
	self.overlays = overlays
	self.series_metadata = series_metadata
	self.tour = tour
	_debug_mode_toggled_signal = debug_mode_toggled_signal
	debug_mode_toggled_signal.connect(set_is_debug_mode)


func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	overlays.cleaned_up.connect(overlays.add_highlight_to_control.bind(self))
	toggle_dimmers_check_button.button_pressed = not overlays.dimmers.is_empty()
	toggle_dimmers_check_button.toggled.connect(
		func(is_active: bool) -> void:
			overlays.toggle_dimmers(is_active)
			dimmers_alpha_h_slider.editable = is_active
	)
	toggle_bubble_check_button.toggled.connect(
		func(is_toggled: bool) -> void:
			if tour != null:
				tour.bubble.visible = is_toggled
	)
	tours_item_list.item_selected.connect(_on_tours_item_list_item_selected)
	button_start_tour.pressed.connect(_start_selected_tour)
	dimmers_alpha_h_slider.value_changed.connect(_on_overlay_alpha_h_slider_value_changed)
	jump_button.pressed.connect(_jump_to_step)
	debug_mode_check_button.toggled.connect(
		func(is_toggled: bool) -> void:
			_debug_mode_toggled_signal.emit(is_toggled)
	)

	dimmers_alpha_h_slider.editable = toggle_dimmers_check_button.button_pressed
	overlays.add_highlight_to_control(self)
	_on_overlay_alpha_h_slider_value_changed(dimmers_alpha_h_slider.value)
	_update_spinbox_step_count()
	populate_tours_item_list()
	toggle_bubble_check_button.button_pressed = tour != null


func _exit_tree() -> void:
	overlays.cleaned_up.disconnect(overlays.add_highlight_to_control)
	_on_overlay_alpha_h_slider_value_changed(1.0)
	overlays.remove_highlights_from_control(self)


func _start_selected_tour() -> void:
	var selected := tours_item_list.get_selected_items()
	if selected.size() == 0:
		return

	var index := tours_item_list.get_selected_items()[0]
	if tour != null:
		tour.clean_up()
	var tour_metadata: GDTourMetadata.Tour = tours_item_list.get_item_metadata(index)
	tour = ResourceInvalidator.resource_force_editor_reload(tour_metadata.script_path).new(tour_metadata, overlays)
	toggle_dimmers_check_button.button_pressed = true
	toggle_bubble_check_button.button_pressed = true
	tour.toggle_visible(true)
	_update_spinbox_step_count()

	tour.bubble.set_is_debug_mode(debug_mode_check_button.button_pressed)
	_debug_mode_toggled_signal.connect(tour.bubble.set_is_debug_mode)


func _on_tours_item_list_item_selected(index: int) -> void:
	button_start_tour.disabled = tours_item_list.get_selected_items().size() == 0


func _on_overlay_alpha_h_slider_value_changed(value: float) -> void:
	get_tree().set_group(DIMMER_GROUP, "modulate", Color(1, 1, 1, value))
	toggle_dimmers_check_button.set_pressed_no_signal(not is_zero_approx(value))


func populate_tours_item_list() -> void:
	tours_item_list.clear()
	for index in series_metadata.tours.size():
		var tour_metadata := series_metadata.tours[index]
		var tour_path := tour_metadata.script_path

		var script_uid := ResourceUID.text_to_id(tour_path)
		if ResourceUID.has_id(script_uid):
			tour_path = ResourceUID.get_id_path(script_uid)

		tours_item_list.add_item(tour_path.get_file())
		tours_item_list.set_item_metadata(index, tour_metadata)


func _update_spinbox_step_count() -> void:
	if tour == null:
		jump_spin_box.suffix = "/ 1"
	else:
		var max_value := tour.steps.size()
		jump_spin_box.suffix = " / " + str(max_value)
		jump_spin_box.max_value = max_value


func _jump_to_step() -> void:
	tour.index = int(jump_spin_box.value - 1)


func set_is_debug_mode(enabled: bool) -> void:
	if debug_mode_check_button != null:
		debug_mode_check_button.button_pressed = enabled
