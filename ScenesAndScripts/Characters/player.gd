extends CharacterBody3D

# Stuff
const SHOOT_COOLDOWN: float = 3.0
const SPEED = 6.0
const SPRINT_SPEED_MULT = 1.4
const SLOW_DOWN_MULT = 0.5
const CLIMB_SPEED_MULT = 0.6
const ACCELERATION = 25.0
const ACCELERATION_IN_AIR_MULT = 0.1
const ACCELERATION_ON_LEDGE_MULT = 0.5
const JUMP_VELOCITY = 5.0
const MAX_JUMP_TIME = 0.25
const FALL_SCREAM_VELOCITY = -12.0
var shoot_cooldown: float = 0.0
var jumping = 0.0
var ledge_in_front = false
var is_climbing = false
var jump_time = 0.0
var jump_press_time = 0.0
const WALL_JUMP_MARGIN = 0.25
var wall_jump_time = 0.0
var last_collision_direction : Vector3 = Vector3.ZERO
var current_speed = 0
var current_acceleration = 0
var direction = Vector3(0, 0, 0)
var input_dir = Vector3(0, 0, 0)
var start_climb_smoothness = 0
var ledge_height = 0
var ledge_leap_cooldown = 0
var wall_normal = Vector3(0, 0, 0)
var can_climb_again = true


# Camera
enum CAMERA_MODES { TPP, SHOULDER, ADS }
var camera_mode: CAMERA_MODES = CAMERA_MODES.TPP
var aiming_down_sights: bool = false

const CAMERA_FOV_TPP = 75.0
const CAMERA_FOV_SHOULDER = 50.0
const CAMERA_FOV_ADS = 25.0

const CAMERA_SPEED_TURN = 5.0
#const CAMERA_SPEED_ZOOM = 20.0
#const CAMERA_SPEED_FOV = 100.0
const CAMERA_SPEED_ADS = 0.25   # ADS time in seconds
var camera_speed_max_dist = 1.0
var camera_speed_fov = 1.0

const CAMERA_MAX_DIST_TPP = 5.0
const CAMERA_MAX_DIST_SHOULDER = 3.0
const CAMERA_MAX_DIST_ADS = 0.1
const CAMERA_WALL_SAFETY_DIST = 1.0

const CAMERA_CENTER_POSITION_TPP = Vector3(0, 1.5, 0)
var camera_target_position_variable : float = 0.0 # 0 means camera target is character, 1 means camera target is gun
var camera_max_dist = CAMERA_MAX_DIST_TPP

var camera_angle_y = 0.0
var camera_angle_x = deg_to_rad(90)
const CAMERA_ANGLE_X_MAX = deg_to_rad(179)
const CAMERA_ANGLE_X_MIN = deg_to_rad(45)


# Weapon stuff
const WEAPON_SHOULDER_POS = Vector3(0, 1.556, 0.162)
const WEAPON_SHOULDER_ROT = Vector3(deg_to_rad(-75), deg_to_rad(-90), 0)
const WEAPON_AIMING_POS = Vector3(0.4, 1.5, 0)
const WEAPON_AIMING_ROT = Vector3.ZERO


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")



func _ready():
	$Camera.position = Vector3(sin(camera_angle_y), camera_angle_x, cos(camera_angle_y)) * CAMERA_MAX_DIST_TPP
	$Camera.look_at(global_position + CAMERA_CENTER_POSITION_TPP)
	$CameraRay.target_position = $Camera.position
	$Model/AnimationPlayer.play("run")
	$Model/AnimationPlayer.pause()



func _physics_process(delta):
	input_dir = Input.get_vector("go_left", "go_right", "go_forward", "go_backward")
	#direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, camera_angle_y)
	direction = (Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, camera_angle_y)
	#if not direction.is_zero_approx():
		#$InputDirection.rotation.y = -Vector3(direction.x, 0, direction.z).signed_angle_to(Vector3.FORWARD, Vector3.UP)

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

		if camera_mode == CAMERA_MODES.TPP:
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
	var new_velocity = Vector3(velocity.x, 0, velocity.z).move_toward(direction * current_speed, delta * current_acceleration)
	velocity.x = new_velocity.x
	velocity.z = new_velocity.z
	if not direction.is_zero_approx() and camera_mode == CAMERA_MODES.TPP and is_on_floor():
		$Model.rotation.y = -Vector3(velocity.x, 0, velocity.z).signed_angle_to(Vector3.FORWARD, Vector3.UP)

	var was_on_floor = is_on_floor()
	move_and_slide()
	if not was_on_floor and is_on_floor() and not $WalkAudio.walking and not $LandingAudio.playing:
		$LandingAudio.play()



func _process(delta):
	if Input.is_action_just_pressed("aim"):
		match camera_mode:
			CAMERA_MODES.TPP:
				camera_mode = CAMERA_MODES.ADS if aiming_down_sights else CAMERA_MODES.SHOULDER
				camera_speed_max_dist = abs(camera_max_dist - (CAMERA_MAX_DIST_ADS if camera_mode == CAMERA_MODES.ADS else CAMERA_MAX_DIST_SHOULDER)) / (CAMERA_SPEED_ADS * (1 - camera_target_position_variable))
				camera_speed_fov = abs($Camera.fov - (CAMERA_FOV_ADS if camera_mode == CAMERA_MODES.ADS else CAMERA_FOV_SHOULDER)) / (CAMERA_SPEED_ADS * (1 - camera_target_position_variable))
				$Model/Ag42b.position = WEAPON_AIMING_POS
				$Model/Ag42b.rotation = WEAPON_AIMING_ROT
			_:
				camera_mode = CAMERA_MODES.TPP
				camera_speed_max_dist = abs(CAMERA_MAX_DIST_TPP - camera_max_dist) / (CAMERA_SPEED_ADS * camera_target_position_variable)
				camera_speed_fov = abs(CAMERA_FOV_TPP - $Camera.fov) / (CAMERA_SPEED_ADS * camera_target_position_variable)
				$Model/Ag42b.position = WEAPON_SHOULDER_POS
				$Model/Ag42b.rotation = WEAPON_SHOULDER_ROT

	handle_camera(delta)

	if (camera_mode == CAMERA_MODES.SHOULDER or camera_mode == CAMERA_MODES.ADS) and not is_climbing:
		if Input.is_action_just_pressed("aim_down_sights"):
			camera_mode = CAMERA_MODES.ADS if camera_mode == CAMERA_MODES.SHOULDER else CAMERA_MODES.SHOULDER
			camera_speed_max_dist = abs(camera_max_dist - (CAMERA_MAX_DIST_ADS if camera_mode == CAMERA_MODES.ADS else CAMERA_MAX_DIST_SHOULDER)) / (CAMERA_SPEED_ADS * (camera_target_position_variable if camera_target_position_variable > 0.5 else (1 - camera_target_position_variable)))
			camera_speed_fov = abs($Camera.fov - (CAMERA_FOV_ADS if camera_mode == CAMERA_MODES.ADS else CAMERA_FOV_SHOULDER)) / (CAMERA_SPEED_ADS * (camera_target_position_variable if camera_target_position_variable > 0.5 else (1 - camera_target_position_variable)))
		$Model.rotation.y = camera_angle_y

	if velocity.y < FALL_SCREAM_VELOCITY and not $FallAudio.playing:
		$FallAudio.play()

	if Input.is_action_pressed("shoot") and (camera_mode == CAMERA_MODES.SHOULDER or camera_mode == CAMERA_MODES.ADS) and shoot_cooldown <= 0:
		$Model/Ag42b.fire()
		velocity -= 5 * -$Model/Ag42b.global_basis.z
		shoot_cooldown = SHOOT_COOLDOWN
	shoot_cooldown -= delta



func handle_camera(delta):
	if Input.is_action_pressed("look_up") or Input.is_action_pressed("look_down") or \
		Input.is_action_pressed("look_right") or Input.is_action_pressed("look_left"):
		camera_angle_y -= pow(Input.get_action_strength("look_right") - Input.get_action_strength("look_left"), 2) * delta * CAMERA_SPEED_TURN * sign(Input.get_action_strength("look_right") - Input.get_action_strength("look_left"))
		if camera_angle_y > 2.0 * PI:
			camera_angle_y -= 2.0 * PI
		elif camera_angle_y < 0.0:
			camera_angle_y += 2.0 * PI
		camera_angle_x += pow(Input.get_action_strength("look_up") - Input.get_action_strength("look_down"), 2) * delta * CAMERA_SPEED_TURN * sign(Input.get_action_strength("look_up") - Input.get_action_strength("look_down"))
		camera_angle_x = clamp(camera_angle_x, CAMERA_ANGLE_X_MIN, CAMERA_ANGLE_X_MAX)

	var camera_position
	var camera_target_position

	if camera_mode == CAMERA_MODES.TPP:
		$CameraRay.position = Vector3(0, 1.5, 0)
		$Camera.fov = move_toward($Camera.fov, CAMERA_FOV_TPP, camera_speed_fov * delta)
		camera_max_dist = move_toward(camera_max_dist,
			CAMERA_MAX_DIST_TPP,
			camera_speed_max_dist * delta)
		camera_target_position_variable = move_toward(camera_target_position_variable, 0.0, (1.0 / CAMERA_SPEED_ADS) * delta)
	else:    # same as elif camera_mode == CAMERA_MODES.SHOULDER or camera_mode == CAMERA_MODES.ADS:
		$Model/Ag42b.rotation.x = -camera_angle_x + PI / 2
		$CameraRay.position = WEAPON_AIMING_POS.rotated(Vector3.UP, camera_angle_y) + \
			Vector3(0, 0.0825, 0.025).rotated(Vector3.RIGHT, -camera_angle_x + PI / 2).rotated(Vector3.UP, camera_angle_y)
		$Camera.fov = move_toward($Camera.fov, CAMERA_FOV_SHOULDER if camera_mode == CAMERA_MODES.SHOULDER else CAMERA_FOV_ADS, camera_speed_fov * delta)
		camera_max_dist = move_toward(camera_max_dist,
			CAMERA_MAX_DIST_SHOULDER if camera_mode == CAMERA_MODES.SHOULDER else CAMERA_MAX_DIST_ADS,
			camera_speed_max_dist * delta)
		camera_target_position_variable = move_toward(camera_target_position_variable, 1.0, (1.0 / CAMERA_SPEED_ADS) * delta)

	if camera_target_position_variable == 0.0:    # Common edge case
		camera_position = Vector3(0, 1.5, 0) + Vector3(
			sin(camera_angle_x) * sin(camera_angle_y),
			-cos(camera_angle_x),
			sin(camera_angle_x) * cos(camera_angle_y)) * camera_max_dist
		camera_target_position = CAMERA_CENTER_POSITION_TPP
	elif camera_target_position_variable == 1.0:    # Common edge case
		camera_position = WEAPON_AIMING_POS.rotated(Vector3.UP, camera_angle_y) + \
			Vector3(0, 0.0825, 0.025).rotated(Vector3.RIGHT, -camera_angle_x + PI / 2).rotated(Vector3.UP, camera_angle_y) + Vector3(
					sin(camera_angle_x) * sin(camera_angle_y),
					-cos(camera_angle_x),
					sin(camera_angle_x) * cos(camera_angle_y)) * camera_max_dist
		camera_target_position = camera_position + Vector3(0, 0, -1).rotated(Vector3.RIGHT, -camera_angle_x + PI / 2).rotated(Vector3.UP, camera_angle_y)
	else:    # Uncommon case between edges
		camera_position = (Vector3(0, 1.5, 0) + Vector3(
				sin(camera_angle_x) * sin(camera_angle_y),
				-cos(camera_angle_x),
				sin(camera_angle_x) * cos(camera_angle_y)) * camera_max_dist) * (1.0 - camera_target_position_variable) + \
			(WEAPON_AIMING_POS.rotated(Vector3.UP, camera_angle_y) + \
				Vector3(0, 0.0825, 0.025).rotated(Vector3.RIGHT, -camera_angle_x + PI / 2).rotated(Vector3.UP, camera_angle_y) + Vector3(
					sin(camera_angle_x) * sin(camera_angle_y),
					-cos(camera_angle_x),
					sin(camera_angle_x) * cos(camera_angle_y)) * camera_max_dist) * camera_target_position_variable
		camera_target_position = CAMERA_CENTER_POSITION_TPP * (1.0 - camera_target_position_variable) + \
			(camera_position + Vector3(0, 0, -1).rotated(Vector3.RIGHT, -camera_angle_x + PI / 2).rotated(Vector3.UP, camera_angle_y)) * camera_target_position_variable

	$Camera.position = camera_position
	$Camera.look_at(global_position + camera_target_position)
	$CameraRay.target_position = camera_position
	$CameraArea.position = camera_position

	if $CameraRay.is_colliding() and ($CameraArea.has_overlapping_bodies() or camera_mode == CAMERA_MODES.TPP):
		var camera_ray_collision_distance = $CameraRay.position.distance_to($CameraRay.get_collision_point() - $CameraRay.global_position + $CameraRay.position)
		if camera_ray_collision_distance < camera_max_dist:
			var to_move_camera = camera_max_dist - camera_ray_collision_distance
			to_move_camera += CAMERA_WALL_SAFETY_DIST * (1 - (camera_max_dist - (to_move_camera + CAMERA_WALL_SAFETY_DIST)) / camera_max_dist)
			$Camera.position = $Camera.position.move_toward(camera_target_position, to_move_camera)

			if camera_max_dist - to_move_camera < CAMERA_WALL_SAFETY_DIST:
				$Model.hide()
			elif not $Model.is_visible_in_tree():
				$Model.show()
	elif not $Model.is_visible_in_tree():
		$Model.show()



func _input(event):
	if event is InputEventMouseMotion:
		camera_angle_x += event.relative.y / 200
		camera_angle_y -= event.relative.x / 200
		if camera_angle_y > 2.0 * PI:
			camera_angle_y -= 2.0 * PI
		elif camera_angle_y < 0.0:
			camera_angle_y += 2.0 * PI
		camera_angle_x = clamp(camera_angle_x, CAMERA_ANGLE_X_MIN, CAMERA_ANGLE_X_MAX)



#func _unhandled_key_input(event):
	##if event.is_pressed() and event.physical_keycode == KEY_P:
		##shoulder_cam = not shoulder_cam
	#pass



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

		#print(global_position.y)

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
