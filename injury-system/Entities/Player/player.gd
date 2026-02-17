class_name Player
extends CharacterBody3D

@onready var camera: Camera3D = $Camera3D
@onready var ability_label: Label = %AbilityLabel
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.01
const SLASH = preload("res://Entities/Player/Projectiles/slash.tscn")
const BOULDER = preload("res://Entities/Player/Projectiles/boulder.tscn")
const STAR = preload("res://Entities/Player/Projectiles/star.tscn")
var abilities: Dictionary
var current_ability: int

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	abilities[1] = "Slash"
	abilities[2] = "Bludgeon"
	abilities[3] = "Pierce"
	current_ability = 1
	ability_label.text = "1. " + abilities[1]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	if event.is_action_pressed("activate_ability"):
		if current_ability == 1:
			spawn_projectile(SLASH)
		if current_ability == 2:
			spawn_projectile(BOULDER)
		if current_ability == 3:
			spawn_projectile(STAR)
	if event.is_action_pressed("ability_1"):
		current_ability = 1
		ability_label.text = "1. " + abilities[1]
	if event.is_action_pressed("ability_2"):
		current_ability = 2
		ability_label.text = "2. " + abilities[2]
	if event.is_action_pressed("ability_3"):
		current_ability = 3
		ability_label.text = "3. " + abilities[3]
	

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func spawn_projectile(projectile_type: PackedScene) -> void:
	var projectile = projectile_type.instantiate() as Projectile
	projectile.direction = -camera.global_transform.basis.z
	get_tree().root.add_child(projectile)
	projectile.global_position = global_position + Vector3(0,1.25,0)
