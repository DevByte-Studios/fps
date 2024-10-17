class_name WeaponInstance

var weapon_type: WeaponConfig = WeaponConfig.new()

var ammo: int = 0
var reserve_ammo: int = 0


static func _new(type: WeaponConfig) -> WeaponInstance:
	var instance = WeaponInstance.new()
	instance.weapon_type = type
	instance.ammo = type.magazine_size
	instance.reserve_ammo = type.reserve_ammo
	return instance
