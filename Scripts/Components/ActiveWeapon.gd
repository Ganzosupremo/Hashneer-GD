class_name ActiveWeaponComponent extends Node2D

signal weapon_setted(weapon: WeaponDetails)

@onready var _sound_component: SoundEffectComponent = $ActiveWeaponSoundComponent

var _current_weapon: WeaponDetails
var _current_weapon_index: int = 0
var _weapons_list: Array = []

func set_weapon(weapon: WeaponDetails) -> void:
	_current_weapon = weapon
	_sound_component.set_sound(_current_weapon.fire_sound)
	add_weapon_to_list(weapon)
	weapon_setted.emit(weapon)

func set_weapon_by_index(index:int) -> void:
	if index - 1 < _weapons_list.size():
		_current_weapon_index = index
		set_weapon(_weapons_list[index-1])


func add_weapon_to_list(weapon: WeaponDetails) -> void:
	if _weapons_list.has(weapon): return
	
	_weapons_list.append(weapon)
		
	# Update the index on the weapon details
	for i in _weapons_list.size():
		_weapons_list[i].weapon_list_index = i


func select_next_weapon():
	_current_weapon_index += 1
	
	if _current_weapon_index > _weapons_list.size():
		_current_weapon_index = 1
	
	set_weapon_by_index(_current_weapon_index)


func select_previous_weapon() -> void:
	_current_weapon_index -= 1
	
	if _current_weapon_index < 1:
		_current_weapon_index = _weapons_list.size()
	
	set_weapon_by_index(_current_weapon_index)


func play_sound_on_fire() -> void:
	_sound_component.play_sound()

func get_current_ammo() -> AmmoDetails:
	return _current_weapon.ammo_details

func get_current_weapon() -> WeaponDetails:
	return _current_weapon

func get_current_weapon_fire_sound() -> SoundEffectDetails:
	return _current_weapon.fire_sound
