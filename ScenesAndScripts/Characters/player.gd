extends CharacterBody3D


const SPEED = 6.0
const SPRINT_SPEED_MULT = 2
const SLOW_DOWN_MULT = 0.5
const ACCELERATION = 25.0
const ACCELERATION_IN_AIR_MULT = 0.1
const JUMP_VELOCITY = 5.0
const MAX_JUMP_TIME = 0.25
var jumping = 0.0

#const CAMERA_MOVE_SPEED = 5
const CAMERA_MOVE_SPEED = 2.5
const CAMERA_MAX_DISTANCE = 10
var camera_target_position = Vector3(0, 1.5, 0)
const CAMERA_WALL_SAFETY_DIST = 1
var camera_angle_y = 0
var camera_angle_x = deg_to_rad(90)
const CAMERA_ANGLE_X_MAX = deg_to_rad(179)
const CAMERA_ANGLE_X_MIN = deg_to_rad(45)

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
	var current_acceleration = ACCELERATION
	if not is_on_floor():
		current_acceleration *= ACCELERATION_IN_AIR_MULT
	var current_speed = SPEED
	if Input.is_action_pressed("sprint"):
		current_speed *= SPRINT_SPEED_MULT
	elif Input.is_action_pressed("slow"):
		current_speed *= SLOW_DOWN_MULT
	velocity = velocity.move_toward(direction * current_speed, delta * current_acceleration)
	if not direction.is_zero_approx():
		$Model.rotation.y = -Vector3(velocity.x, 0, velocity.z).signed_angle_to(Vector3.RIGHT, Vector3.UP)

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
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
			$Model.rotation.y = -Vector3(velocity.x, 0, velocity.z).signed_angle_to(Vector3.RIGHT, Vector3.UP)

	if not is_on_floor():
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
		Input.is_action_pressed("look_right") or Input.is_action_pressed("look_left"):
		camera_angle_y -= (Input.get_action_strength("look_right") - Input.get_action_strength("look_left")) * delta * CAMERA_MOVE_SPEED
		if camera_angle_y > 2 * PI:
			camera_angle_y -= 2 * PI
		elif camera_angle_y < -2 * PI:
			camera_angle_y += 2 * PI

		camera_angle_x += (Input.get_action_strength("look_up") - Input.get_action_strength("look_down")) * delta * CAMERA_MOVE_SPEED
		camera_angle_x = clamp(camera_angle_x, CAMERA_ANGLE_X_MIN, CAMERA_ANGLE_X_MAX)

	#var rot_y = CAMERA_POSITION.rotated(Vector3.UP, camera_angle_y)
	#$Camera.position = rot_y.rotated(Vector3.UP.cross(rot_y).normalized(), camera_angle_x)
	var camera_position = Vector3(
		sin(camera_angle_x) * sin(camera_angle_y),
		-cos(camera_angle_x),
		sin(camera_angle_x) * cos(camera_angle_y)
	) * CAMERA_MAX_DISTANCE
	$Camera.position = camera_position
	$Camera.look_at(global_position + camera_target_position)
	$CameraRay.target_position = camera_position

	if $CameraRay.is_colliding():
		var collision_point = $CameraRay.get_collision_point() - $CameraRay.global_position + $CameraRay.position
		var camera_ray_collision_distance = $CameraRay.position.distance_to($CameraRay.get_collision_point() - $CameraRay.global_position + $CameraRay.position)
		if camera_ray_collision_distance < CAMERA_MAX_DISTANCE:
			var to_move_camera = CAMERA_MAX_DISTANCE - camera_ray_collision_distance
			to_move_camera += CAMERA_WALL_SAFETY_DIST * (1 - (CAMERA_MAX_DISTANCE - (to_move_camera + CAMERA_WALL_SAFETY_DIST)) / CAMERA_MAX_DISTANCE)
			$Camera.position = $Camera.position.move_toward(camera_target_position, to_move_camera)

			if CAMERA_MAX_DISTANCE - to_move_camera < CAMERA_WALL_SAFETY_DIST:
				$Model.hide()
			elif not $Model.is_visible_in_tree():
				$Model.show()
	elif not $Model.is_visible_in_tree():
		$Model.show()

#var p = false

func _unhandled_key_input(event):
	#if event.is_pressed() and event.physical_keycode == KEY_P:
		#p = !p
		#print(p)
	pass
