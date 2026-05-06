extends Node3D

@export var explosion_push_strength: float = 1.0
@export var direction_randomness: float = 0.2
@export var angular_speed: float = 5.0

@onready var explosion_center: Marker3D = $ExplosionCenter

func _ready() -> void:
	var center_pos : Vector3 = explosion_center.global_position
	for child in get_children():
		if child is RigidBody3D:
			var point : Vector3 = child.global_position
			var shape: CollisionShape3D = child.get_node_or_null("CollisionShape3D")
			if shape:
				point = child.global_transform * shape.position
			var base_direction : Vector3 = (point - center_pos).normalized()
			var random_offset := Vector3(
				randf_range(-direction_randomness, direction_randomness),
				randf_range(-direction_randomness, direction_randomness),
				randf_range(-direction_randomness, direction_randomness)
			)
			var direction : Vector3 = (base_direction + random_offset).normalized()
			child.apply_central_impulse(direction * explosion_push_strength)
			child.angular_velocity = Vector3(
				randf_range(-angular_speed, angular_speed),
				randf_range(-angular_speed, angular_speed),
				randf_range(-angular_speed, angular_speed)
			)
			delete_child_timer(child)


func delete_child_timer(node: RigidBody3D) -> void:
	await get_tree().create_timer(3.0).timeout
	var fade_setup_start_usec := ProfilerMonitors.m_now_usec() # monitoring
	# fade out the mesh
	var mesh: MeshInstance3D = get_mesh_instance(node)
	if mesh:
		var material: StandardMaterial3D = mesh.get_active_material(0)
		material = material.duplicate()
		mesh.set_surface_override_material(0, material)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var tween: Tween = create_tween()
		tween.tween_property(material, "albedo_color:a", 0, 2.0)
		tween.play()
		# monitoring
		var fade_setup_ms := float(ProfilerMonitors.m_now_usec() - fade_setup_start_usec) / 1000.0
		ProfilerMonitors.m_record_projectile_impact_vfx(fade_setup_ms)
		# wait for the tween to finish
		await tween.finished
	node.queue_free()


func get_mesh_instance(node: RigidBody3D) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
	return null
