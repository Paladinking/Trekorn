@tool
class_name Spruce
extends Node3D


func _set_height():
	var randy = RandomNumberGenerator.new()

	for child in $Repeatables.get_children():
		child.queue_free()

	$Trunk.height = height
	$Trunk.position.y = height / 2
	$TrunkCollider/CollisionShape3D.shape.height = height
	$TrunkCollider/CollisionShape3D.position.y = height / 2
	$Top.position.y = height + $Top.height / 2
	var height_left = height - $Top.height / 2

	var place_more_leaves = true
	while place_more_leaves:
		var leaf_cone = $Top.duplicate()
		leaf_cone.name = "Repeatable"
		leaf_cone.height = randy.randf_range(1.0, 1.25) + (height_left / height)
		if leaf_cone.height > height_left:
			leaf_cone.height = height_left - $Top.height / 2
			place_more_leaves = false
		leaf_cone.radius = leaf_cone.height / 2
		leaf_cone.position.y = 1 + (height - height_left) + (leaf_cone.height / 2)
		leaf_cone.position.x = randy.randf_range(-0.05, 0.05)
		leaf_cone.position.z = randy.randf_range(-0.05, 0.05)
		$Repeatables.add_child(leaf_cone)
		height_left -= leaf_cone.height / 2

@export_range(1.0, 100.0) var height: float = 3.0:
	set(new_height):
		height = new_height
		_set_height()

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_height()

