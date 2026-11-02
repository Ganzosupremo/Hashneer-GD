class_name WeaponSpecialBuff extends WeaponSpecial
## A special that boosts its weapon for [member duration] seconds.
##
## The boost only applies while that weapon is in hand; switching weapons keeps the timer running.

## Seconds the boost lasts. Armory "power" upgrades make it longer.
@export_range(0.5, 30.0, 0.5) var duration: float = 3.0
## Fire rate multiplier while active.
@export_range(0.1, 10.0, 0.05) var fire_rate_multiplier: float = 1.0
## Damage multiplier while active (lasers included).
@export_range(0.1, 10.0, 0.05) var damage_multiplier: float = 1.0
## Spread multiplier while active, 0 shoots perfectly straight.
@export_range(0.0, 2.0, 0.05) var spread_multiplier: float = 1.0
## Laser beam width multiplier while active.
@export_range(0.5, 5.0, 0.05) var laser_width_multiplier: float = 1.0
## Spin up weapons (Minigun) reach their top speed at once.
@export var instant_spin_up: bool = false
## Seconds the weapon can't fire once the boost ends (overheat). 0 disables it.
@export_range(0.0, 5.0, 0.1) var overheat_time: float = 0.0

func activate(fire_component: FireWeaponComponent, weapon: WeaponDetails, _player_damage_multiplier: float, _target_position: Vector2) -> bool:
	fire_component.start_special_buff(self, weapon, get_duration(weapon.get_special_power_multiplier()))
	return true

## Duration after the Armory power upgrades.
func get_duration(power_multiplier: float) -> float:
	return duration * power_multiplier

func get_summary(weapon: WeaponDetails) -> String:
	var power_multiplier: float = weapon.get_special_power_multiplier()
	var parts: PackedStringArray = []
	if !description.is_empty():
		parts.append(description)
	parts.append("Lasts %.1f s" % get_duration(power_multiplier))
	parts.append("Cooldown %.1f s" % weapon.get_special_cooldown())
	return " · ".join(parts)
