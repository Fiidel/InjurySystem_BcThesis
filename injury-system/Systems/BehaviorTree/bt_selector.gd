@icon("uid://c4o6eeatdjrdy")

class_name BTSelector
extends BTNode

var current_child_idx: int = 0

func execute() -> void:
	if child_nodes.is_empty():
		finished.emit(ReturnStatus.FAILURE)
		return
	current_child_idx = 0
	child_nodes[current_child_idx].execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	if return_status == ReturnStatus.SUCCESS:
		finished.emit(ReturnStatus.SUCCESS)
		return
	current_child_idx += 1
	if current_child_idx >= len(child_nodes):
		finished.emit(ReturnStatus.FAILURE)
	else:
		child_nodes[current_child_idx].execute()
