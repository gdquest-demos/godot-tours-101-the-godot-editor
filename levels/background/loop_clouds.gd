extends Node2D

@export var speed := 0.1
@onready var animation_player := $AnimationPlayer

func _ready() -> void:
	animation_player.speed_scale = speed
