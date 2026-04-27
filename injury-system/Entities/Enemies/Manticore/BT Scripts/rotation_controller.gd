class_name RotationController
extends RefCounted

var tracking_window_min: float = 0.6
var tracking_window_max: float = 0.9
var lock_window_min: float = 0.2
var lock_window_max: float = 0.4

var tracking_time_left: float = 0.0
var lock_time_left: float = 0.0
var random_generator := RandomNumberGenerator.new()


func _init() -> void:
	random_generator.randomize()


func reset() -> void:
	tracking_time_left = 0.0
	lock_time_left = 0.0


func can_rotate(delta: float) -> bool:
	# if lock window is active, do not rotate
	if lock_time_left > 0.0:
		lock_time_left -= delta
		return false

	tracking_time_left -= delta

	# reset tracking and lock windows after tracking window expires
	if tracking_time_left <= 0.0:
		lock_time_left = generate_random_window(lock_window_min, lock_window_max)
		tracking_time_left = generate_random_window(tracking_window_min, tracking_window_max)
		if lock_time_left > 0.0:
			return false

	return true


func generate_random_window(min_value: float, max_value: float) -> float:
	# safeguard if min is greater than max
	if min_value >= max_value:
		return min_value
	# generate a random float between min and max
	return random_generator.randf_range(min_value, max_value)
