class_name BTSequence
extends BTNode

var current_child_idx: int = 0

func _ready() -> void:
	for child in child_nodes:
		child.finished.connect(_on_child_finished)

func execute() -> void:
	# Execute first child
	current_child_idx = 0
	child_nodes[current_child_idx].execute()
	current_child_idx += 1

func _on_child_finished(return_status: ReturnStatus) -> void:
	# Last child - node is finished, return the result of the last child
	if current_child_idx == len(child_nodes):
		finished.emit(return_status)
	# Failure of any child results in the immediate failure of the node
	else:
		if return_status == ReturnStatus.FAILURE:
			finished.emit(ReturnStatus.FAILURE)
		elif return_status == ReturnStatus.SUCCESS:
			child_nodes[current_child_idx].execute()
			current_child_idx += 1
