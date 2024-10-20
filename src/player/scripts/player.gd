class_name Player
extends CharacterBody3D


const JUMP_VELOCITY = 8

const GRAVITY = -25

@export var peer_id: int = -1

@onready var head := $head
@onready var camera := $head/Camera3D;

@onready var feet_sound_source: NetworkSoundSource = $MovementSoundSource

@onready var standup_raycast = $CanStandUp

@onready var visual_character = $Character as VisualCharacter

@onready var weapon_manager = $WeaponManager as WeaponManager

@rpc("authority", "call_local")
func c_spawn_at(spawn_location: Vector3) -> void:
	global_transform.origin = spawn_location

func _ready():
	peer_id = name.to_int()
	set_multiplayer_authority(peer_id)

	if is_multiplayer_authority():
		$head/Camera3D.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		$head/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()
		$Character.visible = false
	else:
		$HUD.queue_free()
		$head/Camera3D.queue_free()
		$head/SubViewportContainer.queue_free()
		$WeaponManager.queue_free()

var step_sound_build_up = 0
const STEP_SOUND_INTERVAL = 0.03

var last_delta = 0.0

var last_motion_can_produce_step = false

var jump_cayote_window = 0
var is_in_air = false
var highest_air_point = 0

var speed_penalty = 0.0


@export var is_crouching = false
func update_animations():
	$AnimationTree.set("parameters/crouch_transition/transition_request", "crouching" if is_crouching else "standing")

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		update_animations()
		return

	# Add the gravity.
	var gravity_normal = get_floor_normal() if is_on_floor() else Vector3.UP
	if not is_on_floor():
		velocity += gravity_normal.normalized() * delta * GRAVITY

	if is_on_floor():
		if is_in_air:
			var fallen_height = highest_air_point - global_transform.origin.y
			if fallen_height > .5:
				feet_sound_source.play_sound("land")
			is_in_air = false
			highest_air_point = 0

		jump_cayote_window = 0.1 
	else:
		jump_cayote_window -= delta

		highest_air_point = max(highest_air_point, global_transform.origin.y)
		if not is_in_air:
			is_in_air = true

	visual_character.is_falling = not is_on_floor()

	var can_jump = jump_cayote_window > 0

	# Handle jump.
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_VELOCITY
		jump_cayote_window = 0


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	speed_penalty = clamp(speed_penalty - delta * 1.75, 0, 2) # 2

	var is_walking = Input.is_action_pressed("walk")
	var SPEED = 2.3 if is_walking else 5.0

	var tries_crouching = Input.is_action_pressed("crouch")
	if tries_crouching:
		SPEED = 1.5
	is_crouching = tries_crouching
	visual_character.is_crouching = is_crouching

	SPEED /= speed_penalty + 1

	var last_frame_hor_mov = get_position_delta()
	last_frame_hor_mov.y = 0

	visual_character.horizontal_speed = last_frame_hor_mov.length() / last_delta

	if last_motion_can_produce_step and is_on_floor():
		step_sound_build_up += last_frame_hor_mov.length() * delta
		if step_sound_build_up > STEP_SOUND_INTERVAL:
			feet_sound_source.play_sound("step", 1, randf_range(0.8, 1.2))
			step_sound_build_up = 0

	last_motion_can_produce_step = not is_walking and is_on_floor()

	var acceleration = 10.0 if is_on_floor() else 5.0

	var lerper = acceleration * delta
	velocity.x = lerp(velocity.x, direction.x * SPEED, lerper)
	velocity.z = lerp(velocity.z, direction.z * SPEED, lerper)

	visual_character.vertical_rotation = camera.rotation.x

	move_and_slide()
	update_animations()
	last_delta = delta


const MOUSE_SENSITIVITY = 0.0008;

var base_target_look = Vector2.ZERO
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		base_target_look -= event.relative * MOUSE_SENSITIVITY
		base_target_look.y = clamp(base_target_look.y, -1.5, 1.5)

func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	var target_look = base_target_look + (weapon_manager.net_recoil / 2)
	rotation.y = target_look.x
	camera.rotation.x = target_look.y


@export var death_screen: PackedScene
func on_died():
	peer_on_died.rpc()
	var death_screen_instance: Node3D = death_screen.instantiate()
	get_tree().root.add_child(death_screen_instance)
	death_screen_instance.global_transform.origin = camera.global_transform.origin
	death_screen_instance.look_at(camera.global_transform.origin - camera.global_transform.basis.z, Vector3.UP)


@onready var match_manager = get_tree().root.get_node("MultiplayerRoom").get_node("Match") as Match

@rpc("any_peer", "call_local")
func peer_on_died():
	visual_character.get_parent().remove_child(visual_character)
	get_parent().add_child(visual_character)
	visual_character.global_transform = global_transform
	visual_character.ragdoll()
	print("ragdoll")

	queue_free()



	if multiplayer.is_server():
		match_manager.s_player_died(peer_id)


func _on_health_component_on_damage(amount: int, slowdown_multiplier) -> void:
	print("I took damage")
	print("bullet impact")
	feet_sound_source.play_sound("bullet_impact", 2)
	speed_penalty += amount * 0.1 * slowdown_multiplier
