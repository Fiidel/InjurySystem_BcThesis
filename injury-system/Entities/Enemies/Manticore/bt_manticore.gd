extends Node

var BT: BTNode

func _init() -> void:
	BT = BTRoot.new()
	var a1: BTAction = BTAction.new()
	a1.node_name = "Action 1"
	var a2: BTAction = BTAction.new()
	a2.node_name = "Action 2"
	var a3: BTAction = BTAction.new()
	a3.node_name = "Action 3"
	BT.add_bt_child(a1)
	BT.add_bt_child(a2)
	BT.add_bt_child(a3)

func _ready() -> void:
	add_child(BT)
	BT.execute()
