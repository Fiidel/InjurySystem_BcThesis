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

	var manticore_instance := manticore_scene.instantiate()
	add_child(manticore_instance)
	await get_tree().process_frame

	var body := manticore_instance.get_node_or_null("Body")
	var body_part := find_first_body_part(body)
	if body_part:
		body_part.play_hit_flash()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

	manticore_instance.queue_free()
	await get_tree().process_frame


func find_first_body_part(body: Node) -> BodyPart:
	if body == null:
		return null

	for child in body.get_children():
		if child is BodyPart:
			return child as BodyPart

	return null
