class_name Enemy
extends CharacterBody3D
## Enemy class for the manticore enemy.

# constants limiting the number of hits and decals
const MAX_HITS: int = 16
const MAX_DECALS: int = 16

# arrays to store hitboxes, hit locations, and decals
var body_part_hitboxes: Array[Hitbox] = []
var hit_locations: Array = []
var decals: Array[Decal] = []

# get the necessary child nodes
@onready var look_at_target: Marker3D = %LookAtTarget
@onready var body_mesh: MeshInstance3D = %BodyMesh


func _ready() -> void:
	# init material and shader parameters
	var mat := body_mesh.get_active_material(0).duplicate()
	body_mesh.set_surface_override_material(0, mat)
	mat.set("shader_parameter/hit_count", 0)
	mat.set("shader_parameter/hit_positions", PackedVector3Array())
	mat.set("shader_parameter/hit_normals", PackedVector3Array())
	mat.set("shader_parameter/hit_radius", PackedFloat32Array())
	mat.set("shader_parameter/hit_strength", PackedFloat32Array())
	get_hitboxes(self)
	for hitbox in body_part_hitboxes:
		hitbox.hitbox_hit.connect(record_hit)


func _process(_delta: float) -> void:
	# update shader with parameters following the bone animation
	if not hit_locations.is_empty():
		update_deformation_shader()


func _physics_process(delta: float) -> void:
	# character movement
	velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	move_and_slide()


func get_hitboxes(node: Node) -> void:
	for child in node.get_children():
		if child is BodyPart:
			body_part_hitboxes.append_array(child.hitboxes)
		get_hitboxes(child)


# record a hit on the enemy, apply deformation and spawn decal
func record_hit(
		_damage_amount: float,
		local_point: Vector3,
		local_normal: Vector3,
		_projectile_direction: Vector3,
		bone_attachment: BoneAttachment3D,
		decal_params: DecalParameters = null,
		deformation_params: DeformationParameters = null
	) -> void:
	# update deformation array and shader
	var do_deform := deformation_params != null and deformation_params.apply_deformation
	if do_deform:
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

	if decal_params:
		spawn_hit_decal(bone_attachment, local_point, local_normal, decal_params)


# update the deformation shader with the hit locations and normals
func update_deformation_shader() -> void:
	var mesh_inv := body_mesh.global_transform.affine_inverse()
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

	var mat := body_mesh.get_surface_override_material(0)
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
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.1
	mesh.bottom_radius = 0.1
	mesh.height = 0.2
	var cylinder := MeshInstance3D.new()
	cylinder.mesh = mesh
	attachment.add_child(cylinder)
	cylinder.global_transform = decal.global_transform


# spawn a debug sphere at the given hit position
func _spawn_debug_sphere(hit_pos: Vector3, attachment: BoneAttachment3D) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	var sphere := MeshInstance3D.new()
	sphere.mesh = mesh
	add_child(sphere)
	sphere.global_position = attachment.global_transform * hit_pos



#@onready var raycast_front: RayCast3D = $ManticoreModel/metarig/Skeleton3D/FootFR/RayCast3D
#@onready var raycast_back: RayCast3D = $ManticoreModel/metarig/Skeleton3D/FootBR/RayCast3D
#@onready var model: Node3D = $ManticoreModel
#
#func _physics_process(delta: float) -> void:
	#align_to_ground_pitch()
	#velocity.y -= 9.81 * delta
	#move_and_slide()
#
#func align_to_ground_pitch():
	#if not raycast_front.is_colliding():
		#return
	#if not raycast_back.is_colliding():
		#return
#
	#var front_hit := raycast_front.get_collision_point()
	#var back_hit  := raycast_back.get_collision_point()
#
	## Direction from back to front foot
	#var slope_vector := front_hit - back_hit
#
	## Remove sideways influence (XZ plane alignment)
	#slope_vector = slope_vector.project(Vector3.FORWARD)
#
	## Angle between slope and flat ground
	#var angle := atan2(slope_vector.y, slope_vector.z)
#
	#model.rotation.x = lerp_angle(
		#model.rotation.x,
		#angle + deg_to_rad(-5),
		#0.15
	#)
