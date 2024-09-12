class_name ActiveWeapon extends Node2D

signal weapon_setted(weapon:WeaponDetails)

var _current_weapon: WeaponDetails

func set_weapon(weapon: WeaponDetails) -> void:
	_current_weapon = weapon
	emit_signal("weapon_setted", weapon)
	print_rich("Weapon_setted signal emitted")

func get_current_ammo() -> AmmoDetails:
	return _current_weapon.ammo_details

func get_current_weapon() -> WeaponDetails:
	return _current_weapon
