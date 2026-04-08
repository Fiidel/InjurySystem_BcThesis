@icon("uid://cwmchu2uav4sm")

class_name BodyPartKnockback3D
extends SkeletonModifier3D

const KNOCKBACK_SPEED: float = 8.0
var active_knockbacks = {}  # bone_idx -> {target_offset, progress, is_returning}


func add_knockback(bone_index: int, hit_direction: Vector3, strength: float = 0.5):
	active_knockbacks[bone_index] = {
		"target_offset": hit_direction * strength,
		"progress": 0.0,
		"is_returning": false
	}


func _process_modification_with_delta(delta: float) -> void:
	var skeleton = get_skeleton()
	if not skeleton:
		return
	
	var to_remove = []
	
	for bone_index in active_knockbacks:
		var kb = active_knockbacks[bone_index]
		if kb.is_returning:
			kb.progress -= delta * KNOCKBACK_SPEED
			if kb.progress <= 0:
				to_remove.append(bone_index)
		else:
			kb.progress += delta * KNOCKBACK_SPEED
			if kb.progress >= 1:
				kb.is_returning = true
				kb.progress = 1.0
		
		var current_offset = lerp(Vector3.ZERO, kb.target_offset, kb.progress)
		var anim_pos = skeleton.get_bone_pose_position(bone_index)
		skeleton.set_bone_pose_position(bone_index, anim_pos + current_offset)
	
	for bone_index in to_remove:
		active_knockbacks.erase(bone_index)
