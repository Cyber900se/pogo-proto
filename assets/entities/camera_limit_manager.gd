extends Node2D

class_name CameraLimitManager

@export var limit_transition_speed = 3

@onready var camera: Camera2D = get_parent()

const MAX_LIMIT = 100000

var camera_bounds_x_min
var camera_bounds_x_max
var camera_bounds_y_min
var camera_bounds_y_max

var limit_left_target: float = - MAX_LIMIT
var limit_right_target: float = MAX_LIMIT
var limit_top_target: float = - MAX_LIMIT
var limit_bottom_target: float = MAX_LIMIT

func _ready():
	var camera_bounds = get_viewport_rect()
	camera_bounds_x_min = camera_bounds.position.x
	camera_bounds_y_min = camera_bounds.position.y
	camera_bounds_x_max = camera_bounds.end.x
	camera_bounds_y_max = camera_bounds.end.y

func _physics_process(_delta):
	camera.limit_left = _calc_limit(camera.limit_left, limit_left_target, true)
	camera.limit_right = _calc_limit(camera.limit_right, limit_right_target, true)
	camera.limit_top = _calc_limit(camera.limit_top, limit_top_target, false)
	camera.limit_bottom = _calc_limit(camera.limit_bottom, limit_bottom_target, false)

func _calc_limit(current_limit, target_limit, is_x):
	if current_limit == target_limit:
		return current_limit
	var clamp_limit = _clamp_limit(current_limit, is_x)
	return _move_limit_toward(clamp_limit, target_limit)

func _clamp_limit(limit, is_x):
	var player_pos = camera.player.global_position.x if is_x else camera.player.global_position.y
	var is_limit_after_player = sign(limit - player_pos)
	var clamp_value
	if is_x:
		clamp_value = camera_bounds_x_max if is_limit_after_player else camera_bounds_x_min
	else:
		clamp_value = camera_bounds_y_max if is_limit_after_player else camera_bounds_y_min

	return minf(clamp_value, limit) if is_limit_after_player else maxf(clamp_value, limit)

func _move_limit_toward(current, target):
	if abs(current) >= MAX_LIMIT || abs(target) >= MAX_LIMIT:
		return target
	if current != target:
		return move_toward(current, target, limit_transition_speed)
	return target

func set_limiter(limiter: CameraLimiter, instant = false):
	limit_left_target = limiter.get_limit_left()
	limit_right_target = limiter.get_limit_right()
	limit_top_target = limiter.get_limit_top()
	limit_bottom_target = limiter.get_limit_bottom()
	if instant:
		camera.limit_left = limit_left_target
		camera.limit_right = limit_right_target
		camera.limit_top = limit_top_target
		camera.limit_bottom = limit_bottom_target
