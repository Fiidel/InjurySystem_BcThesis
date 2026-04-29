extends BTAction

@export var body: Body
@export var pursue_body_part_filters: Array[BTBodyPartFilter] = []


func execute() -> void:
	if not pursue_body_part_filters.is_empty() and is_missing_all_parts() and body != null:
		body.call_deferred("activate_ragdoll")
	finished.emit(ReturnStatus.FAILURE)


func is_missing_all_parts() -> bool:
	for filter in pursue_body_part_filters:
		if not filter.is_any_body_part_unavailable():
			return false
	return true
