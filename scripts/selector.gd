extends Node2D

@export var player: Node2D # Assign your Player node here in the Inspector
@export var selection_pointer_scene: PackedScene
var selection_pointer_instance: Node2D = null

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_position = get_global_mouse_position()
		
		# Trigger player movement
		if player and player.has_method("set_move_target"):
			player.set_move_target(click_position)
		
		# Spawn the selection pointer visual effect
		spawn_pointer(click_position)

func spawn_pointer(global_pos: Vector2):
	if selection_pointer_scene:
		if selection_pointer_instance:
			selection_pointer_instance.queue_free() # Remove the previous pointer if it exists
		
		selection_pointer_instance = selection_pointer_scene.instantiate() as Node2D
		selection_pointer_instance.setup(global_pos, player) # Call the setup method to initialize the pointer
		if selection_pointer_instance:
			# Add instance to the main scene tree root to avoid inheriting parent offsets
			get_tree().current_scene.add_child(selection_pointer_instance)
			selection_pointer_instance.global_position = global_pos
