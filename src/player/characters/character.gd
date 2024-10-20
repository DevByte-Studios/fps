class_name VisualCharacter
extends Node3D


@export var hitbox_parent: Node3D

@export var player_health_component: HealthComponent

@export var raycasts_to_disable: Array[RayCast3D]

@export var physical_bones_controller: PhysicalBoneSimulator3D

@export var remove_on_ragdoll: Array[Node]

@export var vertical_rotation: float = 0

@export var vertical_look_bones: Array[String]

@export var main_skeleton: Skeleton3D

var is_ragdolled = false

func ragdoll():
	is_ragdolled = true
	for node in remove_on_ragdoll:
		node.queue_free()
	physical_bones_controller.active = true
	physical_bones_controller.physical_bones_start_simulation()

	await get_tree().create_timer(3.0).timeout
	physical_bones_controller.active = false
	add_to_group("ragdoll")
	add_to_group("remove_on_reset")


func _ready():
	for bone_att in hitbox_parent.get_children():
		for pot_node in bone_att.get_children():
			if pot_node is BulletHitbox:
				var hitbox = pot_node as BulletHitbox
				print("Setting health component")
				hitbox.health_component = player_health_component
				hitbox.collision_layer = 2
				for raycast in raycasts_to_disable:
					raycast.add_exception(hitbox)

@export var horizontal_speed: float = 0
@export var is_falling: bool = false
@export var is_crouching: bool = false

@onready var anim_tree := $AnimationTree

var current_falling_strength = 0.0

func _process(delta: float) -> void:
	if is_ragdolled:
		return
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

	# Vertical look
	# we need to normalize the rotation to -1 to 1 from -90deg to 90deg in radians
	var deg_vertical_rotation = rad_to_deg(vertical_rotation)
	anim_tree.set("parameters/vertical_look/add_amount", deg_vertical_rotation / 90)
