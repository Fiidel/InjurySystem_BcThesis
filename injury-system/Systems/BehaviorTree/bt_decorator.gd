@abstract class_name BTDecorator
extends BTNode

var child: BTNode

# override to only allow 1 child
func add_bt_child(node: BTNode) -> void:
	child = node
	child_nodes = [node]
	add_child(node)
