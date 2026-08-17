@tool
extends Node2D

# Paper-doll person built from res://assets/people/custom/.
# Face, hair and shirt are 5 variants of 16x16. Pants and shirtskin are 15
# frames: 5 variants x 3 walk poses, so variant v sits at frames v, v+5, v+10.
# Shirt and ShirtSkin share a variant index, so one export drives both.

@export_range(0, 4) var face_frame: int = 0:
	set(value):
		face_frame = value
		_apply()

@export_range(0, 4) var hair_frame: int = 0:
	set(value):
		hair_frame = value
		_apply()

## Drives Shirt and ShirtSkin together.
@export_range(0, 4) var shirt_frame: int = 0:
	set(value):
		shirt_frame = value
		_apply()

@export_range(0, 4) var pants_frame: int = 0:
	set(value):
		pants_frame = value
		_apply()

## Tints Face and ShirtSkin.
@export var skin_color: Color = Color.WHITE:
	set(value):
		skin_color = value
		_apply()

@export var hair_color: Color = Color.WHITE:
	set(value):
		hair_color = value
		_apply()

@export var shirt_color: Color = Color.WHITE:
	set(value):
		shirt_color = value
		_apply()

@export var pants_color: Color = Color.WHITE:
	set(value):
		pants_color = value
		_apply()

## Mirrors every layer horizontally, so the person faces the other way.
@export var flip_x: bool = false:
	set(value):
		flip_x = value
		_apply()

## Loops the Walk animation, which steps through poses 0, 1, 0, 2.
@export var walking: bool = false:
	set(value):
		walking = value
		_update_walk()

# Walk pose (0, 1 or 2), keyed by the Walk AnimationPlayer.
var pose: int = 0:
	set(value):
		pose = value
		_apply()

@onready var pants: Sprite2D = $Pants
@onready var shirt_skin: Sprite2D = $ShirtSkin
@onready var shirt: Sprite2D = $Shirt
@onready var face: Sprite2D = $Face
@onready var hair: Sprite2D = $Hair
@onready var walk: AnimationPlayer = $Walk


func _ready() -> void:
	_apply()
	_update_walk()


func _update_walk() -> void:
	if not is_node_ready():
		return

	if walking:
		if not walk.is_playing():
			walk.play("walk")
	else:
		walk.stop()
		pose = 0


func _apply() -> void:
	if not is_node_ready():
		return

	pants.frame = pants_frame + pose * 5
	shirt_skin.frame = shirt_frame + pose * 5
	shirt.frame = shirt_frame
	face.frame = face_frame
	hair.frame = hair_frame

	shirt_skin.modulate = skin_color
	face.modulate = skin_color
	pants.modulate = pants_color
	shirt.modulate = shirt_color
	hair.modulate = hair_color

	for layer in [pants, shirt_skin, shirt, face, hair]:
		layer.flip_h = flip_x
