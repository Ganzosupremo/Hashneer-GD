class_name WeaponDetails extends IUpgradeable
## This resource contains all the details about the weapon, such as name, texture, fire sound, ammo details, shoot effect, fire rate, precharge time, spread, and shake properties.
##
## This resource is used by the [FireWeaponComponent] to determine how the weapon behaves, how it fires, and how it interacts with the environment.
## The [AmmoDetails] is used by it to determine how this weapon fires the bullets, how many bullets to fire, and what patterns to use.
## The [WeaponDetails] resource is designed to be flexible and extensible, allowing for easy addition of new weapon types and behaviors.

@export_category("Available Upgrades")
## The available upgrades for this weapon, allowing players to enhance the weapon's performance or add new
@export var available_upgrades: Array[ArmoryUpgradeData] = []

@export_category("Weapon Base Details")
## The name of the weapon, used for identification and display purposes.
@export var weapon_name: String = ""
## The texture of the weapon, used for rendering the weapon in the game.
@export var weapon_texture: Texture2D
## The sound effect played when the weapon is fired.
@export var fire_sound: SoundEffectDetails
## The multiplier applied to the weapon's damage, allowing for scaling of damage based on upgrades or global settings.
## This multiplier is applied to the base damage defined in the [AmmoDetails] resource.
@export_range(0.0, 1.0, 0.05) var weapon_damage_multiplier_percent: float = 0.0

@export_category("Ammo Details")
## The details of the ammo used by this weapon, including bullet type, damage, speed, lifetime, and other properties. See [AmmoDetails] for more details.
@export var ammo_details: AmmoDetails


@export_category("Shoot Effect")
## The visual effect played when the weapon is fired, such as muzzle flash or bullet impact effects.
@export var weapon_shoot_effect: VFXEffectProperties

@export_category("Weapon Fire Details")
## Shots that can be fired per second
@export var shots_per_second: float = 1.0
## Time before the weapon can fire again, allowing for precharging or cooldowns.
## This is useful for weapons that require a charge time before firing, such as energy weapons or heavy artillery.
## The precharge time is applied before the weapon can fire, and it can be used to create a delay between shots.
@export var precharge_time: float = 0.0
## Maximum spread angle in radians for patterns that use spread
@export_range(0.0, 1.0) var spread: float = 0.0

@export_category("Weapon Shake")
## The amplitude of the shake effect when the weapon is fired, controlling how much the camera or player view shakes.
@export var amplitude: float = 3.0
## The frequency of the shake effect, controlling how fast the shake oscillates.
@export var frequency: float = 5.0
## The duration of the shake effect, controlling how long the shake lasts when the weapon is fired.
@export var duration: float = .5
## The axis ratio for the Lissajous' curves, controlling the shape of the shake effect.
## A value of 0.0 means no axis ratio, resulting in a circular shake effect.
## A value of 1.0 means a square shake effect, while values between 0.0 and 1.0 create elliptical shapes.
@export var axis_ratio: float = 0.0
## The ratio for the Lissajous' curves. It should have [b]two[/b] entries. If it has more than two entries, the rest will be ignored.
@export var armonic_ration: Array[int] = [1,1]
## The phase offset for the Lissajous' curves, controlling the starting point of the shake effect.
## This value is in degrees and can be used to create a phase shift in the shake effect.
@export var phase_offset: int = 90
## The number of samples used to calculate the shake effect, controlling the smoothness and detail of the shake.
## A higher number of samples results in a smoother shake effect, while a lower number results in a more jittery effect.
## This value should be set based on the desired performance and visual quality of the shake effect.
@export var samples: int = 10
## The transition type used for the shake effect, controlling how the shake transitions over time.
@export var shake_trans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR

@export_group("Weapon Recoil")
## The amount of recoil applied to the player when the weapon is fired, controlling how much the player is pushed back.
@export_range(0.0, 1000.0, 1.0) var recoil_strength: float = 150.0
## The strength of the recoil kick applied to the camera when the weapon is fired, controlling how much the camera is pushed back.
@export_range(0.0, 50.0, 0.1) var recoil_kick_strength: float = 5.0
## The amount of trauma-based shake to add to the camera when the weapon is fired.
@export_range(0.0, 1.0, 0.01) var trauma_shake_amount: float = 0.1


const implements = [
	preload("res://Scripts/Resources/IUpgradeable.gd"),
]

var _upgrade_modifiers: Dictionary = {}  # Dictionary to hold upgrade modifiers for the weapon
var weapon_index: int = 0
var _chached_id: String = ""

#region IUpgradeable Interface Implementation
func get_upgrade_id() -> String:
	if _chached_id.is_empty():
		_chached_id = _generate_id_from_path()
	return _chached_id
	
func get_upgrade_name() -> String:
	return weapon_name

func get_upgrade_description() -> String:
	return upgrade_description

func get_display_icon() -> Texture2D:
	return weapon_texture

func get_available_upgrades() -> Array[ArmoryUpgradeData]:
	return available_upgrades

func get_child_available_upgrades() -> Array[ArmoryUpgradeData]:
	return ammo_details.get_available_upgrades()

func apply_upgrade(upgrade_type: Constants.ArmoryUpgradeType, level: int, upgrade_power_per_level: float) -> void:
	match upgrade_type:
		Constants.ArmoryUpgradeType.WEAPON_DAMAGE_MULTIPLIER:
			_apply_upgrade_modifier("weapon_damage_multiplier_percent", level, upgrade_power_per_level)
		Constants.ArmoryUpgradeType.WEAPON_FIRE_RATE:
			_apply_upgrade_modifier("fire_rate", level, upgrade_power_per_level)
		Constants.ArmoryUpgradeType.WEAPON_SPREAD_REDUCTION:
			_apply_upgrade_modifier("spread_reduction", level, upgrade_power_per_level)
		Constants.ArmoryUpgradeType.WEAPON_PRECHARGE_TIME_REDUCTION:
			_apply_upgrade_modifier("precharge_time_reduction", level, upgrade_power_per_level)
		_:
			DebugLogger.error("Unknown upgrade type: " + str(upgrade_type))

func _apply_upgrade_modifier(upgrade_name: String, level: int, upgrade_power_per_level: float) -> void:
	if !_upgrade_modifiers.has(upgrade_name):
		_upgrade_modifiers[upgrade_name] = 0.0
	
	# Store upgrade modifier instead of directly modifying the base value
	_upgrade_modifiers[upgrade_name] = level * upgrade_power_per_level

func get_current_stats() -> Dictionary:
	var stats: Dictionary = {
		"Weapon Name": weapon_name,
		"Weapon Texture": weapon_texture,
		"Damage": str(get_damage_multiplier()),
		"ShotsPerSecond": str(get_fire_rate()),
		"PrechargeTime": str(get_precharge_time()),
		"Spread": str(get_spread()),
		"Level": str(get_total_upgrade_level()),
	}
	return stats

#endregion

#region Setters and Getters
## Returns the spread of the weapon, applying any spread reduction upgrades.
func get_spread() -> float:
	var spread_reduction: float = _upgrade_modifiers.get("spread_reduction", 0.0)
	return max(spread - spread_reduction, 0.0)

func get_random_spread() -> float:
	# Returns a random spread value based on the weapon's spread and any upgrades applied
	var spread_reduction: float = _upgrade_modifiers.get("spread_reduction", 0.0)
	return max(spread - spread_reduction, 0.0) * randf_range(-PI, PI)

## Returns the fire rate of the weapon, applying any fire rate upgrades.
func get_fire_rate() -> float:
	var shots_per_second_upgrade: float = _upgrade_modifiers.get("shots_per_second", 0.0)
	return shots_per_second * max(shots_per_second_upgrade + 1.0, 1.0)

## Returns the damage multiplier of the weapon, applying any damage multiplier upgrades.
func get_damage_multiplier() -> float:
	var damage_multiplier_upgrade: float = _upgrade_modifiers.get("weapon_damage_multiplier_percent", 0.0)
	return clamp(weapon_damage_multiplier_percent + damage_multiplier_upgrade, 0.0, 1.0)

## Returns the precharge time of the weapon, applying any precharge time reduction upgrades.
func get_precharge_time() -> float:
	var precharge_time_reduction: float = _upgrade_modifiers.get("precharge_time_reduction", 0.0)
	return max(precharge_time - precharge_time_reduction, 0.0)

## Returns the total upgrade level across all available upgrades.
func get_total_upgrade_level() -> int:
	var total_level: int = 0
	for upgrade in available_upgrades:
		total_level += upgrade.upgrade_levels
	return total_level

## Sets the fire rate of the weapon, controlling how many shots can be fired per second.
func set_fire_rate(value: float) -> void:
	shots_per_second = value

## Sets the precharge time for the weapon, controlling how long it takes before the weapon can fire again.
func set_precharge_time(value: float) -> void:
	precharge_time = value

## Returns the cooldown time for firing the weapon, calculated based on the fire rate.
func get_fire_cooldown() -> float:
	var shots_per_second_upgrade: float = _upgrade_modifiers.get("shots_per_second", 0.0)
	return 1.0 / (shots_per_second * max(shots_per_second_upgrade + 1.0, 1.0))

## Returns the ammo details for this weapon, providing information about the bullets fired by this weapon.
func get_ammo_details() -> AmmoDetails:
	return ammo_details

#endregion


#region ID

func _generate_id_from_path() -> String:
	# Generates a unique ID based on the resource path
	var path: String = resource_path
	if path.is_empty():
		# Fallback for runtime-created resources
		return "weapon_runtime_" + str(get_instance_id())
	
	# Extract filename without extension and use as ID
	var filename = path.get_file().get_basename()
	return "weapon_" + filename

#endregion
