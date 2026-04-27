extends BTAction

enum RakeAttackType {
	RAKE_L,
	RAKE_R,
	RAKE_L_R
}

@export var rake_attack_type: RakeAttackType
@export var attack_anim_delay: float = 0.0
@export var animation_tree: AnimationTree
@export var manticore_body: CharacterBody3D

@onready var rotation_controller: RotationController = RotationController.new()
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
	var rotate := rotation_controller.can_rotate(delta)
	if rotate:
		var target_rotation: float = atan2(to_player.x, to_player.z)
		manticore_body.rotation.y = rotate_toward(manticore_body.rotation.y, target_rotation, turn_speed * delta)


func execute() -> void:
	rotation_controller.reset()
	set_physics_process(true)
	
	var rake_condition: String = _get_rake_condition_name()
	animation_tree.set("parameters/AttackStateMachine/conditions/" + rake_condition, true)
	animation_tree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	attack_player()
	
	while !animation_tree.get("parameters/AttackOneShot/active"):
		await get_tree().process_frame
	while animation_tree.get("parameters/AttackOneShot/active"):
		await get_tree().process_frame
	
	animation_tree.set("parameters/AttackStateMachine/conditions/" + rake_condition, false)
	
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


func _get_rake_condition_name() -> String:
	match rake_attack_type:
		RakeAttackType.RAKE_L:
			return "rakeL"
		RakeAttackType.RAKE_R:
			return "rakeR"
		RakeAttackType.RAKE_L_R:
			return "rakeLR"
	push_error("Invalid rake attack type: %s" % rake_attack_type)
	return ""
