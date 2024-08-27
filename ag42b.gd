extends Node3D

const bullet = preload("res://ScenesAndScripts/Characters/bullet.tscn")
const flash = preload("res://ScenesAndScripts/Characters/Flash.tscn")

const BULLET_START_POSITION = Vector3(0.0, 0.05, -0.85)



func fire():
	var b = bullet.instantiate()
	var f = flash.instantiate()
	get_tree().root.add_child(f)
	var dir: Vector3 = -global_basis.z
	b.position = to_global(BULLET_START_POSITION)
	f.position = b.position
	f.emitting = true
	f.finished.connect(f.queue_free)
	b.player_pos = to_global(BULLET_START_POSITION)
	b.linear_velocity = -global_basis.z * 100
	get_tree().root.add_child(b)
	$ShootAudio.play()
