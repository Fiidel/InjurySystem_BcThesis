class_name BTAction
extends BTNode

func execute() -> void:
	print("Action node " + node_name)
	await get_tree().create_timer(2).timeout
	finished.emit(ReturnStatus.SUCCESS) 
