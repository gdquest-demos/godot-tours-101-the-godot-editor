class_name Bullet
extends Area2D

@export var default_speed := 750.0
@export var damage := 1

var max_range := 1000.0

var _travelled_distance = 0.0
var _audio := AudioStreamPlayer2D.new()

@onready var speed := default_speed


func _init() -> void:
	set_as_top_level(true)
	add_child(_audio)


func _physics_process(delta: float) -> void:
	var distance := speed * delta
	var motion := transform.x * speed * delta

	position += motion

	_travelled_distance += distance
	if _travelled_distance > max_range:
		_destroy()


func setup(
	new_global_transform: Transform2D,
	new_range: float,
	new_speed := default_speed,
	random_rotation: float = 0.0
) -> void:
	transform = new_global_transform
	max_range = new_range
	speed = new_speed
	randomize_rotation(random_rotation)


func randomize_rotation(max_angle: float) -> void:
	rotation += randf() * max_angle - max_angle / 2.0


func hit_body(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	body.take_damage(damage)


func _destroy() -> void:
	pass
