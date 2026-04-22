extends BTAction

@export var attack_anim_delay: float = 0.0
@export var animation_tree: AnimationTree
@export var manticore_body: CharacterBody3D
var turn_speed: float = 3.0


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	var player: Node3D = blackboard.read("player")
	if player == null:
		finished.emit(ReturnStatus.FAILURE)
		abort()
		return
	
	var to_player: Vector3 = player.global_position - manticore_body.global_position
	to_player.y = 0.0
	var target_rotation: float = atan2(to_player.x, to_player.z)
	manticore_body.rotation.y = rotate_toward(manticore_body.rotation.y, target_rotation, turn_speed * delta)


func execute() -> void:
	set_physics_process(true)
	
	# start attack animation
	animation_tree.set("parameters/AttackStateMachine/conditions/bite", true)
	animation_tree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	# call the attack func
	attack_player()
	
	# wait until attack is actually active
	while !animation_tree.get("parameters/AttackOneShot/active"):
		await get_tree().process_frame
	# wait until attack finishes
	while animation_tree.get("parameters/AttackOneShot/active"):
		await get_tree().process_frame
	# reset the attack state machine's bite bool
	animation_tree.set("parameters/AttackStateMachine/conditions/bite", false)
	
	# exit with success
	set_physics_process(false)
	finished.emit(ReturnStatus.SUCCESS)


func abort() -> void:
	set_physics_process(false)


func attack_player() -> void:
	await get_tree().create_timer(attack_anim_delay).timeout
	var player = blackboard.read("player") as Player
	if player != null:
		var melee_attack_range: float = blackboard.read("melee_attack_range")
		if melee_attack_range == null:
			finished.emit(ReturnStatus.FAILURE)
			return
		var melee_range_with_grace: float = melee_attack_range * 1.5
		if player.global_position.distance_to(manticore_body.global_position) <= melee_range_with_grace:
			player.take_damage(1)
