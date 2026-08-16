extends CanvasItem

## Feeds the player's position to the pixel focus shader on this sprite, so it
## un-chunks as the player walks closer.

@export var player: Node2D


func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D


func _process(_delta: float) -> void:
	if player == null or material == null:
		return

	material.set_shader_parameter("player_position", player.global_position)
