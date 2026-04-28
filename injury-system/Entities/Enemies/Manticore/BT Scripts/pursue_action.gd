extends BTAction

enum PursueType {
	RUN,
	LIMP,
	CRAWL,
	HIND_LEGS,
	FLY
}

const PURSUE_BLEND_PATH := "parameters/PursueBlend/blend_amount"
const LIMP_BLEND_PATH := "parameters/PursueBlendTree/LimpBlend/blend_amount"
const CRAWL_BLEND_PATH := "parameters/PursueBlendTree/CrawlBlend/blend_amount"
const HIND_LEGS_BLEND_PATH := "parameters/PursueBlendTree/HindLegsBlend/blend_amount"
const FLY_BLEND_PATH := "parameters/PursueBlendTree/FlyBlend/blend_amount"

@export var manticore_body: CharacterBody3D
@export var animation_tree: AnimationTree
@export var turn_speed: float = 3.0
@export var stop_pursuit_range_override: float = -1.0
@export var pursue_type: PursueType = PursueType.RUN
@export var animation_blend_duration: float = 0.2

@export_group("Speed Modifiers")
@export var run_speed_modifier: float = 1.0
@export var fly_speed_modifier: float = 0.9
@export var limp_speed_modifier: float = 0.75
@export var crawl_speed_modifier: float = 0.5
@export var hind_legs_speed_modifier: float = 0.5

@export_group("Fly Hover")
@export var fly_hover_height: float = 1.0
@export var fly_speed: float = 6.0

@onready var rotation_controller: RotationController = RotationController.new()


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
	var base_speed: float = blackboard.read("run_speed")
	if player == null or base_speed == null:
		exit_with_failure()
		return

	var move_speed := base_speed * get_speed_modifier_for_condition(pursue_type)
	blackboard.store("move_speed", move_speed)

	var to_player: Vector3 = player.global_position - manticore_body.global_position
	to_player.y = 0.0
	
	var melee_attack_range: float = blackboard.read("melee_attack_range")
	if melee_attack_range == null:
		exit_with_failure()
		return

	var stop_pursuit_range: float = stop_pursuit_range_override if stop_pursuit_range_override > 0.0 else melee_attack_range
	
	# player is in range
	if to_player.length() <= stop_pursuit_range:
		manticore_body.velocity.x = 0.0
		manticore_body.velocity.z = 0.0
		exit_with_success()
		return
	# pursue the player
	else:
		# enemy rotation
		var rotate := rotation_controller.can_rotate(delta)
		if rotate:
			var target_rotation: float = atan2(to_player.x, to_player.z)
			manticore_body.rotation.y = rotate_toward(manticore_body.rotation.y, target_rotation, turn_speed * delta)
		# enemy movement
		var move_direction := to_player.normalized()
		manticore_body.velocity.x = move_direction.x * move_speed
		manticore_body.velocity.z = move_direction.z * move_speed
		if pursue_type == PursueType.FLY:
			apply_fly_hover(delta)


func execute() -> void:
	rotation_controller.reset()
	# set the movement blends and start the pursuit animation
	set_movement_blends()
	tween_pursue_blend(true)
	# start the physics process
	set_physics_process(true)


func abort() -> void:
	tween_pursue_blend(false)
	manticore_body.velocity.x = 0.0
	manticore_body.velocity.z = 0.0
	set_physics_process(false)


func exit_with_success() -> void:
	finished.emit(ReturnStatus.SUCCESS)
	abort()


func exit_with_failure() -> void:
	finished.emit(ReturnStatus.FAILURE)
	abort()


func tween_pursue_blend(enable: bool) -> void:
	var target = 1.0 if enable else 0.0
	var tween = create_tween()
	tween.tween_property(animation_tree, PURSUE_BLEND_PATH, target, 1.0)


func set_movement_blends() -> void:
	var limb_blend := 0.0
	var crawl_blend := 0.0
	var hind_blend := 0.0
	var fly_blend := 0.0
	match pursue_type:
		PursueType.LIMP:
			limb_blend = 1.0
		PursueType.CRAWL:
			crawl_blend = 1.0
		PursueType.HIND_LEGS:
			hind_blend = 1.0
		PursueType.FLY:
			fly_blend = 1.0
		_:
			pass
	var tween := create_tween()
	tween.parallel().tween_property(animation_tree, LIMP_BLEND_PATH, limb_blend, animation_blend_duration)
	tween.parallel().tween_property(animation_tree, CRAWL_BLEND_PATH, crawl_blend, animation_blend_duration)
	tween.parallel().tween_property(animation_tree, HIND_LEGS_BLEND_PATH, hind_blend, animation_blend_duration)
	tween.parallel().tween_property(animation_tree, FLY_BLEND_PATH, fly_blend, animation_blend_duration)


func get_speed_modifier_for_condition(condition: PursueType) -> float:
	match condition:
		PursueType.RUN:
			return run_speed_modifier
		PursueType.LIMP:
			return limp_speed_modifier
		PursueType.CRAWL:
			return crawl_speed_modifier
		PursueType.HIND_LEGS:
			return hind_legs_speed_modifier
		PursueType.FLY:
			return fly_speed_modifier
		_:
			return 1.0


func apply_fly_hover(delta: float) -> void:
	var ground_y = get_ground_y_below()
	if ground_y == null:
		return
	var target_y: float = ground_y + fly_hover_height
	manticore_body.global_position.y = move_toward(manticore_body.global_position.y, target_y, fly_speed * delta)
	manticore_body.velocity.y = 0.0


func get_ground_y_below() -> Variant:
	var raycast_height := 2.0
	var raycast_depth := 10.0
	var from_pos := manticore_body.global_position + Vector3.UP * raycast_height
	var to_pos := manticore_body.global_position + Vector3.DOWN * raycast_depth
	var ray_params := PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	ray_params.exclude = [manticore_body]
	ray_params.collision_mask = 1 << 2 # Environment is the 3rd layer (in Godot notation)
	var hit := manticore_body.get_world_3d().direct_space_state.intersect_ray(ray_params)
	if hit.is_empty():
		return null
	return (hit["position"] as Vector3).y
