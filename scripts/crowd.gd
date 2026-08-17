extends Node2D

# Spawns a crowd of randomly dressed custom_person instances that pace back and
# forth between the two Marker2D children, PointA and PointB. Straight lines,
# no navmesh, no collision -- these are background life, not obstacles.

const PERSON_SCENE: PackedScene = preload("res://scenes/custom_person.tscn")

@export_range(0, 64) var count: int = 8

## Overrides the person used, in case a different paper doll is wanted.
@export var person_scene: PackedScene = PERSON_SCENE

@export var speed_min: float = 20.0
@export var speed_max: float = 45.0

## Random offset radius around each marker, so nobody stacks on one pixel.
@export var spread: float = 12.0

## Odds of standing still for a moment after reaching an endpoint.
@export_range(0.0, 1.0) var pause_chance: float = 0.4
@export var pause_min: float = 0.5
@export var pause_max: float = 2.5

## 0 draws a fresh crowd every run. Anything else repeats the same crowd.
@export var rng_seed: int = 0

@export var skin_colors: PackedColorArray = [
	Color(1, 0.908, 0.31, 1),
	Color(1, 0.83, 0.62, 1),
	Color(0.87, 0.66, 0.45, 1),
	Color(0.66, 0.45, 0.29, 1),
	Color(0.42, 0.28, 0.19, 1),
]

@export var hair_colors: PackedColorArray = [
	Color(0, 0, 0, 1),
	Color(0.15, 0.1, 0.08, 1),
	Color(0.35, 0.2, 0.1, 1),
	Color(0.72, 0.55, 0.25, 1),
	Color(0.6, 0.6, 0.62, 1),
]

@export var shirt_colors: PackedColorArray = [
	Color(1, 0, 0, 1),
	Color(0.38823529, 0.60784316, 1, 1),
	Color(0.95, 0.75, 0.2, 1),
	Color(0.25, 0.7, 0.4, 1),
	Color(0.7, 0.35, 0.8, 1),
	Color(0.95, 0.95, 0.95, 1),
	Color(0.2, 0.2, 0.25, 1),
]

@export var pants_colors: PackedColorArray = [
	Color(0, 0.4500003, 1, 1),
	Color(0.18823529, 0.37647059, 0.50980392, 1),
	Color(0.25, 0.25, 0.3, 1),
	Color(0.45, 0.35, 0.25, 1),
	Color(0.6, 0.62, 0.65, 1),
]

@onready var point_a: Marker2D = $PointA
@onready var point_b: Marker2D = $PointB

var _rng := RandomNumberGenerator.new()

# One entry per walker: { node, target, speed, wait, to_b }.
var _walkers: Array[Dictionary] = []


func _ready() -> void:
	if rng_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = rng_seed

	for i in count:
		_spawn_walker()


func _spawn_walker() -> void:
	var person: Node2D = person_scene.instantiate()

	person.face_frame = _rng.randi_range(0, 4)
	person.hair_frame = _rng.randi_range(0, 4)
	person.shirt_frame = _rng.randi_range(0, 4)
	person.pants_frame = _rng.randi_range(0, 4)

	person.skin_color = _pick(skin_colors)
	person.hair_color = _pick(hair_colors)
	person.shirt_color = _pick(shirt_colors)
	person.pants_color = _pick(pants_colors)

	# Each walker owns its own pair of endpoints, jittered off the markers.
	var from: Vector2 = point_a.position + _offset()
	var to: Vector2 = point_b.position + _offset()
	var to_b: bool = _rng.randf() < 0.5
	if not to_b:
		var swap: Vector2 = from
		from = to
		to = swap

	# Drop them somewhere along the way so they are not all in lockstep.
	person.position = from.lerp(to, _rng.randf())
	person.walking = true
	person.flip_x = to.x < person.position.x

	add_child(person)

	_walkers.append({
		"node": person,
		"target": to,
		"speed": _rng.randf_range(speed_min, speed_max),
		"wait": 0.0,
		"to_b": to_b,
	})


func _process(delta: float) -> void:
	for walker in _walkers:
		var person: Node2D = walker["node"]

		if walker["wait"] > 0.0:
			walker["wait"] -= delta
			if person.walking:
				person.walking = false
			continue

		if not person.walking:
			person.walking = true

		var target: Vector2 = walker["target"]
		var to_target: Vector2 = target - person.position
		var step: float = walker["speed"] * delta

		if to_target.length() <= step:
			person.position = target
			_turn_around(walker)
			continue

		var direction: Vector2 = to_target.normalized()
		if direction.x != 0.0:
			var flip: bool = direction.x < 0.0
			if person.flip_x != flip:
				person.flip_x = flip

		person.position += direction * step


# Reached an endpoint: head back to the other marker, with fresh jitter.
func _turn_around(walker: Dictionary) -> void:
	walker["to_b"] = not walker["to_b"]
	var marker: Marker2D = point_b if walker["to_b"] else point_a
	walker["target"] = marker.position + _offset()
	walker["speed"] = _rng.randf_range(speed_min, speed_max)

	if _rng.randf() < pause_chance:
		walker["wait"] = _rng.randf_range(pause_min, pause_max)


# Random point in a disc of radius `spread`.
func _offset() -> Vector2:
	return Vector2(_rng.randf_range(0.0, spread), 0.0).rotated(_rng.randf() * TAU)


func _pick(colors: PackedColorArray) -> Color:
	if colors.is_empty():
		return Color.WHITE
	return colors[_rng.randi_range(0, colors.size() - 1)]
