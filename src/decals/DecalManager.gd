class_name DecalManager
extends Node3D

@export var blood_decal: PackedScene

func spawn_blood(point: Vector3, dir: Vector3) -> void:
    c_spawn_blood.rpc(point, dir)

@rpc("any_peer", "call_local")
func c_spawn_blood(point: Vector3, dir: Vector3) -> void:
    var blood: Node3D = blood_decal.instantiate()
    add_child(blood)
    blood.global_transform.origin = point
    blood.look_at(blood.global_transform.origin + dir, Vector3.UP)
    blood.add_to_group("blood")
    blood.add_to_group("remove_on_reset")