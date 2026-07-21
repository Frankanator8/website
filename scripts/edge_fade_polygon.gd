@tool
extends Polygon2D

## Pushes this polygon's vertices into the edge_fade shader so it knows
## where its own edges are. Attach to a Polygon2D using edge_fade.gdshader.

const MAX_POINTS := 64


func _ready() -> void:
	_push_points()


func _push_points() -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	var pts := PackedVector2Array()
	for i in mini(polygon.size(), MAX_POINTS):
		pts.append(polygon[i])
	# Shader array uniform wants a fixed-size list.
	while pts.size() < MAX_POINTS:
		pts.append(Vector2.ZERO)
	mat.set_shader_parameter("points", pts)
	mat.set_shader_parameter("point_count", mini(polygon.size(), MAX_POINTS))


func _set(property: StringName, value: Variant) -> bool:
	if property == &"polygon":
		polygon = value
		_push_points()
		return true
	return false
