extends Weapon


func _init() -> void:
	_audio.stream = preload("shoot_ice.wav")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		shoot()


func shoot() -> void:
	var bullet: Node = bullet_scene.instantiate()
	add_child(bullet)
	bullet.setup(global_transform, max_range, max_bullet_speed, _random_angle)
	_audio.play()
