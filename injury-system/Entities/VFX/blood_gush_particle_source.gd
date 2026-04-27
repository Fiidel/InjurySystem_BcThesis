class_name BloodGushParticleSource
extends Marker3D

@export var severed_body_part: BodyPart
@onready var blood_particles_scene: PackedScene = preload("uid://dalqw5lx4vbr7")


func _ready() -> void:
	if severed_body_part != null:
		SignalBus.body_part_destroyed.connect(on_body_part_destroyed)


func on_body_part_destroyed(body_part: BodyPart) -> void:
	if body_part != severed_body_part:
		return
	
	var blood_particles_instance: GPUParticles3D = blood_particles_scene.instantiate()
	add_child(blood_particles_instance)
	blood_particles_instance.global_position = self.global_position
	blood_particles_instance.emitting = true

	var duration: float = randf_range(6.0, 15.0)
	await get_tree().create_timer(duration).timeout
	blood_particles_instance.emitting = false

	# reactivate periodically
	while is_instance_valid(blood_particles_instance):
		var off_duration: float = randf_range(1.0, 3.0)
		await get_tree().create_timer(off_duration).timeout
		blood_particles_instance.emitting = true
		var on_duration: float = randf_range(1.0, 2.0)
		await get_tree().create_timer(on_duration).timeout
		blood_particles_instance.emitting = false
