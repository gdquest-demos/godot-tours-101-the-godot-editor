@tool
extends ColorRect

var ref_control: Control = null
var target_rect: Rect2 = Rect2()

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	animation_player.play("flash")


func setup(ref_control: Control, target_rect: Rect2) -> void:
	if is_instance_valid(self.ref_control):
		self.ref_control.draw.disconnect(refresh)

	self.ref_control = ref_control
	self.target_rect = target_rect

	if is_instance_valid(self.ref_control):
		self.ref_control.draw.connect(refresh)

	refresh()


func refresh() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root == null or not is_instance_valid(ref_control):
		size = Vector2.ZERO
		global_position = Vector2.ZERO
		visible = false
		return

	var flashing_rect := scene_root.get_viewport().get_screen_transform() * target_rect
	flashing_rect = ref_control.get_global_rect().intersection(flashing_rect)

	size = flashing_rect.size
	global_position = flashing_rect.position
	visible = (flashing_rect.has_area() and ref_control.is_visible_in_tree())
