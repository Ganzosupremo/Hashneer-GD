class_name WeaponSpecial extends Resource
## Base class for a weapon's special ability, fired with the [code]Weapon_Special[/code] action (right click).
##
## Each [WeaponDetails] can have one special. The special only holds its data: the per player state
## (cooldowns, active buffs) lives in [FireWeaponComponent], so the same resource can be shared.[br]
## Subclasses: [WeaponSpecialShot] (fires an empowered shot right away) and [WeaponSpecialBuff]
## (boosts the weapon for some seconds). To add a new special, create a [code].tres[/code] with one of
## them in [code]Resources/Weapons/Specials/[/code] and assign it to the weapon's [member WeaponDetails.special].

## Name shown in the HUD and the Armory.
@export var special_name: String = "Special"
## Description shown in the Armory.
@export_multiline var description: String = ""
## Optional icon for the HUD and the Armory.
@export var icon: Texture2D
## Seconds before the special can be used again, before Armory upgrades.
@export_range(0.5, 120.0, 0.5) var cooldown: float = 10.0

## Runs the special. [param fire_component] is the weapon component that owns the state,
## [param weapon] the weapon it belongs to. Returns true if it was used (the cooldown starts).
func activate(_fire_component: FireWeaponComponent, _weapon: WeaponDetails, _player_damage_multiplier: float, _target_position: Vector2) -> bool:
	return false

## Short text with the special's numbers for [param weapon] (with its Armory upgrades), for the Armory.
func get_summary(_weapon: WeaponDetails) -> String:
	return description
