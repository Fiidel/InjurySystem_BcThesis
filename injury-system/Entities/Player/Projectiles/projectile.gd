class_name Projectile
extends RigidBody3D
## Projectile class for the player's abilities.

enum ProjectileTypeEnum {
	SLASHING,
	BLUDGEONING,
	PIERCING
}

# General settings
@export var type: ProjectileTypeEnum
@export var speed: float = 50.0
@export var is_affected_by_gravity: bool

# Decal applied on hit
@export_group("Hit Decal")
@export var decal_params: DecalParameters

@export_group("Bludgeoning Deformation")
@export var deformation_params: DeformationParameters

# Raycast settings for SLASHING projectiles to detect hits along its arc
@export_group("Slash Detection Raycasts")
@export var slash_detection_width: float = 0.5
@export var slash_ray_count: int = 5

# General variables
var mesh: MeshInstance3D
var projectile_direction: Vector3 = Vector3.ZERO # direction that the projectile is traveling in
var _has_bounced_off: bool = false # prevent bouncing off of the same enemy multiple times
var _hit_recorded: bool = false # limit to 1 hit location recorded per projectile

# Raycast settings for non-BLUDGEONING projectiles to detect hits
var _ray_length: float = 0.0 # length of the raycast used for PIERCING/SLASHING hit detection
var _has_raycast_hit: bool = false # whether the raycast has detected a hit
var raycast_hit_position: Vector3 = Vector3.ZERO # stored position of the hit
var raycast_hit_normal: Vector3 = Vector3.ZERO # stored normal of the hit

@onready var hitbox: Area3D = $Hitbox


func _ready() -> void:
	# get the mesh instance
	mesh = _get_mesh_instance()
	if not mesh:
		push_error("No mesh instance found")
		queue_free()
	# set the length of the raycast used for non-BLUDGEONING projectile hit detection
	_ray_length = speed * 0.1
	# connect signals
	body_entered.connect(_on_physics_body_entered)
	hitbox.area_entered.connect(_on_hitbox_entered)
	# set the facing direction
	look_at(global_position + projectile_direction)
	# offset for gravity-based projectiles to start the arc at an upwards angle
	if is_affected_by_gravity:
		projectile_direction.y += 0.25
	# set velocity
	linear_velocity = projectile_direction * speed


func _physics_process(_delta: float) -> void:
	# skip if the projectile has already hit something
	if _hit_recorded or _has_raycast_hit:
		return
	# raycast forward for hit detection (fixes hits not being detected due to projectiles' speed being too high for Area3D detection)
	match type:
		ProjectileTypeEnum.PIERCING:
			update_piercing_raycast()
		ProjectileTypeEnum.SLASHING:
			update_slashing_raycast()


# for collisions with the environment (nodes with physics rather than Area3Ds)
func _on_physics_body_entered(_body: Node3D) -> void:
	# delete bludgeoning projectiles after impact
	if type == ProjectileTypeEnum.BLUDGEONING:
		start_delete_timer()
	# delete non-bludgeoning projectiles instantly
	else:
		queue_free()


# for enemy hitbox Area3D hit detection
func _on_hitbox_entered(area: Area3D) -> void:
	var enemy: Enemy = _get_enemy_from_hitbox_area(area)
	if enemy:
		match type:
			# shapecast hitbox shape for bludgeoning projectiles and record the shapecast's hit
			ProjectileTypeEnum.BLUDGEONING:
				cast_hitbox_and_record_hit(enemy, area)
			# the projectile has collided with an enemy's hitbox -> record the projectile's hit position that was detected by its raycast(s)
			ProjectileTypeEnum.PIERCING, ProjectileTypeEnum.SLASHING:
				record_hit_from_raycast(enemy, area)

	# bounce off enemy and delete after some time
	if type == ProjectileTypeEnum.BLUDGEONING:
		# only bounce off of the enemy once
		if !_has_bounced_off:
			linear_velocity = linear_velocity.bounce(linear_velocity.normalized()) * 0.2
			_has_bounced_off = true
		start_delete_timer()
	# delete non-bludgeoning projectiles instantly
	else:
		queue_free()


# shapecast hitbox shape for bludgeoning projectiles and record the shapecast's hit
func cast_hitbox_and_record_hit(enemy: Enemy, hitbox_area: Area3D) -> void:
	# allow only 1 hit
	if _hit_recorded:
		return
	
	# get the hitbox's collision shape
	var collision_shape: CollisionShape3D = _get_hitbox_collision_shape()
	if not collision_shape or not collision_shape.shape:
		return
	
	# create a shape query
	var space_state := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = collision_shape.shape
	params.transform = hitbox.global_transform
	params.collide_with_bodies = false
	params.collide_with_areas = true
	params.collision_mask = hitbox.collision_mask
	params.exclude = [get_rid(), hitbox.get_rid()] # exclude the projectile and self's hitbox

	# get the collision info and record hit in enemy script
	var collision := space_state.get_rest_info(params)
	if not collision.is_empty() and "point" in collision and "normal" in collision:
		enemy.record_hit(collision.point, collision.normal, hitbox_area, decal_params, deformation_params)
		_hit_recorded = true


# update the raycast for PIERCING projectiles
func update_piercing_raycast() -> void:
	# construct the raycast
	var dir_norm := projectile_direction.normalized()
	var origin := hitbox.global_position - dir_norm * _ray_length * 0.5
	var target := hitbox.global_position + dir_norm * _ray_length
	var params := PhysicsRayQueryParameters3D.create(origin, target)
	params.exclude = [get_rid(), hitbox.get_rid()]
	params.collide_with_bodies = false
	params.collide_with_areas = true
	params.collision_mask = hitbox.collision_mask
	
	# perform the raycast
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var collision := space_state.intersect_ray(params)
	if not collision.is_empty() and "position" in collision and "normal" in collision:
		raycast_hit_position = collision.position
		raycast_hit_normal = collision.normal
		_has_raycast_hit = true


# update the raycast for SLASHING projectiles (multiple rays in an arc; prefer the middle ray's hit)
func update_slashing_raycast() -> void:
	# get a vector representing the axis of the arc
	var dir := projectile_direction.normalized()
	var arc_axis: Vector3 = dir.cross(Vector3.UP)
	# if the arc axis is too small (=the direction is close to parallel to the UP vector), use the FORWARD vector to calculate the arc axis more accurately
	if arc_axis.length_squared() < 0.01:
		arc_axis = dir.cross(Vector3.FORWARD)
	arc_axis = arc_axis.normalized()
	
	# perform the raycasts
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var center_ray_index := (slash_ray_count - 1) / 2.0
	var best_hit: Dictionary = {}
	# iterate through all the raycasts
	for i in slash_ray_count:
		# normalize indices to -0.5-0.5
		var index_max: float = float(slash_ray_count) - 1.0 if slash_ray_count > 1 else 1.0  # convert to index range 0-max_index (and avoid division by 0)
		var centered_normalized_index := float(i) / index_max - 0.5 # normalize to 0-1 and shift by 0.5 (half to the left of the center of the projectile, half to the right)
		var offset := centered_normalized_index * slash_detection_width # calculate the offset based on the slash arc's width
		# create the raycast query and perform the raycast
		var origin := hitbox.global_position + arc_axis * offset - dir * _ray_length
		var target := hitbox.global_position + arc_axis * offset + dir * _ray_length
		var params := PhysicsRayQueryParameters3D.create(origin, target)
		params.exclude = [get_rid(), hitbox.get_rid()]
		params.collide_with_bodies = false
		params.collide_with_areas = true
		params.collision_mask = hitbox.collision_mask
		var collision := space_state.intersect_ray(params)
		# if the raycast didn't hit anything, continue to next raycast
		if collision.is_empty():
			continue
		# if the raycast didn't hit an enemy's hitbox, continue to next raycast
		var collider = collision.get("collider")
		if not (collider is Area3D) or not _get_enemy_from_hitbox_area(collider):
			continue
		# record hit; prefer the middle ray's hit over side hits
		var dist_from_center = abs(float(i) - center_ray_index)
		if best_hit.is_empty() or dist_from_center < best_hit.dist_from_center:
			best_hit = {
				"dist_from_center": dist_from_center,
				"collision": collision
			}
	# store the final hit
	if not best_hit.is_empty():
		raycast_hit_position = best_hit.collision.position
		raycast_hit_normal = best_hit.collision.normal
		_has_raycast_hit = true


# record the non-bludgeoning projectile's hit through the enemy script
func record_hit_from_raycast(enemy: Enemy, area: Area3D) -> void:
	if _hit_recorded:
		return
	# use the detected hit position and normal, or the projectile hitbox's position and normal if the projectile has collided with the enemy's hitbox but no hit was detected
	var position: Vector3 = raycast_hit_position if _has_raycast_hit else hitbox.global_position
	var normal: Vector3 = raycast_hit_normal if _has_raycast_hit else (-projectile_direction.normalized())
	enemy.record_hit(position, normal, area, decal_params)
	_hit_recorded = true


# start a delete timer to remove the projectile after a period of time
func start_delete_timer() -> void:
	await get_tree().create_timer(3.0).timeout
	var material: StandardMaterial3D = mesh.get_active_material(0)
	material = material.duplicate() # create a unique material to not fade out all others sharing it
	mesh.set_surface_override_material(0, material)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tween: Tween = create_tween()
	tween.tween_property(material, "albedo_color:a", 0, 2.0)
	tween.play()
	await tween.finished
	queue_free()


# get the mesh instance
func _get_mesh_instance() -> MeshInstance3D:
	for child in get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
	return null

# get the Area3D hitbox's collision shape
func _get_hitbox_collision_shape() -> CollisionShape3D:
	for child in hitbox.get_children():
		if child is CollisionShape3D:
			return child as CollisionShape3D
	return null


# search through the node's parents until the Enemy node is found
func _get_enemy_from_hitbox_area(area: Area3D) -> Enemy:
	var node: Node = area
	while node:
		if node is Enemy:
			return node as Enemy
		node = node.get_parent()
	return null
