extends Player
class_name Bot

var goal_queue : Array = []
var current_goal : int
var current_action : int

var explored_tiles : Array = []
var vision : Array = []
var scout_indeces : Array = []
var desire_scout_count : int = 0

var if_player_detected : bool = false

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

func add_to_vision(pos : Vector2, radius : int) -> void:
	if radius == -1:
		return
	elif radius == 0:
		if not pos in vision:
			vision.append(pos)
		if not pos in explored_tiles:
			explored_tiles.append(pos)
	else:
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

func set_goal_queue() -> void:
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
	
	print("%s: ending turn" % player_name)
	Globals.emit_signal("bot_end_turn")
	current_goal = action.END

func update_desire_scout_count() -> void:
	desire_scout_count = int(Globals.world_size.x * Globals.world_size.y / units[0].base_movement[Globals.unit_type.ANT_WORKER] / vision.size())
	print("%s: set desire scout count to %d" % [player_name, desire_scout_count])

func get_action() -> void:
	current_action = action.START
	
	if current_goal == goal.EXPLORE:
		while current_action != action.END:
			if current_action == action.START:
				print("%s: exploring..." % player_name)
				print("%s: updating vision..." % player_name)
				
				update_vision()
				
				if scout_indeces.size() == 0:
					update_desire_scout_count()
				
				for index in range(units.size()):
					if units[index].unit_type == Globals.unit_type.ANT_SOLDIER and not index in scout_indeces:
						scout_indeces.append(index)
						
						print("%s: added scout unit %d..." % [player_name, index])
				
				current_action = action.SPAWN
			elif current_action == action.SPAWN:
				if desire_scout_count >= scout_indeces.size():
					current_action = action.MOVE
					continue
				
				update_desire_scout_count()
				
				if resources[Globals.resource.FOOD] >= Globals.unit_cost[Globals.unit_type.ANT_SOLDIER][1]:
					Globals.emit_signal("bot_spawn_unit", Globals.unit_type.ANT_SOLDIER, 1)
				
				current_action = action.MOVE
			elif current_action == action.MOVE:
				update_vision()
				
				for scout in scout_indeces:
					var explore_target_found : bool = false
					var scout_ring : Array
					var scout_ring_size : int = 1
					var scout_target : Vector2 = Vector2(-1, -1)
					
					while not explore_target_found:
						scout_ring = get_ring(units[scout].tile_pos, scout_ring_size)
						
						for tile in scout_ring:
							if not tile in explored_tiles:
								explore_target_found = true
								scout_target = tile
								break
						
						scout_ring_size += 1
					
					if scout_target != Vector2(-1, -1):
						print("%s: scout unit %d target: %s at ring %d..." % [player_name, scout, scout_target, scout_ring_size - 1])
						print("%s: current vision: %s" % [player_name, vision])
						
						var min_dist : float = Globals.world_size.x * Globals.world_size.y
						var target_tile : Vector2 = Vector2(-1, -1)
						
						for tile in vision:
							var dist : float = scout_target.distance_to(tile)
							min_dist = min(dist, min_dist)
							
							if dist == min_dist:
								target_tile = tile
						
						Globals.emit_signal("bot_move_unit", units[scout], [units[scout].unit_type, units[scout].movement], 1, units[scout].tile_pos, scout_target)
						print("%s: scout unit %d moving to: %s" % [player_name, scout, target_tile])
					
				current_action = action.END

func get_ring(pos : Vector2, size : int) -> Array:
	var ring : Array = []
	
	for x in range(-size, size + 1):
		if pos.x + x < Globals.world_size.x and pos.y + size - abs(x) < Globals.world_size.y:
			ring.append(Vector2(pos.x + x, pos.y + size - abs(x)))
			if size - abs(x) != 0 and pos.y - size - abs(x) >= 0:
				ring.append(Vector2(pos.x + x, pos.y - size - abs(x)))
	return ring
