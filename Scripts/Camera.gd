extends Camera2D

onready var ui_elements = preload("res://Assets/ui_elements_atlas.tres")

var drag_direction : Vector2
var move_direction : Vector2
var zoom_direction : Vector2

var is_camera_dragging : bool = false

var mouse_pre_drag : Vector2
var mouse_post_drag : Vector2
var mouse_drag_delta : Vector2

func _ready() -> void:
	limit_top = 0
	limit_left = 0
	limit_right = int(Globals.world_size.x * Globals.BLOCK_SIZE)
	limit_bottom = int(Globals.world_size.y * Globals.BLOCK_SIZE)
	
	ui_elements.region.position = Vector2(64, 0)
	Input.set_custom_mouse_cursor(ui_elements, Input.CURSOR_ARROW, Vector2(0, 16))

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			is_camera_dragging = true
			mouse_pre_drag = event.position
		else:
			is_camera_dragging = false
			mouse_post_drag = event.position
			mouse_drag_delta = mouse_post_drag - mouse_pre_drag
	
	if event is InputEventMouseMotion and is_camera_dragging:
		Globals.emit_signal("toggle_sidebar", {})
		Globals.emit_signal("highlight_tile", null, null, null)
		drag_direction = event.relative.normalized()
	
	if event.is_action_pressed("ui_zoom_in"):
		zoom_direction = Vector2(-1.0, -1.0)
	elif event.is_action_pressed("ui_zoom_out"):
		zoom_direction = Vector2(1.0, 1.0)

func _process(delta : float) -> void:
	move_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	move_direction = (move_direction - drag_direction).normalized()
	
	if move_direction != Vector2.ZERO:
		Globals.emit_signal("toggle_sidebar", {})
	
	zoom += zoom_direction * Globals.CAMERA_ZOOMSPEED * delta
	zoom.x = clamp(zoom.x, Globals.CAMERA_ZOOM_EXTENTS_MIN, Globals.CAMERA_ZOOM_EXTENTS_MAX)
	zoom.y = clamp(zoom.y, Globals.CAMERA_ZOOM_EXTENTS_MIN, Globals.CAMERA_ZOOM_EXTENTS_MAX)
	zoom_direction = Vector2.ZERO
	
	position += move_direction / zoom.x * Globals.CAMERA_MOVESPEED * Globals.BLOCK_SIZE * delta * (Globals.CAMERA_DRAGSPEED if is_camera_dragging else 1.0)
	position.x = clamp(position.x, limit_left, limit_right - get_viewport().size.x * zoom.x)
	position.y = clamp(position.y, limit_top, limit_bottom - get_viewport().size.y * zoom.y)
	drag_direction = Vector2.ZERO
	
	Globals.emit_signal("highlight_tile", get_local_mouse_position(), position, zoom)
