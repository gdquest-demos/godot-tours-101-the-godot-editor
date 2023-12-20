extends Weapon

@export var fire_rate := 4.0

var _cooldown: Timer


func _init() -> void:
	_audio.stream = preload("res://spells/shoot_fire.wav")


func _ready() -> void:
	super._ready()
	_cooldown = _create_cooldown_timer()
	add_child(_cooldown)


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("shoot") and _cooldown.is_stopped():
		shoot()


func shoot() -> void:
	_cooldown.start()

	var bullet: Node = bullet_scene.instantiate()
	add_child(bullet)
	bullet.setup(global_transform, max_range, max_bullet_speed, _random_angle)
	_audio.pitch_scale = randf_range(0.9, 1.6)
	_audio.play()


func _create_cooldown_timer() -> Timer:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.0 / fire_rate
	return timer
