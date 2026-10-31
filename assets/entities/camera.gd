extends Camera2D
class_name PlayerCamera

const LOOK_AHEAD_STRENGTH := 0.2
const LOOK_SMOOTHNESS := 8.0
const MAX_LOOK_DISTANCE := 500.0

@onready var player: Player = get_parent()
@onready var player_visuals: Node2D = $"../Visuals"
@onready var camera_limit_manager: CameraLimitManager = $CameraLimitManager

func _ready() -> void:
	top_level = true
	global_position = player_visuals.global_position

func _process(delta: float) -> void:
	var offset_vector := (get_global_mouse_position() - player_visuals.global_position)
	offset_vector = offset_vector.limit_length(MAX_LOOK_DISTANCE)

	var desired_position := player_visuals.global_position + offset_vector * LOOK_AHEAD_STRENGTH
	var weight := 1.0 - exp(-LOOK_SMOOTHNESS * delta)
	global_position = global_position.lerp(desired_position, weight)
