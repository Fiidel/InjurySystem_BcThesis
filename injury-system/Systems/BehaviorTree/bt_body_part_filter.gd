@icon("uid://bbevyfjs4e0oa")

class_name BTBodyPartFilter
extends BTDecorator

@export var body_part: BodyPart


func _ready() -> void:
	if body_part == null:
		push_error("Error: Body Part of BTBodyPartFilter " + name + "not set.")
		return


func execute() -> void:
	if not body_part.is_destroyed:
		child.execute()
	else:
		finished.emit(ReturnStatus.FAILURE)


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)
