@tool
extends SubViewportContainer

const Highlight := preload("../highlight/highlight.gd")
const FlashArea := preload("../flash_area/flash_area.gd")

const HighlightPackedScene := preload("../highlight/highlight.tscn")
const FlashAreaPackedScene := preload("../flash_area/flash_area.tscn")
const DimmerMaskPackedScene := preload("dimmer_mask.tscn")

var _highlight_mask_map: Dictionary[Highlight, ColorRect] = {}
var _highlights_pool: Array[Highlight] = []
var _flash_area_pool: Array[FlashArea] = []
var _dimmer_masks_pool: Array[ColorRect] = []

@onready var window := get_window()
@onready var film_color_rect: ColorRect = %FilmColorRect


func _enter_tree() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 0)


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return

	for highlight in _highlight_mask_map:
		highlight.refresh()


func _exit_tree() -> void:
	for highlight in _highlights_pool:
		highlight.queue_free()
	_highlights_pool.clear()

	for highlight in _flash_area_pool:
		highlight.queue_free()
	_flash_area_pool.clear()

	for mask in _dimmer_masks_pool:
		mask.queue_free()
	_dimmer_masks_pool.clear()


# Highlights.

func add_highlight(getters: Array[Callable], play_flash := false) -> void:
	if getters.is_empty():
		return

	var highlight := _highlights_pool.pop_back()
	if not highlight:
		highlight = HighlightPackedScene.instantiate()

	add_child(highlight)
	highlight.setup(getters)
	if play_flash:
		highlight.flash()

	_highlight_mask_map[highlight] = add_mask()
	highlight.rect_changed.connect(_refresh_highlight_mask.bind(highlight))
	_refresh_highlight_mask(highlight)


func clear_highlights() -> void:
	for highlight in _highlight_mask_map:
		var mask := _highlight_mask_map[highlight]
		film_color_rect.remove_child(mask)
		_dimmer_masks_pool.push_back(mask)

	_highlight_mask_map.clear()

	for child_node in get_children():
		if child_node is Highlight:
			remove_child(child_node)
			child_node.rect_changed.disconnect(_refresh_highlight_mask.bind(child_node))
			_highlights_pool.push_back(child_node)


func _refresh_highlight_mask(highlight: Highlight) -> void:
	if not _highlight_mask_map.has(highlight):
		return

	var mask := _highlight_mask_map[highlight]
	mask.global_position = highlight.global_position
	mask.size = highlight.custom_minimum_size
	mask.visible = highlight.visible


func add_mask() -> ColorRect:
	var mask := _dimmer_masks_pool.pop_back()
	if not mask:
		mask = DimmerMaskPackedScene.instantiate()

	film_color_rect.add_child(mask)
	return mask


# Flashing.

func add_flash_area(control: Control, target_rect: Rect2) -> void:
	if not control or not target_rect.has_area():
		return

	var flash_area := _flash_area_pool.pop_back()
	if not flash_area:
		flash_area = FlashAreaPackedScene.instantiate()

	add_child(flash_area)
	flash_area.setup(control, target_rect)
