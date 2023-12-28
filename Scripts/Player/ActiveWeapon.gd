extends Node2D
class_name ActiveWeapon

@onready var player = $".."

var active_weapon: WeaponDetails
var current_weapon: WeaponDetails

func _ready() -> void:
	player = $".."

func set_weapon(weapon: WeaponDetails) -> void:
	current_weapon = weapon
	active_weapon = current_weapon

func get_current_ammo() -> AmmoDetails:
	return current_weapon.ammo_details

func get_current_weapon() -> WeaponDetails:
	return current_weapon
