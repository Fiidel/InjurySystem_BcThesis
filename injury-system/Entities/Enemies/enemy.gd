extends Node3D

var speed: float = 2

func _physics_process(delta: float) -> void:
	global_position = global_position + Vector3(0, 0, delta*speed)
