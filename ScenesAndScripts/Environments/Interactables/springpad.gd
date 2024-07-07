extends Node3D

@export_range(10.0, 100.0) var strength : float = 20.0

#var velocity_to_add = Vector3(0, 1, 0).rotated(Vector3.RIGHT, rotation.x).rotated(Vector3.FORWARD, rotation.z).rotated(Vector3.UP, rotation.y) * strength
var velocity_to_add = global_basis.y * strength

# Called when the node enters the scene tree for the first time.
func _ready():
	#velocity_to_add = Vector3(0, 1, 0).rotated(Vector3.RIGHT, rotation.x).rotated(Vector3.FORWARD, rotation.z).rotated(Vector3.UP, rotation.y) * strength
	velocity_to_add = global_basis.y * strength


func _on_victim_zone_body_entered(body):
	if not $AnimationPlayer.is_playing() or $AnimationPlayer.current_animation_position <= 0.1:
		body.velocity += velocity_to_add
		$AnimationPlayer.play("spring")
