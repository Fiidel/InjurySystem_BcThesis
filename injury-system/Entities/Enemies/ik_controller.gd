class_name IKController
extends Skeleton3D

var limb_mutex: LimbMutex


func _ready():
	limb_mutex = LimbMutex.new()
