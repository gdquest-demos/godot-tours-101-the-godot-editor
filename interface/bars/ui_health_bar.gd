class_name UIHealthBar
extends Control

const TEXTURE_EMPTY := preload("health_point_bg.png")
const TEXTURE_HEART_FULL := preload("health_point.png")

var max_health := 10
var health := max_health: set = set_health

@onready var _row := $HBoxContainer as HBoxContainer


func _ready() -> void:
	set_health(5)


func set_health(new_health: int) -> void:
	health = new_health
	for index in _row.get_child_count():
		var heart: TextureRect = _row.get_child(index)
		if health > index:
			heart.texture = TEXTURE_HEART_FULL
		else:
			heart.texture = TEXTURE_EMPTY


func _on_player_health_changed(new_health) -> void:
	set_health(new_health)
