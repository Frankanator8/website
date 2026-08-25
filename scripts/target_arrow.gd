extends CanvasLayer

# Screen edge marker: points at a node, and teleports the player to it when its
# arrow is held down long enough.

@export var target: Node2D
# Left empty, the first node in the "player" group is used
@export var player: Node2D: set = set_player
# Switched off, the marker stays hidden - owners like TeleportPoint drive this
@export var enabled: bool = true: set = set_enabled
# Shown under the arrow - left empty, no label
@export var point_name: String = "": set = set_point_name
# Tints the arrow and its label, on top of the Arrow node's own modulate
@export var arrow_color: Color = Color.WHITE: set = set_arrow_color
@export var edge_margin: float = 64.0
# Markers closer than this on screen collapse into a single shared marker
@export var merge_distance: float = 96.0
@export var hold_time: float = 2.0
@export var hide_when_on_screen: bool = true
# How long the marker takes to fade up when its owner reveals it
@export var fade_time: float = 0.6
# arrow.png points right, so no offset is needed for it
@export var texture_angle_offset: float = 0.0
# The player squashes down, moves, then springs back
@export var squash_time: float = 0.12
@export var pop_time: float = 0.2
@export var squash_scale: float = 0.3

const LABEL_PADDING: float = 16.0

@onready var marker: Control = $Marker
@onready var hit_button: Button = $Marker/HitButton
@onready var arrow: TextureRect = $Marker/HitButton/Arrow
@onready var hold_bar: ProgressBar = $Marker/HoldBar
@onready var name_label: Label = $Marker/NameLabel
@onready var hold_timer: Timer = $Marker/HoldTimer

# Every live arrow, so overlapping ones can be found and merged
static var _arrows: Array = []

# The sprite, not the body - scale on a RigidBody2D fights the physics server
var _player_visual: Node2D
var _visual_scale: Vector2 = Vector2.ONE
var _squash_tween: Tween

# Filled in each frame before the merge pass
var _wants_show: bool = false
var _edge_pos: Vector2 = Vector2.ZERO
var _to_target: Vector2 = Vector2.ZERO
# The arrows drawn by this one - itself plus anything merged in
var _group: Array = []

func _enter_tree() -> void:
	_arrows.append(self)

func _exit_tree() -> void:
	_arrows.erase(self)

func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	hold_timer.wait_time = hold_time
	hit_button.button_down.connect(_start_hold)
	hit_button.button_up.connect(_cancel_hold)
	hit_button.mouse_exited.connect(_cancel_hold)
	hold_timer.timeout.connect(_teleport)

	set_point_name(point_name)
	set_arrow_color(arrow_color)

	marker.hide()
	hold_bar.hide()

	# Portrait phones turn the camera 90 degrees so the world stays landscape.
	# A plain CanvasLayer ignores that, so the arrows have to turn with it.
	get_viewport().size_changed.connect(_match_screen)
	_match_screen()

# The owner may hand the player over after _ready, so grab the sprite here
func set_player(value: Node2D) -> void:
	player = value
	if player == null:
		return
	_player_visual = player.get_node_or_null("Person") as Node2D
	if _player_visual == null:
		_player_visual = player
	_visual_scale = _player_visual.scale

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled and is_node_ready():
		_hide_marker()

func set_point_name(value: String) -> void:
	point_name = value
	if not is_node_ready():
		return
	name_label.text = point_name
	name_label.visible = not point_name.is_empty()

func set_arrow_color(value: Color) -> void:
	arrow_color = value
	if not is_node_ready():
		return
	# self_modulate, so the Arrow node keeps its own alpha from the scene
	arrow.self_modulate = arrow_color
	# modulate tints the fill and leaves the black outline black. Text sits a
	# bit more solid than the faded arrow, so the name is easier to read.
	var arrow_alpha := arrow_color.a * arrow.modulate.a
	name_label.modulate = Color(arrow_color, clampf(lerpf(arrow_alpha, 1.0, 0.35), 0.0, 1.0))

# Portrait layer is landscape-sized, so layout uses the swapped axes
func _layout_size(view_size: Vector2) -> Vector2:
	if view_size.y > view_size.x:
		return Vector2(view_size.y, view_size.x)
	return view_size

func _match_screen() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	if view.y > view.x:
		transform = Transform2D(-PI / 2.0, Vector2(0.0, view.y))
	else:
		transform = Transform2D()

# Merging needs every arrow's spot at once, so the first one drives them all
func _process(_delta: float) -> void:
	if _arrows.is_empty() or _arrows[0] != self:
		return

	var layout_size: Vector2 = _layout_size(get_viewport().get_visible_rect().size)
	var leaders: Array = []

	for other in _arrows:
		if not other.is_node_ready():
			continue
		other._measure(layout_size)
		if not other._wants_show:
			other._hide_marker()
			continue
		# Sit on top of an earlier arrow? Hand your name and target to it
		var leader = null
		for candidate in leaders:
			for member in candidate._group:
				if member._edge_pos.distance_to(other._edge_pos) < merge_distance:
					leader = candidate
					break
			if leader != null:
				break
		if leader == null:
			other._group = [other]
			leaders.append(other)
		else:
			leader._group.append(other)
			other._hide_marker()

	for leader in leaders:
		leader._draw_marker(layout_size)

# Where this arrow wants to sit this frame, before any merging
func _measure(layout_size: Vector2) -> void:
	_group.clear()
	_wants_show = false
	if not enabled or not is_instance_valid(target):
		return

	# Layer space, after _match_screen turns this overlay with the camera
	var screen_pos: Vector2 = transform.affine_inverse() * (get_viewport().get_canvas_transform() * target.global_position)
	var bounds := Rect2(Vector2.ONE * edge_margin, layout_size - Vector2.ONE * edge_margin * 2.0)
	if hide_when_on_screen and bounds.has_point(screen_pos):
		return

	_wants_show = true
	_edge_pos = screen_pos.clamp(bounds.position, bounds.end)
	_to_target = screen_pos - _edge_pos

func _draw_marker(view_size: Vector2) -> void:
	# A merged marker sits between its members and points the average way
	var edge_pos: Vector2 = Vector2.ZERO
	var to_target: Vector2 = Vector2.ZERO
	var names: PackedStringArray = []
	for member in _group:
		edge_pos += member._edge_pos
		to_target += member._to_target
		if not member.point_name.is_empty():
			names.append(member.point_name)
	edge_pos /= float(_group.size())

	marker.show()
	marker.position = edge_pos - marker.size / 2.0
	if to_target.length() > 0.5:
		arrow.rotation = to_target.angle() + deg_to_rad(texture_angle_offset)

	var text := " / ".join(names)
	if name_label.text != text:
		name_label.text = text
	name_label.visible = not text.is_empty()

	# Near the bottom edge the bar and name would fall off screen - stack them up
	_stack_extras(edge_pos.y > view_size.y * 0.6)
	_place_label(view_size)

	if not hold_timer.is_stopped():
		hold_bar.value = 1.0 - hold_timer.time_left / hold_time

# The name is wider than the arrow, so centring it blindly runs off the side
# edges - size it to the text and keep it inside the screen
func _place_label(view_size: Vector2) -> void:
	if not name_label.visible:
		return

	var width: float = maxf(name_label.get_minimum_size().x + LABEL_PADDING, marker.size.x)
	var left: float = marker.position.x + (marker.size.x - width) * 0.5
	left = clampf(left, LABEL_PADDING, maxf(LABEL_PADDING, view_size.x - width - LABEL_PADDING))

	name_label.offset_left = left - marker.position.x
	name_label.offset_right = name_label.offset_left + width

func _stack_extras(above: bool) -> void:
	hold_bar.offset_top = -22.0 if above else 99.0
	hold_bar.offset_bottom = -11.0 if above else 110.0
	name_label.offset_top = -70.0 if above else 114.0
	name_label.offset_bottom = -22.0 if above else 162.0

# modulate multiplies down onto the arrow, bar and label, and survives the
# show/hide the merge pass does every frame
func fade_in() -> void:
	marker.modulate.a = 0.0
	create_tween().tween_property(marker, "modulate:a", 1.0, fade_time)

func _hide_marker() -> void:
	if marker.visible:
		_cancel_hold()
		marker.hide()

func _start_hold() -> void:
	hold_bar.value = 0.0
	hold_bar.show()
	hold_timer.start(hold_time)

func _cancel_hold() -> void:
	hold_timer.stop()
	hold_bar.hide()

func _teleport() -> void:
	_cancel_hold()
	if player == null or _pick_target() == null:
		return

	if _squash_tween and _squash_tween.is_running():
		_squash_tween.kill()

	# Squash first, hop while the sprite is small, then spring back
	_squash_tween = create_tween()
	_squash_tween.tween_property(_player_visual, "scale", _visual_scale * squash_scale, squash_time)
	_squash_tween.tween_callback(_place_player)
	_squash_tween.tween_property(_player_visual, "scale", _visual_scale, pop_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# A merged marker stands for several places - take the nearest one
func _pick_target() -> Node2D:
	var best: Node2D = target if is_instance_valid(target) else null
	if player == null:
		return best
	var best_distance: float = INF
	if best != null:
		best_distance = player.global_position.distance_squared_to(best.global_position)
	for member in _group:
		if not is_instance_valid(member.target):
			continue
		var distance: float = player.global_position.distance_squared_to(member.target.global_position)
		if distance < best_distance:
			best_distance = distance
			best = member.target
	return best

func _place_player() -> void:
	var goal := _pick_target()
	if goal == null:
		return
	player.global_position = goal.global_position
	# Otherwise the old navigation goal drags the player straight back
	if player.has_method("stop_moving"):
		player.stop_moving()
