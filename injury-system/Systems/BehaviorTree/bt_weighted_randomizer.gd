@icon("uid://5gkcutqds4od")

class_name BTWeightedRandomizer
extends BTNode

@export var avoid_repeating_child_node: bool = false

var selected_child: BTNode = null
var previously_executed_child: BTNode = null


func execute() -> void:
	selected_child = null
	var weighted_nodes: Array[Dictionary] = get_weighted_executable_children()
	if weighted_nodes.is_empty():
		finished.emit(ReturnStatus.FAILURE)
		return

	if avoid_repeating_child_node and weighted_nodes.size() > 1 and previously_executed_child != null:
		var rerolled_weighted_nodes: Array[Dictionary] = []
		for entry in weighted_nodes:
			if entry.node != previously_executed_child:
				rerolled_weighted_nodes.append(entry)
		weighted_nodes = rerolled_weighted_nodes

	if weighted_nodes.is_empty():
		finished.emit(ReturnStatus.FAILURE)
		return

	# choose random child based on weights
	var total_weight: float = 0.0
	for entry in weighted_nodes:
		total_weight += entry.weight
	
	var random_value: float = randf_range(0.0, total_weight)
	var current_ceiling: float = 0.0
	for entry in weighted_nodes:
		current_ceiling += entry.weight
		if random_value <= current_ceiling:
			selected_child = entry.node
			break
	# failsafe
	if selected_child == null:
		finished.emit(ReturnStatus.FAILURE)
		return

	# execute chosen child
	previously_executed_child = selected_child
	selected_child.execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)


func abort() -> void:
	if selected_child != null:
		selected_child.abort()


func get_weighted_executable_children() -> Array[Dictionary]:
	var weighted_children: Array[Dictionary] = []
	for child in child_nodes:
		# do not add nodes that are filtered out
		if not is_node_currently_selectable(child):
			continue

		# default weight is 1.0
		var weight: float = 1.0

		var weight_node: BTWeight = child as BTWeight
		if weight_node != null:
			# skip nodes that don't have a positive weight
			if weight_node.weight <= 0.0:
				continue
			# overwrite the default weight with the actual weight of a BTWeight
			weight = weight_node.weight

		weighted_children.append({
			"node": child,
			"weight": weight
		})
	return weighted_children


func is_node_currently_selectable(node: BTNode) -> bool:
	var current_node: BTNode = node
	while true:
		# if the node is not a decorator, add it directly to the valid children
		var decorator: BTDecorator = current_node as BTDecorator
		if decorator == null:
			return true

		# if the node is a body part filter recheck, add it as valid if all body parts are available
		var body_part_filter_recheck: BTBodyPartFilterRecheck = current_node as BTBodyPartFilterRecheck
		if body_part_filter_recheck != null and body_part_filter_recheck.is_any_body_part_unavailable():
			return false

		# if the node is a body part filter, add it as valid if all body parts are available
		var body_part_filter: BTBodyPartFilter = current_node as BTBodyPartFilter
		if body_part_filter != null and body_part_filter.is_any_body_part_unavailable():
			return false

		# if the node has no child, it is not selectable
		if decorator.child == null:
			return false

		# move to the next node
		current_node = decorator.child
	# if the node is not a decorator and has no child, return false
	return false
