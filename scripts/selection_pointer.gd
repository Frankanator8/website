extends AnimatedSprite2D

var target_position: Vector2 = Vector2.ZERO
var player_node: Node2D = null  # Reference to the player to track their position


# Custom initialization method to call after instantiating
func setup(start_position: Vector2, player_ref: Node2D) -> void:
	global_position = start_position
	player_node = player_ref


func _ready() -> void:
	# Connect the animation finished signal to handle pausing on the last frame
	animation_finished.connect(_on_animation_finished)
	play() # Starts playing the default animation


func _process(_delta: float) -> void:
	# Check if the player reference exists and has reached this object's position
	if player_node and global_position.distance_to(player_node.global_position) < 10.0:
		queue_free()


func _on_animation_finished() -> void:
	pause()
	frame = sprite_frames.get_frame_count(animation) - 1