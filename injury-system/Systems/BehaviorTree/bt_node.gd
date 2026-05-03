@abstract class_name BTNode
extends Node

signal finished(status: ReturnStatus)

enum ReturnStatus {
	RUNNING,
	SUCCESS,
	FAILURE
}

var blackboard: Blackboard
var child_nodes: Array[BTNode] = []


func add_bt_child(node: BTNode) -> void:
	child_nodes.append(node)


func remove_bt_child(node: BTNode) -> void:
	var index: int = child_nodes.find(node)
	child_nodes.remove_at(index)


func construct_tree(bb: Blackboard) -> void:
	blackboard = bb
	var scene_child_nodes = get_children()
	# add children to array and call their own construct func
	for child in scene_child_nodes:
		if child is BTNode:
			add_bt_child(child)
			child.construct_tree(bb)
		# error: child not based on BTNode
		else:
			push_error("Child " + child.name + " is not a BTNode.")
			return
	# connect the finished signals of each child
	for child in child_nodes:
		child.finished.connect(_on_child_finished)


# to be overridden by subclasses
func _on_child_finished(_return_status: ReturnStatus) -> void:
	pass


# cleanup func for interruptable nodes; to be overridden by subclasses
func abort() -> void:
	pass


@abstract func execute() -> void
