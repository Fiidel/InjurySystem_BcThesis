class_name MovementParticles
extends Node3D

@export var body: CharacterBody3D
@export_range(1, 20, 1) var landing_particle_amount: int = 8
@export_range(0.1, 5.0, 0.1) var landing_spawn_radius: float = 1.0
@export_range(1, 20, 1) var trail_particle_amount: int = 4
@export_range(0.05, 2.0, 0.01) var movement_trail_spawn_interval: float = 0.2
@export var trail_minimum_movement_speed: float = 1.0
@export_range(0.0, 2.0, 0.01) var movement_spawn_radius: float = 0.25

@onready var trail_origin: Marker3D = $TrailOrigin
@onready var particle_scene: PackedScene = preload("uid://btvy3lrgegxs2")
var movement_trail_timer: Timer
var rng := RandomNumberGenerator.new()
var was_on_floor: bool = false


func _ready() -> void:
	movement_trail_timer = Timer.new()
	movement_trail_timer.one_shot = true
	movement_trail_timer.autostart = true
	movement_trail_timer.wait_time = movement_trail_spawn_interval
	movement_trail_timer.timeout.connect(on_movement_trail_timer_timeout)
	add_child(movement_trail_timer)
	was_on_floor = body != null and body.is_on_floor()


func _physics_process(_delta: float) -> void:
	if body == null:
		return

	if not was_on_floor and body.is_on_floor():
		spawn_particles(body.global_position, landing_particle_amount, landing_spawn_radius)
	was_on_floor = body.is_on_floor()


func spawn_particles(origin: Vector3, particle_amount: int, spawn_radius: float) -> void:
	if particle_scene == null:
		return

	for i in particle_amount:
		var spawned_particles := particle_scene.instantiate() as GPUParticles3D
		if spawned_particles == null:
			continue

		add_child(spawned_particles)
		var random_offset := random_horizontal_offset(spawn_radius)
		spawned_particles.global_position = origin + random_offset
		spawned_particles.one_shot = true
		spawned_particles.finished.connect(spawned_particles.queue_free)
		spawned_particles.restart()
		spawned_particles.emitting = true


func on_movement_trail_timer_timeout() -> void:
	if trail_origin == null or body == null:
		return
	
	# if the enemy is not on the floor or not moving, restart the timer but don't spawn particles
	var horizontal_speed := Vector2(body.velocity.x, body.velocity.z).length()
	if not body.is_on_floor() or horizontal_speed < trail_minimum_movement_speed:
		movement_trail_timer.wait_time = movement_trail_spawn_interval
		movement_trail_timer.start()
		return
	
	# otherwise spawn particles and reset timer
	spawn_particles(trail_origin.global_position, trail_particle_amount, movement_spawn_radius)
	movement_trail_timer.wait_time = movement_trail_spawn_interval
	movement_trail_timer.start()


func random_horizontal_offset(radius: float) -> Vector3:
	var angle := rng.randf_range(0.0, TAU)
	var distance := sqrt(rng.randf()) * radius
	return Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
