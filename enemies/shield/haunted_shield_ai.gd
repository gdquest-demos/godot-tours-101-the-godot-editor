extends BaseEnemyAI

const ATTACK_RANGE := 300.0 * 300.0

const BulletScene := preload("res://spells/bullets/fireball.tscn")

@export_range(0.5, 3.0, 0.1) var attack_cooldown := 2.0
@export_range(0.5, 3.0, 0.1) var charge_duration := 1.0
## Maximum random angle applied to the shot bullets. Controls the gun's precision.
@export_range(0.0, 30.0, 1.0) var random_angle_degrees := 10.0
## Maximum range a bullet can travel before it disappears.
@export_range(100.0, 2000.0, 1.0) var max_range := 2000.0
## The speed of the shot bullets
@export_range(100.0, 3000.0, 1.0) var max_bullet_speed := 400.0

var _float_offset = randf_range(0.0, 5.0)
var _random_angle := deg_to_rad(random_angle_degrees)
var _cooldown_timer := Timer.new()
var _charge_timer := Timer.new()

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super._ready()

	add_child(_cooldown_timer)
	_cooldown_timer.one_shot = true
	_cooldown_timer.wait_time = attack_cooldown

	add_child(_charge_timer)
	_charge_timer.one_shot = true
	_charge_timer.wait_time = attack_cooldown

	activate()


func _physics_process(_delta: float) -> void:
	_sprite.position.y = sin(Time.get_ticks_msec() / 200.0 + _float_offset) * 8.0
	if not _is_active:
		return

	_target = find_target()
	if not _target:
		return

	var distance := global_position.distance_squared_to(_target.global_position)
	if distance < ATTACK_RANGE:
		orbit_target()
		attack()
	else:
		follow(_target.global_position)


func attack() -> void:
	if not _cooldown_timer.is_stopped() or not _charge_timer.is_stopped():
		return

	_charge_timer.start()
	_sprite.texture = texture_active

	await _charge_timer.timeout

	_sprite.texture = texture_inactive

	if not _target:
		return

	var direction := global_position.direction_to(_target.global_position)
	var bullet: Node = BulletScene.instantiate()
	bullet.setup(
		Transform2D(direction.angle(), global_position), max_range, max_bullet_speed, _random_angle
	)
	get_tree().root.add_child(bullet)
	bullet.collision_mask = 1
	_cooldown_timer.start()
