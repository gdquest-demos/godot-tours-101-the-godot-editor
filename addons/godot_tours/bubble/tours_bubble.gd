## Floating panel used to display a list of available tours to the user.
@tool
extends "bubble_base.gd"

signal tour_start_requested(tour_id: String)
signal tour_reset_requested(tour_id: String)

const RichTextLabelPackedScene := preload("content/rich_text_label.tscn")

const MessageDrawer := preload("layout/message_drawer.gd")
const ConfirmDrawer := preload("layout/confirm_drawer.gd")
const InformDrawer := preload("layout/inform_drawer.gd")

const ShrinkableContainer := preload("layout/shrinkable_container.gd")
const ContentContainer := preload("layout/content_container.gd")
const ToursContainer := preload("lists/tours_container.gd")

const GDTourMetadata := preload("../gdtour_metadata.gd")

const CLOSE_BUTTON_STEP_COLOR := Color("#567099")
const VIEW_OVERLAY_MODULATION := Color("#34456f")

const SHRINKABLE_CONTENT_MIN_HEIGHT := 80.0

var _editor_plugin: EditorPlugin = null
var _editor_toolbar: Control = null

# Layout.

@onready var _view_layout: Control = %ViewLayout
@onready var _view_layout_filler: Control = %ViewLayout/Filler
@onready var _view_container: Control = %ViewContainer
@onready var _view_overlay: Control = %ViewOverlay

@onready var _outline_rounded: Control = %OutlineRounded
@onready var _outline_straight: Control = %OutlineStraight

@onready var _drawer_layout: Control = %DrawerLayout
@onready var _drawer_layout_filler: Control = %DrawerLayout/Filler
@onready var _drawer_container: Control = %DrawerContainer

@onready var _close_button: Button = %CloseButton

@onready var _reset_tour_message: ConfirmDrawer = %ResetTourMessage
@onready var _reset_success_message: InformDrawer = %ResetSuccessMessage
@onready var _reset_failure_message: InformDrawer = %ResetFailureMessage

@onready var _promo_panel: Control = %PromoPanel

# Welcome view.

@onready var _welcome_view: Control = %WelcomeView
@onready var _welcome_title: Label = %WelcomeTitle
@onready var _welcome_subtitle: Label = %WelcomeSubtitle
@onready var _welcome_start_button: Button = %WelcomeButton
@onready var _welcome_footer: Control = %WelcomeFooter
@onready var _welcome_filler: Control = %WelcomeFiller

@onready var _welcome_content_box: ContentContainer = %WelcomeContent
@onready var _welcome_tour_list: ToursContainer = %WelcomeTourList


# Lifecycle.

func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_view_layout = %ViewLayout
		_view_layout_filler = %ViewLayout/Filler
		_view_container = %ViewContainer
		_view_overlay = %ViewOverlay

		_outline_rounded = %OutlineRounded
		_outline_straight = %OutlineStraight

		_drawer_layout = %DrawerLayout
		_drawer_layout_filler = %DrawerLayout/Filler
		_drawer_container = %DrawerContainer

		_close_button = %CloseButton

		_reset_tour_message = %ResetTourMessage
		_reset_success_message = %ResetSuccessMessage
		_reset_failure_message = %ResetFailureMessage

		_promo_panel = %PromoPanel

		_welcome_view = %WelcomeView
		_welcome_title = %WelcomeTitle
		_welcome_subtitle = %WelcomeSubtitle
		_welcome_start_button = %WelcomeButton
		_welcome_footer = %WelcomeFooter
		_welcome_filler = %WelcomeFiller
		_welcome_content_box = %WelcomeContent
		_welcome_tour_list = %WelcomeTourList


func _ready() -> void:
	super()
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_bubble_container.resized.connect(_queue_retransition_bubble, CONNECT_DEFERRED)

	# HACK: The overlay prevents normal handling of drag attempts, so we pass through the
	# event here. It's fine because both panels align perfectly and positional checks are
	# consistent. We also copy the default cursor shape from the result of the call,
	# because, again, the overlay steals mouse events and bubble's default cursor will never
	# be checked with it visible.
	_view_overlay.gui_input.connect(func(event: InputEvent) -> void:
		_panel_gui_input(event)
		_view_overlay.mouse_default_cursor_shape = _bubble_container.mouse_default_cursor_shape
	)

	_close_button.pressed.connect(close_requested.emit)

	_reset_tour_message.left_button_pressed.connect(_try_reset_tour)
	_reset_tour_message.right_button_pressed.connect(_hide_drawer_messages)
	_reset_success_message.accept_button_pressed.connect(_hide_drawer_messages)
	_reset_failure_message.accept_button_pressed.connect(_hide_drawer_messages)

	_welcome_start_button.pressed.connect(_try_start_tour)
	_welcome_tour_list.tour_selected.connect(_update_selected_tour)
	_welcome_tour_list.reset_requested.connect(_show_reset_tour_message)

	var editor_scale := EditorInterface.get_editor_scale()
	_close_button.custom_minimum_size *= editor_scale
	_welcome_filler.custom_minimum_size *= editor_scale


func _enter_tree() -> void:
	_initialize_editor_tools()


func _exit_tree() -> void:
	_destroy_editor_tools()


func set_content_translation_domain(domain_name: String) -> void:
	Utils.set_tour_translation_domain(_welcome_title, domain_name)
	Utils.set_tour_translation_domain(_welcome_content_box, domain_name)
	Utils.set_tour_translation_domain(_welcome_tour_list, domain_name)


# Messages.

func _hide_drawer_messages() -> void:
	_welcome_start_button.visible = true
	_welcome_footer.visible = true
	_welcome_filler.visible = false
	_close_button.visible = true

	_view_container.modulate = Color.WHITE
	_view_overlay.visible = false
	_drawer_container.visible = false

	_reset_tour_message.set_meta("tour_metadata", null)

	for message: MessageDrawer in [ _reset_tour_message, _reset_success_message, _reset_failure_message ]:
		message.visible = false

	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_update_content_size()


func _show_drawer_message(control: MessageDrawer) -> void:
	_welcome_start_button.visible = false
	_welcome_footer.visible = false
	_welcome_filler.visible = true
	_close_button.visible = false

	_view_container.modulate = VIEW_OVERLAY_MODULATION
	_view_overlay.visible = true
	_drawer_container.visible = true

	for message: MessageDrawer in [ _reset_tour_message, _reset_success_message, _reset_failure_message ]:
		message.visible = (message == control)

	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_update_content_size()

	var layout_root: Control = EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_ROOT)
	move_and_anchor(layout_root, At.CENTER, _state_data.margin_offset)


func _show_reset_tour_message(tour_metadata: GDTourMetadata.Tour) -> void:
	_reset_tour_message.set_meta("tour_metadata", tour_metadata)
	_show_drawer_message(_reset_tour_message)


func show_reset_success_message() -> void:
	_show_drawer_message(_reset_success_message)


func show_reset_failure_message() -> void:
	_show_drawer_message(_reset_failure_message)


func _hide_promo_panel() -> void:
	_outline_rounded.visible = true
	_outline_straight.visible = false
	_promo_panel.visible = false


func _show_promo_panel() -> void:
	_outline_rounded.visible = false
	_outline_straight.visible = true
	_promo_panel.visible = true


# Content.

func clear() -> void:
	_hide_drawer_messages()
	_hide_promo_panel()

	_welcome_tour_list.clear_tours()
	_welcome_tour_list.visible = false
	_welcome_start_button.disabled = true

	_welcome_content_box.clear_elements()
	_welcome_content_box.visible = false


func set_title(value: String) -> void:
	_welcome_title.text = value


func set_subtitle(value: String) -> void:
	_welcome_subtitle.text = value


func add_custom_element(element: Control) -> void:
	_welcome_content_box.visible = true
	_welcome_content_box.add_element(element)


func add_text(text: Array[String]) -> void:
	var editor_scale := EditorInterface.get_editor_scale()
	var font_size := 20 * editor_scale

	for line in text:
		var element := RichTextLabelPackedScene.instantiate()
		element.text = "[font_size=%d]%s[/font_size]" % [ font_size, line ]
		add_custom_element(element)


# Tours management.

func add_tour(tour_metadata: GDTourMetadata.Tour, sample_mode: bool = false) -> void:
	_welcome_tour_list.visible = true
	_welcome_tour_list.create_tour(tour_metadata, sample_mode)


func _update_selected_tour() -> void:
	var selected_tour := _welcome_tour_list.get_selected_tour()
	_welcome_start_button.disabled = not selected_tour or selected_tour.is_locked

	if selected_tour.is_locked:
		_show_promo_panel()
	else:
		_hide_promo_panel()


func _try_start_tour() -> void:
	var selected_tour := _welcome_tour_list.get_selected_tour()
	if not selected_tour:
		return

	tour_start_requested.emit(selected_tour.id)


func _try_reset_tour() -> void:
	var resetting_tour: GDTourMetadata.Tour = _reset_tour_message.get_meta("tour_metadata", null)
	_hide_drawer_messages()

	if not resetting_tour:
		return

	tour_reset_requested.emit(resetting_tour.id)


# Positioning and transitions.

func _update_height_limits() -> void:
	_height_limiter_queued = false

	# NOTE: Throughout we try to round everything to integers. Upper limits are rounded
	# down, and lower limits are arounded up. This should help us reduce edge cases where
	# imprecision might cause issues. If edge cases prove to still be a concern, additional
	# safeguards need to be put in place. E.g. a cooldown period when too many attempts at
	# updating limits are registered within a few frames.

	var editor_scale := EditorInterface.get_editor_scale()
	var content_height_limit := SHRINKABLE_CONTENT_MIN_HEIGHT * editor_scale
	var base_control := EditorInterface.get_base_control()
	var maximum_bubble_height := floori(base_control.size.y - _state_data.margin_offset * 2.0)

	# First, calculate the size of the drawer and its shrinking content.

	var drawer_base_height := 0
	var drawer_style := _drawer_container.get_theme_stylebox("panel")

	var message_base_height := 0.0
	var message_content_height := 0.0
	for message: MessageDrawer in [ _reset_tour_message, _reset_success_message, _reset_failure_message ]:
		if message.visible:
			message_base_height = message.get_base_height()
			message_content_height = message.get_content_height()
			break

	if message_base_height > 0.0 and drawer_style:
		drawer_base_height += drawer_style.get_minimum_size().y

	# This is the height that we require at the minimum, shrinking content not included.
	var drawer_shrunk_height := ceili(_drawer_layout_filler.size.y + drawer_base_height + message_base_height)
	# The maximum size of the shrinking content is total allowed maximum minus the height above.
	# We also enforce the absolute minimum size that cannot go below of.
	var message_content_height_limit := maxi(content_height_limit, maximum_bubble_height - drawer_shrunk_height)

	# Next, calculate the size of the views and their shrinking content.

	# FIXME: View content overflow is not implemented yet because it conflicts with the new design.
	var welcome_fixed_height := _welcome_content_box.get_combined_minimum_size().y + _welcome_tour_list.get_combined_minimum_size().y
	welcome_fixed_height += (_welcome_content_box.get_parent() as VBoxContainer).get_theme_constant("separation")

	# This is the height that we require at the minimum, shrinking content not included.
	var welcome_shrunk_height := ceili(drawer_base_height + _view_container.get_combined_minimum_size().y - welcome_fixed_height)
	# The maximum size of the shrinking content is total allowed maximum minus the height above.
	# We also enforce the absolute minimum size that cannot go below of.
	var welcome_content_height_limit := maxi(content_height_limit, maximum_bubble_height - welcome_shrunk_height)

	# Now, try to fit both the views and the drawer without shrinking content.

	var filler_extra_height := ceili(message_base_height + message_content_height)
	var welcome_content_combined_height := welcome_fixed_height

	if filler_extra_height > 0.0 and (filler_extra_height + welcome_content_combined_height) < welcome_content_height_limit:
		_view_layout_filler.custom_minimum_size.y = drawer_base_height + filler_extra_height
	else:
		_view_layout_filler.custom_minimum_size.y = drawer_base_height

	# Finally, update the limits of shrinking content.

	for message: MessageDrawer in [ _reset_tour_message, _reset_success_message, _reset_failure_message ]:
		message.maximum_message_height = message_content_height_limit


# Editor tools.
# A hook that creates an adhoc plugin with a toolbar visible only when editing
# this scene in the editor. This allows us to expose a nice set of actions
# (reactive, if needed), above the main viewport for testing scene behavior without
# modifications.

func _initialize_editor_tools() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() != self:
		return

	_editor_plugin = EditorPlugin.new()
	_editor_toolbar = _create_editor_toolbar()
	_editor_plugin.add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _editor_toolbar)


func _destroy_editor_tools() -> void:
	if not Engine.is_editor_hint() or not is_instance_valid(_editor_plugin):
		return

	if is_instance_valid(_editor_toolbar):
		_editor_plugin.remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _editor_toolbar)
		_editor_toolbar.queue_free()
		_editor_toolbar = null

	_editor_plugin.queue_free()
	_editor_plugin = null


func _create_editor_toolbar() -> Control:
	var toolbar := HBoxContainer.new()

	_add_editor_toolbar_label(toolbar, "Bubble")

	toolbar.add_child(VSeparator.new())

	_add_editor_toolbar_label(toolbar, "Con")
	_add_editor_toolbar_button(toolbar, "× C", "Clear content", clear)
	_add_editor_toolbar_button(toolbar, "+ TX", "Add text content", func() -> void:
		add_text([
			"This is a test string!",
			"This line contains [b]formatting[/b] with [i]bbcode[/i].",
			"This line has a class name, [b]Control[/b].",
		])
	)
	_add_editor_toolbar_button(toolbar, "+ TR", "Add a regular tour", func() -> void:
		var tour_meta := GDTourMetadata.Tour.new()
		tour_meta.id = "test_1"
		tour_meta.title = "This is a Tour"
		add_tour(tour_meta, false)
	)
	_add_editor_toolbar_button(toolbar, "+ TSU", "Add a sample tour (unlocked)", func() -> void:
		var tour_meta := GDTourMetadata.Tour.new()
		tour_meta.id = "test_1"
		tour_meta.title = "This is a Tour"
		add_tour(tour_meta, true)
	)
	_add_editor_toolbar_button(toolbar, "+ TSL", "Add a sample tour (locked)", func() -> void:
		var tour_meta := GDTourMetadata.Tour.new()
		tour_meta.id = "test_1"
		tour_meta.title = "This is a Tour"
		tour_meta.is_locked = true
		add_tour(tour_meta, true)
	)

	toolbar.add_child(VSeparator.new())

	_add_editor_toolbar_label(toolbar, "Msg")
	_add_editor_toolbar_button(toolbar, "- X", "Hide all messages", func() -> void:
		_hide_drawer_messages()
	)
	_add_editor_toolbar_button(toolbar, "○ C", "Show reset tour message", func() -> void:
		_show_reset_tour_message(null)
	)

	toolbar.add_child(VSeparator.new())

	_add_editor_toolbar_label(toolbar, "Avt")
	_add_editor_toolbar_button(toolbar, "PL", "Align avatar to left (prime)", set_avatar_at.bind(AvatarAt.PRIME_LEFT))
	_add_editor_toolbar_button(toolbar, "PC", "Align avatar to center (prime)", set_avatar_at.bind(AvatarAt.PRIME_CENTER))
	_add_editor_toolbar_button(toolbar, "PR", "Align avatar to right (prime)", set_avatar_at.bind(AvatarAt.PRIME_RIGHT))

	return toolbar


func _add_editor_toolbar_label(toolbar: Control, label_text: String) -> void:
	var toolbar_label := Label.new()
	toolbar_label.text = label_text
	toolbar.add_child(toolbar_label)


func _add_editor_toolbar_button(toolbar: Control, button_text: String, button_tooltip_text: String, callback: Callable) -> void:
	var toolbar_button := Button.new()
	toolbar_button.text = button_text
	toolbar_button.tooltip_text = button_tooltip_text
	toolbar.add_child(toolbar_button)
	toolbar_button.pressed.connect(callback)
