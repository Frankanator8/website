extends Camera2D

@export var base_resolution: Vector2i = Vector2i(1920, 1080)

# Engine limits use the unrotated viewport size, so they fight a 90 deg camera.
# Open them wide in portrait and clamp the view ourselves.
const _ENGINE_LIMIT_OPEN: int = 10000000

var _limit_left: int
var _limit_top: int
var _limit_right: int
var _limit_bottom: int
var _base_position: Vector2
var _portrait: bool = false

func _ready() -> void:
	_limit_left = limit_left
	_limit_top = limit_top
	_limit_right = limit_right
	_limit_bottom = limit_bottom
	_base_position = position

	# 1. Enable Godot's built-in black bar scaling programmatically
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	# 2. Connect to the window resizing signal
	get_viewport().size_changed.connect(_on_window_resized)

	# 3. Run once at startup
	_on_window_resized()

func _on_window_resized() -> void:
	var window_size := get_window().size
	_portrait = window_size.y > window_size.x

	if _portrait:
		rotation_degrees = 90
		# Swap the base resolution so black bars calculate correctly for a vertical screen
		get_window().content_scale_size = Vector2i(base_resolution.y, base_resolution.x)
		limit_left = -_ENGINE_LIMIT_OPEN
		limit_top = -_ENGINE_LIMIT_OPEN
		limit_right = _ENGINE_LIMIT_OPEN
		limit_bottom = _ENGINE_LIMIT_OPEN
	else:
		rotation_degrees = 0
		# Restore standard landscape base resolution
		get_window().content_scale_size = base_resolution
		limit_left = _limit_left
		limit_top = _limit_top
		limit_right = _limit_right
		limit_bottom = _limit_bottom
		position = _base_position

func _process(_delta: float) -> void:
	if not _portrait:
		return
	_clamp_rotated()

func _clamp_rotated() -> void:
	var parent_node := get_parent() as Node2D
	if parent_node == null:
		return

	# 90 deg camera: visible world size is the viewport with axes swapped
	var view := get_viewport_rect().size
	var half := Vector2(view.y, view.x) / zoom / 2.0
	var min_center := Vector2(_limit_left, _limit_top) + half
	var max_center := Vector2(_limit_right, _limit_bottom) - half
	if min_center.x > max_center.x:
		var mid_x := (_limit_left + _limit_right) * 0.5
		min_center.x = mid_x
		max_center.x = mid_x
	if min_center.y > max_center.y:
		var mid_y := (_limit_top + _limit_bottom) * 0.5
		min_center.y = mid_y
		max_center.y = mid_y

	var target_center: Vector2 = parent_node.global_position + _base_position
	global_position = Vector2(
		clampf(target_center.x, min_center.x, max_center.x),
		clampf(target_center.y, min_center.y, max_center.y)
	)
