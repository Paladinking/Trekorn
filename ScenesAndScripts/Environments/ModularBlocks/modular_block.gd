@tool
class_name ModularBlock
extends Node3D

func _layout():
	for n in get_children():
		if n is ModularBlock:
			n.size = size
	if has_node("middle"):
		for n in $middle.get_children():
			$middle.remove_child(n)
			n.queue_free()
		var instance = get_meta("Block")
		for i in range(size):
			var node: Node3D = instance.instantiate()
			node.position.y = 4 * (i + 1);
			$middle.add_child(node)
	if has_node("top"):
		$top.position.y = 4 * (size + 1);

@export var size: int = 1:
	set(new_size):
		size = new_size
		_layout()

# Called when the node enters the scene tree for the first time.
func _ready():
	_layout()

