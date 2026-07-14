extends Area2D

@export_multiline var info_text: String = "Default Info Text"
@export var info_name: String = "Info Area"

# Manually define the size of your Node2D dialogue box for boundary calculations
@export var dialogue_box_size: Vector2 = Vector2(200, 100) 

# Changed type from Control to Node2D
@onready var dialogue_box: Node2D = $DialogueBox 

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	dialogue_box.hide()
	dialogue_box.top_level = true 
	
	# Assuming type_speed is a custom variable on your DialogueBox script
	if "type_speed" in dialogue_box:
		dialogue_box.type_speed = 0.01 

func _process(_delta: float) -> void:
	if dialogue_box.visible:
		_place_dialogue_box()

func _on_mouse_entered() -> void:
	var formatted_text = "[b]" + info_name + "[/b]\n" + info_text
	
	if dialogue_box.has_method("set_dialogue_text"):
		dialogue_box.set_dialogue_text(formatted_text)
		
	_place_dialogue_box()
	dialogue_box.show()

func _on_mouse_exited() -> void:
	dialogue_box.hide()

func _place_dialogue_box() -> void:
	var canvas_transform = get_viewport().get_canvas_transform()
	var view_size = get_viewport_rect().size
	
	var min_pos = canvas_transform.affine_inverse() * Vector2.ZERO
	var max_pos = canvas_transform.affine_inverse() * view_size
	
	# Use the manually defined dialogue_box_size instead of .size
	var desired_pos = self.global_position + Vector2(0, -dialogue_box_size.y - 10)
	
	# Restrict the position to the screen boundaries using the custom size
	var clamped_x = clamp(desired_pos.x, min_pos.x, max_pos.x - dialogue_box_size.x)
	var clamped_y = clamp(desired_pos.y, min_pos.y, max_pos.y - dialogue_box_size.y)
	
	dialogue_box.global_position = Vector2(clamped_x, clamped_y)
