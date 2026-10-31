extends PathFollow2D

@export var speed: float = 0.2
@export var wait_time: float = 1.0

var direction: = 1.0
var waiting: = false
var wait_timer: = 0.0

func _ready():
	rotates = false
	add_to_group("moving_platform")

func _process(delta):
	if waiting:
		wait_timer -= delta
		if wait_timer <= 0.0:
			waiting = false
		return

	progress_ratio += delta * speed * direction


	if progress_ratio >= 1.0:
		progress_ratio = 1.0
		direction = -1.0
		_start_wait()
	elif progress_ratio <= 0.0:
		progress_ratio = 0.0
		direction = 1.0
		_start_wait()

func _start_wait():
	waiting = true
	wait_timer = wait_time
