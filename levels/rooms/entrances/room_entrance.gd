@tool
class_name RoomEntrance
extends Node

signal player_entered

@onready var _collider := $StaticBody2D/CollisionShape2D as CollisionShape2D
@onready var _animation_player := $AnimationPlayer as AnimationPlayer


func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	_animation_player.play("RESET")


func open() -> void:
	_collider.set_deferred("disabled", true)
	_animation_player.play("close", -1, -1, true)


func close() -> void:
	_collider.set_deferred("disabled", false)
	_animation_player.play("close")


func _on_body_entered(_body: Node) -> void:
	emit_signal("player_entered")
