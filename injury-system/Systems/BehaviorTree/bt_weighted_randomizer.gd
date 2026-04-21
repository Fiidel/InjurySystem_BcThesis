@icon("uid://5gkcutqds4od")

class_name BTWeightedRandomizer
extends BTNode

var selected_child: BTNode = null


func execute() -> void:
	selected_child = null
	if child_nodes.is_empty():
		finished.emit(ReturnStatus.FAILURE)
		return

	# get child nodes and their weights (default weight 1)
	var weighted_nodes: Dictionary = {}
	for child in child_nodes:
		var weight_node := child as BTWeight
		if weight_node == null:
			weighted_nodes[child] = 1.0
		else:
			# only add nodes with non-zero weight
			if weight_node.weight > 0.0:
				weighted_nodes[child] = weight_node.weight

	# choose random child based on weights
	var total_weight: float = 0.0
	for node in weighted_nodes:
		total_weight += weighted_nodes[node]
	
	var random_value: float = randf_range(0.0, total_weight)
	var current_ceiling: float = 0.0
	for node in weighted_nodes:
		current_ceiling += weighted_nodes[node]
		if random_value <= current_ceiling:
			selected_child = node
			break
	# failsafe
	if selected_child == null:
		finished.emit(ReturnStatus.FAILURE)
		return

	# execute chosen child
	selected_child.execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)


func abort() -> void:
	if selected_child != null:
		selected_child.abort()
