extends ParallaxBackground

@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	animation_player.speed_scale = 0.15
