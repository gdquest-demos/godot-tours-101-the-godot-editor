class_name Weapon
extends Node2D

@export var bullet_scene: PackedScene = preload("bullets/fireball.tscn")

## Maximum random angle applied to the shot bullets. Controls the gun's precision.
@export_range(0.0, 360.0, 1.0) var random_angle_degrees := 10.0
## Maximum range a bullet can travel before it disappears.
@export_range(100.0, 2000.0, 1.0) var max_range := 2000.0
## The speed of the shot bullets
@export_range(100.0, 3000.0, 1.0) var max_bullet_speed := 1500.0

var _audio := AudioStreamPlayer2D.new()

@warning_ignore("unused_private_class_variable")
@onready var _random_angle := deg_to_rad(random_angle_degrees)


func _ready() -> void:
	assert(bullet_scene != null, 'Bullet Scene is not provided for "%s"' % [get_path()])
	add_child(_audio)


## Must be overwritten by scripts that extend this class to fire bullets.
func shoot() -> void:
	pass
