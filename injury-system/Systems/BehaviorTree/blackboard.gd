class_name Blackboard
extends Node

var data: Dictionary


func set_data(key: Variant, value: Variant) -> void:
	data.set(key, value)


func get_data(key: Variant) -> Variant:
	return data.get(key)
