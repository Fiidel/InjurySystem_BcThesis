class_name BTSelector
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

# Excute child nodes until one succeeds
func _on_child_finished(return_status: ReturnStatus) -> void:
	# Last child - node is finished, return the result of the last child
	if current_child_idx == len(child_nodes):
		finished.emit(return_status)
	# Return success if child succeeded, else execute next child
	else:
		if return_status == ReturnStatus.SUCCESS:
			finished.emit(ReturnStatus.SUCCESS)
		elif return_status == ReturnStatus.FAILURE:
			child_nodes[current_child_idx].execute()
			current_child_idx += 1
