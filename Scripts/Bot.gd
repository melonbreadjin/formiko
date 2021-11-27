extends Player
class_name Bot

var yield_map : Array

var goal_queue : Array = []
var current_goal : int
var current_action : int

var explored_tiles : Array = []
var vision : Array = []
var scout_indeces : Array = []
var desire_scout_count : int = 0

var if_player_detected : bool = false

var _sgn

enum action{
	START,
	SPAWN,
	MOVE,
	END
}

enum goal{
	EXPLORE,
	EXPAND,
	EXPLOIT,
	EXTERMINATE,
	END
}

enum explore_target{
	LATERAL_NEGATIVE,
	LATERAL_POSITIVE,
	CENTRAL
}

func despawn_unit(index : int) -> void:
	index = scout_indeces.find(index)
	
	if index != -1:
		scout_indeces.remove(index)

func add_to_vision(pos : Vector2, radius : int) -> void:
	if radius == -1:
		return
	elif radius == 0:
		if pos.x >= 0 and pos.x < Globals.world_size.x and pos.y >= 0 and pos.y < Globals.world_size.y:
			if not pos in vision:
				vision.append(pos)
			if not pos in explored_tiles:
				explored_tiles.append(pos)
	else:
		if pos.x >= 0 and pos.x < Globals.world_size.x and pos.y >= 0 and pos.y < Globals.world_size.y:
			if not pos in vision:
				vision.append(pos)
			if not pos in explored_tiles:
				explored_tiles.append(pos)
		
		add_to_vision(Vector2(pos.x - 1, pos.y), radius - 1)
		add_to_vision(Vector2(pos.x + 1, pos.y), radius - 1)
		add_to_vision(Vector2(pos.x, pos.y - 1), radius - 1)
		add_to_vision(Vector2(pos.x, pos.y + 1), radius - 1)

func update_vision() -> void:
	vision.clear()
	
	for unit in units:
		add_to_vision(unit.tile_pos, unit.base_vision[unit.unit_type])

func set_goal_queue(yields : Array) -> void:
	yield_map = yields
	goal_queue = [goal.EXPAND, goal.EXPLOIT]
	
	if if_player_detected:
		goal_queue.append(goal.EXTERMINATE)
	else:
		goal_queue.append(goal.EXPLORE)
	
	goal_queue.append(goal.END)
	
	update_goal()

func update_goal() -> void:
	for goal in goal_queue:
		current_goal = goal
		
		get_action()
	
	Globals.emit_signal("bot_end_turn")
	current_goal = action.END

func update_desire_scout_count() -> void:
	desire_scout_count = int(Globals.world_size.x * Globals.world_size.y / explored_tiles.size())

func get_action() -> void:
	current_action = action.START
	
	if current_goal == goal.EXPLORE:
		while current_action != action.END:
			if current_action == action.START:
				update_vision()
				
				update_desire_scout_count()
				
				for index in range(units.size()):
					if units[index].unit_type == Globals.unit_type.ANT_SOLDIER and not index in scout_indeces:
						scout_indeces.append(index)
				
				current_action = action.SPAWN
			elif current_action == action.SPAWN:
				if desire_scout_count < scout_indeces.size():
					current_action = action.MOVE
					continue
				
				update_desire_scout_count()
				
				if resources[Globals.resource.FOOD] >= Globals.unit_cost[Globals.unit_type.ANT_SOLDIER][1]:
					Globals.emit_signal("bot_spawn_unit", Globals.unit_type.ANT_SOLDIER, 1)
				
				current_action = action.MOVE
			elif current_action == action.MOVE:
				if scout_indeces.size() == 0:
					current_action = action.END
					continue
				
				update_vision()
				
				for scout in scout_indeces:
					var explore_target_found : bool = false
					var scout_ring : Array
					var scout_ring_size : int = 1
					var scout_target : Vector2 = Vector2(-1, -1)
					
					vision.shuffle()
					
					while not explore_target_found or scout_ring_size < max(Globals.world_size.x, Globals.world_size.y) / 2:
						if explored_tiles.size() >= Globals.world_size.x * Globals.world_size.y:
							current_action = action.END
							scout_target = queen_position
							break
						
						scout_ring = get_ring(units[scout].tile_pos, scout_ring_size)
						
						for tile in scout_ring:
							if not tile in explored_tiles:
								explore_target_found = true
								scout_target = tile
								break
						
						scout_ring_size += 1
					
					if scout_target != Vector2(-1, -1):
						var min_dist : float = Globals.world_size.x * Globals.world_size.y
						var target_tile : Vector2 = Vector2(-1, -1)
						
						for tile in vision:
							var dist : float = scout_target.distance_to(tile)
							
							if dist <= min_dist:
								min_dist = dist
								target_tile = tile
						
						Globals.emit_signal("bot_move_unit", units[scout], [units[scout].unit_type, units[scout].movement], 1, units[scout].tile_pos, target_tile)
					
				current_action = action.END
	elif current_goal == goal.EXPAND:
		if current_action == action.START:
			var areas : Array = []
			var param : Array = []
			
			for unit in units:
				if unit.unit_type == Globals.unit_type.ANT_WORKER:
					var index : int = param.find([unit.tile_pos, unit.base_vision[unit.unit_type]])
					var max_yield : float = yield_map[unit.tile_pos.y][unit.tile_pos.x].yields[Globals.resource.FOOD]
					var target_tile : Vector2 = Vector2(-1, -1)
					var area : Array
					
					if index == -1:
						area = get_area(unit.tile_pos, unit.base_vision[unit.unit_type])
						
						param.append([unit.tile_pos, unit.base_vision[unit.unit_type]])
						areas.append(area)
					else:
						area = areas[index]
					
					area.shuffle()
					
					for tile in area:
						var tile_yield : float = yield_map[tile.y][tile.x].yields[Globals.resource.FOOD]
						
						if tile_yield > max_yield:
							max_yield = tile_yield
							target_tile = tile
					
					if target_tile != Vector2(-1, -1):
						Globals.emit_signal("bot_move_unit", unit, [unit.unit_type, unit.movement], 1, unit.tile_pos, target_tile)
			
			current_action = action.SPAWN
		elif current_action == action.SPAWN:
			for unit in units:
				if unit.unit_type == Globals.unit_type.ANT_QUEEN:
					var ring = get_ring(unit.tile_pos, unit.base_vision[unit.unit_type])
					var max_yield : float = yield_map[unit.tile_pos.y][unit.tile_pos.x].yields[Globals.resource.FOOD]
					var target_tile : Vector2 = Vector2(-1, -1)
					
					for tile in ring:
						var tile_yield : float = yield_map[tile.y][tile.x].yields[Globals.resource.FOOD]
						
						if tile_yield > max_yield:
							max_yield = tile_yield
							target_tile = tile
						
					if target_tile != Vector2(-1, -1):
						Globals.emit_signal("bot_move_unit", unit, [unit.unit_type, unit.movement], 1, unit.tile_pos, target_tile)
					

func get_area(pos : Vector2, size : int) -> Array:
	var area : Array = []
	
	for i in range(size):
		area.append_array(get_ring(pos, i + 1))
	
	return area

func get_ring(pos : Vector2, size : int) -> Array:
	var ring : Array = []
	
	for x in range(-size, size + 1):
		var nx = pos.x + x
		var ny_1 = pos.y + size - abs(x)
		var ny_2 = pos.y - size - abs(x)
		
		if nx >= 0 and nx < Globals.world_size.x:
			if ny_1 >= 0 and ny_1 < Globals.world_size.y:
				ring.append(Vector2(nx, ny_1))
			if ny_1 != ny_2 and ny_2 >= 0 and ny_2 < Globals.world_size.y:
				ring.append(Vector2(nx, ny_2))
	
	return ring
