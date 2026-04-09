@icon("uid://mjhf4md8bf2a")

class_name BTSequence
extends BTNode

var current_child_idx: int = 0

func _ready() -> void:
	for child in child_nodes:
		child.finished.connect(_on_child_finished)

func execute() -> void:
	if child_nodes.is_empty():
		finished.emit(ReturnStatus.SUCCESS)
		return
	current_child_idx = 0
	child_nodes[current_child_idx].execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	if return_status == ReturnStatus.FAILURE:
		finished.emit(ReturnStatus.FAILURE)
		return
	current_child_idx += 1
	if current_child_idx == len(child_nodes):
		finished.emit(ReturnStatus.SUCCESS)
	else:
		child_nodes[current_child_idx].execute()


func abort() -> void:
	if not child_nodes.is_empty() and current_child_idx >= 0 and current_child_idx < child_nodes.size():
		child_nodes[current_child_idx].abort()
