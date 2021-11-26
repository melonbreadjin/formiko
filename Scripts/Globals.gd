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

enum tile{
	GRASS,
	FLOWER,
	TREE,
	TREE_BEE,
	SAND,
	PUDDLE
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

signal bot_spawn_unit(unit_type, unit_count)
signal bot_move_unit(unit, unit_handler, unit_count, from, to)
signal bot_end_turn()

signal reset_ui()
signal close_cancel_button()
signal toggle_sidebar(info)

var camera_rect : Rect2
var world_size : Vector2 = Vector2(6, 6)

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

var food_yields : Dictionary = {
	tile.GRASS : [0.25, 0.0],
	tile.FLOWER : [1.0, 0.0],
	tile.TREE : [0.75, 0.0],
	tile.TREE_BEE : [0.50, 0.75],
	tile.SAND : [0.0, 0.0],
	tile.PUDDLE : [0.5, 0.0]
}

var food_growth : Dictionary = {
	tile.GRASS : [0.025, 0.0],
	tile.FLOWER : [0.15, 0.0],
	tile.TREE : [0.1, 0.0],
	tile.TREE_BEE : [0.05, 0.1],
	tile.SAND : [0.0, 0.0],
	tile.PUDDLE : [0.05, 0.0]
}

var food_decay : Dictionary = {
	tile.GRASS : [0.0001, 0.0],
	tile.FLOWER : [0.002, 0.0],
	tile.TREE : [0.0015, 0.0],
	tile.TREE_BEE : [0.0005, 0.0015],
	tile.SAND : [0.0, 0.0],
	tile.PUDDLE : [0.0005, 0.0]
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
