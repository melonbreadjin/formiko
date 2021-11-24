extends Node

const BUILD = "0.0.1dev"

const ANT_SPRITE_SIZE : float = 16.0
const BLOCK_SIZE : float = 128.0
const CAMERA_MOVESPEED : float = 5.0
const CAMERA_DRAGSPEED : float = 2.0
const CAMERA_ZOOMSPEED : float = 8.0
const CAMERA_ZOOM_EXTENTS_MIN : float = 0.75
const CAMERA_ZOOM_EXTENTS_MAX : float = 1.5

const COLOURS : Array = [
	Color("#e64e4b"),
	Color("#365a9b")
]

const UNIT_NAMES : Array = [
	"Worker Ant",
	"Soldier Ant",
	"Queen Ant"
]

enum unit_type{
	ANT_WORKER,
	ANT_SOLDIER,
	ANT_QUEEN
}

enum resource{
	FOOD,
	HONEY
}

signal highlight_tile(pos, off, zoom)
signal update_seed(rnd_seed)

signal spawn_units(player, spawns)

signal select_unit(unit, unit_handler, unit_image, unit_count)
signal move_unit(unit, unit_handler, unit_count, pos)
signal update_turn(player, player_name, data)
signal update_hud(data)
signal end_turn()

signal move_camera_and_pointer(pos)

signal reset_ui()
signal close_cancel_button()
signal toggle_sidebar(info)

var camera_rect : Rect2
var world_size : Vector2 = Vector2(16, 16)

var player_count : int = 1
var bot_count : int = 1

var worldgen_parameters = {
	"CHANCE_GRASS" : 0.475,
	"CHANCE_FLOWER" : 0.625,
	"CHANCE_TREE" : 0.725,
	"CHANCE_TREE_BEE" : 0.775,
	"CHANCE_SAND" : 0.875,
	"CHANCE_PUDDLE" : 1.0
}

var food_yields = {
	"grass" : 0.25,
	"flower" : 1.0,
	"tree" : 0.75,
	"tree_bee" : 0.75,
	"sand" : 0,
	"puddle" : 0.5
}

var starting_units : Dictionary = {
	unit_type.ANT_WORKER : 10,
	unit_type.ANT_SOLDIER : 1,
	unit_type.ANT_QUEEN : 1
}

var power_values : Dictionary = {
	unit_type.ANT_WORKER : 1,
	unit_type.ANT_SOLDIER : 10,
	unit_type.ANT_QUEEN : 65
}

var unit_cost : Dictionary = {
	unit_type.ANT_WORKER : [resource.FOOD, 10],
	unit_type.ANT_SOLDIER : [resource.FOOD, 50]
}
