@abstract class_name BTNode
extends Node

signal finished(status: ReturnStatus)

enum ReturnStatus {
	RUNNING,
	SUCCESS,
	FAILURE
}

@export var node_name: String = ""
var blackboard: Dictionary
var child_nodes: Array[BTNode] = []

func add_bt_child(node: BTNode) -> void:
	child_nodes.append(node)

func remove_bt_child(node: BTNode) -> void:
	var index: int = child_nodes.find(node)
	child_nodes.remove_at(index)

@abstract func execute() -> void
