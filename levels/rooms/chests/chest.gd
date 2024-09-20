extends Area2D

const LOOT_SCENES := [
	preload("res://pickups/weapon_pickup.tscn"),
	preload("res://pickups/health_pickup.tscn")
]

@onready var _animation_player := $AnimationPlayer as AnimationPlayer
@onready var _path_follow := $Path2D/PathFollow2D as PathFollow2D


func loot() -> void:
	_animation_player.play("open")


func create_pickup() -> void:
	var loot_instance = LOOT_SCENES[randi() % LOOT_SCENES.size()].instantiate()
	_path_follow.add_child.call_deferred(loot_instance)
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_path_follow, "progress_ratio", 1, 0.3)
	tween.play()


func _on_body_entered(_body: Node2D) -> void:
	loot()
