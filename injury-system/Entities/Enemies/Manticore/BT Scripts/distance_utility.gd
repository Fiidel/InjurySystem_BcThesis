extends BTUtility

@export var min_distance: float = 0.0
@export var max_distance: float = 35.0
@export var close_range_utility: float = 0.2
@export var far_range_utility: float = 2.0
@export var manticore_body: CharacterBody3D


func get_utility() -> float:
	var player: Node3D = blackboard.read("player")
	if player == null or manticore_body == null:
		return 0.0

	var distance_to_player: float = manticore_body.global_position.distance_to(player.global_position)
	var how_close_to_player_normalized: float = clamp(inverse_lerp(min_distance, max_distance, distance_to_player), 0.0, 1.0)
	utility = lerp(close_range_utility, far_range_utility, how_close_to_player_normalized)
	return utility
