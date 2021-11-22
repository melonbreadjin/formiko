extends Node2D
class_name Unit

var player : int
var unit_type : int
var movement : float

var tile_pos : Vector2

func init_unit() -> void:
	$Sprite.texture.region.position.y = Globals.ANT_SPRITE_SIZE * unit_type
	$Sprite.modulate = Globals.COLOURS[player]
	
	reset_movement()

func reset_movement() -> void:
	match unit_type:
		Globals.unit_type.ANT_WORKER:
			movement = 3.0
		Globals.unit_type.ANT_SOLDIER:
			movement = 2.0
		Globals.unit_type.ANT_QUEEN:
			movement = 1.0
