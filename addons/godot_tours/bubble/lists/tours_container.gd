@tool
extends MarginContainer

signal tour_selected
signal reset_requested(tour: GDTourMetadata.Tour)

const GDTourMetadata = preload("../../gdtour_metadata.gd")

const TourItem := preload("tour_item.gd")
const TourPackedScene: PackedScene = preload("tour_item.tscn")

var _selected_item: TourItem = null

@onready var _tour_list: VBoxContainer = %List


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_tour_list = %List


func create_tour(tour_metadata: GDTourMetadata.Tour, sample_mode: bool = false) -> TourItem:
	var tour := TourPackedScene.instantiate()
	tour.tour_metadata = tour_metadata
	tour.sample_mode = sample_mode

	_tour_list.add_child(tour)
	tour.pressed.connect(_select_tour.bind(tour))
	tour.reset_pressed.connect(_reset_tour.bind(tour))

	return tour


func has_tours() -> bool:
	return _tour_list.get_child_count() > 0


func clear_tours() -> void:
	_selected_item = null

	for child_node in _tour_list.get_children():
		_tour_list.remove_child(child_node)
		child_node.queue_free()


func _select_tour(tour: TourItem) -> void:
	if _selected_item == tour:
		return

	if _selected_item:
		_selected_item.set_selected(false)

	_selected_item = tour

	if _selected_item:
		_selected_item.set_selected(true)

	tour_selected.emit()


func _reset_tour(tour: TourItem) -> void:
	if not tour:
		return

	reset_requested.emit(tour.tour_metadata)


func get_selected_tour() -> GDTourMetadata.Tour:
	if not is_instance_valid(_selected_item):
		return null

	return _selected_item.tour_metadata
