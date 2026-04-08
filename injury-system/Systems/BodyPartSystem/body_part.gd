@icon("uid://cvv6g76quclal")

class_name BodyPart
extends Node

signal zero_health_reached

@export var health: int = 1
@export var hitboxes: Array[Hitbox]
var knockback_component: BoneKnockback3D
var is_destroyed: bool


func _ready() -> void:
	for child in get_children():
		if child is BoneKnockback3D:
			knockback_component = child
			break
	for hitbox in hitboxes:
		hitbox.hitbox_hit.connect(on_hitbox_hit)
	zero_health_reached.connect(on_zero_health_reached)


func on_hitbox_hit(
		damage_amount: int,
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


func take_damage(amount: int) -> void:
	if is_destroyed:
		return
	health -= amount
	if health <= 0:
		zero_health_reached.emit()


func on_zero_health_reached() -> void:
	is_destroyed = true
	print("body part" + name + "destroyed")
