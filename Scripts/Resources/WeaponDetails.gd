class_name WeaponDetails extends Resource
## This resource contains all the details about the weapon, such as name, texture, fire sound, ammo details, shoot effect, fire rate, precharge time, spread, and shake properties.
##
## This resource is used by the [FireWeaponComponent] to determine how the weapon behaves, how it fires, and how it interacts with the environment.
## The [AmmoDetails] is used by it to determine how this weapon fires the bullets, how many bullets to fire, and what patterns to use.
## The [WeaponDetails] resource is designed to be flexible and extensible, allowing for easy addition of new weapon types and behaviors.


@export_category("Weapon Base Details")
## The name of the weapon, used for identification and display purposes.
@export var weapon_name: String = ""
## The texture of the weapon, used for rendering the weapon in the game.
@export var weapon_texture: Texture2D
## The sound effect played when the weapon is fired.
@export var fire_sound: SoundEffectDetails
## The multiplier applied to the weapon's damage, allowing for scaling of damage based on upgrades or global settings.
## This multiplier is applied to the base damage defined in the [AmmoDetails] resource.
@export_range(0.0, 1.0, 0.5) var weapon_damage_multiplier: float

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


var _upgrade_modifiers: Dictionary = {}  # Dictionary to hold upgrade modifiers for the weapon

## Returns a random spread value between minus and plus defined  spread
func get_random_spread() -> float:
	return randf_range(-spread, spread)


## Sets the fire rate of the weapon, controlling how many shots can be fired per second.
func set_fire_rate(value: float) -> void:
	shots_per_second = value

## Sets the precharge time for the weapon, controlling how long it takes before the weapon can fire again.
func set_precharge_time(value: float) -> void:
	precharge_time = value

func get_fire_cooldown() -> float:
	var shots_per_second_upgrade: float = _upgrade_modifiers.get("shots_per_second", 0.0)
	print_debug("Returning fire cooldown: ", 1.0 / (shots_per_second * max(shots_per_second_upgrade + 1.0, 1.0)))
	return 1.0 / (shots_per_second * max(shots_per_second_upgrade + 1.0, 1.0))

func _init(_weapon_name: String = "Default", _weapon_texture = null) -> void:
	weapon_name = "Default Weapon"
	weapon_texture = null
	fire_sound = null
	weapon_damage_multiplier = 1.0
	ammo_details = AmmoDetails.new()
	weapon_shoot_effect = null
	shots_per_second = 1.0
	precharge_time = 0.0
	spread = 0.0
