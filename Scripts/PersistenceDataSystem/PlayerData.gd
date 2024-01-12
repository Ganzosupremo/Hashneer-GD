class_name PlayerData extends Resource

@export var speed: float
@export var health: float
@export var current_weapon: WeaponDetails
@export var weapons_array: Array

func _init(_speed: float = 0.0, _health: float = 0.0, _current_weapon = WeaponDetails.new(), _weapon_array = [WeaponDetails]) -> void:
	speed = _speed
	health = _health
	current_weapon = _current_weapon
	weapons_array = weapons_array
