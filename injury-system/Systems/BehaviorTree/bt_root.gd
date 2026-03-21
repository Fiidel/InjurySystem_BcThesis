@icon("uid://dfe3o2gbxl7pw")

class_name BTRoot
extends BTNode

var blackboard: Blackboard
var current_child_idx: int = 0


func _ready() -> void:
	blackboard = Blackboard.new()
	construct_tree()
	execute()

func execute() -> void:
	if child_nodes.is_empty():
		return
	current_child_idx = 0
	child_nodes[current_child_idx].execute()


func _on_child_finished(_return_status: ReturnStatus) -> void:
	current_child_idx += 1
	if current_child_idx == child_nodes.size():
		current_child_idx = 0
	child_nodes[current_child_idx].execute()
