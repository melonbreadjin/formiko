extends Node

export(Dictionary) var worldgen_parameters = {
	"CHANCE_GRASS" : 0.475,
	"CHANCE_FLOWER" : 0.625,
	"CHANCE_TREE" : 0.725,
	"CHANCE_TREE_BEE" : 0.775,
	"CHANCE_SAND" : 0.875,
	"CHANCE_PUDDLE" : 1.0
}

var tilemap : TileMap
var tileset : TileSet

var game_seed : int

func _ready() -> void:
	tilemap = $World/TileMap
	tileset = tilemap.tile_set
	
	randomize()
	create_world(randi())

func create_world(rnd_seed : int):
	game_seed = rnd_seed
	seed(game_seed)
	randomize()
	
	for y in Globals.world_size.y:
		for x in Globals.world_size.x:
			var i = randf()
			
			if i < worldgen_parameters["CHANCE_GRASS"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("grass_%d" % (randi() % 3 + 1)))
			elif i < worldgen_parameters["CHANCE_FLOWER"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("flower_%d" % (randi() % 3 + 1)))
			elif i < worldgen_parameters["CHANCE_TREE"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("tree"))
			elif i < worldgen_parameters["CHANCE_TREE_BEE"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("tree_bee"))
			elif i < worldgen_parameters["CHANCE_SAND"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("sand"))
			elif i < worldgen_parameters["CHANCE_PUDDLE"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("puddle"))
	
