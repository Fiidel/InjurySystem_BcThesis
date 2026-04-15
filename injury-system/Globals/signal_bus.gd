extends Node

signal body_part_destroyed

const BODY_PART_DESTROY_TIME_SCALE := 0.2
const BODY_PART_DESTROY_SLOW_SECONDS := 1.0

var _time_restore_timer: Timer


func _ready() -> void:
	_time_restore_timer = Timer.new()
	_time_restore_timer.one_shot = true
	_time_restore_timer.wait_time = BODY_PART_DESTROY_SLOW_SECONDS
	_time_restore_timer.ignore_time_scale = true
	_time_restore_timer.timeout.connect(_restore_time_scale)
	add_child(_time_restore_timer)
	body_part_destroyed.connect(_on_body_part_destroyed_time_emphasis)


func _on_body_part_destroyed_time_emphasis() -> void:
	Engine.time_scale = BODY_PART_DESTROY_TIME_SCALE
	_time_restore_timer.stop()
	_time_restore_timer.start()


func _restore_time_scale() -> void:
	Engine.time_scale = 1.0
