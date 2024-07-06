extends CharacterBody3D


const SPEED = 6.0
const SLOW_DOWN_MULT = 0.5
const ACCELERATION = 25.0
const ACCELERATION_IN_AIR_MULT = 0.1
const JUMP_VELOCITY = 5.0
const MAX_JUMP_TIME = 0.25
var jumping = 0.0
var ledge_in_front = false
var is_climbing = false

const CAMERA_MOVE_SPEED = 5
const CAMERA_MAX_DISTANCE = 10
var camera_target_position = Vector3(0, 1.5, 0)
const CAMERA_WALL_SAFETY_DIST = 1
var camera_angle_y = 0
var camera_angle_x = 0
const CAMERA_ANGLE_X_MAX = deg_to_rad(90)
const CAMERA_ANGLE_X_MIN = deg_to_rad(-15)
const CLIMBING_DESCELLERATION = 18

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	#var rot_y = CAMERA_POSITION.rotated(Vector3.UP, camera_angle_y)
	#$Camera.position = rot_y.rotated(Vector3.UP.cross(rot_y).normalized(), camera_angle_x)
	camera_target_position = $CameraRay.position
	$Camera.position = Vector3(sin(camera_angle_y), camera_angle_x, cos(camera_angle_y)) * CAMERA_MAX_DISTANCE
	$Camera.look_at(global_position + camera_target_position)
	$CameraRay.target_position = $Camera.position


func _physics_process(delta):
	#if not is_on_floor():
		#velocity.y -= gravity * delta

	#if is_on_floor():
	var input_dir = Input.get_vector("go_left", "go_right", "go_forward", "go_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, camera_angle_y)
	if Input.is_action_pressed("slow"):
		direction *= SLOW_DOWN_MULT
	var current_acc = ACCELERATION
	if not is_on_floor():
		current_acc *= ACCELERATION_IN_AIR_MULT
	velocity = velocity.move_toward(direction * SPEED, delta * current_acc)

	if velocity.x != 0 and velocity.z != 0:
		$Model.rotation.y = -Vector3(velocity.x, 0, velocity.z).signed_angle_to(Vector3.RIGHT, Vector3.UP)
	
	ledge_in_front = false
	if $Model/LowerClimbRay.is_colliding() and !$Model/UpperClimbRay.is_colliding():
		ledge_in_front = true
		velocity.y *= 0.5

	if ledge_in_front and not is_on_floor():
		is_climbing = true
	
	if not is_on_wall():
		is_climbing = false

	if Input.is_action_just_pressed("jump"):
		if is_on_floor() and not is_climbing:
			jumping = MAX_JUMP_TIME
			velocity.y = JUMP_VELOCITY

		elif is_on_wall_only():
			jumping = MAX_JUMP_TIME
			var collision : KinematicCollision3D = get_last_slide_collision()
			var jump_direction = collision.get_position().direction_to(global_position)
			jump_direction.y = 0
			jump_direction = jump_direction.normalized() * 0.5
			if jump_direction.dot(direction) > 0:
				jump_direction = direction
			velocity += jump_direction * JUMP_VELOCITY
			velocity.y = JUMP_VELOCITY
	
	if (not is_on_floor()) and (not is_climbing):
		velocity.y -= gravity * delta

	if jumping > 0.0:
		if Input.is_action_pressed("jump"):
			jumping -= delta
			if jumping > 0.0:
				velocity.y = JUMP_VELOCITY * (1 - (jumping / MAX_JUMP_TIME) / 5)
			else:
				jumping = 0.0
		else:
			jumping = 0.0

	
	#if velocity.is_zero_approx():
		#$Model/AnimationPlayer.play("Idle")

	move_and_slide()


func _process(delta):
	if Input.is_action_pressed("look_up") or Input.is_action_pressed("look_down") or \
		Input.is_action_pressed("look_left") or Input.is_action_pressed("look_right"):
		camera_angle_y += (Input.get_action_strength("look_left") - Input.get_action_strength("look_right")) * delta * CAMERA_MOVE_SPEED
		if camera_angle_y > 2 * PI:
			camera_angle_y -= 2 * PI
		elif camera_angle_y < -2 * PI:
			camera_angle_y += 2 * PI

		camera_angle_x += (Input.get_action_strength("look_down") - Input.get_action_strength("look_up")) * delta * CAMERA_MOVE_SPEED
		camera_angle_x = clamp(camera_angle_x, CAMERA_ANGLE_X_MIN, CAMERA_ANGLE_X_MAX)

	#var rot_y = CAMERA_POSITION.rotated(Vector3.UP, camera_angle_y)
	#$Camera.position = rot_y.rotated(Vector3.UP.cross(rot_y).normalized(), camera_angle_x)
	$Camera.position = Vector3(sin(camera_angle_y), camera_angle_x, cos(camera_angle_y)).normalized() * CAMERA_MAX_DISTANCE
	$Camera.look_at(global_position + camera_target_position)
	$CameraRay.target_position = $Camera.position

	if $CameraRay.is_colliding():
		#print("Cam: ", $Camera.position)
		#print("Col: ", $CameraRay.get_collision_point() - $CameraRay.global_position)
		var camera_ray_collision_distance_squared = $CameraRay.position.distance_squared_to($CameraRay.get_collision_point() - $CameraRay.global_position)
		#if camera_ray_collision_distance_squared < (CAMERA_MAX_DISTANCE + CAMERA_WALL_SAFETY_DIST) * (CAMERA_MAX_DISTANCE + CAMERA_WALL_SAFETY_DIST):
		if camera_ray_collision_distance_squared < CAMERA_MAX_DISTANCE * CAMERA_MAX_DISTANCE:
			var to_move_camera = CAMERA_MAX_DISTANCE - sqrt(camera_ray_collision_distance_squared)
			#to_move_camera += CAMERA_WALL_SAFETY_DIST / (CAMERA_MAX_DISTANCE - (to_move_camera + CAMERA_WALL_SAFETY_DIST))
			$Camera.position = $Camera.position.move_toward(camera_target_position, to_move_camera)
			#if camera_angle_x < 0:
				#$Camera.position.y += ($CameraRay.get_collision_point().y - $CameraRay.global_position.y) + CAMERA_WALL_SAFETY_DIST

			if CAMERA_MAX_DISTANCE - to_move_camera < CAMERA_WALL_SAFETY_DIST:
				$Model.hide()
			elif not $Model.is_visible_in_tree():
				$Model.show()
	elif not $Model.is_visible_in_tree():
		$Model.show()
		
	if $Model/LowerClimbRay.is_colliding():
		print("Collission Lower")
	if $Model/UpperClimbRay.is_colliding():
		print("Collission upper")

