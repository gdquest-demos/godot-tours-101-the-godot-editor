@tool
extends RoomEntrance

enum Direction {BLOCK_FROM_LEFT, BLOCK_FROM_RIGHT}

@export var direction: Direction = Direction.BLOCK_FROM_LEFT: set = set_direction


func _ready() -> void:
	set_direction(direction)


func set_direction(new_direction: Direction) -> void:
	direction = new_direction
	if not _collider:
		await self.ready
	_collider.rotation = direction * PI - PI / 2.0
