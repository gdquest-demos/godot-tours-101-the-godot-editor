## Increases the player's health when collected.
extends Pickup


func _pickup(player: Player) -> void:
	player.health += 2
