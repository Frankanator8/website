extends Node2D

@export_multiline var dialogue_text: String = "Default Dialogue Text" : set = set_dialogue_text
@export var show_one_by_one: bool = true
@export var type_speed: float = 0.05 # Time in seconds per character

# DrawLayer is CanvasLayer 20: above arrows (10), below the link popup (100).
# A hidden Node2D does not hide a child CanvasLayer, so this script keeps them
# in sync and copies the box's world transform onto WorldRoot.
@onready var draw_layer: CanvasLayer = $DrawLayer
@onready var world_root: Node2D = $DrawLayer/WorldRoot
@onready var label: RichTextLabel = $DrawLayer/WorldRoot/Label

# To prevent error if set_dialogue_text is called before _ready
var _is_ready: bool = false
var _tween: Tween

func _ready() -> void:
	_is_ready = true
	set_process(false)
	visibility_changed.connect(_sync_draw_layer)
	_sync_draw_layer()
	display_dialogue()

func _process(_delta: float) -> void:
	_stick_to_anchor()

func _sync_draw_layer() -> void:
	var show_layer := is_visible_in_tree()
	draw_layer.visible = show_layer
	set_process(show_layer)
	if show_layer:
		_stick_to_anchor()

func _stick_to_anchor() -> void:
	# Local pos on a follow-viewport layer is world space. Using global_position
	# here would apply the camera twice.
	world_root.position = global_position
	world_root.rotation = global_rotation
	world_root.scale = global_scale

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
