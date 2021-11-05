extends Camera2D

var direction : Vector2

func _process(delta : float) -> void:
	direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	direction = direction.normalized()
	
	position += direction * Globals.CAMERA_MOVESPEED * Globals.BLOCK_SIZE * delta
	position.x = clamp(position.x, 0, Globals.world_size.x * Globals.BLOCK_SIZE)
	position.y = clamp(position.y, 0, Globals.world_size.y * Globals.BLOCK_SIZE)
