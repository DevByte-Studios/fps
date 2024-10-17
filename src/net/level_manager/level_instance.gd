extends Node
class_name LevelInstance

@export var scene: PackedScene = null
@export var level_name: String = ""

func _ready():
	level_name = get_name()	