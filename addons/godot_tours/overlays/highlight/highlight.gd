## Highlights are used to show the user where to click.
## They carve into the dimmer mask ColorRect and display an outline around the clickable area.
## They can optionally play a flash animation to draw attention to a specific area of the editor.
@tool
extends Panel

signal rect_changed

# NOTE: Keep in sync with the scene.
const HIGHLIGHT_GROUP := "highlight"

# We duplicate and scale the highlight stylebox so the outline scales with the editor scale.
# Duplicating here allows us to pass the style to each created highlight.
const HighlightStyle := preload("highlight.tres")
static var _highlight_style_scaled: StyleBoxFlat = HighlightStyle.duplicate(true)

var rect_getters: Array[Callable] = []

@onready var flash_area: ColorRect = %FlashArea


static func _static_init() -> void:
	_scale_stylebox_with_editor(_highlight_style_scaled)


# TODO: Consider extracting into the theme utils plugin.
static func _scale_stylebox_with_editor(stylebox: StyleBoxFlat) -> void:
	var editor_scale := EditorInterface.get_editor_scale()
	stylebox.border_width_bottom *= editor_scale
	stylebox.border_width_left *= editor_scale
	stylebox.border_width_right *= editor_scale
	stylebox.border_width_top *= editor_scale

	stylebox.corner_radius_bottom_left *= editor_scale
	stylebox.corner_radius_bottom_right *= editor_scale
	stylebox.corner_radius_top_left *= editor_scale
	stylebox.corner_radius_top_right *= editor_scale

	stylebox.expand_margin_left *= editor_scale
	stylebox.expand_margin_right *= editor_scale
	stylebox.expand_margin_top *= editor_scale
	stylebox.expand_margin_bottom *= editor_scale


func setup(rect_getters: Array[Callable]) -> void:
	add_theme_stylebox_override("panel", _highlight_style_scaled)

	self.rect_getters.clear()
	self.rect_getters.append_array(rect_getters)
	refresh.call_deferred()


func flash() -> void:
	flash_area.visible = true


func refresh() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	var highlight_rect := Rect2()
	for index in range(rect_getters.size()):
		var getter_rect := rect_getters[index].call()
		if not getter_rect.has_area():
			continue

		if highlight_rect.has_area():
			highlight_rect = highlight_rect.merge(getter_rect)
		else:
			highlight_rect = getter_rect

	global_position = highlight_rect.position
	custom_minimum_size = highlight_rect.size
	visible = highlight_rect.has_area()
	rect_changed.emit()

	reset_size.call_deferred()
