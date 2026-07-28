extends TileMapLayer

## Feeds the player's position to the fade shader on this always-on-top layer,
## so only the tiles right around the player go transparent.

@export var player: Node2D


func _process(_delta: float) -> void:
	if player == null or material == null:
		return

	material.set_shader_parameter("player_position", player.global_position)
