extends Node

var BT: BTNode

func _init() -> void:
	BT = BTRoot.new()
	
	var sel := BTSelector.new()
	
	var seq := BTSequence.new()
	var conDec := BTCondition.new()
	var cond = func():
		return true
	conDec.condition = cond
	
	var a1: BTAction = BTAction.new()
	a1.node_name = "Action 1"
	var a2: BTAction = BTAction.new()
	a2.node_name = "Action 2"
	var a3: BTAction = BTAction.new()
	a3.node_name = "Action 3"
	var a4: BTAction = BTAction.new()
	a4.node_name = "Action 4"
	
	# Plan: Root -> Selector
	BT.add_bt_child(sel)
	# Selector -> Sequence && Action a4
	sel.add_bt_child(seq)
	sel.add_bt_child(a4)
	# Sequence -> a1 && Condition(a2) && a3
	seq.add_bt_child(a1)
	seq.add_bt_child(conDec)
	conDec.add_bt_child(a2)
	seq.add_bt_child(a3)
	
	# Expected print:
	# Action 1
	# Ation 4

func _ready() -> void:
	add_child(BT)
	BT.execute()
