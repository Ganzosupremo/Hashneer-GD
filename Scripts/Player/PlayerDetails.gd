class_name PlayerDetails extends Resource

@export_category("Player Basic Details")
@export var speed: float = 250.0
@export var max_health: float = 100.0
@export var damage_multiplier: float = 1.0

@export var initial_weapon: WeaponDetails
@export var dead_sound_effect: SoundEffectDetails
@export var weapons_array: Array = []

@export_category("Player Stats")
@export var speed_stat: PlayerStat
@export var damage_multiplier_stat: PlayerStat
@export var max_health_stat: PlayerStat

func _init(_speed: float = 250.0) -> void:
	speed = _speed

func add_weapon_to_array(weapon: WeaponDetails) -> void:
	if weapons_array.has(weapon): return
	weapons_array.append(weapon)
 
## Apply the stats bonuses to the player.
## and also adds the unlocked weapons to the [param  PlayerDetails.weapons_array]
func apply_stats() -> Array:
	_add_unlocked_weapons()
	speed = PlayerStatsManager.get_stat_final_value("Speed")
	damage_multiplier = PlayerStatsManager.get_stat_final_value("Damage")
	max_health = PlayerStatsManager.get_stat_final_value("Health")
	
	return [speed, damage_multiplier, max_health]

func _add_unlocked_weapons() -> void:
	for weapon_id in PlayerStatsManager.get_unlocked_weapons().keys():
		var weapon: WeaponDetails = PlayerStatsManager.get_unlocked_weapons().get(weapon_id, null)
		add_weapon_to_array(weapon)

func _to_string() -> String:
	return "PlayerDetails:\n\nSpeed: %s" % speed + "\n\nMax Health: %s" % max_health + "\n\nDamage Multiplier: %s" % damage_multiplier + "\n\nInitial Weapon: %s" % initial_weapon + "\n\nWeapons: %s" % weapons_array + "\n\nDead Sound Effect: %s" % dead_sound_effect + "\n\nSpeed Stat Value: %s" % speed_stat.value + "\n\nDamage Multiplier Stat Value: %s" % damage_multiplier_stat.value + "\n\nMax Health Stat Value: %s" % max_health_stat.value
