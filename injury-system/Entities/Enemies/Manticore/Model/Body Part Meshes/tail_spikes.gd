class_name TailSpikes
extends Node3D

@export var projectile_speed: float = 40.0
@export var max_lifetime: float = 5.0

@onready var spikes_mesh: MeshInstance3D = $TailSpikes

var velocity: Vector3 = Vector3.ZERO
var lifetime_timer: Timer


func _ready() -> void:
	set_physics_process(false)
	lifetime_timer = Timer.new()
	lifetime_timer.wait_time = max_lifetime
	lifetime_timer.one_shot = true
	add_child(lifetime_timer)
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)


func _physics_process(delta: float) -> void:
	global_position += velocity * delta


func launch(direction: Vector3, speed: float = projectile_speed) -> void:
	var launch_direction: Vector3 = direction.normalized()
	
	# rotate towards the direction
	look_at(global_position + launch_direction, Vector3.UP)
	rotate_object_local(Vector3(1, 0, 0), -PI * 0.5) # rotate by -90 degrees on the X axis
	
	velocity = launch_direction * speed
	lifetime_timer.start()
	set_physics_process(true)


func make_material_unique() -> void:
	if spikes_mesh == null:
		return
	var active_material: Material = spikes_mesh.get_active_material(0)
	if active_material != null:
		spikes_mesh.set_surface_override_material(0, active_material.duplicate())


func make_invisible() -> void:
	visible = false


func fade_in_material(duration: float) -> void:
	if spikes_mesh != null:
		var material := spikes_mesh.get_active_material(0) as BaseMaterial3D
		material.albedo_color.a = 0.0
		visible = true
		var fade_in_tween: Tween = get_tree().create_tween()
		fade_in_tween.tween_property(material, "albedo_color:a", 1.0, duration)


func _on_hitbox_body_entered(body: Node3D) -> void:
	if body is Player:
		body.take_damage(1.0)
		free_if_alive()


func _on_lifetime_timer_timeout() -> void:
	free_if_alive()


func free_if_alive() -> void:
	if !is_queued_for_deletion():
		queue_free()
