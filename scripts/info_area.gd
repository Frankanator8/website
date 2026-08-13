extends Area2D

@export_multiline var info_text: String = "Default Info Text"
@export var info_name: String = "Info Area"

# Optional - leave empty for no link
@export var link: String = ""

# Manually define the size of your Node2D description box for boundary calculations
@export var description_box_size: Vector2 = Vector2(200, 100)

const RANGE_ALPHA_IDLE: float = 0.6
const RANGE_ALPHA_ACTIVE: float = 1.0

# One spark seed every few pixels, so density follows the area's size
const EDGE_POINT_SPACING: float = 2.0

# Every area the player currently stands in - only the closest one shows its box
static var _areas_in_range: Array = []

@onready var description_box: Node2D = $DescriptionBox
@onready var base_shape: CollisionShape2D = $CollisionShape2D
@onready var border: Node2D = $Border
@onready var range_indicator: Line2D = $Border/RangeIndicator
@onready var pulse: AnimationPlayer = $Pulse
@onready var sparks_idle: CPUParticles2D = $EdgeSparksIdle
@onready var sparks_active: CPUParticles2D = $EdgeSparksActive

var _player_in_range: bool = false
var _mouse_over: bool = false
var _ring_tween: Tween

func _ready() -> void:
	_setup_indicator()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

	description_box.hide()
	description_box.top_level = true

	# Assuming type_speed is a custom variable on your DescriptionBox script
	if "type_speed" in description_box:
		description_box.type_speed = 0.01

func _exit_tree() -> void:
	_areas_in_range.erase(self)

func _process(_delta: float) -> void:
	_refresh_box()
	if description_box.visible:
		_place_description_box()

# Sparks trace the area's own collision shape, so they show the real range
func _setup_indicator() -> void:
	var shape: Shape2D = base_shape.shape
	if not shape is RectangleShape2D:
		push_warning("InfoArea %s needs a RectangleShape2D to draw its range" % name)
		border.hide()
		sparks_idle.emitting = false
		sparks_active.emitting = false
		return

	var half: Vector2 = shape.size / 2.0
	var corners := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y), # the line is closed, no repeated point
	])
	range_indicator.points = corners
	border.position = base_shape.position
	border.modulate.a = RANGE_ALPHA_IDLE

	# 27 areas breathing in lockstep looks mechanical - scatter the phase
	pulse.seek(randf() * pulse.get_animation("pulse").length, true)

	var emission := _edge_emission(shape.size)
	var perimeter: float = 2.0 * (shape.size.x + shape.size.y)
	for emitter in [sparks_idle, sparks_active]:
		emitter.position = base_shape.position
		emitter.emission_points = emission[0]
		emitter.emission_normals = emission[1]
	# Overlap is what makes the additive glow read as light, so keep it dense.
	# Still scaled by size - small areas would otherwise look as busy as big ones
	sparks_idle.amount = clampi(int(perimeter / 5.0), 12, 48)
	sparks_active.amount = clampi(int(perimeter / 2.5), 24, 90)
	sparks_idle.self_modulate.a = RANGE_ALPHA_IDLE

# Seeds sit on the outline with the outward normal of the edge they sit on, so
# DIRECTED_POINTS throws every spark away from the border it was born on
func _edge_emission(size: Vector2) -> Array:
	var half := size / 2.0
	var pts := PackedVector2Array()
	var normals := PackedVector2Array()
	# start corner, direction along edge, outward normal, edge length
	for e in [
		[Vector2(-half.x, -half.y), Vector2(1, 0), Vector2(0, -1), size.x],
		[Vector2(half.x, -half.y), Vector2(0, 1), Vector2(1, 0), size.y],
		[Vector2(half.x, half.y), Vector2(-1, 0), Vector2(0, 1), size.x],
		[Vector2(-half.x, half.y), Vector2(0, -1), Vector2(-1, 0), size.y],
	]:
		var count: int = maxi(2, int(e[3] / EDGE_POINT_SPACING))
		for i in count:
			# stops short of the next corner, so corners never double up
			pts.append(e[0] + e[1] * (e[3] * float(i) / float(count)))
			normals.append(e[2])
	return [pts, normals]

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = true
	if not _areas_in_range.has(self):
		_areas_in_range.append(self)
	_fade_ring(RANGE_ALPHA_ACTIVE)
	sparks_active.emitting = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = false
	_areas_in_range.erase(self)
	_fade_ring(RANGE_ALPHA_IDLE)
	sparks_active.emitting = false
	_set_link_cursor(false)

# Border and idle glow brighten together, so entering reads as one change
func _fade_ring(alpha: float) -> void:
	if _ring_tween and _ring_tween.is_running():
		_ring_tween.kill()
	_ring_tween = create_tween().set_parallel()
	_ring_tween.tween_property(border, "modulate:a", alpha, 0.2)
	_ring_tween.tween_property(sparks_idle, "self_modulate:a", alpha, 0.2)

# Overlapping ranges would stack description boxes - closest area wins
func _is_closest_in_range() -> bool:
	if not _player_in_range:
		return false

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return true

	var my_distance := global_position.distance_to(player.global_position)
	for area in _areas_in_range:
		if area == self or not is_instance_valid(area):
			continue
		if area.global_position.distance_to(player.global_position) < my_distance:
			return false
	return true

func _refresh_box() -> void:
	var should_show := _is_closest_in_range()

	if should_show == description_box.visible:
		return

	if should_show:
		var formatted_text := "[b]" + info_name + "[/b]\n" + info_text
		if not link.is_empty():
			formatted_text += "\n[i]click to open[/i]"

		if description_box.has_method("set_dialogue_text"):
			description_box.set_dialogue_text(formatted_text)

		_place_description_box()
		description_box.show()
	else:
		description_box.hide()

func _on_mouse_entered() -> void:
	_mouse_over = true
	_set_link_cursor(true)

func _on_mouse_exited() -> void:
	_mouse_over = false
	_set_link_cursor(false)

func _set_link_cursor(wanted: bool) -> void:
	if link.is_empty():
		return
	if wanted and _mouse_over and _player_in_range:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if link.is_empty() or not _player_in_range:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		LinkConfirm.ask(link)
		get_viewport().set_input_as_handled()

func _place_description_box() -> void:
	var canvas_transform = get_viewport().get_canvas_transform()
	var view_size = get_viewport_rect().size

	var min_pos = canvas_transform.affine_inverse() * Vector2.ZERO
	var max_pos = canvas_transform.affine_inverse() * view_size

	# Use the manually defined description_box_size instead of .size
	var desired_pos = self.global_position + Vector2(0, -description_box_size.y - 10)

	# Restrict the position to the screen boundaries using the custom size
	var clamped_x = clamp(desired_pos.x, min_pos.x, max_pos.x - description_box_size.x)
	var clamped_y = clamp(desired_pos.y, min_pos.y, max_pos.y - description_box_size.y)

	description_box.global_position = Vector2(clamped_x, clamped_y)
