extends Weapon

@export_range(100.0, 2000.0, 1.0) var min_range := 200.0
@export_range(100.0, 3000.0, 1.0) var min_bullet_speed := 800.0

@export_range(1, 30) var min_amount := 6
@export_range(1, 30) var max_amount := 9


func _init() -> void:
	_audio.stream = preload("res://common/laser.wav")
	assert(min_range < max_range)
	assert(min_bullet_speed < max_bullet_speed)
	assert(min_amount < max_amount)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		shoot()


func shoot() -> void:
	var bullet_count := randf_range(min_amount, max_amount + 1)

	for i in bullet_count:
		var bullet := bullet_scene.instantiate()
		add_child(bullet)
		var fire_range := randf_range(min_range, max_range)
		var speed := randf_range(min_bullet_speed, max_bullet_speed)
		bullet.setup(global_transform, fire_range, speed, _random_angle)

	_audio.play()
