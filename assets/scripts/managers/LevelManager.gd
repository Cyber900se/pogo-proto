extends Node

signal level_loaded(level: Level)

var levels: Array[LevelData]

var main_scene: Node2D = null
var loaded_level: Level = null

func unload_level() -> void:
	if is_instance_valid(loaded_level):
		var old := loaded_level
		loaded_level = null
		old.queue_free()
		await old.tree_exited

func load_level(level_id: int) -> bool:
	await unload_level()

	if not is_instance_valid(main_scene):
		push_error("LevelManager: main_scene не задан")
		return false

	var level_data := get_level_data_by_id(level_id)
	if not level_data:
		push_error("LevelManager: нет уровня с id %d" % level_id)
		return false

	var level_path := "res://assets/scenes/%s.tscn" % level_data.level_path
	if not ResourceLoader.exists(level_path):
		push_error("LevelManager: нет файла %s" % level_path)
		return false

	var packed := load(level_path) as PackedScene
	if not packed:
		return false

	var instance := packed.instantiate()
	if not instance is Level:
		push_error("LevelManager: корень сцены %s не Level" % level_path)
		instance.queue_free()
		return false

	loaded_level = instance as Level
	loaded_level.level_data = level_data
	main_scene.add_child(loaded_level)
	level_loaded.emit(loaded_level)
	return true

func get_level_data_by_id(id: int) -> LevelData:
	for lvl: LevelData in levels:
		if lvl.level_id == id:
			return lvl
	return null
