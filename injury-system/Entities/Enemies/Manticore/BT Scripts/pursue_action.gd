extends BTAction

@export var turn_speed: float = 0
@export var animation_tree: AnimationTree
@export var manticore_body: CharacterBody3D
@export var stop_pursuit_range_override: float = -1.0


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	# when the player leaves detection range, abort and return
	var is_player_visible: bool = blackboard.read("is_player_detected")
	if is_player_visible != null and !is_player_visible:
		exit_with_failure()
		return
	
	# pursue the player
	var player: Node3D = blackboard.read("player")
	if player == null:
		exit_with_failure()
		return

	var move_speed: float = blackboard.read("run_speed")
	if move_speed == null:
		exit_with_failure()
		return
	var to_player: Vector3 = player.global_position - manticore_body.global_position
	to_player.y = 0.0
	
	var melee_attack_range: float = blackboard.read("melee_attack_range")
	if melee_attack_range == null:
		exit_with_failure()
		return

	var stop_pursuit_range: float = stop_pursuit_range_override if stop_pursuit_range_override > 0.0 else melee_attack_range
	
	if to_player.length() <= stop_pursuit_range:
		manticore_body.velocity.x = 0.0
		manticore_body.velocity.z = 0.0
		exit_with_success()
		return
	else:
		var target_rotation: float = atan2(to_player.x, to_player.z)
		manticore_body.rotation.y = rotate_toward(manticore_body.rotation.y, target_rotation, turn_speed * delta)
		var move_direction := to_player.normalized()
		manticore_body.velocity.x = move_direction.x * move_speed
		manticore_body.velocity.z = move_direction.z * move_speed


func execute() -> void:
	tween_run_blend(true)
	set_physics_process(true)


func abort() -> void:
	tween_run_blend(false)
	manticore_body.velocity.x = 0.0
	manticore_body.velocity.z = 0.0
	set_physics_process(false)


func exit_with_success() -> void:
	finished.emit(ReturnStatus.SUCCESS)
	abort()


func exit_with_failure() -> void:
	finished.emit(ReturnStatus.FAILURE)
	abort()


func tween_run_blend(enable: bool) -> void:
	var target = 1.0 if enable else 0.0
	var tween = create_tween()
	tween.tween_property(animation_tree, "parameters/RunBlend/blend_amount", target, 1.0)
