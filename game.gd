extends Node2D

@onready var _player: Player = find_child("Player", false)
@onready var _health_bar: Control = get_node_or_null("UILayer/UIHealthBar")
@onready var _invisible_walls := $InvisibleWalls

func _ready() -> void:
	_invisible_walls.hide()

	if _player:
		_player.connect("died", Callable(self, "_on_Player_died"))

	if _health_bar:
		_health_bar.set_health(_player.health)


func _on_Player_died() -> void:
	get_tree().change_scene_to_file("res://game_over.tscn")
