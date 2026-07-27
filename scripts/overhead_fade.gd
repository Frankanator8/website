extends TileMapLayer

## Fades this always-on-top layer out when the player walks near it, so the
## player never disappears behind it.

@export var player: Node2D

## Player closer than this to any tile in this layer -> fully faded.
@export var near_distance: float = 24.0
## Player farther than this from every tile -> fully solid.
@export var far_distance: float = 64.0
@export var min_alpha: float = 0.3
## How fast the alpha chases its goal. Higher = snappier.
@export var fade_speed: float = 8.0

var tile_points: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	for cell in get_used_cells():
		tile_points.append(to_global(map_to_local(cell)))


func _process(delta: float) -> void:
	if player == null or tile_points.is_empty():
		return

	var nearest := INF
	for point in tile_points:
		nearest = minf(nearest, player.global_position.distance_to(point))

	var t := clampf(inverse_lerp(near_distance, far_distance, nearest), 0.0, 1.0)
	var goal := lerpf(min_alpha, 1.0, t)
	self_modulate.a = lerpf(self_modulate.a, goal, clampf(fade_speed * delta, 0.0, 1.0))
