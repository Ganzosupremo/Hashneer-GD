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

func apply_stats() -> Array:
	speed += speed_stat.value
	damage_multiplier += damage_multiplier_stat.value
	max_health += max_health_stat.value
	
	return [speed, damage_multiplier, max_health]
