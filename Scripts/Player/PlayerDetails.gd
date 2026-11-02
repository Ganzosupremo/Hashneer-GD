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

## Applies the skill bonuses of [param loadout] (see [method SkillProgress.build_loadout]) to the base stats.
## Returns the final stats and the weapons: [member weapons_array] plus the ones unlocked by skills.
## The resource is shared by every mode, so the unlocked weapons are not added to [member weapons_array].
func apply_stats(loadout: PlayerLoadout) -> Dictionary:
	speed = loadout.get_stat("Speed", PlayerStatsManager.base_stats.Speed)
	damage_multiplier_percent = loadout.get_stat("Damage", PlayerStatsManager.base_stats.Damage)
	max_health = loadout.get_stat("Health", PlayerStatsManager.base_stats.Health)

	var weapons: Array[WeaponDetails] = weapons_array.duplicate()
	for weapon in loadout.weapons:
		if not weapons.has(weapon):
			weapons.append(weapon)

	return {
		"Speed": speed,
		"Damage": damage_multiplier_percent,
		"Health": max_health,
		"Weapons": weapons,
	}
