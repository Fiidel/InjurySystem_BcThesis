@tool
@icon("uid://cvv6g76quclal")

class_name BodyPart
extends Node

signal damage_central_health(amount: float)
signal zero_health_reached

@export var health: float = 1
@export var only_damage_central_health: bool = false
@export var remove_bones_on_destroy: bool = false:
	set(value):
		if remove_bones_on_destroy == value:
			return
		remove_bones_on_destroy = value
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
var knockback_component: BoneKnockback3D
var is_destroyed: bool

const SEVERED_LIMB_BONE_POSE_SCALE := Vector3.ONE * 0.001


func _validate_property(property: Dictionary) -> void:
	# toggle skeleton and bone based on remove_bones_on_destroy
	if property.name in ["skeleton", "bone_to_remove", "severed_body_scene"]:
		if not remove_bones_on_destroy:
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
	for child in get_children():
		if child is BoneKnockback3D:
			knockback_component = child
			break
	for hitbox in hitboxes:
		hitbox.hitbox_hit.connect(on_hitbox_hit)
	zero_health_reached.connect(on_zero_health_reached)


func on_hitbox_hit(
		damage_amount: float,
		_local_point: Vector3,
		_local_normal: Vector3,
		projectile_direction: Vector3,
		_bone_attachment: BoneAttachment3D,
		_decal_params: Variant,
		_deformation_params: Variant
	) -> void:
	take_damage(damage_amount)
	if knockback_component:
		knockback_component.apply_knockback(projectile_direction)


func take_damage(amount: float) -> void:
	if is_destroyed:
		return
	if only_damage_central_health:
		damage_central_health.emit(amount)
		return
	health -= amount
	if health <= 0:
		zero_health_reached.emit()


func on_zero_health_reached() -> void:
	is_destroyed = true
	SignalBus.body_part_destroyed.emit()
	if remove_bones_on_destroy:
		if skeleton != null and bone_to_remove != "":
			var bone_idx: int = skeleton.find_bone(bone_to_remove)
			if bone_idx >= 0:
				var bone_transform: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx)
				skeleton.set_bone_pose_scale(bone_idx, Vector3.ONE * 0.001)
				if severed_body_scene != null:
					spawn_severed_limb(bone_transform)


func spawn_severed_limb(bone_transform: Transform3D) -> void:
	var inst := severed_body_scene.instantiate()
	add_child(inst)
	inst.global_transform = bone_transform
