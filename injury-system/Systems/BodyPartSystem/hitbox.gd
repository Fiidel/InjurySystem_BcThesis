@icon("uid://b7dwo55g2dku5")

class_name Hitbox
extends Area3D

signal hitbox_hit(
	damage_amount: int,
	local_point: Vector3,
	local_normal: Vector3,
	bone_attachment: BoneAttachment3D,
	decal_params: Variant,
	deformation_params: Variant
)


func receive_hit(
		damage_amount: int,
		world_position: Vector3,
		world_normal: Vector3,
		decal_params: DecalParameters = null,
		deformation_params: DeformationParameters = null,
	) -> void:
	var attachment := get_parent() as BoneAttachment3D
	if attachment == null:
		push_warning("Hitbox has no BoneAttachment3D parent")
		return
	# convert the world point and normal to local space as attached to the bone
	var bone_inv := attachment.global_transform.affine_inverse() # affine_inverse() rather than inverse() is used so that the hits are detected correctly when the character is scaled
	var local_point := bone_inv * world_position
	var local_normal := (bone_inv.basis * world_normal).normalized()

	hitbox_hit.emit(damage_amount, local_point, local_normal, attachment, decal_params, deformation_params)
