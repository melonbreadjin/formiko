extends Node
class_name Game

onready var unit = preload("res://Scenes/Unit.tscn")

var tilemap : TileMap
var tilemap_territory : TileMap
var tilemap_fog : TileMap

var tileset : TileSet
var tileset_territory : TileSet
var tileset_fog : TileSet

var unit_map : UnitMap
var yield_map : Array
var fog_map : Array

var players : Array

var game_seed : int
var active_player : int
var player_count : int

var is_unit_dragging : bool
var unit_drag_instance : Unit
var unit_drag_position : Vector2
var unit_drop_position : Vector2
var unit_drag_handler : Array
var unit_drag_count : int
var unit_drag_loss : int

var _sgn

class Yield:
	var type : int
	var yields : Array = []

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
		
		func get_unit_count(player) -> int:
			var total_count : int = 0
			
			for index in range(unit_count.size()):
				if unit_instances[index].player == player:
					total_count += unit_count[index]
			
			return total_count
		
		func reset_movement() -> void:
			for index in range(unit_instances.size()):
				unit_instances[index].reset_movement()
				unit_handler[index][1] = unit_instances[index].movement
		
		func stack_arrays() -> void:
			var temp_handler : Array = []
			var temp_indeces : Array = []
			var move_indeces : Array = []
			
			for index in range(unit_instances.size()):
				var i : int = temp_handler.find(unit_handler[index])
				
				if i != -1:
					move_indeces.append(index)
					unit_count[i] += unit_count[index]
				else:
					temp_handler.append(unit_handler[index])
					temp_indeces.append(index)
			
			for index in move_indeces:
				unit_instances.remove(index)
				unit_handler.remove(index)
				unit_count.remove(index)
		
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
		
		func remove_unit_from_tile(unit : Unit, count : int = 1) -> bool:
			var handle : Array = [unit.unit_type, unit.movement]
			var index : int = unit_handler.find(handle)
			
			if index == -1:
				return false
			else:
				if unit_count[index] <= count:
					unit_instances.remove(index)
					unit_handler.remove(index)
					unit_count.remove(index)
					
					return true
				else:
					unit_count[index] -= count
					
					return false
	
	var data : Array
	
	func init() -> void:
		data.clear()
		
		for y in Globals.world_size.y:
			data.append([])
			
			for x in Globals.world_size.x:
				var tile = Tile.new()
				data[y].append(tile)

func _ready() -> void:
	tilemap = $World/TileMap
	tileset = tilemap.tile_set
	
	tilemap_territory = $World/TerritoryMap
	tileset_territory = tilemap_territory.tile_set
	
	tilemap_fog = $World/FogMap
	tileset_fog = tilemap_fog.tile_set
	
	tilemap_fog.z_index = VisualServer.CANVAS_ITEM_Z_MAX
	
	_sgn = Globals.connect("end_turn", self, "on_end_turn")
	_sgn = Globals.connect("move_unit", self, "on_move_unit")
	_sgn = Globals.connect("spawn_units", self, "on_spawn_units")
	
	_sgn = Globals.connect("bot_spawn_unit", self, "on_bot_spawn_unit")
	_sgn = Globals.connect("bot_move_unit", self, "on_bot_move_unit")
	_sgn = Globals.connect("bot_end_turn", self, "on_bot_end_turn")
	
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
	
	fog_map.clear()
	yield_map.clear()
	players.clear()

func new_game() -> void:
	reset()
	create_world(randi())
	
	for i in range(Globals.player_count + Globals.bot_count):
		var player : Player
		
		if i < Globals.player_count:
			player = Player.new()
			player.player_name = "Player %d" % (i + 1)
			player.is_bot = false
		else:
			player = Bot.new()
			player.player_name = "Player %d (Bot)" % (i + 1)
			player.is_bot = true
		
		player.colour = Globals.COLOURS[i]
		players.append(player)
	
	player_count = players.size()
	active_player = 0
	
	Globals.emit_signal("update_turn", active_player, players[active_player].player_name, players[active_player])
	
	init_players()

func init_players() -> void:
	for player in players:
		var node : Node2D = Node2D.new()
		
		node.name = player.player_name
		
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
		
		spawn_units(index, Globals.starting_units, spawn_points[index])

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
			
			if tilemap_fog.get_cell(int(pos.x), int(pos.y)) == tileset_fog.find_tile_by_name("fog"):
				Globals.emit_signal("toggle_sidebar", {})
			elif is_unit_dragging:
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

func is_out_of_bounds(x : int, y : int) -> bool:
	return true if x < 0 or y < 0 or x >= Globals.world_size.x or y >= Globals.world_size.y else false 

func get_tiles_in_area(x : int, y : int, radius : int, is_add : bool) -> Array:
	var tiles : Array = []
	
	if is_out_of_bounds(x, y):
		return tiles
	
	if is_add:
		fog_map[y][x] += 1
	else:
		fog_map[y][x] -= 1
	
	if radius == 0:
		tiles.append(Vector2(x, y))
	else:
		tiles.append(Vector2(x, y))
		
		tiles.append_array(get_tiles_in_area(x - 1, y, radius - 1, is_add))
		tiles.append_array(get_tiles_in_area(x + 1, y, radius - 1, is_add))
		tiles.append_array(get_tiles_in_area(x, y - 1, radius - 1, is_add))
		tiles.append_array(get_tiles_in_area(x, y + 1, radius - 1, is_add))
	
	return tiles

func clear_fog(x : int, y : int, radius : int, is_init : bool) -> void:
	if is_out_of_bounds(x, y):
		return
	
	if radius == -1:
		return
	elif radius == 0:
		tilemap_fog.set_cell(x, y, -1)
	else:
		tilemap_fog.set_cell(x, y, -1)
		
		if tileset.tile_get_name(tilemap.get_cell(x, y)).begins_with("tree"):
			radius = 1 if is_init else 0
		
		clear_fog(x - 1, y, radius - 1, false)
		clear_fog(x + 1, y, radius - 1, false)
		clear_fog(x, y - 1, radius - 1, false)
		clear_fog(x, y + 1, radius - 1, false)

func create_fog(x : int, y : int, a : int, b : int, radius : int) -> void:
	var tiles_to : Array = get_tiles_in_area(a, b, radius, true)
	
	if x != -1:
		var tiles_from : Array = get_tiles_in_area(x, y, radius, false)
	
		for tile in tiles_from:
			if not tile in tiles_to:
				if fog_map[tile.y][tile.x] == 0:
					tilemap_fog.set_cellv(tile, tileset_fog.find_tile_by_name("fog"))

func _unhandled_key_input(event : InputEventKey) -> void:
	if "dev" in Globals.BUILD and event.pressed:
		match event.scancode:
			KEY_F1:
				new_game()

func create_world(rnd_seed : int) -> void:
	game_seed = rnd_seed
	seed(game_seed)
	Globals.emit_signal("update_seed", game_seed)
	randomize()
	
	unit_map = UnitMap.new()
	unit_map.init()
	
	for y in Globals.world_size.y + 4:
		for x in Globals.world_size.x + 4:
			tilemap_fog.set_cell(x - 2, y - 2, tileset_fog.find_tile_by_name("fog"))
	
	for y in Globals.world_size.y:
		yield_map.append([])
		fog_map.append([])
		
		for x in Globals.world_size.x:
			var i : float = randf()
			var yield_inst : Yield = Yield.new()
			
			tilemap_territory.set_cell(x, y, -1)
			fog_map[y].append(0)
			
			if i < Globals.worldgen_parameters["CHANCE_GRASS"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("grass_%d" % (randi() % 3 + 1)))
				yield_inst.type = Globals.tile.GRASS
			elif i < Globals.worldgen_parameters["CHANCE_FLOWER"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("flower_%d" % (randi() % 3 + 1)))
				yield_inst.type = Globals.tile.FLOWER
			elif i < Globals.worldgen_parameters["CHANCE_TREE"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("tree"))
				yield_inst.type = Globals.tile.TREE
			elif i < Globals.worldgen_parameters["CHANCE_TREE_BEE"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("tree_bee"))
				yield_inst.type = Globals.tile.TREE_BEE
			elif i < Globals.worldgen_parameters["CHANCE_SAND"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("sand"))
				yield_inst.type = Globals.tile.SAND
			elif i < Globals.worldgen_parameters["CHANCE_PUDDLE"]:
				tilemap.set_cell(x, y, tileset.find_tile_by_name("puddle"))
				yield_inst.type = Globals.tile.PUDDLE
			
			yield_inst.yields = []
			
			for resource in range(Globals.resource.size()):
				yield_inst.yields.append(Globals.food_yields[yield_inst.type][resource])
			
			yield_map[y].append(yield_inst)

func on_end_turn() -> void:
	var total : float = 0.0
	
	for worker in players[active_player].node.get_children():
		if worker.unit_type == Globals.unit_type.ANT_WORKER:
			total += yield_map[worker.tile_pos.y][worker.tile_pos.x].yields[Globals.resource.FOOD]
	
	players[active_player].resources[Globals.resource.FOOD] += total
	players[active_player].added_resources[Globals.resource.FOOD] = total
	
	for y in range(Globals.world_size.y):
		for x in range(Globals.world_size.x):
			var tile_data : UnitMap.Tile = get_units_in_tile(Vector2(x, y))
			var total_units : int = tile_data.get_unit_count(active_player)
			
			tile_data.reset_movement()
			tile_data.stack_arrays()
			
			yield_map[y][x].yields[Globals.resource.FOOD] = clamp(
				yield_map[y][x].yields[Globals.resource.FOOD] - \
				pow(total_units, 1.6) * Globals.food_decay[yield_map[y][x].type][Globals.resource.FOOD],
				0.0,
				Globals.food_yields[yield_map[y][x].type][Globals.resource.FOOD]
			)
			
			if (active_player + 1) % player_count == 0:
				yield_map[y][x].yields[Globals.resource.FOOD] = clamp(
					yield_map[y][x].yields[Globals.resource.FOOD] + \
					Globals.food_growth[yield_map[y][x].type][Globals.resource.FOOD],
					0.0,
					Globals.food_yields[yield_map[y][x].type][Globals.resource.FOOD]
				)
	
	for player_unit in players[active_player].units:
		player_unit.reset_movement()
	
	active_player = (active_player + 1) % player_count
	Globals.emit_signal("update_turn", active_player, players[active_player].player_name, players[active_player])
	
	if players[active_player].is_bot:
		players[active_player].set_goal_queue(yield_map)

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
			unit_drag_loss = int(clamp(power_loss / Globals.power_values[unit_drag_instance.unit_type], 0, unit_drag_count))
			unit_drag_count -= unit_drag_loss
		
		if power_loss_enemy > 0:
			var unit_loss_enemy : Array = []
			var unit_loss_type_enemy : Array = []
			
			for index in range(units.unit_count.size()):
				var power_share : float = Globals.power_values[units.unit_instances[index].unit_type] * units.unit_count[index] / enemy_power
				
				unit_loss_enemy.append(int(player_power * power_share / Globals.power_values[units.unit_instances[index].unit_type]))
				unit_loss_type_enemy.append(units.unit_instances[index].unit_type)
			
			var range_offset : int = 0
			
			for index in range(unit_loss_enemy.size()):
				var player_id : int = units.unit_instances[index - range_offset].player
				var loss_count : int = unit_loss_enemy[index]
				var s : int = players[player_id].units.size()
				
				for player_index in range(players[player_id].units.size()):
					if loss_count == 0 or players[player_id].units.size() == 0:
						break
					elif players[player_id].units[s - player_index - 1].unit_type == unit_loss_type_enemy[index] and players[player_id].units[s - player_index - 1].tile_pos == pos:
						var unit_pop : Unit = players[player_id].units[s - player_index - 1] 
						players[player_id].units.remove(s - player_index - 1)
						unit_pop.despawn()
						
						if players[player_id].is_bot:
							players[player_id].despawn_unit(s - player_index - 1)
						
						loss_count -= 1
					
				var is_all_removed : bool = units.remove_unit_from_tile(units.unit_instances[index - range_offset], unit_loss_enemy[index])
				range_offset += 1 if is_all_removed else 0
		
		if unit_drag_count > 0:
			return true
		else:
			return false

func drop_unit(pos : Vector2, dist : int) -> void:
	if unit_drag_position.distance_to(pos) > unit_drag_instance.movement:
		for _count in range(unit_drag_instance.movement - 1):
			var dx : int = int(abs(pos.x - unit_drag_position.x))
			var dy : int = int(abs(pos.y - unit_drag_position.y))
			pos = unit_drag_position
			
			if dx > dy:
				pos.x = pos.x + (1 if unit_drag_position.x < pos.x else -1)
				dx -= 1
			else:
				pos.y = pos.y + (1 if unit_drag_position.y < pos.y else -1)
				dy -= 1
		
	unit_drop_position = pos
	
	if initiate_combat(unit_drop_position):
		tilemap_territory.set_cellv(unit_drop_position, tileset_territory.find_tile_by_name("%d" % active_player))
		
		if active_player == 0:
			clear_fog(int(unit_drop_position.x), int(unit_drop_position.y), unit_drag_instance.base_vision[unit_drag_instance.unit_type], true)
			create_fog(int(unit_drag_position.x), int(unit_drag_position.y), int(unit_drop_position.x), int(unit_drop_position.y), unit_drag_instance.base_vision[unit_drag_instance.unit_type])
		
		var new_unit : Unit = Unit.new()
		
		new_unit.player = unit_drag_instance.player
		new_unit.unit_type  = unit_drag_instance.unit_type
		new_unit.movement = unit_drag_instance.movement - dist
		new_unit.tile_pos = unit_drag_instance.tile_pos
		
		if unit_drag_instance.unit_type == Globals.unit_type.ANT_QUEEN:
			players[active_player].queen_position = unit_drop_position
		
		for unit_handler in unit_map.data[unit_drag_position.y][unit_drag_position.x].unit_handler:
			if unit_handler == unit_drag_handler:
				unit_map.data[unit_drag_position.y][unit_drag_position.x].remove_unit_from_tile(unit_drag_instance, unit_drag_count)
				unit_map.data[unit_drop_position.y][unit_drop_position.x].add_unit_to_tile(new_unit, unit_drag_count)
				
				var player : int = unit_drag_instance.player
				
				for index in range(players[player].units.size()):
					if unit_drag_count > 0:
						if players[player].units[index].unit_type == unit_drag_instance.unit_type and players[player].units[index].movement == unit_drag_instance.movement and players[player].units[index].tile_pos == unit_drag_position:
							players[player].units[index].reposition(unit_drop_position)
							players[player].units[index].movement -= dist
							
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
				players[player].units[index].reposition(unit_drop_position)
				units_to_remove.append(index)
				unit_drag_loss -= 1
		else:
			break
	
	yield(get_tree().create_timer(5.0), "timeout")
	
	for index in range(units_to_remove.size()):
		var s : int = units_to_remove.size()
		players[player].units.remove(units_to_remove[s - index - 1])
		
		player_unit[units_to_remove[s - index - 1]].despawn()
		
		if players[player].is_bot:
			players[player].despawn_unit(s - index - 1)
			
		players[player].node.remove_child(player_unit[units_to_remove[s - index - 1]])

func _on_CancelButton_pressed() -> void:
	is_unit_dragging = false

func on_spawn_units(player : int, spawns : Dictionary) -> void:
	for entry in spawns:
		var cost : Array = Globals.unit_cost[Globals.starting_units.keys()[entry]]
		players[active_player].resources[cost[0]] -= cost[1] * spawns[entry]
	
	Globals.emit_signal("update_hud", players[active_player])
	spawn_units(player, spawns, players[active_player].queen_position)

func spawn_units(player : int, spawns : Dictionary, tile : Vector2 = Vector2(-1, -1)) -> void:
	for entry in spawns:
		for _i in range(spawns[entry]):
			var instance = unit.instance()
			
			instance.player = player
			instance.unit_type = Globals.starting_units.keys()[entry]
			instance.tile_pos = tile
			instance.name = Globals.UNIT_NAMES[instance.unit_type]
			
			instance.position = tile * Globals.BLOCK_SIZE + Vector2(Globals.BLOCK_SIZE / 2.0, Globals.BLOCK_SIZE / 2.0)
			
			instance.init_unit()
			
			unit_map.data[tile.y][tile.x].add_unit_to_tile(instance)
			
			if player == 0:
				clear_fog(int(tile.x), int(tile.y), instance.base_vision[instance.unit_type], true)
				create_fog(-1, -1, int(tile.x), int(tile.y), instance.base_vision[instance.unit_type])
			
			players[player].queen_position = tile
			players[player].unit_count[Globals.starting_units.keys()[entry]] += 1
			players[player].node.add_child(instance)
			players[player].units.append(instance)

func on_bot_spawn_unit(unit_type : int, unit_count : int) -> void:
	on_spawn_units(active_player, {unit_type : unit_count})

func on_bot_move_unit(unit_instance : Unit, unit_handler : Array, unit_count : int, from : Vector2, to : Vector2) -> void:
	on_move_unit(unit_instance, unit_handler, unit_count, from)
	drop_unit(to, int(from.distance_to(to)))

func on_bot_end_turn() -> void:
	on_end_turn()
