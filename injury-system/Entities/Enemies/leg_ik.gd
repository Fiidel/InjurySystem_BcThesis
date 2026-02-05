class_name LegIK
extends SkeletonIK3D

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var default_position: Marker3D = $DefaultPosition
@export var max_step_distance: float = 1
@export var step_duration: float = 0.5
@export var step_height: float = 0.2 # midpoint height during step
@export var limb_group: int = 0
var anchor_point: Marker3D
var current_collision_point: Vector3
var is_stepping: bool = false
var is_initialized: bool = false
var limb_mutex: LimbMutex

func _ready():
	# create marker instances and add them to scene
	anchor_point = Marker3D.new()
	get_tree().root.call_deferred("add_child", anchor_point)

	# setup the position markers and ik	
	call_deferred("setup_markers")
	call_deferred("setup_ik")

func setup_markers():
	anchor_point.global_position = default_position.global_position
	anchor_point.global_rotation = default_position.global_rotation
	
	# make attach point the target of ik and start ik
	target_node = anchor_point.get_path()
	start()
	
	# make the first step for group 0 - alternating legs
	if limb_group == 0:
		anchor_point.global_position = ray_cast_3d.get_collision_point()

	is_initialized = true

func setup_ik():
	# get the limb mutex from the parent
	var parent = get_parent()
	if parent is IKController:
		limb_mutex = parent.limb_mutex
	else:
		push_error("Parent is not a IKController")
		return

func _physics_process(_delta: float) -> void:
	if not is_initialized:
		return
	
	if ray_cast_3d.is_colliding():
		# get the current collision point
		current_collision_point = ray_cast_3d.get_collision_point()
		# if the mutex is unlocked and the distance is great enough for a step, trigger the step
		if limb_mutex.is_unlocked_for_group(limb_group) and current_collision_point.distance_to(anchor_point.global_position) > max_step_distance:
			trigger_step()

func trigger_step():
	# animation in progress, return
	if is_stepping:
		return
	
	# activate step
	is_stepping = true
	limb_mutex.lock_step(limb_group)
	
	# randomized delay for less rigid robotic movement
	var delay = randf_range(0.0, 0.2)
	await get_tree().create_timer(delay).timeout

	# tween for animation (interpolation of starting point, midpoint and final target)
	var tween = create_tween()
	tween.set_parallel(false) # sequential
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_SINE)
	
	var step_start_position: Vector3
	step_start_position = anchor_point.global_position

	# to midpoint
	tween.tween_method(
		func(progress: float):
			if ray_cast_3d.is_colliding():
				var current_target = ray_cast_3d.get_collision_point()
				var dynamic_midpoint = step_start_position.lerp(current_target, 0.65) + Vector3(0, step_height, 0)
				anchor_point.global_position = step_start_position.lerp(dynamic_midpoint, progress), 
		0.0, 1.0, step_duration
	)

	tween.set_ease(Tween.EASE_OUT)
	
	# to final target - needs to be calculated dynamically via tween_method, otherwise the step is too short
	tween.tween_method(
		func(progress: float):
			if ray_cast_3d.is_colliding():
				var current_target = ray_cast_3d.get_collision_point()
				var current_midpoint = step_start_position.lerp(current_target, 0.65) + Vector3(0, step_height, 0)
				anchor_point.global_position = current_midpoint.lerp(current_target, progress),
		0.0, 1.0, step_duration
	)
	
	# deactivate step
	tween.finished.connect(func():
		is_stepping = false
		if limb_mutex:
			limb_mutex.unlock_step(limb_group)
	)
	await tween.finished
	tween.kill()
