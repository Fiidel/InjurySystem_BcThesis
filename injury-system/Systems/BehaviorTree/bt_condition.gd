@icon("uid://c1lqbffssicjv")

class_name BTCondition
extends BTDecorator

var condition: Callable

func _ready() -> void:
	assert(condition != null, "BTCondition node %s requires a condition function." % name)
	assert(condition.is_valid(), "Invalid condition Callable.")
	for child in child_nodes:
		child.finished.connect(_on_child_finished)

func execute() -> void:
	# If the condition is true, continue to the child node. Otherwise, return a failure.
	var condition_result = condition.call()
	assert(typeof(condition_result) == TYPE_BOOL, "BTCondition Callable must return bool.")
	if condition_result == true:
		child.execute()
	else:
		finished.emit(ReturnStatus.FAILURE)

func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)
