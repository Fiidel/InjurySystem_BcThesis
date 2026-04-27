@icon("uid://bsvaohwdo2u17")

class_name Body
extends Node

signal enemy_killed

@export var central_health: float = 1.0
@export var bt_root: BTRoot
@export var animation_tree: AnimationTree
@export var skeleton_simulator: PhysicalBoneSimulator3D
@export var movement_collision_shapes: Array[CollisionShape3D]
@export_range(1, 32, 1) var ragdoll_collision_layer_to_enable: int = 1
var is_dead: bool = false


func _ready() -> void:
	connect_central_damage_signals()


func take_central_damage(amount: float) -> void:
	if is_dead:
		return
	central_health -= amount
	if central_health <= 0:
		is_dead = true
		enemy_killed.emit()
		if bt_root:
			bt_root.abort()
		call_deferred("activate_ragdoll") # must be called deferred


func activate_ragdoll() -> void:
	if animation_tree:
		animation_tree.active = false
	for shape in movement_collision_shapes:
		shape.disabled = true
	set_physical_bone_collision_layer(skeleton_simulator)
	skeleton_simulator.physical_bones_start_simulation()


func set_physical_bone_collision_layer(simulator: PhysicalBoneSimulator3D) -> void:
	if not is_instance_valid(simulator):
		return
	for child in simulator.get_children():
		if child is PhysicalBone3D:
			(child as PhysicalBone3D).set_collision_layer_value(ragdoll_collision_layer_to_enable, true)


func connect_central_damage_signals() -> void:
	for child in get_children():
		if child is BodyPart:
			(child as BodyPart).damage_central_health.connect(take_central_damage)
