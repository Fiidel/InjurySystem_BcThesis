class_name BTRoot
extends BTNode

var current_child_idx: int = 0

func _ready() -> void:
	for child in child_nodes:
		child.finished.connect(_on_child_finished)
	# initialize blackboard
	blackboard = {}

func execute() -> void:
	# Execute first child
	current_child_idx = 0
	child_nodes[current_child_idx].execute()
	current_child_idx += 1

func _on_child_finished(return_status: ReturnStatus) -> void:
	# keep executing children infinitely
	if current_child_idx == len(child_nodes):
		current_child_idx = 0
	child_nodes[current_child_idx].execute()
	current_child_idx += 1
