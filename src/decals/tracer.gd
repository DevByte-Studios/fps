class_name Tracer
extends Node3D

@export var target = Vector3.ZERO
@export var start = Vector3.ZERO

@onready var visual = $TravelVisual

const SPEED = 160


var distance := 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# make sure we are pointing at the target
	global_transform.origin = start
	look_at(target, Vector3.UP)
	distance = start.distance_to(target)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	visual.transform.origin.z = move_toward(visual.transform.origin.z, -distance, SPEED * delta)
	if visual.transform.origin.z <= -distance:
		queue_free()
		print("Tracer reached target")
		return
