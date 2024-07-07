extends Node3D

#@onready var body: StaticBody3D = $StaticBody3D
var body;
# Called when the node enters the scene tree for the first time.
func _ready():
	body = get_parent().find_child("Player");

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position = Vector3(body.global_transform.origin.x, body.global_transform.origin.y +5, body.global_transform.origin.z)
	

	

