# Level Manager to change Level client side
class_name LevelManager
extends Node

@export var levels: Array[LevelInstance]

@export var level_container: Node3D = null

@rpc("authority", "call_local")
func change_level(level_name: String) -> void:
	# first remove the current level
	for child in level_container.get_children():
		child.queue_free()


	# then add the new level
	var level_instance = levels[levels.find(func (x): x.level_name == level_name)].scene.instantiate()
	level_container.add_child(level_instance)
