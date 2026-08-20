extends Area2D

@export_multiline var info_text: String = "Default Book Text"
@export var info_name: String = "Book"
@export var description_box_size: Vector2 = Vector2(200, 100)

# Hover (bob) motion — applied to the sprite continuously
@export var bob_amplitude: float = 2.0
@export var bob_speed: float = 2.0
# Distance (px) covered by one full wave — phase shifts with the book's x so a
# row of books ripples instead of bobbing in unison
@export var bob_wavelength: float = 96.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var description_box: Node2D = $DescriptionBox
@onready var proximity_area: Area2D = $ProximityArea

var _selector_on: bool = false
var _player_near: bool = false
var _time: float = 0.0
var _sprite_base_y: float = 0.0
var _phase: float = 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	proximity_area.body_entered.connect(_on_body_entered)
	proximity_area.body_exited.connect(_on_body_exited)

	_sprite_base_y = animated_sprite.position.y
	if bob_wavelength != 0.0:
		_phase = global_position.x / bob_wavelength * TAU

	description_box.hide()
	description_box.top_level = true
	if "type_speed" in description_box:
		description_box.type_speed = 0.005

	# Start still: bob only, no frame animation until selected or the player is close
	animated_sprite.stop()
	animated_sprite.frame = 0

func _process(delta: float) -> void:
	_time += delta
	animated_sprite.position.y = _sprite_base_y + sin(_time * bob_speed - _phase) * bob_amplitude
	if description_box.visible:
		_place_description_box()

# The click marker (selection pointer) landing on the book is what opens it -
# works the same with a mouse or a tap
func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("selector"):
		return
	_selector_on = true
	_refresh_box()

func _on_area_exited(area: Area2D) -> void:
	if not area.is_in_group("selector"):
		return
	_selector_on = false
	_refresh_box()

# Description shows while the selector sits on the book
func _refresh_box() -> void:
	var should_show := _selector_on
	if should_show == description_box.visible:
		_update_animation()
		return

	if should_show:
		var formatted_text := "[b]" + info_name + "[/b]\n" + info_text
		if description_box.has_method("set_dialogue_text"):
			description_box.set_dialogue_text(formatted_text)
		_place_description_box()
		description_box.show()
	else:
		description_box.hide()
	_update_animation()

func _on_body_entered(body: Node) -> void:
	if not body.has_method("set_move_target"):  # only the Player has this
		return
	_player_near = true
	_update_animation()

func _on_body_exited(body: Node) -> void:
	if not body.has_method("set_move_target"):
		return
	_player_near = false
	_update_animation()

# Frame animation plays on selector OR proximity; otherwise the book just bobs on frame 0
func _update_animation() -> void:
	if _selector_on or _player_near:
		animated_sprite.play("float")
	else:
		animated_sprite.stop()
		animated_sprite.frame = 0

# Reused verbatim from scripts/info_area.gd
func _place_description_box() -> void:
	var inverse := get_viewport().get_canvas_transform().affine_inverse()
	var view_size = get_viewport_rect().size
	var min_pos: Vector2 = inverse * Vector2.ZERO
	var max_pos: Vector2 = min_pos
	for corner in [Vector2(view_size.x, 0.0), view_size, Vector2(0.0, view_size.y)]:
		var world: Vector2 = inverse * corner
		min_pos = min_pos.min(world)
		max_pos = max_pos.max(world)
	var desired_pos = self.global_position + Vector2(0, -description_box_size.y - 10)
	var clamped_x = clamp(desired_pos.x, min_pos.x, max_pos.x - description_box_size.x)
	var clamped_y = clamp(desired_pos.y, min_pos.y, max_pos.y - description_box_size.y)
	description_box.global_position = Vector2(clamped_x, clamped_y)
