@icon("uid://byl71ix7sn4ny")

class_name BTWeight
extends BTDecorator

@export_range(0.0, 1000.0, 0.01) var weight: float = 1.0


func execute() -> void:
	if child == null:
		finished.emit(ReturnStatus.FAILURE)
		return
	child.execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)
