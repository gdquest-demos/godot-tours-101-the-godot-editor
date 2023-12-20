@tool
extends RoomEntrance

enum Direction {BLOCK_FROM_TOP, BLOCK_FROM_BOTTOM}

@export var direction: Direction = Direction.BLOCK_FROM_BOTTOM: set = set_direction


func set_direction(new_direction: Direction) -> void:
	direction = new_direction
	if not _collider:
		await self.ready
	_collider.rotation = direction * PI
