extends Area2D

@export_multiline var info_text: String = "Default Info Text"
@export var info_name: String = "Info Area"
@onready var dialogue_box: Control = $DialogueBox # Adjust type if DialogueBox is a custom class

func _ready() -> void:
	# Connect the mouse signals to local functions
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Ensure the box is hidden at the start
	dialogue_box.hide()
	dialogue_box.type_speed = 0.01 # Adjust typing speed as needed

func _on_mouse_entered() -> void:
	var formatted_text = "[b]" + info_name + "[/b]\n" + info_text
	dialogue_box.set_dialogue_text(formatted_text)
	dialogue_box.show()

func _on_mouse_exited() -> void:
	dialogue_box.hide()
