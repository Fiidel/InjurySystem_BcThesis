@icon("uid://cw8uroox0ciu")

class_name BTRandomizer
extends BTNode

var selected_child_idx: int = -1
var executable_children: Array[BTNode] = []


func execute() -> void:
	selected_child_idx = -1
	executable_children = get_executable_children()
	if executable_children.is_empty():
		finished.emit(ReturnStatus.FAILURE)
		return

	selected_child_idx = randi_range(0, executable_children.size() - 1)
	executable_children[selected_child_idx].execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)


func abort() -> void:
	if not executable_children.is_empty() and selected_child_idx >= 0 and selected_child_idx < executable_children.size():
		executable_children[selected_child_idx].abort()


func get_executable_children() -> Array[BTNode]:
	var valid_children: Array[BTNode] = []
	for child in child_nodes:
		if is_node_currently_selectable(child):
			valid_children.append(child)
	return valid_children


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
