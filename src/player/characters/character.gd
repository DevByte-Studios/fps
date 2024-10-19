class_name VisualCharacter
extends Node3D


@export var horizontal_speed: float = 0
@export var is_falling: bool = false
@export var is_crouching: bool = false

@onready var anim_tree := $AnimationTree

var current_falling_strength = 0.0

func _process(delta: float) -> void:
	anim_tree.set("parameters/Walking_speed/scale", horizontal_speed / 3)
	anim_tree.set("parameters/Crouching_speed/scale", horizontal_speed / 3)
	var is_walking = horizontal_speed > 0.1

	anim_tree.set("parameters/Legs_transitions/transition_request", "Walking" if is_walking else "Idle")

	anim_tree.set("parameters/Crouching_transition/transition_request", "yes" if is_crouching else "no")


	if is_falling:
		current_falling_strength += 3 * delta
	else:
		current_falling_strength -= 8 * delta

	current_falling_strength = clamp(current_falling_strength, 0.0, 1.0)
	anim_tree.set("parameters/Falling_strength/blend_amount", current_falling_strength)