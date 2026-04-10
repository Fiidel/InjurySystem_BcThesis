class_name ProjectileHitData
extends Resource

var damage_amount: float = 0.0
var world_position: Vector3 = Vector3.ZERO
var world_normal: Vector3 = Vector3.UP
var projectile_direction: Vector3 = Vector3.ZERO
var decal_params: DecalParameters
var deformation_params: DeformationParameters


func _init(
	damage: float = 0.0,
	world_position: Vector3 = Vector3.ZERO,
	world_normal: Vector3 = Vector3.UP,
	projectile_direction: Vector3 = Vector3.ZERO,
	decal_params: DecalParameters = null,
	deformation_params: DeformationParameters = null,
) -> void:
	self.damage_amount = damage
	self.world_position = world_position
	self.world_normal = world_normal
	self.projectile_direction = projectile_direction
	self.decal_params = decal_params
	self.deformation_params = deformation_params
