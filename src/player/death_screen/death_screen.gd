extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("deathscreen hello")
	$AnimationPlayer.play("death_screen")
	$Camera3D.current = true

func _process(_delta: float) -> void:
	if not ($Camera3D as Camera3D).current:
		print("deathscreen bye")
		queue_free()