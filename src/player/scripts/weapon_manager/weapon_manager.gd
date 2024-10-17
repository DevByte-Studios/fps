extends Camera3D

@onready var head := %head
@onready var camera := %head/Camera3D;
@onready var raycast := %head/Camera3D/RayCast3D;
@onready var fps_rig := $fps_rig
@onready var animation_player := $fps_rig/shotgun/AnimationPlayer

# Gun variables

var gunshot_sound # remove and add to config

#####################

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	%head/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Set the view model camera to the global camera transform.
	%head/SubViewportContainer/SubViewport/view_model_camera.global_transform = camera.global_transform

	# Sway the camera.
	fps_rig.position.x = lerp(fps_rig.position.x, 0.0, delta*5)
	fps_rig.position.y = lerp(fps_rig.position.y, 0.0, delta*5)

func sway(sway_amount):
	fps_rig.position.x += sway_amount.x*0.000015
	fps_rig.position.y += sway_amount.y*0.000015

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		sway(Vector2(event.relative.x, event.relative.y))

func play_sound(stream):
	if not stream:
		print('Error: Invalid audio stream')
		
	var audioPlayer = AudioStreamPlayer3D.new()
	add_child(audioPlayer)
	audioPlayer.stream = stream
	audioPlayer.play()

	await audioPlayer.finished
	audioPlayer.queue_free()


func fire():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		if(collider is BulletHitbox):
			collider._on_bullet_hit(10)

	animation_player.play("fire")

	play_sound(gunshot_sound)
