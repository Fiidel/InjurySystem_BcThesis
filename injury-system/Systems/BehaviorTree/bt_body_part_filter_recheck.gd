@icon("uid://o7l2bm84luhn")

class_name BTBodyPartFilterRecheck
extends BTBodyPartFilter

@export var recheck_interval: float = 1.0
var recheck_timer: Timer


func _ready() -> void:
	super._ready()


func execute() -> void:
	if is_any_body_part_unavailable():
		finished.emit(ReturnStatus.FAILURE)
		return
	
	cleanup_recheck_timer()
	recheck_timer = Timer.new()
	recheck_timer.wait_time = recheck_interval
	recheck_timer.one_shot = false
	recheck_timer.autostart = true
	add_child(recheck_timer)
	recheck_timer.timeout.connect(on_recheck_conditions)
	
	child.execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	cleanup_recheck_timer()
	super._on_child_finished(return_status)


func on_recheck_conditions() -> void:
	if not is_any_body_part_unavailable():
		return
	
	cleanup_recheck_timer()
	if child != null:
		child.abort()
	finished.emit(ReturnStatus.FAILURE)


func abort() -> void:
	cleanup_recheck_timer()
	super.abort()


func cleanup_recheck_timer() -> void:
	if recheck_timer == null:
		return
	if not is_instance_valid(recheck_timer):
		recheck_timer = null
		return
	if recheck_timer.timeout.is_connected(on_recheck_conditions):
		recheck_timer.timeout.disconnect(on_recheck_conditions)
	recheck_timer.stop()
	remove_child(recheck_timer)
	recheck_timer.queue_free()
	recheck_timer = null
