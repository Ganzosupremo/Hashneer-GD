class_name PlayerDetails extends Resource

@export_category("Player Basic Details")
@export var speed: float = 200.0
@export var max_health: float = 100.0

@export var initial_weapon: WeaponDetails
@export var dead_sound_effect: SoundEffectDetails
@export var weapons_array: Array = []

@export_category("Player Stats")
@export var stats_list: Array[StatsResource]
