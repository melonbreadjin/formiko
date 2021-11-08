extends Node

const BUILD = "0.0.1dev"

const BLOCK_SIZE : float = 128.0
const CAMERA_MOVESPEED : float = 5.0
const CAMERA_DRAGSPEED : float = 2.0
const CAMERA_ZOOMSPEED : float = 4.0
const CAMERA_ZOOM_EXTENTS_MIN : float = 0.75
const CAMERA_ZOOM_EXTENTS_MAX : float = 1.5

const unit_names : Array = [
	"Worker Ant",
	"Soldier Ant",
	"Queen Ant"
]

enum unit_type{
	ANT_WORKER,
	ANT_SOLDIER,
	ANT_QUEEN
}

signal highlight_tile(pos, off, zoom)
signal update_seed(rnd_seed)

signal toggle_sidebar(info)

var world_size : Vector2 = Vector2(16, 16)

var player_count : int = 1
var bot_count : int = 1

var starting_units : Dictionary = {
	unit_type.ANT_WORKER : 10,
	unit_type.ANT_SOLDIER : 1,
	unit_type.ANT_QUEEN : 1
}
