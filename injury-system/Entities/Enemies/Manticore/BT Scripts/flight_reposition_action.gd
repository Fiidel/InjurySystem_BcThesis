extends BTAction


func execute() -> void:
	print("flight reposition!")
	await get_tree().create_timer(1.0).timeout
	finished.emit(ReturnStatus.SUCCESS)
