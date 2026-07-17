extends Area2D

@export_multiline var info_text: String = "Default Book Text"
@export var info_name: String = "Book"
@export var dialogue_box_size: Vector2 = Vector2(200, 100)

# Hover (bob) motion — applied to the sprite continuously
@export var bob_amplitude: float = 2.0
@export var bob_speed: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dialogue_box: Node2D = $DialogueBox
@onready var proximity_area: Area2D = $ProximityArea

var _mouse_inside: bool = false
var _player_near: bool = false
var _time: float = 0.0
var _sprite_base_y: float = 0.0

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	proximity_area.body_entered.connect(_on_body_entered)
	proximity_area.body_exited.connect(_on_body_exited)

	_sprite_base_y = animated_sprite.position.y

	dialogue_box.hide()
	dialogue_box.top_level = true
	if "type_speed" in dialogue_box:
		dialogue_box.type_speed = 0.01

	# Start still: hover only, no frame animation until hovered or the player is close
	animated_sprite.stop()
	animated_sprite.frame = 0

func _process(delta: float) -> void:
	_time += delta
	animated_sprite.position.y = _sprite_base_y + sin(_time * bob_speed) * bob_amplitude
	if dialogue_box.visible:
		_place_dialogue_box()

func _on_mouse_entered() -> void:
	_mouse_inside = true
	# Dialogue shows on hover only
	var formatted_text = "[b]" + info_name + "[/b]\n" + info_text
	if dialogue_box.has_method("set_dialogue_text"):
		dialogue_box.set_dialogue_text(formatted_text)
	_place_dialogue_box()
	dialogue_box.show()
	_update_animation()

func _on_mouse_exited() -> void:
	_mouse_inside = false
	dialogue_box.hide()
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

# Frame animation plays on hover OR proximity; otherwise the book just bobs on frame 0
func _update_animation() -> void:
	if _mouse_inside or _player_near:
		animated_sprite.play("float")
	else:
		animated_sprite.stop()
		animated_sprite.frame = 0

# Reused verbatim from scripts/info_area.gd
func _place_dialogue_box() -> void:
	var canvas_transform = get_viewport().get_canvas_transform()
	var view_size = get_viewport_rect().size
	var min_pos = canvas_transform.affine_inverse() * Vector2.ZERO
	var max_pos = canvas_transform.affine_inverse() * view_size
	var desired_pos = self.global_position + Vector2(0, -dialogue_box_size.y - 10)
	var clamped_x = clamp(desired_pos.x, min_pos.x, max_pos.x - dialogue_box_size.x)
	var clamped_y = clamp(desired_pos.y, min_pos.y, max_pos.y - dialogue_box_size.y)
	dialogue_box.global_position = Vector2(clamped_x, clamped_y)
