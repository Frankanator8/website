extends AnimationPlayer

func _ready() -> void:
	var time := Time.get_time_dict_from_system()
	var hour := float(time.hour) + float(time.minute) / 60.0
	var offset := fmod(hour - 12.0 + 24.0, 24.0) * 5.0
	# var offset = 53.0
	play(&"cycle")
	seek(offset, true)
