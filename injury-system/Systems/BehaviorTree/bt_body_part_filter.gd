@icon("uid://bbevyfjs4e0oa")

class_name BTBodyPartFilter
extends BTDecorator

@export var body_parts: Array[BodyPart] = []


func _ready() -> void:
	if body_parts.is_empty():
		push_error("Error: Body parts of BTBodyPartFilter " + name + " not set.")
		return


func execute() -> void:
	if is_any_body_part_unavailable():
		finished.emit(ReturnStatus.FAILURE)
		return
	child.execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)


func is_any_body_part_unavailable() -> bool:
	for body_part in body_parts:
		if body_part.is_destroyed:
			return true
	return false
