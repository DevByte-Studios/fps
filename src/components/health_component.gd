class_name HealthComponent
extends Node

signal on_damage(amount: int, slowdown_multiplier: float)
signal on_death()

@export var max_health: int = 100
@export var health: int = 100

@export var label: Label
func update_label() -> void:
	if label:
		label.text = str(health) + " / " + str(max_health)

func _ready():
	update_label()

func _on_damage(amount: int, slowdown_multiplier = 1.0) -> void:
	on_damage.emit(amount, slowdown_multiplier)
	health = max(0, health - amount)
	if health == 0:
		on_death.emit()

	update_label()
