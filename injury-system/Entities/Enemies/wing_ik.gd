class_name WingIK
extends SkeletonIK3D

@export var is_right_wing: bool
@onready var attach_point: Marker3D = $Marker3D
var start_position: Vector3
var start_rotation: Vector3
var end_position: Vector3
var end_rotation: Vector3

func _ready() -> void:
	start_position = attach_point.position
	start_rotation = attach_point.rotation
	
	# end position and rotation checking
	if is_right_wing:
		end_position = attach_point.position - Vector3(-2, 2, 0)
		end_rotation = attach_point.rotation + Vector3(0.1, 0.8, 0.6)
	else:
		end_position = attach_point.position  - Vector3(2, 2, 0)
		end_rotation = attach_point.rotation - Vector3(0.1, 0.8, 0.6)
	# start IK
	start()

func flap_down(position_offset: Vector3, rotation_offset: Vector3, time_offset: float) -> Tween:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "attach_point:position", end_position + position_offset, 1.5 + time_offset)
	tween.tween_property(self, "attach_point:rotation", end_rotation + rotation_offset, 1.5 + time_offset)
	return tween

func flap_up(position_offset: Vector3, rotation_offset: Vector3, time_offset: float) -> Tween:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "attach_point:position", start_position + position_offset, 1.5 + time_offset)
	tween.tween_property(self, "attach_point:rotation", start_rotation + rotation_offset, 1.5 + time_offset)
	return tween
