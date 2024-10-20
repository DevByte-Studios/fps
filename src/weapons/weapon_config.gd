class_name WeaponConfig
extends Resource

@export_group("Basic Information")

@export var display_name: String = "Weapon"
@export var model_name: String;
@export var view_model_name: String;

@export_group("Type")

@export var magazine_size: int;
@export var reserve_ammo: int;

@export var fire_rate: float;
@export var weapon_type: WeaponType;
@export var reload_time: float;
@export var has_crosshair: bool;

@export_group("Damage")

@export var base_damage: int;
@export var armor_penetration: int;

@export_group("Recoil and Spread")

@export var vertical_recoil_strength: float;
@export var horizontal_recoil_strength: float;

@export_group("Audio Streams")

@export var fire_sound: String;
@export var reload_sound: String;


enum WeaponType {
    AUTOMATIC,
    SEMI_AUTOMATIC,
}


