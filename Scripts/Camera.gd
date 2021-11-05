extends Camera2D

var move_direction : Vector2
var zoom_direction : Vector2

func _ready() -> void:
	limit_top = 0
	limit_left = 0
	limit_right = int(Globals.world_size.x * Globals.BLOCK_SIZE)
	limit_bottom = int(Globals.world_size.y * Globals.BLOCK_SIZE)

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_zoom_in"):
		zoom_direction = Vector2(-1.0, -1.0)
	elif event.is_action_pressed("ui_zoom_out"):
		zoom_direction = Vector2(1.0, 1.0)

func _process(delta : float) -> void:
	move_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	move_direction = move_direction.normalized()
	
	position += move_direction / zoom.x * Globals.CAMERA_MOVESPEED * Globals.BLOCK_SIZE * delta
	position.x = clamp(position.x, limit_left, limit_right - get_viewport().size.x)
	position.y = clamp(position.y, limit_top, limit_bottom - get_viewport().size.y)
	
	zoom += zoom_direction * delta
	zoom.x = clamp(zoom.x, Globals.CAMERA_ZOOM_EXTENTS_MIN, Globals.CAMERA_ZOOM_EXTENTS_MAX)
	zoom.y = clamp(zoom.y, Globals.CAMERA_ZOOM_EXTENTS_MIN, Globals.CAMERA_ZOOM_EXTENTS_MAX)
	zoom_direction = Vector2.ZERO
