@tool
extends Area2D

@export var link_url: String = "https://example.com" : set = set_link_url
@export var logo_texture: Texture2D : set = set_logo_texture

@onready var logo: TextureRect = $Logo
@onready var hover: Control = $Hover
@onready var tooltip: Node2D = $Tooltip
@onready var tooltip_label: Label = $Tooltip/Panel/Label

var _mouse_over: bool = false
var _player_near: bool = false

func _ready() -> void:
	logo.texture = logo_texture
	tooltip_label.text = link_url

	if Engine.is_editor_hint():
		return

	tooltip.hide()
	hover.gui_input.connect(_on_hover_gui_input)
	hover.mouse_entered.connect(_set_mouse_over.bind(true))
	hover.mouse_exited.connect(_set_mouse_over.bind(false))
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func set_link_url(new_url: String) -> void:
	link_url = new_url
	if tooltip_label:
		tooltip_label.text = link_url

func set_logo_texture(new_texture: Texture2D) -> void:
	logo_texture = new_texture
	if logo:
		logo.texture = logo_texture

func _set_mouse_over(is_over: bool) -> void:
	_mouse_over = is_over
	_refresh_tooltip()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_refresh_tooltip()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_refresh_tooltip()

func _refresh_tooltip() -> void:
	tooltip.visible = _mouse_over or _player_near

func _on_hover_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		OS.shell_open(link_url)
