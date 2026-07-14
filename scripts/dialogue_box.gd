extends Node2D

@export var dialogue_text: String = "Default Dialogue Text" : set = set_dialogue_text
@export var show_one_by_one: bool = true
@export var type_speed: float = 0.05 # Time in seconds per character

@onready var label: RichTextLabel = $Label

# To prevent error if set_dialogue_text is called before _ready
var _is_ready: bool = false 
var _tween: Tween

func _ready() -> void:
	_is_ready = true
	display_dialogue()

func set_dialogue_text(new_text: String) -> void:
	dialogue_text = new_text
	if _is_ready:
		display_dialogue()

func display_dialogue() -> void:
	if not label:
		return
		
	# Kill any running animation
	if _tween and _tween.is_running():
		_tween.kill()
		
	if show_one_by_one:
		label.text = dialogue_text
		label.visible_characters = 0
		
		_tween = create_tween()
		# Animate the visible_characters property from 0 to total characters
		_tween.tween_property(
			label, 
			"visible_characters", 
			dialogue_text.length(), 
			dialogue_text.length() * type_speed
		)
	else:
		label.text = dialogue_text
		label.visible_characters = -1 # Shows all characters

# Optional helper function to skip the animation and show all text immediately
func skip_animation() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
		label.visible_characters = -1
