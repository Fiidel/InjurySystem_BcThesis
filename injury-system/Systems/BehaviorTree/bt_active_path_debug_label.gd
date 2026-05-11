extends CanvasLayer

@export var bt_root: BTRoot
@export var label: Label


func _ready() -> void:
	if label == null:
		push_warning("Label not assigned in the BT path print canvas layer.")


func _physics_process(_delta: float) -> void:
	if not visible or label == null:
		return
	refresh_label()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var e: InputEventKey = event as InputEventKey
		if e.pressed and not e.echo and e.keycode == KEY_I:
			visible = not visible


func refresh_label() -> void:
	if not is_instance_valid(bt_root):
		label.text = "--"
		return
	var names: PackedStringArray = collect_active_path_names(bt_root)
	label.text = "\n".join(names)


func collect_active_path_names(root: BTRoot) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var node: BTNode = root
	while is_instance_valid(node):
		out.append(node.name)
		var next: BTNode = get_active_bt_child(node)
		if next == null:
			break
		node = next
	return out


func get_active_bt_child(node: BTNode) -> BTNode:
	if not is_instance_valid(node):
		return null
	match true:
		_ when node is BTPriorityReselector or node is BTSelector or node is BTSequence or node is BTRoot:
			return child_at_index(node.child_nodes, _indexed_composite_child_idx(node))
		_ when node is BTRandomizer:
			return (node as BTRandomizer).selected_child
		_ when node is BTWeightedRandomizer:
			return (node as BTWeightedRandomizer).selected_child
		_ when node is BTUtilityRandomizer:
			return (node as BTUtilityRandomizer).selected_child
		_ when node is BTDecorator:
			return (node as BTDecorator).child
		_:
			return null


func _indexed_composite_child_idx(node: BTNode) -> int:
	match true:
		_ when node is BTPriorityReselector:
			return (node as BTPriorityReselector).current_child_idx
		_ when node is BTSelector:
			return (node as BTSelector).current_child_idx
		_ when node is BTSequence:
			return (node as BTSequence).current_child_idx
		_ when node is BTRoot:
			return (node as BTRoot).current_child_idx
		_:
			return -1


func child_at_index(children: Array[BTNode], idx: int) -> BTNode:
	if children.is_empty():
		return null
	if idx < 0 or idx >= children.size():
		return null
	var child: BTNode = children[idx]
	if is_instance_valid(child):
		return child
	return null
