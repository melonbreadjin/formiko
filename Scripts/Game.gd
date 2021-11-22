extends Node
class_name Game

onready var unit = preload("res://Scenes/Unit.tscn")

var tilemap : TileMap
var tileset : TileSet

var tilemap_territory : TileMap
var tileset_territory : TileSet

var unit_map : UnitMap
var yield_map : Array

var players : Array

var game_seed : int
var active_player : int
var player_count : int

var is_unit_dragging : bool
var unit_drag_instance : Unit
var unit_drag_position : Vector2
var unit_drag_handler : Array
var unit_drag_count : int
var unit_drag_loss : int

var _sgn

class UnitMap:
	class Tile:
		var unit_instances : Array = []
		var unit_handler : Array = []
		var unit_count : Array = []
		
		func get_tile_power() -> int:
			var tile_power : int = 0
			
			for index in range(unit_count.size()):
				tile_power += Globals.power_values[unit_instances[index].unit_type] * unit_count[index]
			
			return tile_power
		
		func reset_movement() -> void:
			for index in range(unit_instances.size()):
				unit_instances[index].reset_movement()
				unit_handler[index][1] = unit_instances[index].movement
		
		func add_unit_to_tile(unit : Unit, count : int = 1) -> void:
			var handle : Array = [unit.unit_type, unit.movement]
			var index : int = unit_handler.find(handle)
			
			if index != -1:
				unit_count[index] += count
			else:
				var new_unit : Unit = Unit.new()
				new_unit.player = unit.player
				new_unit.unit_type = unit.unit_type
				new_unit.movement = unit.movement
				new_unit.tile_pos = unit.tile_pos
				
				unit_instances.append(new_unit)
				unit_handler.append(handle)
				unit_count.append(count)
		
		func remove_unit_from_tile(unit : Unit, count : int = 1) -> void:
			var handle : Array = [unit.unit_type, unit.movement]
			var index : int = unit_handler.find(handle)
			
			if index == -1:
				return
			else:
				if unit_count[index] <= count:
					unit_instances.remove(index)
					unit_handler.remove(index)
					unit_count.remove(index)
				else:
					unit_count[index] -= count
	
	var data : Array
	
	func init() -> void:
		data.clear()
		
		for y in Globals.world_size.y:
			data.append([])
			
			for x in Globals.world_size.x:
				var tile = Tile.new()
				data[y].append(tile)

class Player:
	var name : String
	var is_bot : bool
	var colour : Color
	var node : Node2D
	
	var units : Array = []
	
	var unit_count : Dictionary = {
		Globals.unit_type.ANT_WORKER : 0,
		Globals.unit_type.ANT_SOLDIER : 0,
		Globals.unit_type.ANT_QUEEN : 0
	}
	
	var resources : Dictionary = {
		Globals.resource.FOOD : 0,
		Globals.resource.HONEY : 0
	}
	
	var added_resources : Dictionary = {
		Globals.resource.FOOD : 0,
		Globals.resource.HONEY : 0
	}
	
	func _to_string():
		return "[name : %s, is_bot : %s, colour : %s, units : %s]" % [name, is_bot, colour, unit_count]

func _ready() -> void:
	tilemap = $World/TileMap
	tileset = tilemap.tile_set
	
	tilemap_territory = $World/TerritoryMap
	tileset_territory = tilemap_territory.tile_set
	
	_sgn = Globals.connect("end_turn", self, "on_end_turn")
	_sgn = Globals.connect("move_unit", self, "on_move_unit")
	
	randomize()
	new_game()

func reset() -> void:
	Globals.emit_signal("reset_ui")
	is_unit_dragging = false
	
	for child in $World/Entities.get_children():
		$World/Entities.remove_child(child)
		child.queue_free()
	
	for player_node in $World/Entities.get_children():
		for unit_node in player_node.get_children():
			player_node.remove_child(unit_node)
			unit_node.queue_free()
		
		$World/Entities.remove_child(player_node)
		player_node.queue_free()
	
	yield_map.clear()
	players.clear()

func new_game() -> void:
	reset()
	create_world(randi())
	
	for i in range(Globals.player_count + Globals.bot_count):
		var player : Player = Player.new()
		
		if i < Globals.player_count:
			player.name = "Player %d" % (i + 1)
			player.is_bot = false
		else:
			player.name = "Player %d (Bot)" % (i + 1)
			player.is_bot = true
		
		player.colour = Globals.COLOURS[i]
		players.append(player)
	
	player_count = players.size()
	active_player = 0
	
	Globals.emit_signal("update_turn", active_player, players[active_player].name, players[active_player])
	
	init_players()

func init_players() -> void:
	for player in players:
		var node : Node2D = Node2D.new()
		
		node.name = player.name
		
		players[players.find(player)].node = node
		$World/Entities.add_child(node)
	
	init_units()

func init_units() -> void:
	var spawn_points : Array = init_spawn_points()
	
	$Camera.position = spawn_points[0] * Globals.BLOCK_SIZE + \
		Vector2(Globals.BLOCK_SIZE / 2.0, Globals.BLOCK_SIZE / 2.0) - \
		$Camera.get_viewport_rect().size / 2.0
	
	for index in range(spawn_points.size()):
		tilemap_territory.set_cellv(spawn_points[index], tileset_territory.find_tile_by_name("%d" % index))
		
		for entry in Globals.starting_units:
			for _i in range(Globals.starting_units[entry]):
				var instance = unit.instance()
				
				instance.player = index
				instance.unit_type = Globals.starting_units.keys()[entry]
				instance.tile_pos = spawn_points[index]
				instance.name = Globals.UNIT_NAMES[instance.unit_type]
				
				instance.position = spawn_points[index] * Globals.BLOCK_SIZE + Vector2(Globals.BLOCK_SIZE / 2.0, Globals.BLOCK_SIZE / 2.0)
				
				instance.init_unit()
				
				unit_map.data[spawn_points[index].y][spawn_points[index].x].add_unit_to_tile(instance)
				
				players[index].unit_count[Globals.starting_units.keys()[entry]] += 1
				players[index].node.add_child(instance)
				players[index].units.append(instance)

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
			
			var distance : int = get_tile_distance(pos, unit_drag_position)
			
			if is_unit_dragging:
				if unit_drag_instance.movement < distance or distance == 0:
					print("too far ", unit_drag_instance.movement)
				else:
					drop_unit(pos, distance)
			else:
				Globals.emit_signal("toggle_sidebar", {
					"tilemap_position" : pos,
					"tilemap_global_position" : tilemap.map_to_world(pos),
					"tile_name" : tileset.tile_get_name(tilemap.get_cellv(pos)),
					"tile_region" : tileset.tile_get_region(tilemap.get_cellv(pos)),
					"tile_yield" : yield_map[pos.y][pos.x],
					"units" : get_units_in_tile(pos)
				})

func get_tile_distance(a : Vector2, b : Vector2) -> int:
	return int(abs(a.x - b.x) + abs(a.y - b.y))

func get_units_in_tile(pos : Vector2) -> UnitMap.Tile:
	return unit_map.data[pos.y][pos.x]

func _unhandled_key_input(event : InputEventKey) -> void:
	if "dev" in Globals.BUILD and event.scancode == KEY_F1 and event.pressed:
		new_game()

func create_world(rnd_seed : int) -> void:
	game_seed = rnd_seed
	seed(game_seed)
	Globals.emit_signal("update_seed", game_seed)
	randomize()
	
	unit_map = UnitMap.new()
	unit_map.init()
	
	for y in Globals.world_size.y:
		yield_map.append([])
		
		for x in Globals.world_size.x:
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
	var total : float = 0.0
	
	for worker in players[active_player].node.get_children():
		if worker.unit_type == Globals.unit_type.ANT_WORKER:
			total += yield_map[worker.tile_pos.y][worker.tile_pos.x]
	
	players[active_player].resources[Globals.resource.FOOD] += total
	players[active_player].added_resources[Globals.resource.FOOD] = total
	
	for y in range(Globals.world_size.y):
		for x in range(Globals.world_size.x):
			get_units_in_tile(Vector2(x, y)).reset_movement()
	
	for player_unit in players[active_player].units:
		player_unit.reset_movement()
	
	active_player = (active_player + 1) % player_count
	Globals.emit_signal("update_turn", active_player, players[active_player].name, players[active_player])

func on_move_unit(unit_instance : Unit, unit_handler : Array, unit_count : int, pos : Vector2) -> void:
	if is_unit_dragging == false:
		unit_drag_instance = unit_instance
		unit_drag_handler = unit_handler
		unit_drag_count = unit_count
		unit_drag_position = pos
		
		is_unit_dragging = true

func initiate_combat(pos : Vector2) -> bool:
	var units : UnitMap.Tile = get_units_in_tile(pos)
	
	if tilemap_territory.get_cellv(pos) != -1 and int(tileset_territory.tile_get_name(tilemap_territory.get_cellv(pos))) == active_player:
		return true
	else:
		var player_power : float = Globals.power_values[unit_drag_instance.unit_type] * unit_drag_count
		var enemy_power : float = units.get_tile_power()
		
		var power_diff : float = player_power - enemy_power
		var power_loss : float = player_power - power_diff
		
		var power_diff_enemy : float = -power_diff
		var power_loss_enemy : float = enemy_power - power_diff_enemy
		
		if power_loss > 0:
			unit_drag_loss = int(power_loss / Globals.power_values[unit_drag_instance.unit_type])
			unit_drag_count -= unit_drag_loss
		
		if power_loss_enemy > 0:
			var unit_loss_enemy : Array = []
			
			for index in range(units.unit_count.size()):
				var power_share : float = Globals.power_values[units.unit_instances[index].unit_type] * units.unit_count[index] / enemy_power
				
				unit_loss_enemy.append(int(player_power * power_share / Globals.power_values[units.unit_instances[index].unit_type]))
			
			for index in range(unit_loss_enemy.size()):
				var player_id : int = units.unit_instances[index].player
				var player_unit : Array = players[player_id].node.get_children()
				
				for player_index in range(players[player_id].units.size()):
					if unit_loss_enemy[index] == 0:
						break
					elif players[player_id].units[index].unit_type == unit_loss_enemy[index] and players[player_id].units[index].tile_pos == pos:
						var unit_pop : Unit = players[player_id].units.pop_back()
						player_unit[player_index].remove_child(unit_pop)
						unit_pop.queue_free()
						
						unit_loss_enemy[index] -= 1
					
				units.remove_unit_from_tile(units.unit_instances[index], unit_loss_enemy[index])
		
		if power_diff > 0:
			return true
		else:
			return false

func drop_unit(pos : Vector2, dist : int) -> void:
	if initiate_combat(pos):
		tilemap_territory.set_cellv(pos, tileset_territory.find_tile_by_name("%d" % active_player))
		
		var new_unit : Unit = Unit.new()
		
		new_unit.player = unit_drag_instance.player
		new_unit.unit_type  = unit_drag_instance.unit_type
		new_unit.movement = unit_drag_instance.movement - dist
		new_unit.tile_pos = unit_drag_instance.tile_pos
		
		for unit_instance in unit_map.data[unit_drag_position.y][unit_drag_position.x].unit_instances:
			if unit_instance == unit_drag_instance:
				unit_map.data[unit_drag_position.y][unit_drag_position.x].remove_unit_from_tile(unit_drag_instance, unit_drag_count)
				unit_map.data[pos.y][pos.x].add_unit_to_tile(new_unit, unit_drag_count)
				
				var player : int = unit_drag_instance.player
				var player_unit : Array = players[player].node.get_children()
				
				for index in range(players[player].units.size()):
					if unit_drag_count > 0:
						if players[player].units[index].unit_type == unit_drag_instance.unit_type and players[player].units[index].movement == unit_drag_instance.movement and players[player].units[index].tile_pos == unit_drag_position:
							players[player].units[index].tile_pos = pos
							players[player].units[index].movement -= dist
							player_unit[index].position = player_unit[index].tile_pos * Globals.BLOCK_SIZE + Vector2(Globals.BLOCK_SIZE / 2.0, Globals.BLOCK_SIZE / 2.0)
							
							
							unit_drag_count -= 1
					else:
						break
				
				new_unit.movement -= dist
		
		remove_units()
	else:
		remove_units()
		
	is_unit_dragging = false
	Globals.emit_signal("close_cancel_button")

func remove_units():
	unit_map.data[unit_drag_position.y][unit_drag_position.x].remove_unit_from_tile(unit_drag_instance, unit_drag_loss)
	
	var player : int = unit_drag_instance.player
	var player_unit : Array = players[player].node.get_children()
	var units_to_remove : Array = []
	
	for index in range(players[player].units.size()):
		if unit_drag_loss > 0:
			if players[player].units[index].unit_type == unit_drag_instance.unit_type and players[player].units[index].movement == unit_drag_instance.movement and players[player].units[index].tile_pos == unit_drag_position:
				units_to_remove.append(index)
				unit_drag_loss -= 1
		else:
			break
	
	for index in range(units_to_remove.size()):
		var s : int = units_to_remove.size()
		players[player].units.remove(units_to_remove[s - index - 1])
		
		players[player].node.remove_child(player_unit[units_to_remove[s - index - 1]])
		player_unit[units_to_remove[s - index - 1]].queue_free()

func _on_CancelButton_pressed():
	is_unit_dragging = false
