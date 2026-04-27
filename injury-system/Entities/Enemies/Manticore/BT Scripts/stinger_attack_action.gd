extends BTAction

@export var tail_spikes: TailSpikes
@export var animation_tree: AnimationTree
@export var manticore_body: CharacterBody3D
@export var release_spikes_animation_delay: float = 0.0
@export var spikes_regenerate_time: float = 1.0

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
	if tail_spikes == null:
		push_error("Tail spikes node not assigned!")
		finished.emit(ReturnStatus.FAILURE)
		return
	if manticore_body == null:
		push_error("Manticore body not assigned!")
		finished.emit(ReturnStatus.FAILURE)
		return
	var player: Node3D = blackboard.read("player")
	if player == null:
		finished.emit(ReturnStatus.FAILURE)
		return
	
	rotation_controller.reset()
	set_physics_process(true)
	animation_tree.set("parameters/AttackStateMachine/conditions/stinger", true)
	animation_tree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	release_spikes(player)
	
	while !animation_tree.get("parameters/AttackOneShot/active"):
		await get_tree().process_frame
	while animation_tree.get("parameters/AttackOneShot/active"):
		await get_tree().process_frame
	animation_tree.set("parameters/AttackStateMachine/conditions/stinger", false)
	set_physics_process(false)
	finished.emit(ReturnStatus.SUCCESS)


func release_spikes(player: Node3D) -> void:
	# wait for the right moment in the animation
	await get_tree().create_timer(release_spikes_animation_delay).timeout
	
	# spawn the spikes projectile and launch it
	var spikes_projectile: TailSpikes = tail_spikes.duplicate() as TailSpikes
	get_tree().current_scene.add_child(spikes_projectile)
	spikes_projectile.global_position = tail_spikes.global_position
	spikes_projectile.make_material_unique()
	tail_spikes.make_invisible() # hide the original tail spikes
	# shoot it at the player
	var to_player: Vector3 = (player.global_position + Vector3.UP * 0.5) - spikes_projectile.global_position
	spikes_projectile.launch(to_player)

	# spike regeneration
	await get_tree().create_timer(spikes_regenerate_time).timeout
	tail_spikes.fade_in_material(0.5)


func abort() -> void:
	set_physics_process(false)
