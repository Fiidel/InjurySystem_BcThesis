@icon("uid://bbevyfjs4e0oa")

class_name BTBodyPartFilter
extends BTDecorator

@export var body_parts: Array[BodyPart] = []


func _ready() -> void:
	if body_parts.is_empty():
		push_error("Error: Body parts of BTBodyPartFilter " + name + " not set.")
		return


func execute() -> void:
	for body_part in body_parts:
		if body_part.is_destroyed:
			finished.emit(ReturnStatus.FAILURE)
			return

	child.execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)
