extends Node

const SAVE_PATH := "user://progress.cfg"

var completed: Dictionary = {}       # {level_id: true}
var unlocked: Dictionary = {1: true}

func _ready() -> void:
	load_progress()

func is_completed(level_id: int) -> bool:
	return completed.get(level_id, false)

func is_unlocked(level_id: int) -> bool:
	return unlocked.get(level_id, false)

func complete_level(level_id: int) -> void:
	completed[level_id] = true
	unlocked[level_id + 1] = true    # предполагает последовательные id
	save_progress()

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed", completed)
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.save(SAVE_PATH)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	completed = cfg.get_value("progress", "completed", {})
	unlocked = cfg.get_value("progress", "unlocked", {1: true})
