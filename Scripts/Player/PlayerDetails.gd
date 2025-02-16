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

var standard_speed: float
var standard_health: float
var standard_damage: float

func _init(_speed: float = 250.0) -> void:
	standard_speed = speed
	standard_damage = damage_multiplier
	standard_health = max_health

func add_weapon_to_array(weapon: WeaponDetails) -> void:
	if weapons_array.has(weapon): return
	weapons_array.append(weapon)

func apply_stats() -> Array:
	_reset_stats_to_standard()
	speed += speed_stat.value
	damage_multiplier += damage_multiplier_stat.value
	max_health += max_health_stat.value
	
	return [speed, damage_multiplier, max_health]

func _reset_stats_to_standard() -> void:
	standard_speed = speed
	standard_damage = damage_multiplier
	standard_health = max_health
	
	
	speed = standard_speed
	max_health = standard_health
	damage_multiplier = standard_damage

func _to_string() -> String:
	return "PlayerDetails:\n\nSpeed: %s" % speed + "\n\nMax Health: %s" % max_health + "\n\nDamage Multiplier: %s" % damage_multiplier + "\n\nInitial Weapon: %s" % initial_weapon + "\n\nWeapons: %s" % weapons_array + "\n\nDead Sound Effect: %s" % dead_sound_effect + "\n\nSpeed Stat Value: %s" % speed_stat.value + "\n\nDamage Multiplier Stat Value: %s" % damage_multiplier_stat.value + "\n\nMax Health Stat Value: %s" % max_health_stat.value
