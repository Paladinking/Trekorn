class_name Target
extends CharacterBody3D


var dead = false

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func get_shot():
	if not dead:
		#$Death.finished.connect(queue_free)
		$Death.play()
		#hide()
		($guardblue/Armature_004/Skeleton3D/PhysicalBoneSimulator3D as PhysicalBoneSimulator3D).physical_bones_start_simulation()
		dead = true

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
