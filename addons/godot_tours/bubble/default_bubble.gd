## Floating panel used to display step-by-step instruction to the tour user.
@tool
extends "bubble_base.gd"

const CodeEditPackedScene := preload("content/code_edit.tscn")
const TextureRectPackedScene := preload("content/texture_rect.tscn")
const VideoStreamPlayerPackedScene := preload("content/video_stream_player.tscn")
const RichTextLabelPackedScene := preload("content/rich_text_label.tscn")

const ConfirmDrawer := preload("layout/confirm_drawer.gd")
const ShrinkableContainer := preload("layout/shrinkable_container.gd")
const ContentContainer := preload("layout/content_container.gd")
const TasksContainer := preload("lists/tasks_container.gd")

const EDITOR_ICON_MARKUP := r"[img=%dx%d]editor://theme_icons/$1[/img] [b]$1[/b]"
const EDITOR_ICON_SIZE := 24

const CLOSE_BUTTON_BOOKEND_COLOR := Color("#ffffff99")
const CLOSE_BUTTON_STEP_COLOR := Color("#567099")
const VIEW_OVERLAY_MODULATION := Color("#34456f")

const SHRINKABLE_CONTENT_MIN_HEIGHT := 80.0

static var _class_name_regex := RegEx.new()

var _editor_plugin: EditorPlugin = null
var _editor_toolbar: Control = null

# Layout.

@onready var _view_layout: Control = %ViewLayout
@onready var _view_layout_filler: Control = %ViewLayout/Filler
@onready var _view_container: Control = %ViewContainer
@onready var _view_overlay: Control = %ViewOverlay

@onready var _drawer_layout: Control = %DrawerLayout
@onready var _drawer_layout_filler: Control = %DrawerLayout/Filler
@onready var _drawer_container: Control = %DrawerContainer
@onready var _footer: Control = %Footer
@onready var _step_count_label: Label = %StepCountLabel

@onready var _close_button: Button = %CloseButton
@onready var _help_button: LinkButton = %HelpButton
@onready var _skip_button: LinkButton = %SkipButton

@onready var _close_tour_message: ConfirmDrawer = %CloseTourMessage
@onready var _get_help_message: ConfirmDrawer = %GetHelpMessage
@onready var _skip_step_message: ConfirmDrawer = %SkipStepMessage

# Bookend view.

@onready var _bookend_background: Control = %BookendBackground
@onready var _bookend_view: Control = %BookendView
@onready var _bookend_title: Label = %BookendTitle
@onready var _bookend_proceed_button: Button = %BookendButton

@onready var _bookend_content_box: ContentContainer = %BookendContent

# Step view.

@onready var _step_view: Control = %StepView
@onready var _step_title: Label = %StepTitle
@onready var _step_navigation_box: Control = %StepNavigation
@onready var _step_prev_button: Button = %StepBackButton
@onready var _step_next_button: Button = %StepNextButton

@onready var _step_content_shrink: ShrinkableContainer = %StepContentShrink
@onready var _step_content_box: ContentContainer = %StepContent
@onready var _step_task_list: TasksContainer = %StepTaskList


# Lifecycle.

static func _static_init() -> void:
	var classes := Array(ClassDB.get_class_list())
	classes.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	_class_name_regex.compile(r"\[b\](%s)\[\/b\]" % "|".join(classes))


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_view_layout = %ViewLayout
		_view_layout_filler = %ViewLayout/Filler
		_view_container = %ViewContainer
		_view_overlay = %ViewOverlay

		_drawer_layout = %DrawerLayout
		_drawer_layout_filler = %DrawerLayout/Filler
		_drawer_container = %DrawerContainer
		_footer = %Footer

		_close_button = %CloseButton
		_help_button = %HelpButton
		_skip_button = %SkipButton

		_close_tour_message = %CloseTourMessage
		_get_help_message = %GetHelpMessage
		_skip_step_message = %SkipStepMessage

		_step_view = %StepView
		_step_title = %StepTitle
		_step_navigation_box = %StepNavigation
		_step_prev_button = %StepBackButton
		_step_next_button = %StepNextButton
		_step_content_shrink = %StepContentShrink
		_step_content_box = %StepContent
		_step_task_list = %StepTaskList

		_bookend_background = %BookendBackground
		_bookend_view = %BookendView
		_bookend_title = %BookendTitle
		_bookend_proceed_button = %BookendButton
		_bookend_content_box = %BookendContent


func setup(step_count: int) -> void:
	super(step_count)


func _ready() -> void:
	super()
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_update_step_controls()
	_update_step_count_display()

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

	_close_button.pressed.connect(_try_close_tour)
	_skip_button.pressed.connect(_try_request_next_step)
	_help_button.pressed.connect(_show_get_help_message)

	_close_tour_message.left_button_pressed.connect(_hide_drawer_messages)
	_close_tour_message.right_button_pressed.connect(close_requested.emit)
	_get_help_message.left_button_pressed.connect(log_requested.emit)
	_get_help_message.right_button_pressed.connect(_hide_drawer_messages)
	_skip_step_message.left_button_pressed.connect(next_step_requested.emit)
	_skip_step_message.right_button_pressed.connect(_hide_drawer_messages)

	_bookend_proceed_button.pressed.connect(_proceed_bookend_step)

	_step_prev_button.pressed.connect(prev_step_requested.emit)
	_step_next_button.pressed.connect(_try_request_next_step)
	_step_content_shrink.resized.connect(_update_content_size)

	var editor_scale := EditorInterface.get_editor_scale()
	_close_button.custom_minimum_size *= editor_scale


func _enter_tree() -> void:
	_initialize_editor_tools()


func _exit_tree() -> void:
	_destroy_editor_tools()


func set_content_translation_domain(domain_name: String) -> void:
	Utils.set_tour_translation_domain(_bookend_title, domain_name)
	Utils.set_tour_translation_domain(_bookend_content_box, domain_name)
	Utils.set_tour_translation_domain(_step_title, domain_name)
	Utils.set_tour_translation_domain(_step_content_box, domain_name)
	Utils.set_tour_translation_domain(_step_task_list, domain_name)


func set_is_debug_mode(value: bool) -> void:
	super(value)

	# Add shortcuts to the navigation buttons, allowing to quickly flip through steps.

	_step_next_button.shortcut = null
	_step_prev_button.shortcut = null

	if is_debug_mode:
		var shortcut_next := Shortcut.new()
		var event_next := InputEventKey.new()
		event_next.keycode = KEY_N
		event_next.ctrl_pressed = true
		event_next.alt_pressed = true
		shortcut_next.events = [event_next]
		_step_next_button.shortcut = shortcut_next

		var shortcut_back := Shortcut.new()
		var event_back := InputEventKey.new()
		event_back.keycode = KEY_B
		event_back.ctrl_pressed = true
		event_next.alt_pressed = true
		shortcut_back.events = [event_back]
		_step_prev_button.shortcut = shortcut_back


# Navigation.

func set_current_step(index: int) -> void:
	super(index)
	_update_step_controls()
	_update_step_count_display()


func _update_step_controls() -> void:
	if not is_node_ready():
		return

	if _current_step_index == 0 or _current_step_index == (_step_count - 1):
		_bookend_background.visible = true
		_bookend_view.visible = true
		_step_view.visible = false
		_close_button.modulate = CLOSE_BUTTON_BOOKEND_COLOR

		_hide_drawer_messages()
		_drawer_layout.visible = false
		_view_layout_filler.visible = false

	else:
		_bookend_background.visible = false
		_bookend_view.visible = false
		_step_view.visible = true
		_close_button.modulate = CLOSE_BUTTON_STEP_COLOR

		check_tasks()
		_drawer_layout.visible = true
		_view_layout_filler.visible = true


func _update_step_count_display() -> void:
	if not is_node_ready():
		return

	_step_count_label.text = "%s / %s" % [_current_step_index, _step_count - 2]
	_step_count_label.visible = _current_step_index > 0 and _current_step_index < (_step_count - 1)


func _proceed_bookend_step() -> void:
	if _current_step_index == 0:
		next_step_requested.emit()

	elif _current_step_index == _step_count - 1:
		finish_requested.emit()


func _try_request_next_step() -> void:
	# In debug mode we bypass any tasks and force going to the next step
	if is_debug_mode:
		next_step_requested.emit()
		return

	if _step_next_button.theme_type_variation == "StepInactiveButton":
		_show_skip_step_message()
	else:
		next_step_requested.emit()


func _try_close_tour() -> void:
	# On bookend steps there is no progress lost, so close without confirmation.
	if _current_step_index == 0 or _current_step_index == (_step_count - 1):
		# TODO: When we track tour completion, make sure that it is counted when we reach finale,
		# so even if the close button then pressed, tour completion is accounted for.
		close_requested.emit()
	else:
		_show_close_tour_message()


# Messages.

func _hide_drawer_messages() -> void:
	_step_navigation_box.visible = true
	_close_button.visible = true
	_help_button.visible = true
	_skip_button.visible = true

	_view_container.modulate = Color.WHITE
	_view_overlay.visible = false

	for message: ConfirmDrawer in [ _close_tour_message, _get_help_message, _skip_step_message ]:
		message.visible = false

	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_update_content_size()


func _show_drawer_message(control: ConfirmDrawer) -> void:
	_step_navigation_box.visible = false
	_close_button.visible = false
	_help_button.visible = false
	_skip_button.visible = false

	_view_container.modulate = VIEW_OVERLAY_MODULATION
	_view_overlay.visible = true

	for message: ConfirmDrawer in [ _close_tour_message, _get_help_message, _skip_step_message ]:
		message.visible = (message == control)

	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_update_content_size()

	var layout_root: Control = EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_ROOT)
	move_and_anchor(layout_root, At.CENTER, _state_data.margin_offset)


func _show_close_tour_message() -> void:
	_show_drawer_message(_close_tour_message)


func _show_get_help_message() -> void:
	_show_drawer_message(_get_help_message)


func _show_skip_step_message() -> void:
	_show_drawer_message(_skip_step_message)


# Content.

func clear() -> void:
	_hide_drawer_messages()

	_step_task_list.clear_tasks()
	_step_task_list.visible = false
	check_tasks()

	_step_content_box.clear_elements()
	_step_content_box.visible = false

	_bookend_content_box.clear_elements()
	_bookend_content_box.visible = false


func set_bookend_title(text: String) -> void:
	_bookend_title.text = text


func add_bookend_text(text: Array[String], style: BookendTextStyle = BookendTextStyle.INFO) -> void:
	_bookend_content_box.visible = true

	const POPPINS_REGULAR := "res://addons/godot_tours/assets/fonts/poppins_regular.ttf"
	const POPPINS_MEDIUM := "res://addons/godot_tours/assets/fonts/poppins_medium.ttf"
	const POPPINS_BOLD := "res://addons/godot_tours/assets/fonts/poppins_bold.ttf"

	var editor_scale := EditorInterface.get_editor_scale()
	var font_normal_size := 15 * editor_scale
	var font_large_size := 18 * editor_scale
	var img_size := EDITOR_ICON_SIZE * editor_scale

	for line in text:
		var matches := _class_name_regex.search_all(line)
		for match in matches:
			Utils.precache_icon_image(match.get_string(1))

		line = _class_name_regex.sub(line, EDITOR_ICON_MARKUP % [img_size, img_size], true)

		var element := RichTextLabelPackedScene.instantiate()

		match style:
			BookendTextStyle.INFO:
				element.text = "[font=%s][font_size=%d]%s[/font_size][/font]" % [ POPPINS_MEDIUM, font_normal_size, line ]

			BookendTextStyle.KEY:
				element.text = "[font=%s][font_size=%d][color=#ffd500]%s[/color][/font_size][/font]" % [ POPPINS_BOLD, font_normal_size, line ]

			BookendTextStyle.RECAP:
				element.text = "[font=%s][font_size=%d]%s[/font_size][/font]" % [ POPPINS_REGULAR, font_large_size, line ]

			_:
				element.text = line


		_bookend_content_box.add_element(element)


func set_bookend_button_text(text: String) -> void:
	_bookend_proceed_button.text = text


func set_title(title_text: String) -> void:
	_step_title.text = title_text


func add_custom_element(element: Control) -> void:
	_step_content_box.visible = true
	_step_content_box.add_element(element)


func add_text(text: Array[String]) -> void:
	var img_size := EDITOR_ICON_SIZE * EditorInterface.get_editor_scale()

	for line in text:
		var matches := _class_name_regex.search_all(line)
		for match in matches:
			Utils.precache_icon_image(match.get_string(1))

		line = _class_name_regex.sub(line, EDITOR_ICON_MARKUP % [img_size, img_size], true)

		var element := RichTextLabelPackedScene.instantiate()
		element.text = line
		add_custom_element(element)


func add_code(code: Array[String]) -> void:
	for snippet in code:
		var element := CodeEditPackedScene.instantiate()
		element.text = snippet
		add_custom_element(element)


func add_texture(texture: Texture2D, max_height := 0.0) -> void:
	if texture == null:
		return

	var element := TextureRectPackedScene.instantiate()
	element.texture = texture
	if max_height > 0.0:
		element.max_height = max_height

	add_custom_element(element)


func add_video(stream: VideoStream) -> void:
	if stream == null:
		return

	var element := VideoStreamPlayerPackedScene.instantiate()
	element.stream = stream
	element.finished.connect(element.play) # Loop.

	add_custom_element(element)
	element.play()

	var texture: Texture2D = element.get_video_texture()
	_step_content_box.fit_element_to_width(element, texture.get_height() / texture.get_width())


# Tasks.

func add_task(description: String, repeat: int, repeat_callable: Callable, error_predicate: Callable, setup_callable: Callable) -> void:
	_step_task_list.visible = true
	var task := _step_task_list.create_task(description, repeat, repeat_callable, error_predicate, setup_callable)
	task.status_changed.connect(check_tasks)

	check_tasks()


func check_tasks() -> bool:
	var are_tasks_done := _step_task_list.check_tasks()

	if are_tasks_done:
		_step_next_button.theme_type_variation = "StepActiveButton"
		_hide_drawer_messages()

		if _step_task_list.has_tasks():
			_avatar.do_wink()

	else:
		_step_next_button.theme_type_variation = "StepInactiveButton"

	return are_tasks_done


# Positioning and transitions.

func ensure_minimum_size(size: Vector2) -> void:
	var scaled_size := size * EditorInterface.get_editor_scale()

	_bubble_container.custom_minimum_size.y = scaled_size.y
	_step_view.custom_minimum_size.x = scaled_size.x


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

	var drawer_base_height := ceili(_footer.size.y)
	var drawer_style := _drawer_container.get_theme_stylebox("panel")
	if drawer_style:
		drawer_base_height += drawer_style.get_minimum_size().y

	var message_base_height := 0.0
	var message_content_height := 0.0
	for message: ConfirmDrawer in [ _close_tour_message, _get_help_message, _skip_step_message ]:
		if message.visible:
			message_base_height = message.get_base_height()
			message_content_height = message.get_content_height()
			break

	# This is the height that we require at the minimum, shrinking content not included.
	var drawer_shrunk_height := ceili(_drawer_layout_filler.size.y + drawer_base_height + message_base_height)
	# The maximum size of the shrinking content is total allowed maximum minus the height above.
	# We also enforce the absolute minimum size that cannot go below of.
	var message_content_height_limit := maxi(content_height_limit, maximum_bubble_height - drawer_shrunk_height)

	# Next, calculate the size of the views and their shrinking content.

	# This is the height that we require at the minimum, shrinking content not included.
	var step_shrunk_height := ceili(drawer_base_height + _view_container.get_combined_minimum_size().y - _step_content_shrink.get_combined_minimum_size().y)
	# The maximum size of the shrinking content is total allowed maximum minus the height above.
	# We also enforce the absolute minimum size that cannot go below of.
	var step_content_height_limit := maxi(content_height_limit, maximum_bubble_height - step_shrunk_height)

	# Now, try to fit both the views and the drawer without shrinking content.

	var filler_extra_height := ceili(message_base_height + message_content_height)
	var step_content_combined_height := _step_content_shrink.get_content_height()

	if filler_extra_height > 0.0 and (filler_extra_height + step_content_combined_height) < step_content_height_limit:
		_view_layout_filler.custom_minimum_size.y = drawer_base_height + filler_extra_height
	else:
		_view_layout_filler.custom_minimum_size.y = drawer_base_height

	# Finally, update the limits of shrinking content.

	_step_content_shrink.maximum_height = step_content_height_limit

	for message: ConfirmDrawer in [ _close_tour_message, _get_help_message, _skip_step_message ]:
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
	_add_editor_toolbar_button(toolbar, "○ BE", "Show bookend view", func() -> void:
		_step_count = 42
		set_current_step(0)
	)
	_add_editor_toolbar_button(toolbar, "○ S", "Show step view", func() -> void:
		_step_count = 42
		set_current_step(5)
	)

	toolbar.add_child(VSeparator.new())

	_add_editor_toolbar_label(toolbar, "Con")
	_add_editor_toolbar_button(toolbar, "× C", "Clear content", clear)
	_add_editor_toolbar_button(toolbar, "+ TX", "Add text content", func() -> void:
		if _bookend_view.visible:
			add_bookend_text([
				"At this point, you just hope it all works as intended. That's it. That's the purpose of the tour."
			], BookendTextStyle.RECAP)
			add_bookend_text([
				"Follow the steps to validate this proposition. Or don't. Here's a little more text to ensure we wrap around."
			], BookendTextStyle.KEY)
			add_bookend_text([
				"At the end, there will be nothing but a small sense of pride and accomplishment."
			], BookendTextStyle.INFO)
		else:
			add_text([
				"This is a test string!",
				"This line contains [b]formatting[/b] with [i]bbcode[/i].",
				"This line has a class name, [b]Control[/b].",
			])
	)
	_add_editor_toolbar_button(toolbar, "+ IM", "Add image content", func() -> void:
		var image_texture := load("res://godot-tour-screenshot.webp")
		add_texture(image_texture, 240.0)
	)
	_add_editor_toolbar_button(toolbar, "+ T1", "Add non-repeatable task", func() -> void:
		add_task("Press [i]any button[/i] to continue", 0, Callable(), Callable(), Callable())
	)
	_add_editor_toolbar_button(toolbar, "+ T2", "Add repeatable task", func() -> void:
		add_task("Do this [b]action[/b] several times", 5, Callable(), Callable(), Callable())
	)
	_add_editor_toolbar_button(toolbar, "+ T!", "Add completed task", func() -> void:
		add_task("This task is [b]complete[/b]", 0, func(task: TasksContainer.Task) -> int: return 1, Callable(), Callable())
	)
	_add_editor_toolbar_button(toolbar, "+ TE", "Add erred task", func() -> void:
		var error_func := func(task: TasksContainer.Task) -> bool:
			task.error = "And there is nothing you can do to fix this..."
			return true

		add_task("And this one has [u]an error[/u]", 0, func(task: TasksContainer.Task) -> int: return 0, error_func, Callable())
	)

	toolbar.add_child(VSeparator.new())

	_add_editor_toolbar_label(toolbar, "Msg")
	_add_editor_toolbar_button(toolbar, "- X", "Hide all messages", func() -> void:
		_hide_drawer_messages()
	)
	_add_editor_toolbar_button(toolbar, "○ C", "Show close tour message", func() -> void:
		_show_close_tour_message()
	)
	_add_editor_toolbar_button(toolbar, "○ H", "Show get help message", func() -> void:
		_show_get_help_message()
	)
	_add_editor_toolbar_button(toolbar, "○ S", "Show skip step message", func() -> void:
		_show_skip_step_message()
	)

	toolbar.add_child(VSeparator.new())

	_add_editor_toolbar_label(toolbar, "Avt")
	_add_editor_toolbar_button(toolbar, "L", "Align avatar to left", set_avatar_at.bind(AvatarAt.LEFT))
	_add_editor_toolbar_button(toolbar, "C", "Align avatar to center", set_avatar_at.bind(AvatarAt.CENTER))
	_add_editor_toolbar_button(toolbar, "R", "Align avatar to right", set_avatar_at.bind(AvatarAt.RIGHT))
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
