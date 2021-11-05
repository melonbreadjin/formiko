extends Camera2D

var direction : Vector2

func _ready():
	limit_top = 0
	limit_left = 0
	limit_right = int(Globals.world_size.x * Globals.BLOCK_SIZE)
	limit_bottom = int(Globals.world_size.y * Globals.BLOCK_SIZE)

func _process(delta : float) -> void:
	direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	direction = direction.normalized()
	
	position += direction * Globals.CAMERA_MOVESPEED * Globals.BLOCK_SIZE * delta
	position.x = clamp(position.x, limit_left, limit_right - get_viewport().size.x)
	position.y = clamp(position.y, limit_top, limit_bottom - get_viewport().size.y)
