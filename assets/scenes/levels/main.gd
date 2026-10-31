extends Node2D

@export var available_levels: Array[LevelData]

@onready var _2d_scene = $"."

func _ready() -> void :
	LevelManager.main_scene = _2d_scene
	LevelManager.levels = available_levels
