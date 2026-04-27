extends BTAction

@export var body: Body


func execute() -> void:
	if body != null:
		body.call_deferred("activate_ragdoll")
	finished.emit(ReturnStatus.FAILURE)
