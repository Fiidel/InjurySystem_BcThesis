class_name Enemy
extends CharacterBody3D
## Enemy class for the manticore enemy.

# constants limiting the number of hits and decals
const MAX_HITS: int = 16
const MAX_DECALS: int = 16

# arrays to store hit locations and decals
var hit_locations: Array = []
var decals: Array = []

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


func _process(_delta: float) -> void:
	# update shader with parameters following the bone animation
	if not hit_locations.is_empty():
		update_deformation_shader()


func _physics_process(delta: float) -> void:
	# character movement
	velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	move_and_slide()


# record a hit on the enemy, apply deformation and spawn decal
func record_hit(world_point: Vector3, world_normal: Vector3, hitbox_area: Area3D, decal_texture: Texture2D = null, apply_deformation: bool = true, decal_width: float = 1.0, decal_height: float = 1.0, decal_depth: float = 0.5) -> void:
	# get the bone attachment parent
	var attachment := hitbox_area.get_parent() as BoneAttachment3D
	if attachment == null:
		push_warning("Hit area has no BoneAttachment3D parent")
		return

	# convert the world point and normal to local space as attached to the bone
	var bone_inv := attachment.global_transform.affine_inverse() # affine_inverse() rather than inverse() is used so that the hits are detected correctly when the character is scaled
	var local_point := bone_inv * world_point
	var local_normal := (bone_inv.basis * world_normal).normalized()

	# update deformation array and shader
	if apply_deformation:
		if hit_locations.size() >= MAX_HITS:
			hit_locations.pop_front()
		hit_locations.append({
			"attachment": attachment,
			"pos": local_point,
			"normal": local_normal
		})
		update_deformation_shader()

	# spawn hit decal
	spawn_hit_decal(attachment, local_point, local_normal, decal_texture, decal_width, decal_height, decal_depth)


# update the deformation shader with the hit locations and normals
func update_deformation_shader() -> void:
	var mesh_inv := body_mesh.global_transform.affine_inverse()
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()

	# iterate through all the hit locations and normals
	for hit in hit_locations:
		# hit is stored in bone-attachment local space; convert to mesh local so the mesh deformation shader can use it
		var attachment := hit["attachment"] as BoneAttachment3D
		# recalculate the attachment-to-mesh transform each frame so the hits follow the bone animation
		var attachment_to_mesh := mesh_inv * attachment.global_transform
		positions.append(attachment_to_mesh * hit["pos"])
		var mesh_normal = (attachment_to_mesh.basis.inverse().transposed() * hit["normal"]).normalized()
		normals.append(mesh_normal)

	var mat := body_mesh.get_surface_override_material(0)
	mat.set("shader_parameter/hit_count", hit_locations.size())
	mat.set("shader_parameter/hit_positions", positions)
	mat.set("shader_parameter/hit_normals", normals)


# spawn a hit decal at the given position, oriented by the given normal
func spawn_hit_decal(attachment: BoneAttachment3D, local_point: Vector3, local_normal: Vector3, decal_texture: Texture2D = null, decal_width: float = 1.0, decal_height: float = 1.0, decal_depth: float = 0.5) -> void:
	# limit the number of decals
	if decals.size() >= MAX_DECALS:
		var old: Decal = decals.pop_front()
		old.queue_free()

	# create a new decal and set its parameters
	var decal := Decal.new()
	decal.texture_albedo = decal_texture
	decal.size = Vector3(decal_width, decal_depth, decal_height)
	decal.upper_fade = 0.8
	decal.lower_fade = 0.8
	decal.normal_fade = 0.4
	
	# parent to the bone attachment so the decal moves with the bone deformations
	attachment.add_child(decal)

	# offset the decal position slightly so that the look_at position is different from the decal position
	var pos_local := local_point - local_normal * 0.02
	var target_local := local_point + local_normal
	# set the decal's position and orientation
	decal.global_position = attachment.global_transform * pos_local
	decal.look_at(attachment.global_transform * target_local, Vector3.UP)
	decal.rotate_object_local(Vector3(1, 0, 0), -PI / 2.0) # rotate the decal along the X axis by -90 degrees so that the decal texture is the correct orientation on the surface

	# add the decal to the decals array
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

