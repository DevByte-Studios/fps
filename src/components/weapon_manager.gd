class_name WeaponManager
extends Node

@export var head: Node;
@export var raycast: RayCast3D;
@export var view_model: Camera3D;
@export var cooldown_timer: Timer;

@export var guns: Array[WeaponConfig] = [];

@onready var sound_source: NetworkSoundSource = $NetworkSoundSource

var selected_weapon: String = "primary"

var weapons = {}

func _ready() -> void:
	# Add head to raycast exceptions
	raycast.add_exception(head.get_parent())
	raycast.add_exception(head.get_parent().get_node('BulletHitbox'))

	# Initialize weapons
	weapons = {
		"primary": WeaponInstance._new(guns[0]),
		"secondary": null,
		"melee": null
	}

	update_view_model()

	get_current_weapon().can_fire = true

	# Initialize timer
	cooldown_timer.one_shot = true
	cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_timer_timeout"))

func get_current_weapon() -> WeaponInstance:
	return weapons[selected_weapon]

func get_current_weapon_animation() -> AnimationPlayer:
	var weapon = get_current_weapon()
	
	if weapon:
		return view_model.get_node('fps_rig').get_node(weapon.weapon_type.view_model_name).get_node("AnimationPlayer")
	else:
		return null

func set_current_weapon(slot: String) -> void:
	# Check slot is dirrent to current active slot
	if slot == selected_weapon:
		return
		
	if slot in weapons:
		if weapons[slot]:
			selected_weapon = slot

			update_view_model()

			get_current_weapon_animation().play("equip")
		else: 
			print("Error: Weapon not found")
	else:
		print("Error: Weapon not found")
	
func update_view_model():
	for child in view_model.get_node('fps_rig').get_children():
		if child.name.to_lower() == weapons[selected_weapon].weapon_type.model_name.to_lower():
			child.show()
		else:
			child.hide()

func attack() -> void:
	var current_weapon = get_current_weapon()
	if !current_weapon:
		print("Error: No weapon selected")
		return

	if !current_weapon.can_fire:
		return # Cooldown in progress

	if current_weapon.ammo > 0:
		current_weapon.ammo -= 1

		get_current_weapon_animation().play("fire")
		sound_source.play_sound(current_weapon.weapon_type.fire_sound)

		if raycast.is_colliding():
			var collider = raycast.get_collider()
		
			if(collider is BulletHitbox):
				collider._on_bullet_hit(current_weapon.weapon_type.base_damage)

		# Set the cooldown
		current_weapon.can_fire = false
		cooldown_timer.start(current_weapon.weapon_type.fire_rate)
	else:
		reload()

func _on_cooldown_timer_timeout() -> void:
	get_current_weapon().can_fire = true

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

	
