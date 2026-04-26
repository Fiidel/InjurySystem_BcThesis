extends BTAction

@export var animation_tree: AnimationTree
@export var manticore_body: CharacterBody3D
@export var turn_speed: float = 3.0
@export var jump_animation_delay: float = 0.0
@export var halt_movement_animation_delay: float = 0.0
@export var leap_velocity: float = 8.0
@export var leap_upward_velocity: float = 2.0

var halt_movement_timer: Timer
var animation_movement_halted: bool = false


func _ready() -> void:
	set_physics_process(false)
	halt_movement_timer = Timer.new()
	halt_movement_timer.one_shot = true
	halt_movement_timer.timeout.connect(_on_halt_movement_timeout)
	get_tree().root.add_child.call_deferred(halt_movement_timer)


func _physics_process(delta: float) -> void:
	# rotate towards player
	var player: Node3D = blackboard.read("player")
	if player == null:
		abort()
		finished.emit(ReturnStatus.FAILURE)
		return
	var to_player: Vector3 = player.global_position - manticore_body.global_position
	to_player.y = 0.0
	var target_rotation: float = atan2(to_player.x, to_player.z)
	manticore_body.rotation.y = rotate_toward(manticore_body.rotation.y, target_rotation, turn_speed * delta)


func execute() -> void:
	var player: Player = blackboard.read("player") as Player
	if animation_tree == null or manticore_body == null or player == null:
		abort()
		finished.emit(ReturnStatus.FAILURE)
		return
	
	set_physics_process(true)
	
	# start leap animation and the movement halt timer
	set_leap_animation(true)
	animation_movement_halted = false
	if halt_movement_animation_delay > 0.0:
		halt_movement_timer.start(halt_movement_animation_delay)
	
	# wait until animation anticipation finishes before jumping
	if jump_animation_delay > 0.0:
		await get_tree().create_timer(jump_animation_delay).timeout
	
	# leap at player
	player = blackboard.read("player") as Player
	if player == null:
		abort()
		finished.emit(ReturnStatus.FAILURE)
		return
	var to_player: Vector3 = player.global_position - manticore_body.global_position
	to_player.y = 0.0
	to_player = to_player.normalized()
	
	manticore_body.velocity.x = to_player.x * leap_velocity
	manticore_body.velocity.z = to_player.z * leap_velocity
	manticore_body.velocity.y = leap_upward_velocity
	
	var has_left_floor: bool = false
	var has_processed_landing: bool = false
	while animation_tree.get("parameters/AttackOneShot/active"):
		await get_tree().physics_frame
		if animation_movement_halted:
			manticore_body.velocity.x = 0.0
			manticore_body.velocity.z = 0.0

		# register take-off
		if !has_left_floor and !manticore_body.is_on_floor():
			has_left_floor = true
		# handle landing
		elif !has_processed_landing and has_left_floor and manticore_body.is_on_floor():
			has_processed_landing = true
			player = blackboard.read("player") as Player
			var melee_attack_range = blackboard.read("melee_attack_range")
			if player != null and melee_attack_range != null:
				if player.global_position.distance_to(manticore_body.global_position) <= melee_attack_range * 1.5:
					player.take_damage(1)
	
	# wait for animation to finish
	while animation_tree.get("parameters/AttackOneShot/active"):
		await get_tree().process_frame
	
	animation_movement_halted = false
	if halt_movement_timer != null:
		halt_movement_timer.stop()
	set_leap_animation(false)
	manticore_body.velocity = Vector3.ZERO
	set_physics_process(false)
	finished.emit(ReturnStatus.SUCCESS)


func abort() -> void:
	animation_movement_halted = false
	if halt_movement_timer != null:
		halt_movement_timer.stop()
	set_physics_process(false)
	set_leap_animation(false)
	if manticore_body != null:
		manticore_body.velocity = Vector3.ZERO


func set_leap_animation(active: bool) -> void:
	if animation_tree == null:
		return
	animation_tree.set("parameters/AttackStateMachine/conditions/leap", active)
	if active:
		animation_tree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_halt_movement_timeout() -> void:
	animation_movement_halted = true
