extends Node2D
class_name ActiveWeapon

@onready var player = $".."

var current_weapon: WeaponDetails
var weapons_array: Array = [WeaponDetails]

func set_weapon(weapon: WeaponDetails) -> void:
	current_weapon = weapon
	weapons_array.append(weapon)

func get_current_ammo() -> AmmoDetails:
	return current_weapon.ammo_details

func get_current_weapon() -> WeaponDetails:
	return current_weapon
