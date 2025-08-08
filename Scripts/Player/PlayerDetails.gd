class_name PlayerDetails extends Resource

@export_category("Player Basic Details")
@export var speed: float = 250.0
@export var max_health: float = 100.0
@export var damage_multiplier_percent: float = 1.0

@export_category("Weapons")
@export var initial_weapon: WeaponDetails
@export var weapons_array: Array[WeaponDetails] = []

@export_category("Sounds and VFX")
@export var move_sound_effect: SoundEffectDetails
@export var hit_sound_effect: SoundEffectDetails
@export var dead_sound_effect: SoundEffectDetails
@export var death_vfx: VFXEffectProperties
@export var hit_vfx: VFXEffectProperties

func _init(_speed: float = 250.0) -> void:
	speed = _speed

func add_weapon_to_array(weapon: WeaponDetails) -> void:
	if weapons_array.has(weapon): return
	weapons_array.append(weapon)
 
## Apply the stats bonuses to the player.
## and also adds the unlocked weapons to the [param  PlayerDetails.weapons_array]
func apply_stats() -> Dictionary:
	_add_unlocked_weapons()
	speed = PlayerStatsManager.get_stat_final_value("Speed")
	damage_multiplier_percent = PlayerStatsManager.get_stat_final_value("Damage")
	max_health = PlayerStatsManager.get_stat_final_value("Health")
	
	return {
		"Speed": speed,
		"Damage": damage_multiplier_percent,
		"Health": max_health,
	}

func _add_unlocked_weapons() -> void:
	for weapon_id in PlayerStatsManager.get_unlocked_weapons().keys():
		var weapon: WeaponDetails = PlayerStatsManager.get_unlocked_weapons().get(weapon_id, null)
		add_weapon_to_array(weapon)
