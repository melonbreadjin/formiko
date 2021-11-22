extends Node2D
class_name Unit

var rng : RandomNumberGenerator

var player : int
var unit_type : int
var movement : float

var tile_pos : Vector2
var target_rot : float

func init_unit() -> void:
	match unit_type:
		Globals.unit_type.ANT_WORKER:
			$Sprite.animation = "walk_worker"
		Globals.unit_type.ANT_SOLDIER:
			movement = 2.0
		Globals.unit_type.ANT_QUEEN:
			movement = 1.0
	
	#$Sprite.texture.region.position.y = Globals.ANT_SPRITE_SIZE * unit_type
	$Sprite.modulate = Globals.COLOURS[player]
	rng = RandomNumberGenerator.new()
	rng.randomize()
	target_rot = rng.randf_range(0, 2 * PI)
	
	$Sprite.speed_scale = rng.randf_range(4, 4.5)
	$Timer.wait_time = rng.randf_range(0, 1)
	
	reset_movement()

func reset_movement() -> void:
	match unit_type:
		Globals.unit_type.ANT_WORKER:
			movement = 3.0
		Globals.unit_type.ANT_SOLDIER:
			movement = 2.0
		Globals.unit_type.ANT_QUEEN:
			movement = 1.0

func _physics_process(delta):
	if not Globals.camera_rect.has_point(position):
		return
	
	rotation = lerp_angle(rotation, target_rot, 0.05)
	position += Vector2(cos(rotation - PI / 4), sin(rotation - PI / 4)).normalized() * 16.0 * delta

func _on_Timer_timeout():
	if not Globals.camera_rect.has_point(position):
		return
	
	var center_pos = tile_pos * Globals.BLOCK_SIZE + Vector2(Globals.BLOCK_SIZE / 2, Globals.BLOCK_SIZE / 2)
	
	if position.distance_to(center_pos) > 48.0:
		target_rot = rng.randfn(position.direction_to(center_pos).angle())
	else:
		target_rot = rng.randfn(target_rot)
		
	$Timer.wait_time = rng.randf_range(0, 1)
	$Timer.start()
