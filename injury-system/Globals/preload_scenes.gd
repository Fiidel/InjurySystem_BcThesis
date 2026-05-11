extends CanvasLayer

@export var projectile_scenes: Array[PackedScene]
@export var manticore_scene: PackedScene
@export var other_scenes: Array[PackedScene]

@onready var blackout_panel: PanelContainer = $BlackoutPanel


func _ready() -> void:
	await preload_scenes()
	await preload_projectiles()
	await preload_manticore_hit_flash()
	
	# turn off loading screen
	blackout_panel.hide()


func preload_scenes() -> void:
	for scene in other_scenes:
		var instance := scene.instantiate()
		add_child(instance)
		await get_tree().process_frame
		instance.queue_free()


func preload_projectiles() -> void:
	for scene in projectile_scenes:
		var projectile := scene.instantiate() as Projectile
		if projectile == null:
			continue

		add_child(projectile)
		projectile.projectile_direction = Vector3(0, 0, -1)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		await spawn_impact_particles(projectile)
		await spawn_decal(projectile)
		await spawn_projectile_fragments(projectile)
		projectile.queue_free()


func spawn_impact_particles(projectile: Projectile) -> void:
	if projectile.impact_particles_scene == null:
		return
	var particles := projectile.impact_particles_scene.instantiate()
	if particles == null:
		return
	projectile.add_child(particles)
	set_emitting(particles, true)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	set_emitting(particles, false)
	particles.queue_free()


func set_emitting(node: Node, emitting: bool) -> void:
	if node is GPUParticles3D:
		(node as GPUParticles3D).emitting = emitting
	else:
		for child in node.get_children():
			set_emitting(child, emitting)


func spawn_decal(projectile: Projectile) -> void:
	var params := projectile.decal_params
	if params == null or params.texture == null:
		return
	var decal := Decal.new()
	decal.cull_mask = 1
	decal.texture_albedo = params.texture
	decal.texture_normal = params.texture_normal
	decal.size = Vector3(params.width, params.depth, params.height)
	projectile.add_child(decal)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	decal.queue_free()


func spawn_projectile_fragments(projectile: Projectile) -> void:
	if projectile.projectile_fragments_scene == null:
		return
	var fragments := projectile.projectile_fragments_scene.instantiate()
	if fragments == null:
		return
	projectile.add_child(fragments)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	fragments.queue_free()


func preload_manticore_hit_flash() -> void:
	if manticore_scene == null:
		return

	var manticore_instance := manticore_scene.instantiate() as BodyPart
	if manticore_instance == null:
		return
	add_child(manticore_instance)
	await get_tree().process_frame
	
	var flash_tween := manticore_instance.play_hit_flash()
	if flash_tween:
		await flash_tween.finished

	if manticore_instance.mesh:
		var fade_tween := create_tween()
		fade_tween.tween_property(manticore_instance.mesh, "transparency", 1.0, 0.1)
		await fade_tween.finished

	manticore_instance.queue_free()
	await get_tree().process_frame
