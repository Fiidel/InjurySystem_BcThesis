@icon("uid://cd21riu2uoqlq")

class_name BTPriorityReselector
extends BTNode

var current_child_idx: int = 0
var recheck_timer: Timer


func execute() -> void:
	if child_nodes.is_empty():
		finished.emit(ReturnStatus.FAILURE)
		return
	# start condition recheck interval
	recheck_timer = Timer.new()
	recheck_timer.wait_time = 1.0
	recheck_timer.one_shot = false
	recheck_timer.autostart = true
	add_child(recheck_timer)
	recheck_timer.timeout.connect(on_recheck_conditions)
	
	# activate the first child node
	current_child_idx = 0
	child_nodes[current_child_idx].execute()


func _on_child_finished(return_status: ReturnStatus) -> void:
	# on successful and complete child execution, return success
	if return_status == ReturnStatus.SUCCESS:
		cleanup_recheck_timer()
		finished.emit(ReturnStatus.SUCCESS)
		return
	# on failure, execute the next child node
	if return_status == ReturnStatus.FAILURE:
		current_child_idx += 1
		if current_child_idx >= len(child_nodes):
			cleanup_recheck_timer()
			finished.emit(ReturnStatus.FAILURE)
		else:
			child_nodes[current_child_idx].execute()


func on_recheck_conditions() -> void:
	# recheck conditions for child nodes before the current one
	if current_child_idx <= 0:
		return
	for i in range(current_child_idx):
		var condition_node: BTCondition = child_nodes[i] as BTCondition
		# skip non-condition nodes
		if condition_node == null:
			continue
		# skip invalid condition callables
		if condition_node.condition == null or not condition_node.condition.is_valid():
			continue
		# call the condition callable and check if it returns true
		var condition_result: Variant = condition_node.condition.call()
		if condition_result == true:
			# abort current child and start executing the child node with the higher priority whose condition is true
			child_nodes[current_child_idx].abort()
			current_child_idx = i
			child_nodes[current_child_idx].execute()
			return


func abort() -> void:
	cleanup_recheck_timer()
	if not child_nodes.is_empty() and current_child_idx >= 0 and current_child_idx < child_nodes.size():
		child_nodes[current_child_idx].abort()


func cleanup_recheck_timer() -> void:
	if recheck_timer == null:
		return
	if not is_instance_valid(recheck_timer):
		recheck_timer = null
		return
	if recheck_timer.timeout.is_connected(on_recheck_conditions):
		recheck_timer.timeout.disconnect(on_recheck_conditions)
	recheck_timer.stop()
	remove_child(recheck_timer)
	recheck_timer.queue_free()
	recheck_timer = null
