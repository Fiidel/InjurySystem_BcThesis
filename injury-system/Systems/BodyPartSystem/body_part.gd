@tool
@icon("uid://cvv6g76quclal")

class_name BodyPart
extends Node

signal damage_central_health(amount: float)
signal zero_health_reached

const MAX_HITS: int = 16
const MAX_DECALS: int = 16
const HIT_FLASH_INTENSITY: float = 0.15
const HIT_FLASH_WINDUP: float = 0.03
const HIT_FLASH_UNWIND: float = 0.1

@export var only_damage_central_health: bool = false:
	set(value):
		if only_damage_central_health == value:
			return
		only_damage_central_health = value
		if only_damage_central_health and health <= 0:
			health = 1
		notify_property_list_changed()
@export var health: float = 1
@export var mesh: MeshInstance3D
@export var remove_part_if_destroyed: bool = false:
	set(value):
		if remove_part_if_destroyed == value:
			return
		remove_part_if_destroyed = value
		notify_property_list_changed()
@export var skeleton: Skeleton3D:
	set(value):
		if skeleton == value:
			return
		skeleton = value
		notify_property_list_changed()
@export var bone_to_remove: StringName
@export var severed_body_scene: PackedScene
@export var hitboxes: Array[Hitbox]
var hit_locations: Array = []
var decals: Array[Decal] = []
var knockback_component: BoneKnockback3D
var is_destroyed: bool
var hit_flash_tween: Tween


func _validate_property(property: Dictionary) -> void:
	# hide health when this body part only relays damage
	if property.name == &"health" and only_damage_central_health:
		property.usage = PROPERTY_USAGE_NO_EDITOR

	# toggle skeleton and bone based on remove_bones_on_destroy
	if property.name in ["skeleton", "bone_to_remove", "severed_body_scene"]:
		if not remove_part_if_destroyed:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	
	# validate the bone_to_destroy property
	if property.name == &"bone_to_remove" and skeleton != null:
		# get the bone names and set it as the hint string enum
		var hint_string := String(skeleton.get_concatenated_bone_names())
		if hint_string.is_empty():
			return
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = hint_string


func _ready() -> void:
	# init material and shader parameters
	var mat := mesh.get_active_material(0).duplicate()
	mesh.set_surface_override_material(0, mat)
	mat.set("shader_parameter/hit_count", 0)
	mat.set("shader_parameter/hit_positions", PackedVector3Array())
	mat.set("shader_parameter/hit_normals", PackedVector3Array())
	mat.set("shader_parameter/hit_radius", PackedFloat32Array())
	mat.set("shader_parameter/hit_strength", PackedFloat32Array())
	mat.set("shader_parameter/hit_flash", 0.0)
	# get the knockback component
	for child in get_children():
		if child is BoneKnockback3D:
			knockback_component = child
			break
	# connect the signals
	for hitbox in hitboxes:
		hitbox.hitbox_hit.connect(on_hitbox_hit)
	zero_health_reached.connect(on_zero_health_reached)


func _process(_delta: float) -> void:
	# update shader with parameters following the bone animation
	if not hit_locations.is_empty():
		update_deformation_shader()


func on_hitbox_hit(
		damage_amount: float,
		local_point: Vector3,
		local_normal: Vector3,
		projectile_direction: Vector3,
		bone_attachment: BoneAttachment3D,
		decal_params: Variant,
		deformation_params: Variant
	) -> void:
	SignalBus.enemy_hit.emit()
	# apply damage
	take_damage(damage_amount)
	# play flash effect on limb
	play_hit_flash()
	# apply knockback
	if knockback_component:
		knockback_component.apply_knockback(projectile_direction)
	# update deformation array and shader
	var do_deform : bool = deformation_params != null and deformation_params.apply_deformation
	if do_deform:
		if can_register_deformation_hit(bone_attachment, local_point, deformation_params):
			if hit_locations.size() >= MAX_HITS:
				hit_locations.pop_front()
			hit_locations.append({
				"attachment": bone_attachment,
				"pos": local_point,
				"normal": local_normal,
				"radius": deformation_params.hit_radius,
				"strength": deformation_params.hit_strength
			})
			update_deformation_shader()
	# spawn a decal
	if decal_params:
		spawn_hit_decal(bone_attachment, local_point, local_normal, decal_params)


# check if the new hit location is too close to any existing hit location
func can_register_deformation_hit(attachment: BoneAttachment3D, new_local_point: Vector3, deformation_params: DeformationParameters) -> bool:
	if hit_locations.is_empty() or deformation_params.min_hit_separation <= 0.0:
		return true

	var new_world_point: Vector3 = attachment.global_transform * new_local_point
	for hit in hit_locations:
		var existing_world_point: Vector3 = hit["attachment"].global_transform * hit["pos"]
		if existing_world_point.distance_to(new_world_point) <= deformation_params.min_hit_separation:
			return false

	return true


func take_damage(amount: float) -> void:
	if is_destroyed:
		return
	if only_damage_central_health:
		damage_central_health.emit(amount)
		return
	health -= amount
	if health <= 0:
		zero_health_reached.emit()


func play_hit_flash() -> void:
	var mat := mesh.get_surface_override_material(0)
	if mat == null:
		return
	if hit_flash_tween and hit_flash_tween.is_valid():
		hit_flash_tween.kill()
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(mat, "shader_parameter/hit_flash", HIT_FLASH_INTENSITY, HIT_FLASH_WINDUP)
	hit_flash_tween.tween_property(mat, "shader_parameter/hit_flash", 0.0, HIT_FLASH_UNWIND)


func on_zero_health_reached() -> void:
	is_destroyed = true
	SignalBus.body_part_destroyed.emit(self)
	if remove_part_if_destroyed:
		# make the mesh material flash
		var mat := mesh.get_active_material(0)
		var tween: Tween = create_tween()
		tween.tween_property(mat, "shader_parameter/albedo", Color.DARK_RED, 0.1)
		await tween.finished
		await get_tree().create_timer(0.8).timeout
		tween = create_tween()
		tween.tween_property(mat, "shader_parameter/albedo", Color.WHITE, 0.1)
		await tween.finished
		# spawn the severed limb rigidbody and remove the original bones and all children
		spawn_severed_limb()
		remove_bones()
		for child in get_children():
			child.queue_free()


func spawn_severed_limb() -> void:
	mesh.hide()
	if severed_body_scene != null:
		var severed_body: RigidBody3D = severed_body_scene.instantiate()
		get_parent().add_child(severed_body)
		severed_body.global_transform = mesh.global_transform


func remove_bones() -> void:
	if skeleton == null or bone_to_remove == "":
		return
	var root_bone_idx := skeleton.find_bone(bone_to_remove)
	if root_bone_idx < 0:
		return
	remove_bone_subtree(root_bone_idx)


func remove_bone_subtree(root_bone_idx: int) -> void:
	var simulator: PhysicalBoneSimulator3D = find_physical_bone_simulator()
	if simulator == null:
		push_warning("BodyPart: no PhysicalBoneSimulator3D found for bone removal.")
		return

	var physical_bones: Dictionary = {} # bone name -> physical bone
	for child in simulator.get_children():
		if child is PhysicalBone3D:
			var physical_bone := child as PhysicalBone3D
			physical_bones[physical_bone.bone_name] = physical_bone
	
	var bones_to_remove: Array[int] = [root_bone_idx]
	while not bones_to_remove.is_empty():
		# get current bone
		var current_bone: int = bones_to_remove.pop_back()
		# log its children as to be deleted
		for child_idx in skeleton.get_bone_children(current_bone):
			bones_to_remove.append(child_idx)
		# get the physical bone
		var bone_name: StringName = skeleton.get_bone_name(current_bone)
		var physical_bone: PhysicalBone3D = physical_bones.get(bone_name, null)
		if physical_bone != null:
			physical_bone.queue_free()


func find_physical_bone_simulator() -> PhysicalBoneSimulator3D:
	if skeleton == null:
		return null
	for child in skeleton.get_children():
		if child is PhysicalBoneSimulator3D:
			return child as PhysicalBoneSimulator3D
	return null


# update the deformation shader with the hit locations and normals
func update_deformation_shader() -> void:
	var mesh_inv := mesh.global_transform.affine_inverse()
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var radius := PackedFloat32Array()
	var strength := PackedFloat32Array()

	# iterate through all the hit locations and normals
	for hit in hit_locations:
		# hit is stored in bone-attachment local space; convert to mesh local so the mesh deformation shader can use it
		var attachment := hit["attachment"] as BoneAttachment3D
		# recalculate the attachment-to-mesh transform each frame so the hits follow the bone animation
		var attachment_to_mesh := mesh_inv * attachment.global_transform
		positions.append(attachment_to_mesh * hit["pos"])
		var mesh_normal = (attachment_to_mesh.basis.inverse().transposed() * hit["normal"]).normalized()
		normals.append(mesh_normal)
		radius.append(float(hit["radius"]))
		strength.append(float(hit["strength"]))

	var mat := mesh.get_surface_override_material(0)
	mat.set("shader_parameter/hit_count", hit_locations.size())
	mat.set("shader_parameter/hit_positions", positions)
	mat.set("shader_parameter/hit_normals", normals)
	mat.set("shader_parameter/hit_radius", radius)
	mat.set("shader_parameter/hit_strength", strength)


func spawn_hit_decal(attachment: BoneAttachment3D, local_point: Vector3, local_normal: Vector3, hit_decal_params: DecalParameters) -> void:
	if hit_decal_params == null or hit_decal_params.texture == null:
		return
	if decals.size() >= MAX_DECALS:
		var old: Decal = decals.pop_front()
		old.queue_free()

	# create a new decal and set its parameters
	var decal := Decal.new()
	decal.texture_albedo = hit_decal_params.texture
	decal.texture_normal = hit_decal_params.texture_normal
	decal.size = Vector3(hit_decal_params.width, hit_decal_params.depth, hit_decal_params.height)
	decal.upper_fade = 0.5
	decal.lower_fade = 0.5
	decal.normal_fade = 0.2

	# parent to the attachment node
	attachment.add_child(decal)

	# offset the decal position slightly so that the look_at position is different from the decal position
	var pos_local := local_point - local_normal * 0.02
	var target_local := local_point + local_normal

	# set the decal's position and orientation
	decal.global_position = attachment.global_transform * pos_local
	decal.look_at(attachment.global_transform * target_local, Vector3.UP)
	decal.rotate_object_local(Vector3(1, 0, 0), -PI / 2.0) # rotate the decal along the X axis by -90 degrees so that the decal texture is the correct orientation on the surface

	decals.append(decal)


# spawn a debug cylinder matching the decal's transforms
func _spawn_debug_cylinder(attachment: BoneAttachment3D, decal: Decal) -> void:
	var debug_mesh := CylinderMesh.new()
	debug_mesh.top_radius = 0.1
	debug_mesh.bottom_radius = 0.1
	debug_mesh.height = 0.2
	var cylinder := MeshInstance3D.new()
	cylinder.mesh = debug_mesh
	attachment.add_child(cylinder)
	cylinder.global_transform = decal.global_transform


# spawn a debug sphere at the given hit position
func _spawn_debug_sphere(hit_pos: Vector3, attachment: BoneAttachment3D) -> void:
	var debug_mesh := SphereMesh.new()
	debug_mesh.radius = 0.1
	debug_mesh.height = 0.2
	var sphere := MeshInstance3D.new()
	sphere.mesh = debug_mesh
	add_child(sphere)
	sphere.global_position = attachment.global_transform * hit_pos
