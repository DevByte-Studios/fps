class_name BulletHitbox
extends Area3D

func _on_bullet_hit(damage: int) -> void:
	_on_bullet_hit_rpc.rpc(damage)


@export var health_component: HealthComponent

@rpc("any_peer", "call_local")
func _on_bullet_hit_rpc(damage: int) -> void:
	if is_multiplayer_authority():
		health_component._on_damage(damage)
	
