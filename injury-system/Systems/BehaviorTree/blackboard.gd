class_name Blackboard
extends Node

var data: Dictionary


func store(key: Variant, value: Variant) -> void:
	data.set(key, value)


func read(key: Variant) -> Variant:
	return data.get(key)


func remove(key: Variant) -> void:
	data.erase(key)
