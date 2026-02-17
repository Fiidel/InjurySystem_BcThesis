class_name Projectile
extends Node3D

@export var speed: float = 50.0
@export var is_affected_by_gravity: bool
@onready var collision_area: Area3D = $Area3D
var direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	collision_area.body_entered.connect(_on_body_entered)
	look_at(global_position+direction)
	# throwing upwards offset
	if is_affected_by_gravity:
		direction.y += 0.25

func _physics_process(delta: float) -> void:
	if is_affected_by_gravity:
		direction.y -= 0.01
		global_position += direction * speed * delta
	else:
		global_position += direction * speed * delta

func _on_body_entered(body: Node3D):
	if body is not Player:
		queue_free()
