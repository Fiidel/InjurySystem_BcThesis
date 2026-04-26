extends BTAction

@export var manticore_body: CharacterBody3D
@export var animation_tree: AnimationTree
@export var ascend_height: float = 7.0
@export var ascend_speed: float = 5.0
@export var dive_speed: float = 15.0
@export var turn_speed: float = 3.0


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	# rotate towards player
	var player = blackboard.read("player")
	if player == null:
		abort()
		finished.emit(ReturnStatus.FAILURE)
		return
	var to_player: Vector3 = player.global_position - manticore_body.global_position
	to_player.y = 0.0
	var target_rotation: float = atan2(to_player.x, to_player.z)
	manticore_body.rotation.y = rotate_toward(manticore_body.rotation.y, target_rotation, turn_speed * delta)


func execute() -> void:
	var player: Node3D = blackboard.read("player")
	var melee_attack_range: float = blackboard.read("melee_attack_range")
	if manticore_body == null or player == null or melee_attack_range == null:
		push_error("Error: Fly and dive has no access to CharacterBody3D (export), player (blackboard) or melee_attack_range (blackboard).")
		abort()
		finished.emit(ReturnStatus.FAILURE)
		return
	
	set_physics_process(true)
	
	# 1) fly up
	var target_height: float = manticore_body.global_position.y + ascend_height
	enable_fly_animation()
	while manticore_body.global_position.y < target_height:
		await get_tree().physics_frame
		manticore_body.velocity = Vector3.UP * ascend_speed
	
	# 2) dive at the player
	enable_dive_animation()
	while !manticore_body.is_on_floor():
		await get_tree().physics_frame
		player = blackboard.read("player")
		if player == null:
			abort()
			finished.emit(ReturnStatus.FAILURE)
			return

		var to_player: Vector3 = player.global_position - manticore_body.global_position
		if to_player.length() <= melee_attack_range:
			break

		var dive_direction: Vector3 = to_player.normalized()
		manticore_body.velocity = dive_direction * dive_speed

	# 3) damage the player on landing if in range
	if player != null and manticore_body.global_position.distance_to(player.global_position) <= melee_attack_range:
		player.take_damage(1)

	# 4) clean up and exit
	disable_fly_and_dive_animation()
	manticore_body.velocity = Vector3.ZERO
	set_physics_process(false)
	finished.emit(ReturnStatus.SUCCESS)


func abort() -> void:
	if manticore_body != null:
		manticore_body.velocity = Vector3.ZERO
	disable_fly_and_dive_animation()
	set_physics_process(false)


func enable_fly_animation() -> void:
	if animation_tree == null:
		return
	tween_blend("parameters/FlyBlend/blend_amount", true)
	tween_blend("parameters/DiveBlend/blend_amount", false)


func enable_dive_animation() -> void:
	if animation_tree == null:
		return
	tween_blend("parameters/FlyBlend/blend_amount", false)
	tween_blend("parameters/DiveBlend/blend_amount", true)


func disable_fly_and_dive_animation() -> void:
	if animation_tree == null:
		return
	tween_blend("parameters/FlyBlend/blend_amount", false)
	tween_blend("parameters/DiveBlend/blend_amount", false)


func tween_blend(property_path: String, enable: bool) -> void:
	var target := 1.0 if enable else 0.0
	var tween := create_tween()
	tween.tween_property(animation_tree, property_path, target, 1.0)
