class_name BulletHitbox
extends Area3D

func _on_bullet_hit(damage: int) -> void:
	_on_bullet_hit_rpc.rpc(damage * damage_multiplier)


@export var health_component: HealthComponent

@export var damage_multiplier: float = 1.0
@export var is_headshot: bool = false
@export var slowdown_multiplier: float = 1.0

@rpc("any_peer", "call_local")
func _on_bullet_hit_rpc(damage: int) -> void:
	if is_multiplayer_authority():
		health_component._on_damage(damage, slowdown_multiplier)
	
