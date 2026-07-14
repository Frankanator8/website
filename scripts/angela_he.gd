extends AnimatedSprite2D

# Physics variables
var velocity_y: float = 0.0
@export var GRAVITY: float = 980.0
@export var JUMP_FORCE: float = -400.0
@export var UPWARD_NUDGE: float = -150.0

func _process(delta: float) -> void:
	# Handle frame-specific actions
	match frame:
		0:
			# Trigger jump only at the very start of frame 0
			if position.y == 15.0 and velocity_y == 0.0:
				velocity_y = JUMP_FORCE
		
		10, 11:
			# Nudge upward on frames 10 and 11
			velocity_y = UPWARD_NUDGE

	# Apply constant downward gravity
	velocity_y += GRAVITY * delta
	position.y += velocity_y * delta

	# Optional: Ground collision clamp so it doesn't fall forever
	if position.y > 15.0:
		position.y = 15.0
		velocity_y = 0.0