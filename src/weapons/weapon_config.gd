class_name WeaponConfig
extends Resource

@export var display_name: String = "Weapon"
@export var model_name: String;
@export var view_model_name: String;
@export var magazine_size: int;
@export var reserve_ammo: int;
@export var has_crosshair: bool;

@export var fire_rate: float;
@export var weapon_type: WeaponType;

@export var base_damage: int;
@export var armor_penetration: int;

@export_group("Audio Streams")

@export var fire_sound: String;
@export var reload_sound: String;


enum WeaponType {
    AUTOMATIC,
    SEMI_AUTOMATIC,
}


