extends Node2D

@export var title_text: String = "Title" : set = set_title_text

@onready var label: RichTextLabel = $Label

var _is_ready: bool = false

func _ready() -> void:
	_is_ready = true
	_display()

func set_title_text(new_text: String) -> void:
	title_text = new_text
	if _is_ready:
		_display()

func _display() -> void:
	if not label:
		return
	label.text = "[b]" + title_text + "[/b]"
