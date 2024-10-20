class_name WeaponManager
extends Node

@export var head: Node;
@export var camera: Camera3D;
@export var raycast: RayCast3D;
@export var view_model: Camera3D;
@export var cooldown_timer: Timer;
@export var sound_source: NetworkSoundSource;
@export var decal_manager: DecalManager

@export var ammo_label: Label;

@export var guns: Array[WeaponConfig] = [];

var selected_weapon: String = "primary"

var weapons = {}


var is_firing_automatic = false
@onready var automatic_fire_timer = $AutomaticFireTimer

@export var net_recoil = Vector2.ZERO
var recoil_time = 0.0

const RECOIL_VECTOR_RECOVERY = 3
func _process(delta: float) -> void:
	net_recoil.x = lerp(net_recoil.x, 0.0, delta * RECOIL_VECTOR_RECOVERY)
	net_recoil.y = lerp(net_recoil.y, 0.0, delta * RECOIL_VECTOR_RECOVERY)
	recoil_time = move_toward(recoil_time, 0, delta * 0.005)

	# Update the raycast
	print(raycast.rotation.x)
	raycast.rotation.y = net_recoil.x / 2
	raycast.rotation.x = net_recoil.y / 2 + deg_to_rad(90)

	# Update ammo label
	var current_weapon = get_current_weapon()
	if current_weapon:
		ammo_label.text = str(current_weapon.ammo) + "/" + str(current_weapon.weapon_type.reserve_ammo)
	else:
		ammo_label.text = "0/0"

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

	# Initialize automatic fire timer
	automatic_fire_timer = Timer.new()
	automatic_fire_timer.one_shot = true
	automatic_fire_timer.connect("timeout", Callable(self, "_on_AutomaticFireTimer_timeout"))
	add_child(automatic_fire_timer)

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
		if child.name.to_lower() == weapons[selected_weapon].weapon_type.view_model_name.to_lower():
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
		sound_source.play_sound(current_weapon.weapon_type.fire_sound, 0.5)
		recoil_time += 1 / current_weapon.weapon_type.magazine_size
		var vert = current_weapon.weapon_type.vertical_recoil_strength / 100
		var hor = current_weapon.weapon_type.horizontal_recoil_strength / 100
		net_recoil += Vector2(
			hor * randf_range(-1, 1),
			vert + randf_range(-0.1, 0.1) * vert # +- 10% of vertical recoil
		)

		if raycast.is_colliding():
			var collider = raycast.get_collider()
			print("Collider: ", collider)
			if(collider is BulletHitbox):
				collider._on_bullet_hit(current_weapon.weapon_type.base_damage)
				var collision_point = raycast.get_collision_point()
				var blood_dir = (raycast.global_transform.origin - collision_point).normalized()
				decal_manager.spawn_decal(
					"blood",	
					collision_point,
					blood_dir
				)
				decal_manager.spawn_decal(
					"blood",
					collision_point,
					(3 * Vector3.UP + blood_dir).normalized()
				)
			else:
				var collision_point = raycast.get_collision_point()
				var normal = raycast.get_collision_normal()
				decal_manager.spawn_decal(
					"bullet_hole",
					collision_point,
					normal
				)
		# Set the cooldown
		current_weapon.can_fire = false
		cooldown_timer.start(current_weapon.weapon_type.fire_rate)
	else:
		reload()

func start_firing() -> void:
	var current_weapon = get_current_weapon()
	if current_weapon and current_weapon.weapon_type.weapon_type == WeaponConfig.WeaponType.AUTOMATIC:
		is_firing_automatic = true
		automatic_fire()
	elif current_weapon and current_weapon.weapon_type.weapon_type == WeaponConfig.WeaponType.SEMI_AUTOMATIC:
		attack()

func stop_firing() -> void:
	is_firing_automatic = false
	automatic_fire_timer.stop()

func automatic_fire() -> void:
	if is_firing_automatic:
		attack()
		automatic_fire_timer.start(0.0001)

func _on_AutomaticFireTimer_timeout() -> void:
	automatic_fire()

func _on_cooldown_timer_timeout() -> void:
	get_current_weapon().can_fire = true

func reload():
	var current_weapon = get_current_weapon()
	if !current_weapon:
		print("Error: No weapon selected")
		return

	if current_weapon.ammo < current_weapon.weapon_type.magazine_size:
		current_weapon.can_fire = false

		get_current_weapon_animation().play("reload")

		sound_source.play_sound(current_weapon.weapon_type.reload_sound, 0.5)
		
		cooldown_timer.start(current_weapon.weapon_type.reload_time)

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
		start_firing()
	elif event.is_action_released("primary_attack"):
		stop_firing()
	elif event.is_action_pressed("reload"):
		reload()

	
