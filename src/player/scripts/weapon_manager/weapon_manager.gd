extends Camera3D

@onready var head := %head
@onready var camera := %head/Camera3D;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%head/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	%head/SubViewportContainer/SubViewport/view_model_camera.global_transform = camera.global_transform
