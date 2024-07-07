extends Node3D

var walking: bool = false
var passed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func start_walk():
	if walking:
		return
	$Walk.play()
	walking = true
	
func stop_walk():
	walking = false
	$Walk.stop()

