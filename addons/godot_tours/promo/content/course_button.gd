@tool
extends LinkButton

@export var icon: Texture2D = null:
	set = set_icon
@export var icon_size: Vector2 = Vector2.ZERO:
	set = set_icon_size
@export var icon_separation: float = 0.0:
	set = set_icon_separation

var _text_buffer: TextLine = TextLine.new()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_text_buffer()


func _ready() -> void:
	_update_text_buffer()


func _draw() -> void:
	if not icon:
		return

	var icon_rect := Rect2()
	icon_rect.size = icon_size
	icon_rect.position.x = size.x - icon_size.x
	icon_rect.position.y = (size.y - icon_size.y) / 2.0

	draw_texture_rect(icon, icon_rect, false)


# Properties.

func set_icon(value: Texture2D) -> void:
	if icon == value:
		return

	icon = value
	_update_custom_size()


func set_icon_size(value: Vector2) -> void:
	if icon_size == value:
		return

	icon_size = value
	_update_custom_size()


func set_icon_separation(value: float) -> void:
	if icon_separation == value:
		return

	icon_separation = value
	_update_custom_size()


# Helpers.

func _update_text_buffer() -> void:
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")

	_text_buffer.clear()
	_text_buffer.add_string(text, font, font_size)
	_update_custom_size()


func _update_custom_size() -> void:
	var minsize := _text_buffer.get_size()

	var scale_factor := 1.0
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root() == self:
		scale_factor = EditorInterface.get_editor_scale()

	if icon:
		minsize.x += (icon_separation + icon_size.x) * scale_factor
		minsize.y = maxf(minsize.y, icon_size.y * scale_factor)

	custom_minimum_size = minsize
	queue_redraw()
