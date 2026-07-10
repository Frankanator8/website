extends Node2D

@export var speed: float = 100.0
@export var target_tilemap: TileMapLayer

var is_moving: bool = false
var last_tile_coords: Vector2i = Vector2i(-999, -999)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var walking_particles: CPUParticles2D = $WalkingParticles
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	animated_sprite.play("idle")
	walking_particles.target_tilemap = target_tilemap
	
	# Configure agent thresholds if needed
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0

func _process(delta):
	if is_moving:
		if not nav_agent.is_navigation_finished():
			move_self_to(delta)
			
			var current_tile = get_cell_coords_from_position(global_position)
			if current_tile != last_tile_coords:
				last_tile_coords = current_tile
				walking_particles.match_particle_to_tile(current_tile)
		else:
			stop_moving()
	else:
		walking_particles.emitting = false

func get_cell_coords_from_position(pos: Vector2) -> Vector2i:
	var tilemap_layer: TileMapLayer = walking_particles.target_tilemap
	if tilemap_layer:
		var local_pos = tilemap_layer.to_local(pos)
		return tilemap_layer.local_to_map(local_pos)
	return Vector2i.ZERO

func move_self_to(delta):
	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	var direction: Vector2 = (next_path_position - global_position).normalized()
	
	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0
		
	global_position += direction * speed * delta

func stop_moving():
	is_moving = false
	animated_sprite.play("idle")

# Public method to be called by the Selection Pointer or Input Manager
func set_move_target(global_pos: Vector2):
	nav_agent.target_position = global_pos
	is_moving = true
	animated_sprite.play("walking")