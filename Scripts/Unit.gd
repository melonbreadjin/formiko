extends Node2D
class_name Unit

var rng : RandomNumberGenerator

var player : int
var unit_type : int
var movement : float

var tile_pos : Vector2
var center_pos : Vector2
var target_rot : float

var is_repositioning : bool

var roam_speed : float

func init_unit() -> void:
	center_pos = tile_pos * Globals.BLOCK_SIZE + Vector2(Globals.BLOCK_SIZE / 2, Globals.BLOCK_SIZE / 2)
	
	match unit_type:
		Globals.unit_type.ANT_WORKER:
			$Sprite.animation = "walk_worker"
		Globals.unit_type.ANT_SOLDIER:
			movement = 2.0
		Globals.unit_type.ANT_QUEEN:
			movement = 1.0
	
	rng = RandomNumberGenerator.new()
	rng.randomize()
	target_rot = rng.randf_range(0, 2 * PI)
	
	$Sprite.speed_scale = rng.randf_range(4, 4.5)
	$Sprite.modulate = Globals.COLOURS[player]
	
	$Timer.wait_time = rng.randf_range(0, 1)
	
	is_repositioning = false
	roam_speed = 16.0
	
	reset_movement()

func reset_movement() -> void:
	match unit_type:
		Globals.unit_type.ANT_WORKER:
			movement = 3.0
		Globals.unit_type.ANT_SOLDIER:
			movement = 2.0
		Globals.unit_type.ANT_QUEEN:
			movement = 1.0

func reposition(pos : Vector2) -> void:
	tile_pos = pos
	center_pos = tile_pos * Globals.BLOCK_SIZE + Vector2(Globals.BLOCK_SIZE / 2, Globals.BLOCK_SIZE / 2)
	
	is_repositioning = true
	$Timer.start(0.1)

func _physics_process(delta : float) -> void:
	if not Globals.camera_rect.has_point(position):
		return
	
	if position.distance_to(center_pos) > 48.0 and is_repositioning:
		roam_speed = 64.0
	else:
		if is_repositioning:
			is_repositioning = false
			$Timer.start(0.1)
		roam_speed = 16.0
	
	rotation = lerp_angle(rotation, target_rot, 0.05)
	position += Vector2(cos(rotation - PI / 4), sin(rotation - PI / 4)).normalized() * roam_speed * delta

func _on_Timer_timeout() -> void:
	if not Globals.camera_rect.has_point(position):
		return
	
	if position.distance_to(center_pos) > 48.0:
		target_rot = rng.randfn(position.direction_to(center_pos).angle())
	else:
		target_rot = rng.randfn(target_rot)
	
	if is_repositioning:
		$Timer.wait_time = 0.1
	else:
		$Timer.wait_time = rng.randf_range(0, 1)
	$Timer.start()
