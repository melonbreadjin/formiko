extends Node
class_name Player

var player_name : String
var is_bot : bool
var colour : Color
var node : Node2D

var queen_position : Vector2

var units : Array = []

var unit_count : Dictionary = {
	Globals.unit_type.ANT_WORKER : 0,
	Globals.unit_type.ANT_SOLDIER : 0,
	Globals.unit_type.ANT_QUEEN : 0
}

var resources : Dictionary = {
	Globals.resource.FOOD : 10,
	Globals.resource.HONEY : 0
}

var added_resources : Dictionary = {
	Globals.resource.FOOD : 0,
	Globals.resource.HONEY : 0
}

func _to_string():
	return "[name : %s, is_bot : %s, colour : %s, units : %s]" % [name, is_bot, colour, unit_count]
