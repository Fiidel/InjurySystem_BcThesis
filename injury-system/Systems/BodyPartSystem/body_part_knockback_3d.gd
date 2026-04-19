@tool
@icon("uid://cwmchu2uav4sm")

class_name BodyPartKnockback3D
extends SkeletonModifier3D

const KNOCKBACK_SPEED: float = 12.0
const MASS_BASE_MULTIPLIER: float = 0.5

@export var skeleton: Skeleton3D:
	set(value):
		if skeleton == value:
			return
		skeleton = value
		notify_property_list_changed()
@export var mass_base_bone: StringName
var active_knockbacks = {}  # bone_idx -> {target_offset, progress, is_returning}


func _validate_property(property: Dictionary) -> void:
	# get the bone names and set it as the hint string enum
	if property.name == &"mass_base_bone" and skeleton != null:
		var hint_string := String(skeleton.get_concatenated_bone_names())
		if hint_string.is_empty():
			return
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = hint_string


func add_knockback(bone_index: int, direction: Vector3, strength: float):
	active_knockbacks[bone_index] = {
		"target_offset": direction * strength,
		"progress": 0.0,
		"is_returning": false
	}

	# main body knockback
	var current_skeleton := get_skeleton()
	if current_skeleton == null or mass_base_bone == StringName():
		return
	var mass_base_index := current_skeleton.find_bone(mass_base_bone)
	if mass_base_index == -1 or mass_base_index == bone_index:
		return
	direction = Vector3(direction.x, 0.0, direction.z)
	active_knockbacks[mass_base_index] = {
		"target_offset": direction * strength * MASS_BASE_MULTIPLIER,
		"progress": 0.0,
		"is_returning": false
	}


func _process_modification_with_delta(delta: float) -> void:
	if not skeleton:
		return
	
	var to_remove = []
	
	for bone_index in active_knockbacks:
		var kb = active_knockbacks[bone_index]
		if kb.is_returning:
			kb.progress -= delta * KNOCKBACK_SPEED * 0.5 # slower when returning
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
