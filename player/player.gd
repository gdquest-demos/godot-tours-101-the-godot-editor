class_name Player
extends CharacterBody2D

signal health_changed(new_health)
signal died

const PAIN_SOUNDS := [
	preload("pain_01.wav"),
	preload("pain_02.wav"),
	preload("pain_03.wav"),
	preload("pain_04.wav"),
	preload("pain_05.wav"),
]
const DEATH_SOUNDS := [
	preload("death_01.wav"),
	preload("death_02.wav"),
	preload("death_03.wav"),
]

@export var max_health := 5
@export var speed := 460.0
@export var drag_factor := 5.0

var health := max_health: set = set_health

@onready var _camera: ShakingCamera2D = $ShakingCamera2D
@onready var _weapon_holder := $WeaponHolder

@onready var _damage_audio = $DamageAudio


func _ready() -> void:
	add_weapon(preload("res://spells/rapid_fire.tscn"))


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	var move_direction := input_vector.normalized()

	var desired_velocity := speed * move_direction
	var steering := desired_velocity - velocity
	velocity += steering / drag_factor
	set_velocity(velocity)
	move_and_slide()
	velocity = velocity


func take_damage(amount: int) -> void:
	set_health(health - amount)
	if health == 0:
		emit_signal("died")
		_damage_audio.stream = DEATH_SOUNDS[randi() % DEATH_SOUNDS.size()]
	else:
		_damage_audio.stream = PAIN_SOUNDS[randi() % PAIN_SOUNDS.size()]

	_damage_audio.play()
	_camera.shake_intensity += 0.75


func add_weapon(weapon: PackedScene) -> void:
	_weapon_holder.add_weapon(weapon)


func set_health(new_health: int) -> void:
	health = clamp(new_health, 0, max_health)
	emit_signal("health_changed", new_health)


func _on_ExitDetector2D_area_entered(_area: Area2D) -> void:
	get_tree().reload_current_scene()
