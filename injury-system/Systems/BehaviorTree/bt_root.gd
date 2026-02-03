class_name BTRoot
extends BTNode

func _ready() -> void:
	# initialize blackboard
	blackboard = {}
	# add children to scene tree
	for child in child_nodes:
		add_child(child)

func execute() -> void:
	while true:
		for child in child_nodes:
			child.execute()
			await child.finished
	# Root node should never stop while the Behavior Tree is active
	finished.emit(ReturnStatus.FAILURE)
