extends Node

onready var unit = preload("res://Entities/Unit.tscn")

var tilemap : TileMap
var tileset : TileSet

var unit_map : Array
var yield_map : Array

var players : Array

var game_seed : int
var active_player : int
var player_count : int

var _sgn

func _ready() -> void:
	tilemap = $World/TileMap
	tileset = tilemap.tile_set
	
	_sgn = Globals.connect("end_turn", self, "on_end_turn")
	
	randomize()
	new_game()

func new_game() -> void:
	create_world(randi())
	
	for i in range(Globals.player_count + Globals.bot_count):
		if i < Globals.player_count:
			players.append(["Player %d" % (i + 1), false, Globals.COLOURS[i]])
		else:
			players.append(["Player %d (Bot)" % (i + 1), true, Globals.COLOURS[i]])
	
	player_count = players.size()
	active_player = 0
	
	init_players()

func init_players() -> void:
	for player in players:
		var node : Node2D = Node2D.new()
		
		node.name = player[0]
		
		players[players.find(player)].append(node)
		$World/Entities.add_child(node)
	
	var spawn_points : Array = init_spawn_points()
	
	for index in range(spawn_points.size()):
		for entry in Globals.starting_units:
			for _i in range(Globals.starting_units[entry]):
				var instance = unit.instance()
				
				instance.unit_type = Globals.starting_units.keys()[entry]
				instance.name = Globals.UNIT_NAMES[instance.unit_type]
				
				instance.position = spawn_points[index] * Globals.BLOCK_SIZE
				instance.get_node("Polygon2D").color = players[index][2]
				
				unit_map[spawn_points[index].y][spawn_points[index].x].append(instance)
				
				players[index][3].add_child(instance)

func init_spawn_points() -> PoolVector2Array:
	var indeces : Array = []
	var points : PoolVector2Array = []
	
	randomize()
	var dev : float = randf() * PI
	
	for i in range(player_count):
		indeces.append(i + 0.5)
	
	for i in indeces:
		var r = sqrt(i / player_count)
		var t = PI * (1 + sqrt(5)) * i
		
		var x = r * cos(t)
		var y = r * sin(t)
		
		var xr = (cos(dev) * x - sin(dev) * y) + 1
		var yr = (sin(dev) * x + cos(dev) * y) + 1
		
		xr = clamp(round(xr * Globals.world_size.x / 2), 1, Globals.world_size.x - 2)
		yr = clamp(round(yr * Globals.world_size.y / 2), 1, Globals.world_size.y - 2)
		
		points.append(Vector2(xr, yr))
	
	return points

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_position : Vector2 = event.position
		
		if not event.pressed and event.button_index == BUTTON_LEFT and $Camera.mouse_drag_delta == Vector2.ZERO:
			var pos : Vector2 = tilemap.world_to_map((mouse_position * $Camera.zoom + $Camera.position) / tilemap.scale)
			
			if pos.x < 0 or pos.y < 0 or pos.x >= Globals.world_size.x or pos.y >= Globals.world_size.y:
				return
			
			Globals.emit_signal("toggle_sidebar", {
				"tilemap_position" : pos,
				"tile_name" : tileset.tile_get_name(tilemap.get_cellv(pos)),
				"tile_region" : tileset.tile_get_region(tilemap.get_cellv(pos)),
				"tile_yield" : yield_map[pos.y][pos.x],
				"units" : get_units_in_tile(pos)
			})

func get_units_in_tile(pos : Vector2) -> Array:
	return unit_map[pos.y][pos.x]

func _unhandled_key_input(event : InputEventKey) -> void:
	if "dev" in Globals.BUILD and event.scancode == KEY_F1 and event.pressed:
		create_world(randi())

func create_world(rnd_seed : int) -> void:
	game_seed = rnd_seed
	seed(game_seed)
	Globals.emit_signal("update_seed", game_seed)
	randomize()
	
	for y in Globals.world_size.y:
		yield_map.append([])
		unit_map.append([])
		
		for x in Globals.world_size.x:
			unit_map[y].append([])
			
			var i = randf()
			
			if i < Globals.worldgen_parameters["CHANCE_GRASS"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("grass_%d" % (randi() % 3 + 1)))
				yield_map[y].append(Globals.food_yields["grass"])
			elif i < Globals.worldgen_parameters["CHANCE_FLOWER"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("flower_%d" % (randi() % 3 + 1)))
				yield_map[y].append(Globals.food_yields["flower"])
			elif i < Globals.worldgen_parameters["CHANCE_TREE"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("tree"))
				yield_map[y].append(Globals.food_yields["tree"])
			elif i < Globals.worldgen_parameters["CHANCE_TREE_BEE"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("tree_bee"))
				yield_map[y].append(Globals.food_yields["tree_bee"])
			elif i < Globals.worldgen_parameters["CHANCE_SAND"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("sand"))
				yield_map[y].append(Globals.food_yields["sand"])
			elif i < Globals.worldgen_parameters["CHANCE_PUDDLE"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("puddle"))
				yield_map[y].append(Globals.food_yields["puddle"])

func on_end_turn() -> void:
	active_player = (active_player + 1) % player_count
	Globals.emit_signal("update_turn", players[active_player][0])
