extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var instances: Array = get_meta("Rect")
	if (instances != null):
		var child = $default
		var pos = child.position
		var rot = child.rotation
		remove_child(child)
		child.queue_free()
		child = instances[randi_range(0, len(instances) - 1)].instantiate()
		child.position = pos
		child.rotation = rot
		add_child(child)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
