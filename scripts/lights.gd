extends Node2D

## Single day/night driver for every lamp in the world. One AnimationPlayer track
## writes `night`; the children are only touched when that value actually moves,
## so the two brief fades cost work and the rest of the cycle costs nothing.

const LIT_THRESHOLD := 0.001

@export var night: float = 0.0:
	set(value):
		if is_equal_approx(value, night):
			return
		night = value
		_apply()

var _lights: Array = []
var _lamps: Array = []
var _lit := false

func _ready() -> void:
	_lights = find_children("*", "PointLight2D", true, false)
	_lamps = find_children("*", "AnimatedSprite2D", true, false)
	_lit = night <= LIT_THRESHOLD
	_apply()

func _apply() -> void:
	var lit := night > LIT_THRESHOLD
	for light in _lights:
		light.energy = night
		light.enabled = lit
	if lit != _lit:
		_lit = lit
		var frame := &"on" if lit else &"off"
		for lamp in _lamps:
			lamp.animation = frame
