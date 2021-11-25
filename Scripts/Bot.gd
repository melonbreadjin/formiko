extends Player
class_name Bot

var goal_queue : Array = []
var current_goal : int
var current_action : int

var if_player_detected : bool = false

enum action{
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

func get_action() -> void:
	while current_action != action.END:
		if current_goal == goal.EXPLORE:
			current_action = (current_action + 1) % action.size()
