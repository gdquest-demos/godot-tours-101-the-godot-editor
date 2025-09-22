@tool
extends CanvasLayer

## Emitted when the start learning button_start_learning is pressed.
signal tour_start_requested(tour_index: int)
signal tour_reset_requested(tour_path: String)
## Emitted when the menu is closed.
signal closed

const UISelectableTour = preload("ui_selectable_tour.gd")
const GDTourMetadata = preload("../gdtour_metadata.gd")
const Tour := preload("../tour.gd")
const Utils := preload("../utils.gd")
const TranslationService := preload("../translation/translation_service.gd")
const ThemeUtils := preload("../../gdquest_theme_utils/theme_utils.gd")

const UISelectableTourPackedScene = preload("ui_selectable_tour.tscn")

@onready var control: Control = %Control
@onready var button_start_learning: Button = %ButtonStartLearning
@onready var button_reset_selected: TextureButton = %ButtonResetSelected
@onready var tours_column: VBoxContainer = %ToursColumn
@onready var button_close: Button = %ButtonClose
@onready var label_title: Label = %LabelTitle
@onready var margin_container: MarginContainer = %MarginContainer
@onready var panel_container: PanelContainer = %PanelContainer
@onready var color_rect: ColorRect = %ColorRect

# Nodes for reset view and confirmation
@onready var view_menu: VBoxContainer = %ViewMenu
@onready var view_reset_confirmation: VBoxContainer = %ViewResetConfirmation
@onready var label_reset_explanation: RichTextLabel = %LabelResetExplanation
@onready var button_reset_no: Button = %ButtonResetNo
@onready var button_reset_yes: Button = %ButtonResetYes
@onready var label_reset_title: Label = %LabelResetTitle
@onready var button_reset_ok: Button = %ButtonResetOk


func _ready() -> void:
	view_menu.show()
	view_reset_confirmation.hide()
	button_reset_ok.hide()
	button_reset_no.show()
	button_reset_yes.show()


func setup(translation_service: TranslationService, tour_metadata: GDTourMetadata) -> void:
	Utils.update_locale(translation_service, {
		label_title: {text = "Welcome to GDTour!"},
		button_start_learning: {text = "START LEARNING"},
		button_reset_no: {text = "NO"},
		button_reset_yes: {text = "YES"},
	})

	button_close.pressed.connect(func emit_closed_and_free() -> void:
		closed.emit()
		queue_free()
	)
	button_start_learning.pressed.connect(func request_tour() -> void:
		tour_start_requested.emit(get_selectable_tour().get_index())
	)
	button_reset_selected.pressed.connect(func open_reset_menu() -> void:
		view_reset_confirmation.show()
		view_menu.hide()
		button_reset_ok.hide()
		button_reset_no.show()
		button_reset_yes.show()
		label_reset_title.text = tr("Reset the tour?")
		label_reset_explanation.text = tr("Do you want to reset [b]%s[/b]?" % get_selectable_tour().title)
		label_reset_explanation.text += "\n" + tr("This will reset the files to the tour starting point, overwriting your changes.")
	)
	button_reset_no.pressed.connect(func open_welcome_menu() -> void:
		view_menu.show()
		view_reset_confirmation.hide()
	)
	button_reset_yes.pressed.connect(func emit_reset_tour() -> void:
		tour_reset_requested.emit(get_selectable_tour().tour_path)
	)
	button_reset_ok.pressed.connect(func open_welcome_menu() -> void:
		view_menu.show()
		view_reset_confirmation.hide()
	)

	for tour_entry: GDTourMetadata.TourMetadata in tour_metadata.list:
		var selectable_tour: UISelectableTour = UISelectableTourPackedScene.instantiate()
		tours_column.add_child(selectable_tour)
		selectable_tour.setup(tour_entry)

	# Scale with editor scale
	if Engine.is_editor_hint() and owner != self:
		control.theme = ThemeUtils.generate_scaled_theme(control.theme)
		var editor_scale := EditorInterface.get_editor_scale()
		panel_container.custom_minimum_size.x *= editor_scale
		ThemeUtils.scale_margin_container_margins(margin_container)
		for button: BaseButton in [button_reset_selected, button_close]:
			button.custom_minimum_size *= editor_scale

	if tours_column.get_child_count() > 0:
		tours_column.get_child(0).select()


func get_selectable_tour() -> UISelectableTour:
	return UISelectableTour.group.get_pressed_button().owner


func toggle_dimmer(is_on := true) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_STOP if is_on else Control.MOUSE_FILTER_IGNORE
	color_rect.mouse_filter = control.mouse_filter


## Shows a message to the user that a tour reset was successful.
## Called by the plugin after a tour has been reset.
func show_reset_success() -> void:
	label_reset_title.text = tr("Reset successful")
	label_reset_explanation.text = tr("The tour [b]%s[/b] has been reset to its starting point." % get_selectable_tour().title)
	label_reset_explanation.text += "\n" + tr("You may need to close and reopen Godot scenes to see the changes.")
	button_reset_no.hide()
	button_reset_yes.hide()
	button_reset_ok.show()

## Shows a message to the user that a tour reset failed.
## Called by the plugin after a tour has been reset.
func show_reset_failure() -> void:
	label_reset_title.text = tr("Reset failed")
	label_reset_explanation.text = tr("The tour [b]%s[/] could not be reset. Try closing and reopening Godot or restarting your computer and try resetting again." % get_selectable_tour().title)
	label_reset_explanation.text += "\n" + tr("If the problem persists, please check the errors in the Output bottom panel and let us know!")
	button_reset_no.hide()
	button_reset_yes.hide()
	button_reset_ok.show()
