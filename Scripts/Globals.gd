extends Node

const BUILD = "0.0.1dev"

const BLOCK_SIZE = 128.0
const CAMERA_MOVESPEED = 5.0
const CAMERA_ZOOM_EXTENTS_MIN = 0.75
const CAMERA_ZOOM_EXTENTS_MAX = 1.5

signal update_seed(rnd_seed)

var world_size : Vector2 = Vector2(16, 16)
