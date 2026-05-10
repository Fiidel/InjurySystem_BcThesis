extends CanvasLayer

@export var scenes_to_preload: Array[PackedScene]
@export var manticore_scene: PackedScene

@onready var blackout_panel: PanelContainer = $BlackoutPanel


func _ready() -> void:
	await preload_scenes()
	await preload_manticore_hit_flash()
	
	# turn off loading screen
	blackout_panel.hide()


func preload_scenes() -> void:
	for scene in scenes_to_preload:
		var instance := scene.instantiate()
		add_child(instance)
		await get_tree().process_frame
		instance.queue_free()
		await get_tree().process_frame


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
