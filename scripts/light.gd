@tool
extends Node2D

@export var light_color: Color = Color(1, 0.88, 0.66, 1):
	set(value):
		light_color = value
		if is_node_ready():
			$Light.color = value

func _ready() -> void:
	$Light.color = light_color
