@tool
extends MarginContainer

signal pressed
signal reset_pressed

const GDTourMetadata = preload("../../gdtour_metadata.gd")

const STATE_COLORS: Array[Color] = [ Color("#2f3e5e"), Color("#2c5695") ]
const CHECK_COLORS: Array[Color] = [ Color("#567099"), Color("#4bff2e") ]
const LOCK_ICONS: Array[Texture2D] = [
	preload("assets/locked.svg"),
	preload("assets/unlocked.svg"),
]

## Static metadata defining the tour.
var tour_metadata: GDTourMetadata.Tour = null:
	set = set_tour_metadata
## Dynamic progress for the tour, not operational for now.
var tour_progress: RefCounted = null:
	set = set_tour_progress
## Flag that enables sample mode layout for the item.
var sample_mode: bool = false:
	set = set_sample_mode

var _hovered: bool = false
var _selected: bool = false

@onready var _content_panel: PanelContainer = %Content
@onready var _checkbox_panel: Panel = %Checkbox
@onready var _checkbox_icon: TextureRect = %CheckIcon
@onready var _number_label: Label = %NumberLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _steps_label: Label = %StepsLabel
@onready var _lock_icon: TextureRect = %LockIcon

@onready var _reset_anchor: Control = %ResetAnchor
@onready var _reset_icon: TextureRect = %ResetIcon


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_content_panel = %Content
		_checkbox_panel = %Checkbox
		_checkbox_icon = %CheckIcon
		_number_label = %NumberLabel
		_description_label = %DescriptionLabel
		_steps_label = %StepsLabel
		_lock_icon = %LockIcon

		_reset_anchor = %ResetAnchor
		_reset_icon = %ResetIcon


func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_update_checkbox()
	_update_labels()
	_update_lock()
	_update_reset_icon()

	_content_panel.mouse_entered.connect(func() -> void:
		_hovered = true
		_content_panel.queue_redraw()
	)
	_content_panel.mouse_exited.connect(func() -> void:
		_hovered = false
		_content_panel.queue_redraw()
	)
	_content_panel.gui_input.connect(_content_gui_input)
	_reset_icon.gui_input.connect(_reset_gui_input)

	_content_panel.draw.connect(_content_draw)

	_checkbox_panel.custom_minimum_size *= EditorInterface.get_editor_scale()
	_lock_icon.custom_minimum_size *= EditorInterface.get_editor_scale()
	_reset_icon.custom_minimum_size *= EditorInterface.get_editor_scale()


func _content_draw() -> void:
	var local_rect := Rect2()
	local_rect.size = _content_panel.size

	if _selected:
		var selected_overlay := _content_panel.get_theme_stylebox("selected_overlay")
		_content_panel.draw_style_box(selected_overlay, local_rect)

	if _hovered:
		var hovered_overlay := _content_panel.get_theme_stylebox("hover_overlay")
		_content_panel.draw_style_box(hovered_overlay, local_rect)


func _content_gui_input(event: InputEvent) -> void:
	if not _hovered:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()


func _reset_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			reset_pressed.emit()


# Properties.

func set_tour_metadata(value: GDTourMetadata.Tour) -> void:
	if tour_metadata == value:
		return

	tour_metadata = value
	_update_checkbox()
	_update_labels()
	_update_lock()


func set_tour_progress(value: RefCounted) -> void:
	if tour_progress == value:
		return

	tour_progress = value
	_update_checkbox()
	_update_labels()
	_update_reset_icon()


func set_sample_mode(value: bool) -> void:
	if sample_mode == value:
		return

	sample_mode = value
	_update_lock()


func set_selected(value: bool) -> void:
	if _selected == value:
		return

	_selected = value
	_update_checkbox()
	_content_panel.queue_redraw()


# Helpers.

func _update_checkbox() -> void:
	_checkbox_icon.modulate = STATE_COLORS[1] if _selected else STATE_COLORS[0]

	# TODO: Update the color depending on the progress.

	_checkbox_panel.self_modulate = CHECK_COLORS[0]
	_steps_label.remove_theme_color_override("font_color")

	#_checkbox_panel.self_modulate = CHECK_COLORS[1]
	#_steps_label.add_theme_color_override("font_color", CHECK_COLORS[1])


func _update_labels() -> void:
	if not tour_metadata:
		return

	var title_parts := tour_metadata.title.split(".", false, 1)
	if title_parts.size() == 2 and title_parts[0].is_valid_int():
		_number_label.visible = true
		_number_label.text = "%d." % [ title_parts[0].to_int() ]
		_description_label.text = title_parts[1].strip_edges()
	else:
		_number_label.visible = false
		_number_label.text = ""
		_description_label.text = tour_metadata.title

	# TODO: Update the label based on the progress.
	_steps_label.text = "%d / %d" % [ 0, tour_metadata.step_count ]


func _update_lock() -> void:
	if not tour_metadata:
		return

	if not sample_mode:
		_lock_icon.visible = false
		return

	_lock_icon.visible = true
	_lock_icon.texture = LOCK_ICONS[0] if tour_metadata.is_locked else LOCK_ICONS[1]


func _update_reset_icon() -> void:
	if not tour_metadata:
		return

	if sample_mode and tour_metadata.is_locked:
		_reset_anchor.visible = false
		return

	# TODO: Update visibility of the button based on the progress.

	_reset_anchor.visible = true
