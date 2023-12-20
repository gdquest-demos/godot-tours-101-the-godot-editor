extends Bullet

@onready var _sprite := $Sprite2D
@onready var _particles := $GPUParticles2D


func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	_audio.stream = preload("hit_lightning.wav")


func _on_body_entered(body: Node) -> void:
	hit_body(body)

	_audio.pitch_scale = randf_range(0.9, 1.2)
	_audio.play()

	_sprite.hide()
	_particles.emitting = true
	speed = 0.0

	await _audio.finished
	queue_free()
