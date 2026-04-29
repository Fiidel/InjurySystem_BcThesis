@icon("uid://bdmt676laca5f")

class_name BTUtilityRandomizer
extends BTNode

@export var avoid_repeating_child_node: bool = false

var selected_child: BTNode = null
var previously_executed_child: BTNode = null


func execute() -> void:
	selected_child = null
	var weighted_nodes: Array[Dictionary] = get_utility_weighted_children()
	if weighted_nodes.is_empty():
		finished.emit(ReturnStatus.FAILURE)
		return

	# for avoid_repeating_child_node: construct a new list to choose from without the child that was previously executed
	if avoid_repeating_child_node and weighted_nodes.size() > 1 and previously_executed_child != null:
		var rerolled_weighted_nodes: Array[Dictionary] = []
		for entry in weighted_nodes:
			if entry.node != previously_executed_child:
				rerolled_weighted_nodes.append(entry)
		weighted_nodes = rerolled_weighted_nodes

	if weighted_nodes.is_empty():
		finished.emit(ReturnStatus.FAILURE)
		return

	# select a random child based on the utility weights
	var total_utility: float = 0.0
	for entry in weighted_nodes:
		total_utility += entry.utility

	var random_value: float = randf_range(0.0, total_utility)
	var current_ceiling: float = 0.0
	for entry in weighted_nodes:
		current_ceiling += entry.utility
		if random_value <= current_ceiling:
			selected_child = entry.node
			break

	if selected_child == null:
		finished.emit(ReturnStatus.FAILURE)
		return

	previously_executed_child = selected_child
	selected_child.execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)


func abort() -> void:
	if selected_child != null:
		selected_child.abort()


func get_utility_weighted_children() -> Array[Dictionary]:
	var weighted_children: Array[Dictionary] = []
	for child in child_nodes:
		if not is_node_currently_selectable(child):
			continue

		var utility: float = get_utility_from_node(child)
		if utility <= 0.0:
			continue

		weighted_children.append({
			"node": child,
			"utility": utility
		})
	return weighted_children


func get_utility_from_node(node: BTNode) -> float:
	# iterate through all decorators until BTUtility
	var current_node: BTNode = node
	while true:
		var utility_node: BTUtility = current_node as BTUtility
		# utility_node is not null == conversion to BTUtility succeeded, it is a BTUtility node
		if utility_node != null:
			return max(utility_node.get_utility(), 0.0)

		# continue to the next decorator or break due to the next child not being a decorator
		var decorator: BTDecorator = current_node as BTDecorator
		if decorator == null or decorator.child == null:
			break
		current_node = decorator.child

	# default utility weight
	return 1.0


func is_node_currently_selectable(node: BTNode) -> bool:
	var current_node: BTNode = node
	while true:
		var decorator: BTDecorator = current_node as BTDecorator

		# not a decorator
		if decorator == null:
			return true

		# filter out branches with destroyed body parts
		var body_part_filter_recheck: BTBodyPartFilterRecheck = current_node as BTBodyPartFilterRecheck
		if body_part_filter_recheck != null and body_part_filter_recheck.is_any_body_part_unavailable():
			return false

		var body_part_filter: BTBodyPartFilter = current_node as BTBodyPartFilter
		if body_part_filter != null and body_part_filter.is_any_body_part_unavailable():
			return false

		# no executable decorator child
		if decorator.child == null:
			return false

		# continue to the next decorator/node
		current_node = decorator.child
	# fallback
	return false
