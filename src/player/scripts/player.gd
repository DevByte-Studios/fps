class_name Player
extends CharacterBody3D


const JUMP_VELOCITY = 8

const GRAVITY = -25

@export var peer_id: int = -1

@onready var head := $head
@onready var camera := $head/Camera3D;

@onready var sound_source: NetworkSoundSource = $NetworkSoundSource

@onready var standup_raycast = $CanStandUp

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
	else:
		$HUD.queue_free()
		$head.queue_free()
		$WeaponManager.queue_free()

var step_sound_build_up = 0
const STEP_SOUND_INTERVAL = 0.03

var last_motion_can_produce_step = false

var jump_cayote_window = 0
var is_in_air = false
var highest_air_point = 0

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	$head/SubViewportContainer/SubViewport/view_model_camera.global_transform = camera.global_transform # remove after pull

	# Add the gravity.
	var gravity_normal = get_floor_normal() if is_on_floor() else Vector3.UP
	if not is_on_floor():
		velocity += gravity_normal.normalized() * delta * GRAVITY

	if is_on_floor():
		if is_in_air:
			var fallen_height = highest_air_point - global_transform.origin.y
			if fallen_height > .5:
				sound_source.play_sound("land")
			is_in_air = false
			highest_air_point = 0

		jump_cayote_window = 0.1 
	else:
		jump_cayote_window -= delta

		highest_air_point = max(highest_air_point, global_transform.origin.y)
		if not is_in_air:
			is_in_air = true

	var can_jump = jump_cayote_window > 0

	# Handle jump.
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = JUMP_VELOCITY
		jump_cayote_window = 0


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_walking = Input.is_action_pressed("walk")
	var SPEED = 2.3 if is_walking else 5.0

	var is_crouching = Input.is_action_pressed("crouch")
	$AnimationTree.set("parameters/crouch_transition/transition_request", "crouched" if is_crouching else "standing")
	if is_crouching:
		SPEED = 1.5


	if last_motion_can_produce_step and is_on_floor():
		var mov_delta = get_position_delta()
		mov_delta.y = 0
		step_sound_build_up += mov_delta.length() * delta
		if step_sound_build_up > STEP_SOUND_INTERVAL:
			sound_source.play_sound("step", 1, randf_range(0.8, 1.2))
			print("step")
			step_sound_build_up = 0

	last_motion_can_produce_step = not is_walking and is_on_floor()

	var acceleration = 10.0 if is_on_floor() else 5.0

	var lerper = acceleration * delta
	velocity.x = lerp(velocity.x, direction.x * SPEED, lerper)
	velocity.z = lerp(velocity.z, direction.z * SPEED, lerper)

	move_and_slide()


const MOUSE_SENSITIVITY = 0.0008;

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x - event.relative.y * MOUSE_SENSITIVITY, -1.5, 1.5)


func on_died():
	print("I died")
	peer_on_died.rpc()

@onready var match_manager = get_tree().root.get_node("MultiplayerRoom").get_node("Match") as Match

@rpc("any_peer", "call_local")
func peer_on_died():
	print("peer_on_died")
	queue_free()
	if multiplayer.is_server():
		match_manager.s_player_died(peer_id)
