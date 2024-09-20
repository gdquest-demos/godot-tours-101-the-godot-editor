class_name Pickup
extends Area2D

@warning_ignore("unused_private_class_variable")
@onready var _audio := $AudioStreamPlayer2D as AudioStreamPlayer2D
@onready var _animation_player := $AnimationPlayer as AnimationPlayer


func _ready() -> void:
	_animation_player.play("idle")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	_pickup(body)
	_animation_player.play("destroy")
	set_deferred("monitoring", false)


func _pickup(_player: Player) -> void:
	pass
