class_name Enemy
extends CharacterBody3D
## Enemy class for the manticore enemy.

@onready var look_at_target: Marker3D = %LookAtTarget


func _physics_process(delta: float) -> void:
	# character movement
	velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	move_and_slide()


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
