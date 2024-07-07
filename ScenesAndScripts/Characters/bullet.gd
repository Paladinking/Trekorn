extends RigidBody3D


const bullet_trail_asset = preload("res://ScenesAndScripts/Characters/bullet_trail.tscn")
var current_pos: Vector3;
var bullet_trail;

# Called when the node enters the scene tree for the first time.
func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
	
	current_pos = position;
	bullet_trail = bullet_trail_asset.instantiate()
	bullet_trail.point_end = current_pos
	bullet_trail.point_start = self.linear_velocity.normalized() * -1 + current_pos
	
	get_tree().root.add_child(bullet_trail)

	# Prepare attributes for add_vertex.
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	queue_free()
	print("Headshot!")
