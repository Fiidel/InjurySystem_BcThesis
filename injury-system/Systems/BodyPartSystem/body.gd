@icon("uid://bsvaohwdo2u17")

class_name Body
extends Node

@export var central_health: float = 1.0
@export var bt_root: BTRoot
@export var animation_tree: AnimationTree
@export var skeleton_simulator: PhysicalBoneSimulator3D
@export var movement_collision: CollisionShape3D


func _ready() -> void:
	connect_central_damage_signals()


func take_central_damage(amount: float) -> void:
	central_health -= amount
	if central_health <= 0:
		if bt_root:
			bt_root.abort()
		call_deferred("activate_ragdoll") # must be called deferred


func activate_ragdoll() -> void:
	if animation_tree:
		animation_tree.active = false
	movement_collision.disabled = true
	skeleton_simulator.physical_bones_start_simulation()


func connect_central_damage_signals() -> void:
	for child in get_children():
		if child is BodyPart:
			(child as BodyPart).damage_central_health.connect(take_central_damage)
