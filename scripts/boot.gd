extends Control

const MAIN_SCENE := "res://scenes/main.tscn"

@onready var progress_bar: ProgressBar = $ProgressBar


func _ready() -> void:
	ResourceLoader.load_threaded_request(MAIN_SCENE)
	set_process(true)


func _process(_delta: float) -> void:
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(MAIN_SCENE, progress)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			progress_bar.value = progress[0] * 100.0
		ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			push_error("Boot: failed to load '%s'" % MAIN_SCENE)
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			progress_bar.value = 100.0
			var packed_scene: PackedScene = ResourceLoader.load_threaded_get(MAIN_SCENE)
			get_tree().change_scene_to_packed(packed_scene)
