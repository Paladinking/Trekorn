extends RigidBody3D


const bullet_trail_asset = preload("res://ScenesAndScripts/Characters/bullet_trail.tscn")
var current_pos: Vector3
var player_pos: Vector3
var bullet_trail
var amount_bullet_trails: int = 0
const max_bullet_trails: int = 50
const trail_step_size: float = 0.05
const max_bullet_dist: float = 5000

# Called when the node enters the scene tree for the first time.
func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if amount_bullet_trails < max_bullet_trails and player_pos.distance_to(position) < max_bullet_dist:
		amount_bullet_trails+=1
		print(amount_bullet_trails)
		spawn_trail()
	else: 
		queue_free()


func spawn_trail():
	var position1 = Vector3()
	var position2 = Vector3()
	if position.distance_to(player_pos) < position.distance_to(self.linear_velocity * (-trail_step_size) + player_pos):
		position1 = position
		position2 = player_pos
	else:
		position1 = position
		#position2 = (position-player_pos).normalized() * (-trail_step_size) + player_pos
		position2 = self.linear_velocity * (-trail_step_size) + player_pos
	
	bullet_trail = bullet_trail_asset.instantiate()
	bullet_trail.point_end = position1
	bullet_trail.point_start = position2
	
	get_tree().root.add_child(bullet_trail)


func _on_body_entered(body):
	print(player_pos.distance_to(position))
	spawn_trail()
	queue_free()
	print("Headshot!")
