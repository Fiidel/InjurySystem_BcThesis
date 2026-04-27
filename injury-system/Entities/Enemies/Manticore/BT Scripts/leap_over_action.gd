extends BTAction

@export var animation_tree: AnimationTree
@export var manticore_body: CharacterBody3D
@export var turn_speed: float = 3.0
@export var leap_horizontal_speed: float = 9.0
@export var leap_upward_velocity: float = 10.0
@export var jump_halt_animation_delay: float = 0.0
var can_look_towards_player: bool = true
@onready var rotation_controller: RotationController = RotationController.new()


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	# rotate towards player
	if !can_look_towards_player:
		return
	var player: Node3D = blackboard.read("player")
	if player == null:
		return
	var to_player: Vector3 = player.global_position - manticore_body.global_position
	to_player.y = 0.0
	var rotate := rotation_controller.can_rotate(delta)
	if rotate:
		var target_rotation: float = atan2(to_player.x, to_player.z)
		manticore_body.rotation.y = rotate_toward(manticore_body.rotation.y, target_rotation, turn_speed * delta)


func execute() -> void:
	if manticore_body == null or animation_tree == null:
		abort()
		finished.emit(ReturnStatus.FAILURE)
		return
	
	can_look_towards_player = true
	rotation_controller.reset()
	set_physics_process(true)
	
	animation_tree.set("parameters/AttackStateMachine/conditions/leap", true)
	animation_tree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	# wait until animation anticipation finishes before jumping
	if jump_halt_animation_delay > 0.0:
		await get_tree().create_timer(jump_halt_animation_delay).timeout
	
	# leap at player
	var player: Player = blackboard.read("player") as Player
	if player == null:
		abort()
		finished.emit(ReturnStatus.FAILURE)
		return
	var to_player: Vector3 = player.global_position - manticore_body.global_position
	to_player.y = 0.0
	to_player = to_player.normalized()
	manticore_body.velocity.x = to_player.x * leap_horizontal_speed
	manticore_body.velocity.z = to_player.z * leap_horizontal_speed
	manticore_body.velocity.y = leap_upward_velocity

	var has_left_floor: bool = false
	var has_landed: bool = false
	while animation_tree.get("parameters/AttackOneShot/active"):
		await get_tree().physics_frame
		# take-off
		if !has_left_floor and !manticore_body.is_on_floor():
			has_left_floor = true
			can_look_towards_player = false
		# landing
		elif has_left_floor and manticore_body.is_on_floor():
			has_landed = true
			break
	
	# wait for enemy to land (in case the animation has finished and the enemy hasn't landed yet)
	while !has_landed and !manticore_body.is_on_floor():
		await get_tree().physics_frame

	# damage player if in range when landing
	var melee_attack_range: float = blackboard.read("melee_attack_range")
	if melee_attack_range != null:
		if player.global_position.distance_to(manticore_body.global_position) <= melee_attack_range * 1.5:
			player.take_damage(1)
	
	# exit
	animation_tree.set("parameters/AttackStateMachine/conditions/leap", false)
	can_look_towards_player = true
	manticore_body.velocity.x = 0.0
	manticore_body.velocity.z = 0.0
	set_physics_process(false)
	finished.emit(ReturnStatus.SUCCESS)


func abort() -> void:
	if animation_tree != null:
		animation_tree.set("parameters/AttackStateMachine/conditions/leap", false)
	can_look_towards_player = true
	if manticore_body != null:
		manticore_body.velocity.x = 0.0
		manticore_body.velocity.z = 0.0
	set_physics_process(false)
