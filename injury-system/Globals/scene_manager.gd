extends Node3D

@onready var deformation_test_mesh: MeshInstance3D = %DeformationTestMesh
var is_deform_test_mesh_enabled: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
	if event is InputEventKey and event.pressed and event.keycode == KEY_U:
		is_deform_test_mesh_enabled = !is_deform_test_mesh_enabled
		if is_deform_test_mesh_enabled:
			deformation_test_mesh.show()
		else:
			deformation_test_mesh.hide()
