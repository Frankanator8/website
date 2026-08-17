extends Node

# The look picked in the web shell's character creator.
#
# The shell downloads the engine while the visitor dresses up, but does not boot
# the game until Play. So by the time any of this runs the look is already
# decided, and there is nothing to wait for: it is read once at startup.
#
# The shell leaves it in two places -- on the window for this run, and in
# localStorage to seed the creator next visit. The window is preferred, since
# localStorage can be unwritable in private browsing. Both are treated as
# untrusted, since a visitor can edit either by hand.

const VARIANTS := 5
const STORAGE_KEY := "godot_character"

# Creator key -> custom_person.gd property.
const FRAME_PROPERTIES := {
	"face": "face_frame",
	"hair": "hair_frame",
	"shirt": "shirt_frame",
	"pants": "pants_frame",
}

const COLOR_PROPERTIES := {
	"skinColor": "skin_color",
	"hairColor": "hair_color",
	"shirtColor": "shirt_color",
	"pantsColor": "pants_color",
}

var _look: Dictionary = {}
var _on_web: bool = false


func _ready() -> void:
	_on_web = OS.has_feature("web")
	if not _on_web:
		return

	load_from_json(_eval_string("window.__pendingCharacter || ''"))
	if _look.is_empty():
		load_from_json(_eval_string(
			"(function () { try { return window.localStorage.getItem('%s') || ''; } catch (e) { return ''; } }())" % STORAGE_KEY))


## Called by the player once the world is on screen, so the shell knows it can
## drop the overlay rather than reveal a half-built scene.
func notify_world_ready() -> void:
	if _on_web:
		JavaScriptBridge.eval("window.__gameStarted = true;", true)


## Reads the creator's JSON. Anything malformed leaves the look untouched.
func load_from_json(text: String) -> void:
	if text.is_empty():
		return

	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		_look = parsed


## Dresses a custom_person instance. Keys that are missing or out of range are
## skipped, so whatever the scene already sets survives.
func apply_to(person: Node2D) -> void:
	if person == null or _look.is_empty():
		return

	for key in FRAME_PROPERTIES:
		_apply_frame(person, key, FRAME_PROPERTIES[key])

	for key in COLOR_PROPERTIES:
		_apply_color(person, key, COLOR_PROPERTIES[key])


func _eval_string(code: String) -> String:
	var raw: Variant = JavaScriptBridge.eval(code, true)
	return raw if raw is String else ""


func _apply_frame(person: Node2D, key: String, property: String) -> void:
	var raw: Variant = _look.get(key)
	if not (raw is float or raw is int):
		return

	var frame := int(raw)
	if frame < 0 or frame >= VARIANTS:
		return

	person.set(property, frame)


func _apply_color(person: Node2D, key: String, property: String) -> void:
	var raw: Variant = _look.get(key)
	if not (raw is Array) or (raw as Array).size() < 3:
		return

	var channels := PackedFloat32Array()
	for i in 3:
		var value: Variant = (raw as Array)[i]
		if not (value is float or value is int):
			return
		channels.append(clampf(float(value), 0.0, 1.0))

	person.set(property, Color(channels[0], channels[1], channels[2]))
