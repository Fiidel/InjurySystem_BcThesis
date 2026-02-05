class_name BTAction
extends BTNode

@export var return_success: bool = true # for testing

func execute() -> void:
	print("Action node " + node_name)
	await get_tree().create_timer(0.5).timeout
	if return_success:
		finished.emit(ReturnStatus.SUCCESS)
	else:
		finished.emit(ReturnStatus.FAILURE)
