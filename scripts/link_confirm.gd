extends CanvasLayer

# Autoload. Anything that wants to open a link calls LinkConfirm.ask(url)
# instead of OS.shell_open, so the user gets a yes/no prompt first.

@onready var blocker: Control = $Blocker
@onready var url_label: Label = $Blocker/Panel/VBox/Url
@onready var yes_button: Button = $Blocker/Panel/VBox/HBox/Yes
@onready var no_button: Button = $Blocker/Panel/VBox/HBox/No

var _pending_link: String = ""

func _ready() -> void:
	blocker.hide()
	yes_button.pressed.connect(_on_yes)
	no_button.pressed.connect(_on_no)

func is_open() -> bool:
	return blocker.visible

func ask(link: String) -> void:
	if link.is_empty() or is_open():
		return
	_pending_link = link
	url_label.text = link
	blocker.show()
	yes_button.grab_focus()

func _on_yes() -> void:
	var link = _pending_link
	_close()
	# Button press is a fresh user gesture, so the web popup blocker allows this.
	OS.shell_open(link)

func _on_no() -> void:
	_close()

func _close() -> void:
	blocker.hide()
	_pending_link = ""
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		_on_no()
		get_viewport().set_input_as_handled()
