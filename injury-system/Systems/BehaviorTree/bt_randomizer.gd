@icon("uid://cw8uroox0ciu")

class_name BTRandomizer
extends BTNode

var selected_child_idx: int = -1


func execute() -> void:
	selected_child_idx = -1
	if child_nodes.is_empty():
		finished.emit(ReturnStatus.FAILURE)
		return

	selected_child_idx = randi_range(0, child_nodes.size() - 1)
	child_nodes[selected_child_idx].execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)


func abort() -> void:
	if not child_nodes.is_empty() and selected_child_idx >= 0 and selected_child_idx < child_nodes.size():
		child_nodes[selected_child_idx].abort()
