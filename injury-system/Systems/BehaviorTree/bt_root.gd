@icon("uid://enle37qryp01")

class_name BTRoot
extends BTNode

var current_child_idx: int = 0


func _init() -> void:
	blackboard = Blackboard.new()


func _ready() -> void:
	construct_tree(blackboard)
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
