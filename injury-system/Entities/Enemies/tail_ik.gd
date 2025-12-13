class_name TailIK
extends SkeletonIK3D

@onready var attach_point: Marker3D = $Marker3D
var original_position: Vector3
var original_rotation: Vector3

func _ready():
	original_position = attach_point.position
	original_rotation = attach_point.rotation
	start()
	wiggle_tail()

func generate_random_position_offset() -> Vector3:
	return Vector3(randfn(0, 0.5), randfn(0, 0.1), 0)

func generate_random_rotation_offset() -> Vector3:
	return Vector3(randfn(0, 0.1), randfn(0, 0.1), randfn(0, 0.2))

func generate_random_time_offset() -> float:
	return randf_range(0, 0.75)

func wiggle_tail():
	while true:
		var random_position_offset: Vector3 = generate_random_position_offset()
		var random_rotation_offset: Vector3 = generate_random_rotation_offset()
		var random_time_offset: float = generate_random_time_offset()

		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(attach_point, "position", original_position + random_position_offset, 1 + random_time_offset)
		tween.tween_property(attach_point, "rotation", original_rotation + random_rotation_offset, 1 + random_time_offset)
		
		await tween.finished
		tween.kill()
