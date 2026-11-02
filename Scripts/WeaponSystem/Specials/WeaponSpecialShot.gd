class_name WeaponSpecialShot extends WeaponSpecial
## A special that fires one or more empowered volleys right away, ignoring the fire cooldown.
##
## The volley uses a copy of the weapon's ammo with the changes below, so the weapon's own
## ammo (shared by every shot) is never modified.

## Damage multiplier of the special shot. Armory "power" upgrades scale it.
@export_range(0.1, 20.0, 0.05) var damage_multiplier: float = 1.0
## How many volleys are fired.
@export_range(1, 10) var volleys: int = 1
## Seconds between volleys.
@export_range(0.0, 1.0, 0.01) var volley_interval: float = 0.0
## Bullets per volley. 0 keeps the ammo's own count.
@export_range(0, 64) var bullet_count: int = 0
## Pattern override for the volley. Leave on [code]false[/code] to keep the ammo's pattern.
@export var override_pattern: bool = false
@export var bullet_pattern: AmmoDetails.BulletPattern = AmmoDetails.BulletPattern.CIRCLE
## Extra enemies the bullets pass through. Above 0 the bullets become piercing.
@export_range(0, 50) var extra_pierce: int = 0
## Bullets also go through terrain blocks instead of stopping on them.
@export var pierce_terrain: bool = false
## Each explosive bullet splits into two halves on impact this many times (Halving Rocket).
@export_range(0, 4) var split_generations: int = 0
## Multiplier for the bullet size.
@export_range(0.5, 4.0, 0.05) var size_multiplier: float = 1.0
## Multiplier for the bullet speed.
@export_range(0.25, 4.0, 0.05) var speed_multiplier: float = 1.0
## Multiplier for the recoil pushed onto the player (a big one works as a dash).
@export_range(0.0, 10.0, 0.1) var recoil_multiplier: float = 1.0

func activate(fire_component: FireWeaponComponent, weapon: WeaponDetails, player_damage_multiplier: float, target_position: Vector2) -> bool:
	var base_ammo: AmmoDetails = weapon.get_ammo_details()
	if base_ammo == null or base_ammo.bullet_type == AmmoDetails.BulletType.LASER:
		return false
	var ammo: AmmoDetails = build_ammo(base_ammo, weapon.get_special_power_multiplier())
	fire_component.fire_special_volleys(ammo, volleys, volley_interval, player_damage_multiplier, target_position, recoil_multiplier)
	return true

## Returns a copy of [param base_ammo] with this special's changes.
func build_ammo(base_ammo: AmmoDetails, power_multiplier: float) -> AmmoDetails:
	var ammo: AmmoDetails = base_ammo.make_runtime_copy()
	ammo.bullet_damage *= damage_multiplier * power_multiplier
	ammo.size = max(1, int(round(ammo.size * size_multiplier)))
	ammo.bullet_speed *= speed_multiplier
	if bullet_count > 0:
		ammo.bullets_per_shoot_min = bullet_count
		ammo.bullets_per_shoot_max = bullet_count
		ammo.upgrade_modifiers.erase("bullet_count_upgrade")
		ammo.fire_pattern_simultaneous = true
	if override_pattern:
		ammo.bullet_pattern = bullet_pattern
	if extra_pierce > 0 or pierce_terrain:
		ammo.bullet_type = AmmoDetails.BulletType.PIERCING
		ammo.max_pierce_count += extra_pierce
		ammo.pierce_terrain = pierce_terrain
	if split_generations > 0:
		ammo.split_generations = split_generations
		ammo.explosion_fail_chance = 0.0
	return ammo

func get_summary(weapon: WeaponDetails) -> String:
	var power_multiplier: float = weapon.get_special_power_multiplier()
	var parts: PackedStringArray = []
	if !description.is_empty():
		parts.append(description)
	parts.append("Damage x%.2f" % (damage_multiplier * power_multiplier))
	parts.append("Cooldown %.1f s" % weapon.get_special_cooldown())
	return " · ".join(parts)
