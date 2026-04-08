@tool
@icon("uid://ct3ildyypbnxr")

class_name BoneKnockback3D
extends Node

@export var knockback_modifier: BodyPartKnockback3D
@export var skeleton: Skeleton3D:
	set(value):
		if skeleton == value:
			return
		skeleton = value
		notify_property_list_changed()
@export var bone_name: StringName


func _validate_property(property: Dictionary) -> void:
	# only validate the bone_name property
	if property.name != &"bone_name":
		return
	if skeleton == null:
		return
	# get the bone names and set it as the hint string enum
	var hint_string := String(skeleton.get_concatenated_bone_names())
	if hint_string.is_empty():
		return
	property.hint = PROPERTY_HINT_ENUM
	property.hint_string = hint_string


func apply_knockback(direction: Vector3) -> void:
	if skeleton == null:
		return
	var bone_index = skeleton.find_bone(bone_name)
	if bone_index == -1:
		return
	knockback_modifier.add_knockback(bone_index, direction)
