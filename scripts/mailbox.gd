extends Area2D

@export var link_url: String = "https://example.com"
@export var title_box_size: Vector2 = Vector2(140, 60)
@export var logo_texture: Texture2D : set = set_logo_texture

@onready var title_box: Node2D = $TitleBox
@onready var logo: Sprite2D = $Logo

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

	title_box.hide()
	title_box.top_level = true

	if logo_texture:
		logo.texture = logo_texture

func set_logo_texture(new_texture: Texture2D) -> void:
	logo_texture = new_texture
	if logo and logo_texture:
		logo.texture = logo_texture

func _process(_delta: float) -> void:
	if title_box.visible:
		_place_title_box()

func _on_mouse_entered() -> void:
	if title_box.has_method("set_title_text"):
		title_box.set_title_text(link_url)

	_place_title_box()
	title_box.show()

func _on_mouse_exited() -> void:
	title_box.hide()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		OS.shell_open(link_url)

func _place_title_box() -> void:
	var canvas_transform = get_viewport().get_canvas_transform()
	var view_size = get_viewport_rect().size

	var min_pos = canvas_transform.affine_inverse() * Vector2.ZERO
	var max_pos = canvas_transform.affine_inverse() * view_size

	var desired_pos = self.global_position + Vector2(0, -title_box_size.y - 10)

	var clamped_x = clamp(desired_pos.x, min_pos.x, max_pos.x - title_box_size.x)
	var clamped_y = clamp(desired_pos.y, min_pos.y, max_pos.y - title_box_size.y)

	title_box.global_position = Vector2(clamped_x, clamped_y)
