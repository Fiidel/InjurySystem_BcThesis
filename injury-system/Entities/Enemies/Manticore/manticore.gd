class_name Enemy
extends CharacterBody3D
## Enemy class for the manticore enemy.

@export var body: Body
@export var delay_before_fade_out: float = 0.0
@export var collision_shapes: Array[CollisionShape3D] = []
@export_group("Death Fading")
@export_range(0.0, 10.0, 0.1) var death_fade_duration: float = 3.0
@export var fade_meshes: Array[MeshInstance3D] = []
@export var instant_fade_meshes: Array[MeshInstance3D] = []

@onready var look_at_target: Marker3D = %LookAtTarget
@onready var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dying: bool = false
var ground_align_ray_length: float = 2.0
var ground_align_speed: float = 8.0
var ground_align_z_rotation_scale: float = 0.33


func _ready() -> void:
	if body:
		body.enemy_killed.connect(on_enemy_killed)


func _physics_process(delta: float) -> void:
	if is_dying:
		return
	align_to_ground(delta)
	# character movement
	velocity.y -= GRAVITY * delta
	move_and_slide()


func on_enemy_killed() -> void:
	if is_dying:
		return
	is_dying = true
	if delay_before_fade_out > 0.0:
		await get_tree().create_timer(delay_before_fade_out).timeout
	await fade_out_meshes()
	queue_free()


func fade_out_meshes() -> void:
	var instant_tween := create_tween()
	for mesh_instance in instant_fade_meshes:
		instant_tween.parallel().tween_property(mesh_instance, "transparency", 1.0, 0.2)
	var tween := create_tween()
	for mesh_instance in fade_meshes:
			tween.parallel().tween_property(mesh_instance, "transparency", 1.0, death_fade_duration)
	await tween.finished


func align_to_ground(delta: float) -> void:
	if collision_shapes.size() != 2:
		push_warning("Add 2 collision shapes to " + name + " for ground alignment")
		return

	# get ground normals and average them
	var front_shape := collision_shapes[0]
	var back_shape := collision_shapes[1]
	var front_hit := get_ground_hit(front_shape.global_position)
	var back_hit := get_ground_hit(back_shape.global_position)
	if front_hit.is_empty() or back_hit.is_empty():
		return
	var ground_normal := ((front_hit["normal"] as Vector3) + (back_hit["normal"] as Vector3)).normalized()

	# calculate the rotation for the enemy based on the ground normal
	var front_direction := back_shape.global_position.direction_to(front_shape.global_position).normalized()
	var forward := front_direction.slide(ground_normal).normalized()
	# flip z axis if forward is facing backwards (Godot's forward axis is -Z)
	if forward.dot(-global_basis.z) < 0.0:
		forward = -forward
	var side_axis := forward.cross(ground_normal).normalized()
	var target_basis := Basis(side_axis, ground_normal, -forward).orthonormalized()
	var rotation_basis := target_basis.get_euler() # get the rotation from the basis
	rotation_basis.z *= ground_align_z_rotation_scale # adjust the rotation along the z-axis (the enemy's sideways rotation to stand correctly along the ground normal)
	# interpolate the current basis with the target basis
	target_basis = Basis.from_euler(rotation_basis).orthonormalized() # convert back to a stable basis
	var current_basis := global_basis.orthonormalized()
	var current_rotation := current_basis.get_rotation_quaternion()
	var target_rotation := target_basis.get_rotation_quaternion()
	var clamp = clamp(ground_align_speed * delta, 0.0, 1.0) # clamp interpolation to 0-1
	global_basis = Basis(current_rotation.slerp(target_rotation, clamp)).orthonormalized()


func get_ground_hit(from_position: Vector3) -> Dictionary:
	var ray_params := PhysicsRayQueryParameters3D.create(
		from_position + Vector3.UP * 0.2,
		from_position + Vector3.DOWN * ground_align_ray_length
	)
	ray_params.exclude = [self]
	ray_params.collision_mask = 1 << 2 # Environment is the 3rd layer (in Godot notation)
	return get_world_3d().direct_space_state.intersect_ray(ray_params)
