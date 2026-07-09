extends Node2D

@export var speed: float = 100.0

var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var last_tile_coords: Vector2i = Vector2i(-999, -999) # Tracks previous frame's tile

# Reference to the AnimatedSprite2D node
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var walking_particles: CPUParticles2D = $WalkingParticles # Using CPUParticles2D type directly

func _ready():
	# Initialize target at current position so the player doesn't instantly move
	target_position = global_position
	animated_sprite.play("idle")

func _input(event):
	# Check for left mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# get_global_mouse_position() translates screen click to world coordinates
		target_position = get_global_mouse_position()
		is_moving = true
		animated_sprite.play("walking")

func _process(delta):
	if is_moving:
		move_self_to(delta)
		
		# Get current tile and check if the player moved to a different tile
		var current_tile = get_cell_coords_from_position(global_position)
		if current_tile != last_tile_coords:
			last_tile_coords = current_tile
			walking_particles.match_particle_to_tile(current_tile)
		
	else:
		walking_particles.emitting = false

func get_cell_coords_from_position(pos: Vector2) -> Vector2i:
	var tilemap_layer: TileMapLayer = walking_particles.target_tilemap
	if tilemap_layer:
		# FIX: In Godot 4, it is local_to_map(), not world_to_map()
		# We must convert global_position to the TileMapLayer's local space first
		var local_pos = tilemap_layer.to_local(pos)
		return tilemap_layer.local_to_map(local_pos)
	return Vector2i.ZERO

func move_self_to(delta):
	# Check if we are close enough to the target to stop
	if global_position.distance_to(target_position) > 1.0:
		var direction = (target_position - global_position).normalized()
		
		# Flip sprite based on horizontal direction
		if direction.x != 0:
			animated_sprite.flip_h = direction.x < 0
			
		global_position += direction * speed * delta
	else:
		global_position = target_position
		is_moving = false
		animated_sprite.play("idle")
