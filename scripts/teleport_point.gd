@tool
extends Node2D

# A place the player can warp to. Owns the screen edge arrow that points here,
# and decides when that arrow is allowed to show.

# Who gets warped here - left empty, the first node in the "player" group is used
@export var player: Node2D: set = set_player
# Shown under the arrow - left empty, no label
@export var point_name: String = "": set = set_point_name
@export var arrow_color: Color = Color.WHITE: set = set_arrow_color
# Master switch - off means no arrow, ever
@export var active: bool = true: set = set_active
# Show the arrow from anywhere, instead of only inside the box below
@export var always_show: bool = false: set = set_always_show
# Convenience for typing a size - the CollisionShape2D is the real box
@export var show_box_size: Vector2 = Vector2(900, 600): set = set_show_box_size

@onready var zone: Area2D = $ShowZone
@onready var zone_shape: CollisionShape2D = $ShowZone/CollisionShape2D
@onready var target_arrow: CanvasLayer = $TargetArrow

var _player_inside: bool = false
var _reading_shape: bool = false

func _ready() -> void:
	# Shape node wins. Writing the export onto it was stomping boxes
	# dragged in the editor (MS_P72 / Amazon / Ramp).
	_read_box_size_from_shape()
	set_process(Engine.is_editor_hint())
	if Engine.is_editor_hint():
		queue_redraw()
		return

	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	set_player(player)
	set_point_name(point_name)
	set_arrow_color(arrow_color)
	_refresh()
	# Signals miss a player who already sits in the box at spawn
	await get_tree().physics_frame
	_sync_player_inside()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	var box := zone_shape.shape as RectangleShape2D
	if box == null:
		return
	var center: Vector2 = zone.position + zone_shape.position
	var rect := Rect2(center - box.size * 0.5, box.size)
	var fill := Color(1.0, 0.85, 0.2, 0.08 if always_show else 0.14)
	var edge := Color(1.0, 0.85, 0.2, 0.45 if always_show else 0.9)
	draw_rect(rect, fill, true)
	draw_rect(rect, edge, false, 2.0)

func set_player(value: Node2D) -> void:
	player = value
	if player and _arrow_ready():
		target_arrow.player = player

func set_point_name(value: String) -> void:
	point_name = value
	if _arrow_ready():
		target_arrow.point_name = point_name

func set_arrow_color(value: Color) -> void:
	arrow_color = value
	if _arrow_ready():
		target_arrow.arrow_color = arrow_color

func _arrow_ready() -> bool:
	return is_node_ready() and not Engine.is_editor_hint()

func set_active(value: bool) -> void:
	active = value
	_refresh()
	queue_redraw()

# Switched on for good, with a fade so the arrow does not just pop in
func reveal() -> void:
	set_active(true)
	if _arrow_ready():
		target_arrow.fade_in()

func set_always_show(value: bool) -> void:
	always_show = value
	_refresh()
	queue_redraw()

func set_show_box_size(value: Vector2) -> void:
	show_box_size = value
	if _reading_shape or not is_node_ready():
		return
	var box := zone_shape.shape as RectangleShape2D
	if box:
		box.size = show_box_size
	queue_redraw()

func _read_box_size_from_shape() -> void:
	var box := zone_shape.shape as RectangleShape2D
	if box == null or show_box_size.is_equal_approx(box.size):
		return
	_reading_shape = true
	show_box_size = box.size
	_reading_shape = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_refresh()

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	_refresh()

func _sync_player_inside() -> void:
	_player_inside = false
	for body in zone.get_overlapping_bodies():
		if body.is_in_group("player"):
			_player_inside = true
			break
	_refresh()

func _refresh() -> void:
	if Engine.is_editor_hint() or not is_node_ready():
		return
	target_arrow.enabled = active and (always_show or _player_inside)
