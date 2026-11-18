extends Node2D
class_name Level

@export var level_id: int
@export var initial_camera_limiter: CameraLimiter

var level_data: LevelData

@onready var player: Player = $Player
@onready var level_start_position: Node2D = $PlayerStart
