extends CharacterBody3D

const SHOOT_COOLDOWN: float = 3.0
const SPEED = 6.0
const SPRINT_SPEED_MULT = 2.0
const SLOW_DOWN_MULT = 0.5
const ACCELERATION = 25.0
const ACCELERATION_IN_AIR_MULT = 0.1
const JUMP_VELOCITY = 5.0
const MAX_JUMP_TIME = 0.25
var jumping = 0.0
var ledge_in_front = false
var is_climbing = false
var jump_time = 0.0
var jump_press_time = 0.0
const WALL_JUMP_MARGIN = 0.25
var wall_jump_time = 0.0
var last_collision_direction : Vector3 = Vector3.ZERO

#const CAMERA_MOVE_SPEED = 5
const CAMERA_MOVE_SPEED = 2.5
const CAMERA_MAX_DISTANCE = 10
var camera_target_position = Vector3(0, 1.5, 0)
const CAMERA_WALL_SAFETY_DIST = 1
var camera_angle_y = 0
var camera_angle_x = deg_to_rad(90)
const CAMERA_ANGLE_X_MAX = deg_to_rad(179)
const CAMERA_ANGLE_X_MIN = deg_to_rad(45)

var shoot_cooldown: float = 0.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

const bullet = preload("res://ScenesAndScripts/Characters/bullet.tscn")

func _ready():
	#var rot_y = CAMERA_POSITION.rotated(Vector3.UP, camera_angle_y)
	#$Camera.position = rot_y.rotated(Vector3.UP.cross(rot_y).normalized(), camera_angle_x)
	camera_target_position = $CameraRay.position
	$Camera.position = Vector3(sin(camera_angle_y), camera_angle_x, cos(camera_angle_y)) * CAMERA_MAX_DISTANCE
	$Camera.look_at(global_position + camera_target_position)
	$CameraRay.target_position = $Camera.position


func _physics_process(delta):
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
		$Model.rotation.y = -Vector3(velocity.x, 0, velocity.z).signed_angle_to(Vector3.FORWARD, Vector3.UP)

	if is_on_wall_only():
		wall_jump_time = WALL_JUMP_MARGIN
		last_collision_direction = get_last_slide_collision().get_position().direction_to(global_position)
	elif wall_jump_time > 0:
		wall_jump_time -= delta
	elif not last_collision_direction.is_zero_approx():
		last_collision_direction = Vector3.ZERO

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
		else:
			jump_press_time = WALL_JUMP_MARGIN
	elif jump_press_time > 0:
		jump_press_time -= delta

	if wall_jump_time > 0 and jump_press_time > 0:
		wall_jump_time = 0
		jump_press_time = 0
		jump_time = MAX_JUMP_TIME
		last_collision_direction.y = 0
		last_collision_direction = last_collision_direction.normalized() * 0.5
		if last_collision_direction.dot(direction) > 0:
			last_collision_direction = direction
		velocity += last_collision_direction * JUMP_VELOCITY
		velocity.y = JUMP_VELOCITY
		$Model.rotation.y = -Vector3(velocity.x, 0, velocity.z).signed_angle_to(Vector3.RIGHT, Vector3.UP)

	if not is_on_floor() and not is_climbing:
		velocity.y -= gravity * delta

	if jump_time > 0.0:
		if Input.is_action_pressed("jump"):
			jump_time -= delta
			if jump_time > 0.0:
				velocity.y = JUMP_VELOCITY * (1 - (jump_time / MAX_JUMP_TIME) / 5)
			else:
				jump_time = 0.0
		else:
			jump_time = 0.0
			if velocity.y > 0:
				velocity.y *= 0.5

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
		
	if $Model/LowerClimbRay.is_colliding():
		print("Collission Lower")
	if $Model/UpperClimbRay.is_colliding():
		print("Collission upper")
	if Input.is_action_pressed("shoot") and shoot_cooldown <= 0:
		var b = bullet.instantiate()
		var dir: Vector3 = -$Model.global_basis.z
		b.position = Vector3(position.x, position.y + 1, position.z) + 2 * dir
		b.linear_velocity = 500 * dir
		get_tree().root.add_child(b)
		shoot_cooldown = SHOOT_COOLDOWN
	shoot_cooldown -= delta
		
#var p = false

func _unhandled_key_input(event):
	#if event.is_pressed() and event.physical_keycode == KEY_P:
		#p = !p
		#print(p)
	pass