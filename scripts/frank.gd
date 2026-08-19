extends AnimatedSprite2D

@export var speed: float = 100.0
@export var player: Node2D
## Frank never walks higher than this.
@export var top_limit: float = -238.0
## Once Frank comes back down to this y, he leaves for his spot.
@export var leave_y: float = -110.0
## Where Frank goes once he is done following.
@export var final_spot: Vector2 = Vector2(89, -76)
## Box that pops above Frank's head once he catches up to the player.
@export var dialogue_box: Node2D
## Click hint that shows a moment after Frank talks.
@export var cursor: CanvasItem
## Clicks are dead until Frank has walked up, so his intro always plays.
@export var selector: Node
## Teleport points, dark until Frank heads off on his own.
@export var quick_points: Node

@onready var cursor_delay: Timer = $CursorDelay

var armed: bool = false
var leaving: bool = false
var greeting: bool = false
var tutorial_done: bool = false

func _ready() -> void:
	if selector:
		selector.set_process_unhandled_input(false)
	for point in _quicks():
		point.active = false

func _process(delta: float) -> void:
	# First click means the player already gets it, so drop the tutorial.
	if not tutorial_done and player and player.is_moving:
		_end_tutorial()

	var target: Vector2
	if leaving:
		target = final_spot
	else:
		if player:
			target = Vector2(position.x, maxf(player.position.y, top_limit))
		else:
			target = position

		if position.y < leave_y:
			armed = true
		elif armed:
			leaving = true
			target = final_spot
			for point in _quicks():
				point.reveal()

	var start: Vector2 = position
	var to_target: Vector2 = target - position
	var step: float = speed * delta
	if to_target.length() <= step:
		position = target
	else:
		position += to_target.normalized() * step

	# Walking anim whenever Frank actually shifted this frame, even when he is
	# only trailing the player by a step.
	if start.distance_to(position) > step * 0.1:
		play("walking")
	else:
		play("default")

	# Caught up to the player up top, so greet them.
	if not greeting and not tutorial_done and armed and not leaving and position.is_equal_approx(target):
		_start_greeting()

func _quicks() -> Array:
	if quick_points == null:
		return []
	return quick_points.get_children().filter(func(point): return point.has_method("reveal"))

func _start_greeting() -> void:
	greeting = true
	if selector:
		selector.set_process_unhandled_input(true)
	if dialogue_box:
		dialogue_box.display_dialogue()
		dialogue_box.show()
	cursor_delay.start()

func _on_cursor_delay_timeout() -> void:
	if not tutorial_done and cursor:
		cursor.show()

func _end_tutorial() -> void:
	tutorial_done = true
	cursor_delay.stop()
	if dialogue_box:
		dialogue_box.hide()
	if cursor:
		cursor.hide()
