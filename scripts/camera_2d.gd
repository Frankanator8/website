extends Camera2D

@export var base_resolution: Vector2i = Vector2i(1920, 1080)

func _ready() -> void:
	# 1. Enable Godot's built-in black bar scaling programmatically
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	
	# 2. Connect to the window resizing signal
	get_viewport().size_changed.connect(_on_window_resized)
	
	# 3. Run once at startup
	_on_window_resized()

func _on_window_resized() -> void:
	var window_size := get_window().size
	var is_portrait := window_size.y > window_size.x
	
	if is_portrait:
		rotation_degrees = 90
		# Swap the base resolution so black bars calculate correctly for a vertical screen
		get_window().content_scale_size = Vector2i(base_resolution.y, base_resolution.x)
	else:
		rotation_degrees = 0
		# Restore standard landscape base resolution
		get_window().content_scale_size = base_resolution