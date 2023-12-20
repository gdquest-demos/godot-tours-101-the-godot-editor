extends Node2D

# Maps weapon names to a hand look
const WEAPONS_HANDS_MAP := {
	"IcePunch": preload("hand_ice.png"),
	"RapidFire": preload("hand_fire.png"),
	"FireSpray": preload("hand_fire.png"),
	"LightningShot": preload("hand_lightning.png"),
}

const SELECT_SOUNDS_MAP := {
	"IcePunch": preload("select_ice.wav"),
	"RapidFire": preload("select_fire.wav"),
	"FireSpray": preload("select_fire.wav"),
	"LightningShot": preload("select_lightning.wav"),
}

@onready var _audio := $AudioStreamPlayer2D

@export var use_controller := false

var weapon: Weapon: set = set_weapon

var _weapons := []
var _weapon_index := -1: set = _set_weapon_index

@onready var _weapon_anchor: Marker2D = $WeaponAnchor

@onready var _weapon: Weapon = null
@onready var _hand_left: Sprite2D = $WeaponAnchor/HandLeft
@onready var _hand_right: Sprite2D = $WeaponAnchor/HandRight


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cycle_weapon_up"):
		_set_weapon_index(_weapon_index + 1)
	elif event.is_action_pressed("cycle_weapon_down"):
		_set_weapon_index(_weapon_index - 1)

	if use_controller and event is InputEventMouseMotion or event is InputEventKey:
		use_controller = false
	elif not use_controller and event is InputEventJoypadButton or event is InputEventJoypadMotion:
		use_controller = true


func _process(_delta: float) -> void:
	var aim_direction := Vector2.ZERO
	if use_controller:
		aim_direction = Vector2(
			Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
			Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
		)
	else:
		aim_direction = get_global_mouse_position() - global_position
	if aim_direction.length_squared() > 0.5:
		rotation = aim_direction.angle()

	z_index = 3
	if aim_direction.y < 0.0:
		z_index = 1


func add_weapon(new_weapon: PackedScene) -> void:
	for weapon_type in _weapons:
		if weapon_type.resource_path == new_weapon.resource_path:
			return

	_weapons.append(new_weapon)
	_set_weapon_index(_weapons.find(new_weapon))


func set_weapon(new_weapon: Weapon) -> void:
	if _weapon:
		_weapon_anchor.remove_child(_weapon)
		_weapon.queue_free()
	_weapon = new_weapon
	_weapon_anchor.add_child(_weapon)

	assert(_weapon.name in WEAPONS_HANDS_MAP, "Weapon %s not in %s" % [_weapon.name, WEAPONS_HANDS_MAP])
	var hand_texture: Texture2D = WEAPONS_HANDS_MAP[_weapon.name]
	_hand_left.texture = hand_texture
	_hand_right.texture = hand_texture

	assert(_weapon.name in SELECT_SOUNDS_MAP)
	_audio.stream = SELECT_SOUNDS_MAP[_weapon.name]
	_audio.play()


func _set_weapon_index(new_weapon_index: int) -> void:
	var weapon_count := _weapons.size()
	if weapon_count == 0:
		return

	var target_index := wrapi(new_weapon_index, 0, weapon_count)
	if target_index == _weapon_index:
		return

	_weapon_index = target_index
	set_weapon(_weapons[_weapon_index].instantiate())
