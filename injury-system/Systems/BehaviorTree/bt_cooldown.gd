@icon("uid://8ounyk2fj1hy")

class_name BTCooldown
extends BTDecorator

@export var cooldown_time: float = 1.0
var is_available: bool = true


func execute() -> void:
	if !is_available:
		finished.emit(ReturnStatus.FAILURE)
		return
	go_on_cooldown()
	child.execute()


func _on_cooldown_timer_timeout() -> void:
	is_available = true


func _on_child_finished(return_status: ReturnStatus) -> void:
	finished.emit(return_status)


func go_on_cooldown() -> void:
	is_available = false
	get_tree().create_timer(cooldown_time).timeout.connect(_on_cooldown_timer_timeout)
