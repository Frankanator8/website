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

## A real Light2D multiplies its contribution by the surface it lands on, so dark
## ground only ever caught a fraction of the lamp. These glows add on top of the
## scene instead, so this stands in for that average surface brightness.
@export_range(0.0, 2.0, 0.01) var energy_scale: float = 0.4:
	set(value):
		energy_scale = value
		_apply()

var _glows: Array = []
var _lamps: Array = []
var _lit := false

func _ready() -> void:
	_glows = find_children("*", "Sprite2D", true, false)
	_lamps = find_children("*", "AnimatedSprite2D", true, false)
	_lit = night <= LIT_THRESHOLD
	_apply()

func _apply() -> void:
	var lit := night > LIT_THRESHOLD
	# `modulate` is the energy multiplier; each glow keeps its own colour in `self_modulate`.
	var e := night * energy_scale
	var energy := Color(e, e, e, 1.0)
	for glow in _glows:
		glow.modulate = energy
		glow.visible = lit
	if lit != _lit:
		_lit = lit
		var frame := &"on" if lit else &"off"
		for lamp in _lamps:
			lamp.animation = frame
