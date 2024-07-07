extends CharacterBody3D

const SHOOT_COOLDOWN: float = 3.0
const SPEED = 6.0
const SPRINT_SPEED_MULT = 2.0
const SLOW_DOWN_MULT = 0.5
const CLIMB_SPEED_MULT = 0.6
const ACCELERATION = 25.0
const ACCELERATION_IN_AIR_MULT = 0.1
const ACCELERATION_ON_LEDGE_MULT = 0.5
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

const FALL_SCREAM_VELOCITY = -12.0

const CAMERA_MOVE_SPEED = 5
const CAMERA_MAX_DISTANCE = 10
const SHOULDER_MAX_DISTANCE = 3
var camera_target_position = Vector3(0, 1.5, 0)
const CAMERA_WALL_SAFETY_DIST = 1
var camera_angle_y = 0
var camera_angle_x = deg_to_rad(90)
const CAMERA_ANGLE_X_MAX = deg_to_rad(179)
const CAMERA_ANGLE_X_MIN = deg_to_rad(45)

var current_speed = 0
var current_acceleration = 0
var direction = Vector3(0, 0, 0)
var input_dir = Vector3(0, 0, 0)
var start_climb_smoothness = 0
var ledge_height = 0
var ledge_leap_cooldown = 0
var wall_normal = Vector3(0, 0, 0)
var can_climb_again = true

var shoot_cooldown: float = 0.0
var shoulder_cam: bool = false

var weapon_pos

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

const bullet = preload("res://ScenesAndScripts/Characters/bullet.tscn")
const flash = preload("res://ScenesAndScripts/Characters/Flash.tscn")

func _ready():
	weapon_pos = $ag42b.position
	#var rot_y = CAMERA_POSITION.rotated(Vector3.UP, camera_angle_y)
	#$Camera.position = rot_y.rotated(Vector3.UP.cross(rot_y).normalized(), camera_angle_x)
	camera_target_position = $CameraRay.position
	$Camera.position = Vector3(sin(camera_angle_y), camera_angle_x, cos(camera_angle_y)) * CAMERA_MAX_DISTANCE
	$Camera.look_at(global_position + camera_target_position)
	$CameraRay.target_position = $Camera.position
	$Model/AnimationPlayer.play("run")
	$Model/AnimationPlayer.pause()


func _physics_process(delta):
	if Input.is_action_just_pressed("aim"):
		shoulder_cam = not shoulder_cam

	input_dir = Input.get_vector("go_left", "go_right", "go_forward", "go_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, camera_angle_y)
	if not direction.is_zero_approx():
		$InputDirection.rotation.y = -Vector3(direction.x, 0, direction.z).signed_angle_to(Vector3.FORWARD, Vector3.UP)
	
	current_speed = SPEED
	current_acceleration = ACCELERATION
	
	if not is_on_floor() and not is_climbing:
		current_acceleration *= ACCELERATION_IN_AIR_MULT
	elif not is_on_floor() and is_climbing:
		current_acceleration *= ACCELERATION_ON_LEDGE_MULT
		current_speed *= CLIMB_SPEED_MULT
	if Input.is_action_pressed("sprint"):
		current_speed *= SPRINT_SPEED_MULT
	elif Input.is_action_pressed("slow"):
		current_speed *= SLOW_DOWN_MULT
	#if not direction.is_zero_approx() and not shoulder_cam:
	#	$Model.rotation.y = -Vector3(velocity.x, 0, velocity.z).signed_angle_to(Vector3.FORWARD, Vector3.UP)

	if is_on_wall_only():
		wall_jump_time = WALL_JUMP_MARGIN
		last_collision_direction = get_last_slide_collision().get_position().direction_to(global_position)
	elif wall_jump_time > 0:
		wall_jump_time -= delta
	elif not last_collision_direction.is_zero_approx():
		last_collision_direction = Vector3.ZERO

	if Input.is_action_just_pressed("jump"):
		if is_on_floor() and not is_climbing:
			$Model/AnimationPlayer.stop(true)
			$Model/AnimationPlayer.play("running_jump")
			jump_time = MAX_JUMP_TIME
			velocity.y = JUMP_VELOCITY
		else:
			jump_press_time = WALL_JUMP_MARGIN
	elif jump_press_time > 0:
		jump_press_time -= delta

	if wall_jump_time > 0 and jump_press_time > 0:
		$Model/AnimationPlayer.stop(true)
		$Model/AnimationPlayer.play("wall_jump")
		$LandingAudio.play()
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

		if not shoulder_cam:
			$Model.rotation.y = -Vector3(velocity.x, 0, velocity.z).signed_angle_to(Vector3.RIGHT, Vector3.UP)

	if not is_on_floor() and not is_climbing:
		velocity.y -= gravity * delta
		
	if jump_time > 0.0 and not is_climbing:
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
				

	if is_on_floor():
		if velocity.y == 0 and not velocity.is_zero_approx():
			$Model/AnimationPlayer.play("run")
			$WalkAudio.start_walk()
		else:
			$WalkAudio.stop_walk()
	else:
		$WalkAudio.stop_walk()
		#$Model/AnimationPlayer.pause()
		#velocity.y -= gravity * delta
		pass
	
	
	handle_climbing(delta)
	# velocity måste sättas EFTER handle_climbing
	velocity = velocity.move_toward(direction * current_speed, delta * current_acceleration)
	if not direction.is_zero_approx() and not shoulder_cam and is_on_floor():
		$Model.rotation.y = -Vector3(velocity.x, 0, velocity.z).signed_angle_to(Vector3.FORWARD, Vector3.UP)

	var was_on_floor = is_on_floor()
	move_and_slide()
	if not was_on_floor and is_on_floor() and not $WalkAudio.walking and not $LandingAudio.playing:
		$LandingAudio.play()


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
	var max_dist = CAMERA_MAX_DISTANCE
	if shoulder_cam:
		max_dist = SHOULDER_MAX_DISTANCE
		$CameraRay.position = Vector3(0.5, 1.5, 0).rotated(Vector3.UP, $Model.rotation.y)
		camera_target_position = Vector3(0.5, 1.5, 0).rotated(Vector3.UP, $Model.rotation.y)
	else:
		$CameraRay.position = Vector3(0, 1.5, 0)
		camera_target_position = Vector3(0, 1.5, 0)
	
	var camera_position = Vector3(
		sin(camera_angle_x) * sin(camera_angle_y),
		-cos(camera_angle_x),
		sin(camera_angle_x) * cos(camera_angle_y)) * max_dist
	if shoulder_cam:
		camera_position += Vector3(0.5, 0, 0).rotated(Vector3.UP, $Model.rotation.y)
	$Camera.position = camera_position
	$Camera.look_at(global_position + camera_target_position)
	$CameraRay.target_position = camera_position
	$CameraArea.position = camera_position

	if $CameraRay.is_colliding() and ($CameraArea.has_overlapping_bodies() or not shoulder_cam):
		var camera_ray_collision_distance = $CameraRay.position.distance_to($CameraRay.get_collision_point() - $CameraRay.global_position + $CameraRay.position)
		if camera_ray_collision_distance < max_dist:
			var to_move_camera = max_dist - camera_ray_collision_distance
			to_move_camera += CAMERA_WALL_SAFETY_DIST * (1 - (max_dist - (to_move_camera + CAMERA_WALL_SAFETY_DIST)) / max_dist)
			$Camera.position = $Camera.position.move_toward(camera_target_position, to_move_camera)

			if max_dist - to_move_camera < CAMERA_WALL_SAFETY_DIST:
				$Model.hide()
			elif not $Model.is_visible_in_tree():
				$Model.show()
	elif not $Model.is_visible_in_tree():
		$Model.show()

	if shoulder_cam and not is_climbing:
		$Model.rotation.y = camera_angle_y
		
		$ag42b.basis = $Camera.basis
		$ag42b.position = camera_target_position
	if velocity.y < FALL_SCREAM_VELOCITY and not $FallAudio.playing:
		$FallAudio.play()
		$ag42b.basis = $Model.basis
		$ag42b.position = weapon_pos
	#if $Model/LowerClimbRay.is_colliding():
		#print("Collission Lower")
	#if $Model/UpperClimbRay.is_colliding():
		#print("Collission upper")
	if shoulder_cam and Input.is_action_pressed("shoot") and shoot_cooldown <= 0:
		var b = bullet.instantiate()
		var f = flash.instantiate()
		get_tree().root.add_child(f)
		var dir: Vector3 = -$ag42b.basis.z
		b.position = to_global($ag42b.position + 2 * dir)
		f.position = b.position
		f.emitting = true
		f.finished.connect(f.queue_free)
		b.player_pos = to_global(camera_target_position)
		b.linear_velocity = -$ag42b.global_basis.z * 100
		velocity -= 5 * dir
		get_tree().root.add_child(b)
		shoot_cooldown = SHOOT_COOLDOWN
		$ShootAudio.play()
	shoot_cooldown -= delta
		
#var p = false
func _input(event):
	if event is InputEventMouseMotion:
		camera_angle_x += event.relative.y / 200
		camera_angle_y -= event.relative.x / 200
		if camera_angle_y > 2 * PI:
			camera_angle_y -= 2 * PI
		elif camera_angle_y < -2 * PI:
			camera_angle_y += 2 * PI
		camera_angle_x = clamp(camera_angle_x, CAMERA_ANGLE_X_MIN, CAMERA_ANGLE_X_MAX)

func _unhandled_key_input(event):
	#if event.is_pressed() and event.physical_keycode == KEY_P:
		#shoulder_cam = not shoulder_cam
	pass

func handle_climbing(delta):
	if is_on_wall():
		wall_normal = get_wall_normal()
		$Model.rotation.y = -wall_normal.signed_angle_to(Vector3.BACK, Vector3.UP)
	#print(wall_normal)
	
	
	if not $Model/LowerClimbRay.is_colliding() or $Model/UpperClimbRay.is_colliding():
		can_climb_again = true
		
	if is_climbing and wall_normal.dot($Camera.get_global_transform().basis.z) > 0.1:
		var side_of_wall = sign(wall_normal.dot($Camera.get_global_transform().basis.z))
		direction = (Basis(wall_normal.cross(Vector3(0,1,0)), Vector3(0,1,0), wall_normal) * Vector3(-input_dir.x * side_of_wall, 0, input_dir.y))
	
	#print(wall_normal.dot($Camera.get_global_transform().basis.z))
	
	if not is_on_floor() and is_climbing:
		current_acceleration *= ACCELERATION_ON_LEDGE_MULT
		current_speed *= CLIMB_SPEED_MULT
	
		
	ledge_in_front = false
	if can_climb_again and $Model/LowerClimbRay.is_colliding() and not $Model/UpperClimbRay.is_colliding():
		ledge_in_front = true
		ledge_height = $Model/HeightMeasureRay.get_collision_point().y
		#print("Ledge")

	if ledge_in_front and not is_on_floor():
		is_climbing = true
		start_climb_smoothness = velocity.y
		velocity.y = 0.0
		#print("Climbing")
	
	if is_climbing:
		if abs(global_position.y + 1.8 - ledge_height) < 0.01:
			global_position.y = ledge_height - 1.8
		else:
			global_position.y -= (global_position.y - ledge_height + 1.8) * 0.5

		print(global_position.y)
	
	if is_climbing and ledge_leap_cooldown < 0:
		ledge_leap_cooldown = 0.5
	ledge_leap_cooldown -= delta
	if is_climbing and input_dir.y < -0.5 and ledge_leap_cooldown < 0:
		velocity.y = 7
		is_climbing = false

	if input_dir.y > 0.5:
		can_climb_again = false
		
	if not is_on_wall() or not can_climb_again:# or not $InputDirection/LowerClimbRay.is_colliding() or $InputDirection/UpperClimbRay.is_colliding():
		is_climbing = false
		#print("Stop climbing")

func handle_model():
	pass
