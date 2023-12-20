## Changes the player's current weapon randomly from a list of all cannons.
extends Pickup

const ICONS_MAP := {
	preload("res://spells/fire_spray.tscn"): preload("pickup_fire.png"),
	preload("res://spells/rapid_fire.tscn"): preload("pickup_fire.png"),
	preload("res://spells/ice_punch.tscn"): preload("pickup_ice.png"),
	preload("res://spells/lightning_shot.tscn"): preload("pickup_lightning.png"),
}

const SOUNDS_MAP := {
	preload("res://spells/fire_spray.tscn"): preload("pickup_fire.wav"),
	preload("res://spells/rapid_fire.tscn"): preload("pickup_fire.wav"),
	preload("res://spells/ice_punch.tscn"): preload("pickup_ice.wav"),
	preload("res://spells/lightning_shot.tscn"): preload("pickup_lightning.wav"),
}

var _weapon_scene: PackedScene

@onready var _sprite := $Sprite2D as Sprite2D


func _ready() -> void:
	super._ready()
	var randomized_weapons: Array = GlobalResources.weapons.duplicate()
	randomized_weapons.shuffle()
	_weapon_scene = randomized_weapons.pop_back()
	_sprite.texture = ICONS_MAP[_weapon_scene]
	_audio.stream = SOUNDS_MAP[_weapon_scene]
	body_entered.connect(_pickup)


func _pickup(player: Player) -> void:
	player.add_weapon(_weapon_scene)
