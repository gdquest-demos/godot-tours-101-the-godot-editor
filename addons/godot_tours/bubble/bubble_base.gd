## Base class for the text bubble used to display instructions to the user.
## Check out ["addons/godot_tours/bubble/default_bubble.gd"] for the default implementation.
@tool
@abstract
extends CanvasLayer

## Emitted to go backward one step in the tour.
signal prev_step_requested
## Emitted to go forward one step in the tour.
signal next_step_requested
## Emitted when the user confirms wanting to quit the tour.
signal close_requested
## Emitted when the user confirms wanting to finish the tour (for example, when they finish the last step).
signal finish_requested
## Emitted when the user asks to locate the log file for the tour.
signal log_requested

const EditorInterfaceAccess := preload("res://addons/gdquest_editor_interface/editor_interface_access.gd")
const EditorNodePoints := EditorInterfaceAccess.Enums.NodePoint

const Utils := preload("../utils.gd")

const DRAG_MARGIN := 32.0

enum State { IDLE, DRAGGING }
enum At {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_LEFT,
	CENTER_LEFT,
	TOP_CENTER,
	BOTTOM_CENTER,
	CENTER_RIGHT,
	CENTER,
}
enum AvatarAt {
	LEFT, CENTER, RIGHT,
	PRIME_LEFT, PRIME_CENTER, PRIME_RIGHT,
}
enum BookendTextStyle { INFO, RECAP, KEY }

class StateData:
	## Bubble's interaction state.
	var state: State = State.IDLE
	## Bubble position relative to the reference [Control].
	var bubble_at := At.CENTER
	## Avatar position relative to the bubble's top edge.
	var avatar_at := AvatarAt.LEFT

	## Reference [Control] node that the bubble is aligned to. See
	## [method move_and_anchor].
	var ref_control: Control = null
	## Margin offset from the relevant edge of the reference [Control]. See
	## [method move_and_anchor].
	var margin_offset := 16.0
	## Additional offset for the positioned bubble. See [method move_and_anchor].
	var extra_offset := Vector2.ZERO

	## If set to [code]true[/code], the bubble was recently moved by the user.
	var was_moved := false

var is_debug_mode: bool = false:
	set = set_is_debug_mode

var _state_data: StateData = StateData.new()
var _step_count: int = 0
var _current_step_index: int = 0

var _bubble_transition_position: Vector2 = Vector2.ZERO
var _bubble_transition_tween: Tween = null
var _avatar_transition_tween: Tween = null

var _height_limiter_queued: bool = false
var _retransition_queued: bool = false

## Root node responsible for positioning.
@onready var _bubble_anchor: Control = %BubbleAnchor
## Root node responsible for size and containing the contents.
@onready var _bubble_container: Control = %BubbleContainer
## Anchor point for the decorative avatar.
@onready var _avatar_anchor: Control = %AvatarAnchor
## Decorative avatar floating alongside the content edge.
@onready var _avatar: Node2D = %Avatar


# Lifecycle.

func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_bubble_anchor = %BubbleAnchor
		_bubble_container = %BubbleContainer
		_avatar = %Avatar


func setup(step_count: int) -> void:
	_step_count = step_count
	_current_step_index = 0

	# Default anchoring to prevent the bubble from moving unexpectedly.
	# Use move_and_anchor() to override this.
	move_and_anchor(EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_ROOT), At.CENTER)


func _ready() -> void:
	Utils.set_plugin_translation_domain(self, Utils.TranslationDomains.BUBBLE_UI)
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	_bubble_container.gui_input.connect(_panel_gui_input)
	_bubble_container.custom_minimum_size *= EditorInterface.get_editor_scale()
	_bubble_anchor.theme = Utils.get_default_theme()

	_transition_bubble(true)


func _input(event: InputEvent) -> void:
	if not (_state_data.state == State.DRAGGING):
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_state_data.state = State.IDLE

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion

		# Ensure the bubble stays within the editor's bounds.
		_bubble_anchor.position = _fit_anchor_position(_bubble_anchor.position + mm.screen_relative)
		_state_data.was_moved = true


func _panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _is_point_in_drag_margin(mb.position):
			_state_data.state = State.DRAGGING

	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _is_point_in_drag_margin(mm.position) or _state_data.state == State.DRAGGING:
			_bubble_container.mouse_default_cursor_shape = Control.CURSOR_MOVE
		else:
			_bubble_container.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _is_point_in_drag_margin(point: Vector2) -> bool:
	var drag_margin := DRAG_MARGIN * EditorInterface.get_editor_scale()
	return (
		point.y <= drag_margin
		or point.y >= _bubble_container.size.y - drag_margin
		or point.x <= drag_margin
		or point.x >= _bubble_container.size.x - drag_margin
	)


## [b]Virtual[/b] method for changing the translation domain of content elements.
func set_content_translation_domain(domain_name: String) -> void:
	pass


## [b]Virtual[/b] method for toggling the debug mode for this bubble.
func set_is_debug_mode(value: bool) -> void:
	is_debug_mode = value


# Navigation.

## [b]Virtual[/b] method for reacting to the tour step change. See ["addons/godot_tours/tour.gd"]
## [code]step_changed[/code] signal for details.
func set_current_step(index: int) -> void:
	_current_step_index = index

	if is_debug_mode:
		print_debug("TOUR STEP: ", _current_step_index)


# Content.

## [b]Virtual[/b] method called at the beginning of every tour step for clearing anything necessary.
@abstract func clear() -> void


## [b]Virtual[/b] method for setting the title of the bookend view.
func set_bookend_title(text: String) -> void:
	pass


## [b]Virtual[/b] method to add text content to the bookend view.
func add_bookend_text(text: Array[String], style: BookendTextStyle = BookendTextStyle.INFO) -> void:
	pass


## [b]Virtual[/b] method for setting the button text in the bookend view.
func set_bookend_button_text(text: String) -> void:
	pass


## [b]Virtual[/b] method to set the bubble title.
func set_title(title_text: String) -> void:
	pass


## [b]Virtual[/b] method to insert an arbitrary Control-based element.
func add_custom_element(element: Control) -> void:
	pass


## [b]Virtual[/b] method to insert lines of text.
func add_text(text: Array[String]) -> void:
	pass


## [b]Virtual[/b] method to insert a code snippet.
func add_code(code: Array[String]) -> void:
	pass


## [b]Virtual[/b] method to insert a texture image.
func add_texture(texture: Texture2D, max_height := 0.0) -> void:
	pass


## [b]Virtual[/b] method to insert a video.
func add_video(video: VideoStream) -> void:
	pass


# Tasks.

## [b]Virtual[/b] method to add a task.
func add_task(description: String, repeat: int, repeat_callable: Callable, error_predicate: Callable, setup_callable: Callable) -> void:
	pass


## [b]Virtual[/b] method for checking if all tasks are done.
## Returns [code]true[/code] or [code]false[/code] based on the status of all tasks.
func check_tasks() -> bool:
	return false


# Positioning and transitions.

## [b]Virtual[/b] method to force a minimum size of the bubble's content.
func ensure_minimum_size(size: Vector2) -> void:
	pass


func _update_content_size() -> void:
	_queue_update_height_limits()
	_queue_retransition_bubble()


## Moves and anchors the bubble relative to the given control node. Check out [member at],
## [member margin_offset], and [member extra_offset] for details on the parameters.
func move_and_anchor(control: Control, at := At.CENTER, margin := 16.0, extra_offset := Vector2.ZERO) -> void:
	_state_data.ref_control = control
	_state_data.bubble_at = at
	_state_data.margin_offset = margin
	_state_data.extra_offset = extra_offset
	_state_data.was_moved = false

	if _state_data.ref_control == null: # Always anchor to something.
		_state_data.ref_control = EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_ROOT)

	_transition_bubble.call_deferred() # Allow the layout to settle.


func _fit_anchor_position(value: Vector2) -> Vector2:
	var layout_root: Control = EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_ROOT)
	var point_tl := _bubble_container.size / 2.0
	var point_br := layout_root.size - _bubble_container.size / 2.0

	var fitted_position := value
	fitted_position.x = clampf(fitted_position.x, point_tl.x, point_br.x)
	fitted_position.y = clampf(fitted_position.y, point_tl.y, point_br.y)

	return fitted_position


func _queue_update_height_limits() -> void:
	if _height_limiter_queued:
		return

	_height_limiter_queued = true
	_update_height_limits.call_deferred()


## [b]Virtual[/b] method for updating shrinkable content.
func _update_height_limits() -> void:
	_height_limiter_queued = false


func _transition_bubble(immediate: bool = false) -> void:
	if not is_node_ready() or _state_data.ref_control == null:
		return

	var margin_offset := Vector2.ZERO
	var anchor_offset := Vector2.ZERO
	var control_size := _state_data.ref_control.size

	match _state_data.bubble_at:
		At.TOP_LEFT:
			margin_offset = _state_data.margin_offset * Vector2(1.0, 1.0)
			anchor_offset = _bubble_container.size / 2.0
		At.TOP_CENTER:
			margin_offset = _state_data.margin_offset * Vector2(0.0, 1.0)
			anchor_offset = Vector2(control_size.x / 2.0, _bubble_container.size.y / 2.0)
		At.TOP_RIGHT:
			margin_offset = _state_data.margin_offset * Vector2(-1.0, 1.0)
			anchor_offset = Vector2(control_size.x - _bubble_container.size.x / 2.0, _bubble_container.size.y / 2.0)
		At.BOTTOM_RIGHT:
			margin_offset = _state_data.margin_offset * Vector2(-1.0, -1.0)
			anchor_offset = control_size - _bubble_container.size / 2.0
		At.BOTTOM_CENTER:
			margin_offset = _state_data.margin_offset * Vector2(0.0, -1.0)
			anchor_offset = Vector2(control_size.x / 2.0, control_size.y - _bubble_container.size.y / 2.0)
		At.BOTTOM_LEFT:
			margin_offset = _state_data.margin_offset * Vector2(1.0, -1.0)
			anchor_offset = Vector2(_bubble_container.size.x / 2.0, control_size.y - _bubble_container.size.y / 2.0)
		At.CENTER_LEFT:
			margin_offset = _state_data.margin_offset * Vector2(1.0, 0.0)
			anchor_offset = Vector2(_bubble_container.size.x / 2.0, control_size.y / 2.0)
		At.CENTER_RIGHT:
			margin_offset = _state_data.margin_offset * Vector2(-1.0, 0.0)
			anchor_offset = Vector2(control_size.x - _bubble_container.size.x / 2.0, control_size.y / 2.0)
		At.CENTER:
			margin_offset = Vector2.ZERO
			anchor_offset = control_size / 2.0

	_bubble_transition_position = _state_data.ref_control.global_position + margin_offset + anchor_offset + _state_data.extra_offset
	_bubble_transition_position = _fit_anchor_position(_bubble_transition_position)

	if immediate:
		_bubble_anchor.position = _bubble_transition_position
		return

	if is_instance_valid(_bubble_transition_tween):
		_bubble_transition_tween.kill()
		_bubble_transition_tween = null

	_bubble_transition_tween = create_tween()
	_bubble_transition_tween.set_parallel(true)
	_bubble_transition_tween.set_ease(Tween.EASE_OUT)
	_bubble_transition_tween.set_trans(Tween.TRANS_CUBIC)
	var must_tween := false

	const TWEEN_DURATION := 0.25

	if not _bubble_anchor.position.is_equal_approx(_bubble_transition_position):
		# NOTE: This is why we need the anchor; setting position on the container here locks its
		# current size and it stop being responsive to its contents. Splitting responsibilities
		# works around that.
		_bubble_transition_tween.tween_property(
			_bubble_anchor,
			"position",
			_bubble_transition_position,
			TWEEN_DURATION,
		)
		must_tween = true

	if not must_tween:
		_bubble_transition_tween.kill()
		_bubble_transition_tween = null


func _queue_retransition_bubble() -> void:
	if _retransition_queued:
		return

	_retransition_queued = true
	_retransition_bubble.call_deferred()


func _retransition_bubble() -> void:
	_retransition_queued = false

	# Move the bubble back into the editor view, if it managed to escape due to
	# bad alignment or resize. Only do this when necessary, so we don't override
	# manually positioned bubbles (unless they require this fix).

	var layout_root: Control = EditorInterfaceAccess.get_node(EditorNodePoints.LAYOUT_ROOT)
	var layout_rect := layout_root.get_global_rect()
	var bubble_rect := _bubble_container.get_global_rect()
	if _bubble_transition_tween: # When mid-transition, use the target position.
		bubble_rect.position = _bubble_transition_position

	# Quickly check if not the entire area is on screen.
	if bubble_rect.intersection(layout_rect).get_area() >= bubble_rect.get_area():
		return

	if _bubble_transition_tween:
		_transition_bubble(false)
	else:
		_transition_bubble(true)


## Sets the avatar location at the top of the bubble. Check [member avatar_at] for details on
## the parameter.
func set_avatar_at(at := AvatarAt.LEFT) -> void:
	_state_data.avatar_at = at
	_transition_avatar.call_deferred() # Allow the layout to settle.


func _transition_avatar(immediate: bool = false) -> void:
	if not is_node_ready():
		return

	var new_anchor_position := 0.0
	var new_avatar_position := Vector2.ZERO
	var new_avatar_rotation := 0.0
	var new_avatar_scale := Vector2.ONE

	match _state_data.avatar_at:
		AvatarAt.LEFT:
			new_anchor_position = 0.0
			new_avatar_position = Vector2(-8.0, -8.0)
			new_avatar_rotation = -15.0
			new_avatar_scale = Vector2(0.35, 0.35)
		AvatarAt.CENTER:
			new_anchor_position = 0.5
			new_avatar_position = Vector2(0.0, -12.0)
			new_avatar_rotation = -4.0
			new_avatar_scale = Vector2(0.35, 0.35)
		AvatarAt.RIGHT:
			new_anchor_position = 1.0
			new_avatar_position = Vector2(3.0, -8.0)
			new_avatar_rotation = 7.5
			new_avatar_scale = Vector2(0.35, 0.35)

		AvatarAt.PRIME_LEFT:
			new_anchor_position = 0.0
			new_avatar_position = Vector2(42.0, 12.0)
			new_avatar_rotation = -6.12
			new_avatar_scale = Vector2(0.5, 0.5)
		AvatarAt.PRIME_CENTER:
			new_anchor_position = 0.5
			new_avatar_position = Vector2(0.0, -32.0)
			new_avatar_rotation = -6.12
			new_avatar_scale = Vector2(0.5, 0.5)
		AvatarAt.PRIME_RIGHT:
			new_anchor_position = 1.0
			new_avatar_position = Vector2(-38.0, 12.0)
			new_avatar_rotation = 6.12
			new_avatar_scale = Vector2(0.5, 0.5)

	# Don't scale when editing in the editor.
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root() != self:
		var editor_scale := EditorInterface.get_editor_scale()
		new_avatar_position *= editor_scale
		new_avatar_scale *= editor_scale

	if immediate:
		_avatar_anchor.anchor_left = new_anchor_position
		_avatar_anchor.anchor_right = new_anchor_position
		_avatar.position = new_avatar_position
		_avatar.rotation_degrees = new_avatar_rotation
		_avatar.scale = new_avatar_scale
		return

	if is_instance_valid(_avatar_transition_tween):
		_avatar_transition_tween.kill()
		_avatar_transition_tween = null

	_avatar_transition_tween = create_tween()
	_avatar_transition_tween.set_parallel(true)
	_avatar_transition_tween.set_ease(Tween.EASE_OUT)
	_avatar_transition_tween.set_trans(Tween.TRANS_CUBIC)
	var must_tween := false

	const TWEEN_DURATION := 0.15

	if not is_equal_approx(_avatar_anchor.anchor_left, new_anchor_position):
		_avatar_transition_tween.tween_property(
			_avatar_anchor,
			"anchor_left",
			new_anchor_position,
			TWEEN_DURATION,
		)
		_avatar_transition_tween.tween_property(
			_avatar_anchor,
			"anchor_right",
			new_anchor_position,
			TWEEN_DURATION,
		)
		must_tween = true

	if not _avatar.position.is_equal_approx(new_avatar_position):
		_avatar_transition_tween.tween_property(
			_avatar,
			"position",
			new_avatar_position,
			TWEEN_DURATION,
		)
		must_tween = true

	if not is_equal_approx(_avatar.rotation, new_avatar_rotation):
		_avatar_transition_tween.tween_property(
			_avatar,
			"rotation_degrees",
			new_avatar_rotation,
			TWEEN_DURATION,
		)
		must_tween = true

	if not _avatar.scale.is_equal_approx(new_avatar_scale):
		_avatar_transition_tween.tween_property(
			_avatar,
			"scale",
			new_avatar_scale,
			TWEEN_DURATION,
		)
		must_tween = true

	if not must_tween:
		_avatar_transition_tween.kill()
		_avatar_transition_tween = null
