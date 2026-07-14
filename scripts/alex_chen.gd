extends AnimatedSprite2D

@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 980.0

var velocity: Vector2 = Vector2.ZERO
var direction: float = 1.0

# Tracks the high-precision floating point position
var precise_position: Vector2

func _ready() -> void:
	frame_changed.connect(_on_frame_changed)
	play()
	# Initialize our high-precision tracker to the starting position
	precise_position = position

func _process(delta: float) -> void:
	velocity.x = direction * speed
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0:
			velocity.y = 0

	# 1. Update the underlying true position with high precision
	precise_position += velocity * delta
	
	# 2. Snap the visual position to whole integer pixels
	position = precise_position.round()

func _on_frame_changed() -> void:
	# 8th frame (index 7) or 9th frame (index 8)
	if frame == 7 or frame == 8:
		velocity.y = jump_force
		
	# 14th frame (index 13)
	if frame == 13:
		direction *= -1.0
		flip_h = (direction == -1.0)

func is_on_floor() -> bool:
	# Check against precise position instead of snapped position
	if precise_position.y >= -15:
		precise_position.y = -15
		return true
	return false