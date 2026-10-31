extends Node2D
class_name Level

@export var level_id: int
@export var initial_camera_limiter: CameraLimiter

var level_data: LevelData

@onready var player: Player = $Player
@onready var level_start_position: Node2D = $PlayerStart

#func _ready() -> void:
#	if not level_data:
#		level_data = LevelManager.get_level_data_by_id(level_id)
#	if initial_camera_limiter:
#		player.camera.camera_limit_manager.set_limiter(initial_camera_limiter, true)
