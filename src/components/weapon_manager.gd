class_name WeaponManager
extends Node

@export var head: Node;
@export var raycast: RayCast3D;
@export var view_model: Camera3D;

@export var guns: Array[WeaponConfig] = [];

var selected_weapon: String = "primary"

var weapons = {}

func _ready() -> void:
	raycast.add_exception(head.get_parent())
	raycast.add_exception(head.get_parent().get_node('BulletHitbox'))

	weapons = {
		"primary": WeaponInstance._new(guns[0]),
		"secondary": null,
	}

	update_view_model()

func get_current_weapon() -> WeaponInstance:
	return weapons[selected_weapon]

func set_current_weapon(slot: String) -> void:
	if slot in weapons:
		selected_weapon = slot
	else:
		print("Error: Weapon not found")
	
	update_view_model()

func update_view_model():
	for child in view_model.get_node('fps_rig').get_children():
		print(child.name, weapons[selected_weapon].weapon_type.model_name.to_lower())
		if child.name.to_lower() == weapons[selected_weapon].weapon_type.model_name.to_lower():
			child.show()
		else:
			child.hide()

func play_sound(stream):
	if not stream:
		print('Error: Invalid audio stream')
		
	var audioPlayer = AudioStreamPlayer3D.new()
	add_child(audioPlayer)
	audioPlayer.stream = stream
	audioPlayer.play()

	await audioPlayer.finished
	audioPlayer.queue_free()

func attack() -> void:
	var current_weapon = get_current_weapon()
	if !current_weapon:
		print("Error: No weapon selected")
		return

	if current_weapon.ammo > 0:
		current_weapon.ammo -= 1
		if raycast.is_colliding():
			var collider = raycast.get_collider()
		
			if(collider is BulletHitbox):
				collider._on_bullet_hit(current_weapon.weapon_type.base_damage)
	else:
		reload()

func reload():
	var current_weapon = get_current_weapon()
	if !current_weapon:
		print("Error: No weapon selected")
		return

	if current_weapon.ammo < current_weapon.weapon_type.magazine_size:
		current_weapon.ammo = current_weapon.weapon_type.magazine_size
	else:
		print("Error: Weapon is already full")


# Handle weapon swtiching and attack
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon_primary"):
		set_current_weapon("primary")
	elif event.is_action_pressed("weapon_secondary"):
		set_current_weapon("secondary")
	elif event.is_action_pressed("weapon_knife"):
		set_current_weapon("knife")
	elif event.is_action_pressed("primary_attack"):
		attack()

	
