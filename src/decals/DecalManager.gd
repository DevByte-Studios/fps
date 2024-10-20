class_name DecalManager
extends Node3D

@export var decals: Dictionary

func spawn_decal(decal: String, point: Vector3, dir: Vector3) -> void:
	c_spawn_decal.rpc(decal, point, dir)

@rpc("any_peer", "call_local")
func c_spawn_decal(decal: String, point: Vector3, dir: Vector3) -> void:
	print("Spawning decal")
	var instance: Node3D = decals.get(decal).instantiate()
	add_child(instance)
	print(instance)
	instance.global_transform.origin = point
	instance.look_at(instance.global_transform.origin + dir, Vector3.UP)
	instance.add_to_group("decal")
	instance.add_to_group("remove_on_reset")
