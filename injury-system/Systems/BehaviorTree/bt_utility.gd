@icon("uid://dqjj7uhv5m08x")

class_name BTUtility
extends BTDecorator

var utility: float = 1.0


func execute() -> void:
	if child == null:
		finished.emit(ReturnStatus.FAILURE)
		return
	child.execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)


func get_utility() -> float:
	return utility
