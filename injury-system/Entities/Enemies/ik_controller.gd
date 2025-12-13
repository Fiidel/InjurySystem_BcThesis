class_name IKController
extends Skeleton3D

var limb_mutex: LimbMutex
var wings: Array[WingIK] = []

func _ready():
	limb_mutex = LimbMutex.new()
	setup_wings()
	flap_wings()

func setup_wings():
	for child in get_children():
		if child is WingIK:
			wings.append(child)

func flap_wings():
	while true:
		var random_position_offset: Vector3 = generate_random_position_offset()
		var random_rotation_offset: Vector3 = generate_random_rotation_offset()
		var random_time_offset: float = generate_random_time_offset()
		var tweens: Array[Tween] = []

		# flap down
		for wing in wings:
			tweens.append(wing.flap_down(random_position_offset, random_rotation_offset, random_time_offset))
		for tween in tweens:
			await tween.finished
		for tween in tweens:
			tween.kill()
		tweens.clear()

		# flap up
		for wing in wings:
			tweens.append(wing.flap_up(random_position_offset, random_rotation_offset, random_time_offset))
		for tween in tweens:
			await tween.finished
		for tween in tweens:
			tween.kill()
		tweens.clear()

func generate_random_position_offset() -> Vector3:
	return Vector3(randfn(0, 0.1), randfn(0, 0.1), randfn(0, 0.1))

func generate_random_rotation_offset() -> Vector3:
	return Vector3(randfn(0, 0.1), randfn(0, 0.1), randfn(0, 0.1))

func generate_random_time_offset() -> float:
	return randf_range(0, 0.25)
