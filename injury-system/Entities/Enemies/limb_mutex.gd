class_name LimbMutex
extends Skeleton3D

var current_locked_group: int = -1
var limb_amount: int = 0

# Returns whether the mutex is open for the group (either no active movement or movement of the same group)
func is_unlocked_for_group(limb_group: int) -> bool:
	if current_locked_group == -1:
		return true
	if current_locked_group == limb_group:
		return true
	return false

# Lock the mutex for the current limb group
func lock_step(limb_group: int):
	if current_locked_group == -1 or current_locked_group == limb_group:
		current_locked_group = limb_group
		limb_amount += 1

# Unlock the mutex for the current group
func unlock_step(limb_group: int):
	if current_locked_group == limb_group:
		limb_amount -= 1
		if limb_amount <= 0:
			current_locked_group = -1
