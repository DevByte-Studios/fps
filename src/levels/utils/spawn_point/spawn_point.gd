extends Node
class_name SpawnPoint

@export var allow_in_deathmatch: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MeshInstance3D.queue_free()
	add_to_group("spawn_point")