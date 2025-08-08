class_name AmmoDetails extends IUpgradeable
## This resource contains all the details about the ammo, such as bullet type, damage, speed, lifetime, etc.
##
## This resource is used by the [FractureBullet] to determine how the bullet behaves, what damage it deals, and how it interacts with the environment.
## It is also used by the [WeaponDetails] to determine how the weapon fires the bullets, how many bullets to fire, and what patterns to use.
## The [AmmoDetails] resource is designed to be flexible and extensible, allowing for easy addition of new bullet types and behaviors.

## Defines the different types of bullets that can be used in the game.[br]
## Each bullet type has its own unique behavior and properties.
enum BulletType {
	NORMAL, ## Standard bullet that destroys on impact.
	LASER, ## Specialized projectile that fires a constant beam, destroying on impact.
	EXPLOSIVE, ## Explodes dealing damage to objects in it's radius and creates an explosion effect on impact.
	PIERCING, ## Can pass through certain objects a limited number of times.
	BOUNCING, ## Can bounce off solid surfaces a limited number of times.
}

## Defines the different bullet patterns that can be used when firing ammo.[br]
## Each pattern defines how the bullets are spread out when fired, allowing for different firing styles and strategies.
## Patterns can be used to create unique firing effects, such as spreading bullets in a cone, firing in a circle, or creating waves of bullets.
## The patterns can be combined with different bullet types to create complex and interesting firing behaviors.
## The patterns are designed to be flexible and can be easily modified or extended to create new firing styles.
enum BulletPattern {
	SINGLE, ## Fires a single bullet in the direction of the weapon.
	RANDOM_SPREAD, ## Fires bullets in random directions within a specified angle.
	SPREAD, ## Fires bullets the direction of the weapon with a [member  WeaponDetails.spread] defined in [WeaponDetails].
	CIRCLE, ## Fires bullets in a circular pattern around the weapon's firing point.
	ARC, ## Fires bullets in an arc pattern, spreading them out over a specified angle.
	SPIRAL, ## Fires bullets in a spiral pattern, creating a swirling effect.
	DOUBLE_SPIRAL, ## Fires bullets in two spirals, one clockwise and one counterclockwise.
	WAVE, ## Fires bullets in a wave pattern, creating a ripple effect.
	SINE_WAVE, ## Fires bullets in a sine wave pattern, creating a smooth oscillating effect.
	SQUARE, ## Fires bullets in a square pattern, creating a grid-like effect.
	STAR, ## Fires bullets in a star pattern, creating a burst effect.
	CROSS, ## Fires bullets in a cross pattern, creating a plus sign effect.
	DIAGONAL_CROSS, ## Fires bullets in a diagonal cross pattern, creating an X shape.
	FLOWER, ## Fires bullets in a flower pattern, creating a radial burst effect.
	GRID, ## Fires bullets in a grid pattern, creating a matrix of bullets.
}

@export var available_upgrades: Array[ArmoryUpgradeData] = []
@export_category("Ammo Details")
@export_subgroup("Parameters")
## The name of the ammo, used for identification and display purposes.
@export var ammo_name: String = "Default Ammo"
## the min lifetime for the ammo, a random value is chosed between the min and max.
@export var min_lifetime: float = 1.0
## the max lifetime for the ammo, a random value is chosed between the min and max.
@export var max_lifetime: float = 10.0
## The damage dealt by the bullet.
@export var bullet_damage: float = 25.0
## The speed of the bullet.
@export var bullet_speed: float = 1000.0
@export_subgroup("Bullet Behaviour")
## Bullet behaviour type. see [BulletType] for more details.
@export var bullet_type: BulletType = BulletType.NORMAL
## Pattern used when firing this ammo
@export var bullet_pattern: BulletPattern = BulletPattern.SINGLE
## The angle of the bullet pattern, used for some patterns like arc, spiral, etc.
@export_range(0.0, 360.0, 5.0) var pattern_arc_angle: float = 45.0
## If [code]true[/code], the bullet pattern will fire all bullets at once, otherwise it will fire them one by one with a delay
## defined by [param bullet_spawn_interval_min] for the min value and [param bullet_spawn_interval_max] for the max value.
@export var fire_pattern_simultaneous: bool = false
## Maximum number of targets this bullet can pierce
@export var max_pierce_count: int = 0
## Maximum number of bounces this bullet can do
@export var max_bounce_count: int = 0
@export_subgroup("Explosive Bullet Parameters")
## The explosive bullet will deal damage to the targets within this radius
@export var explosion_radius: float = 0.0
@export_flags_2d_physics() var explosion_layer_mask: int = 1
@export_subgroup("Laser Bullet Parameters")
@export var laser_beam_scene: PackedScene = preload("res://Scenes/WeaponSystem/LaserBeam.tscn")
## The length of the laser beam, only applicable if the bullet type is [BulletType.LASER].
@export var laser_length: float = 300.0
## The cooldown time between laser beam hits, only applicable if the bullet type is [BulletType.LASER].
@export var laser_damage_cooldown: float = 0.1
## The collision mask for the laser beam, only applicable if the bullet type is [BulletType.LASER].
@export_flags_2d_physics() var laser_collision_mask: int = 1
@export_subgroup("Bullet Size and Spawn Parameters")
## The radius of this bullet
@export var size: int = 10
### The amount of bullets to spawn per single shoot, a random value will be selected from the min and max
@export var bullets_per_shoot_min: int = 1
## The amount of bullets to spawn per single shoot, a random value will be selected from the min and max
@export var bullets_per_shoot_max: int = 1
## A delay between bullet spawn, a random value will be selected between the min and max
@export_range(0.0, 0.25) var bullet_spawn_interval_min: float = 0.0
## A delay between bullet spawn, a random value will be selected between the min and max
@export_range(0.0, 0.25) var bullet_spawn_interval_max: float = 0.0

@export_category("Bullet Trail")
## The trail texture used for the bullet.
@export var trail_gradient: Gradient
## The length of the trail.
@export var trail_length: int = 20
## The width of the trail.
@export_range(1.0, 30.0, 0.5) var trail_width: float = 20.0

@export_category("Fracture Parameters")
## Force applied to fractured objects, i.e. an enemy.
@export var fracture_force: float = 15_000.0

@export_category("VFX")
## The VFX effect to spawn when the bullet collides with an object.
@export var bullet_hit_vfx: VFXEffectProperties
## The VFX effect to spawn when the bullet does not explode. Only applicable is the bullet is type [BulletType.EXPLOSIVE].
@export var failed_explosion_vfx: VFXEffectProperties

## Dictionary storing upgrade modifiers for this ammo.
var upgrade_modifiers: Dictionary = {}
var _chached_id: String = ""  # Cached ID for the ammo, generated from the resource path
## Calculated final damage after applying multipliers.
var damage_final: float = 0.0

const implements = [
	preload("res://Scripts/Resources/IUpgradeable.gd"),
]

#region IUpgradeable Interface Implementation
func get_upgrade_id() -> String:
	if _chached_id.is_empty():
		_chached_id = _generate_id_from_path()
	return _chached_id
	
func get_upgrade_name() -> String:
	return ammo_name

func get_upgrade_description() -> String:
	return "Upgrade details for " + ammo_name

func get_display_icon() -> Texture2D:
	return null

func get_available_upgrades() -> Array[ArmoryUpgradeData]:
	return available_upgrades

func apply_upgrade(upgrade_type: Constants.ArmoryUpgradeType, level: int, upgrade_power_per_level: float) -> void:
	match upgrade_type:
		Constants.ArmoryUpgradeType.AMMO_DAMAGE, Constants.ArmoryUpgradeType.AMMO_LASER_DAMAGE, Constants.ArmoryUpgradeType.AMMO_EXPLOSION_DAMAGE:
			_apply_upgrade_modifier("damage_upgrade", level, upgrade_power_per_level)
		Constants.ArmoryUpgradeType.AMMO_SPEED:
			_apply_upgrade_modifier("ammo_speed_upgrade", level, upgrade_power_per_level)
		Constants.ArmoryUpgradeType.AMMO_PIERCE_COUNT:
			_apply_upgrade_modifier("pierce_upgrade", level, upgrade_power_per_level)
		Constants.ArmoryUpgradeType.AMMO_BOUNCE_COUNT:
			_apply_upgrade_modifier("bounce_upgrade", level, upgrade_power_per_level)
		Constants.ArmoryUpgradeType.AMMO_EXPLOSION_RADIUS:
			_apply_upgrade_modifier("explosion_radius_upgrade", level, upgrade_power_per_level)
		Constants.ArmoryUpgradeType.AMMO_BULLET_COUNT:
			_apply_upgrade_modifier("bullet_count_upgrade", level, upgrade_power_per_level)
		Constants.ArmoryUpgradeType.AMMO_LASER_LENGTH:
			_apply_upgrade_modifier("laser_length_upgrade", level, upgrade_power_per_level)
		_:
			DebugLogger.error("Unknown ammo upgrade type: " + str(upgrade_type))

func _apply_upgrade_modifier(upgrade_name: String, level: int, upgrade_power_per_level: float) -> void:
	if !upgrade_modifiers.has(upgrade_name):
		upgrade_modifiers[upgrade_name] = 0.0
	upgrade_modifiers[upgrade_name] += upgrade_power_per_level * level

func get_current_stats() -> Dictionary:
	var stats: Dictionary = {
		"Bullet Type": Utils.enum_label(BulletType, bullet_type),
		"Bullet Pattern": Utils.enum_label(BulletPattern, bullet_pattern),
		"Min Lifetime": str(min_lifetime),
		"Max Lifetime": str(max_lifetime),
		"Base Bullet Damage": str(bullet_damage),
		"Bullet Damage Final": str(damage_final),
		"Bullet Speed": str(bullet_speed),
		"Explosion Radius": str(explosion_radius),
		"Laser Length": str(laser_length),
		"Laser Damage Cooldown": str(laser_damage_cooldown),
		"Laser Collision Mask": str(laser_collision_mask),
		"Size": str(size),
		"Bullets Per Shoot Min": str(bullets_per_shoot_min),
		"Bullets Per Shoot Max": str(bullets_per_shoot_max),
		"Bullet Spawn Interval Min": str(bullet_spawn_interval_min),
		"Bullet Spawn Interval Max": str(bullet_spawn_interval_max),
		"Trail Length": str(trail_length),
		"Trail Width": str(trail_width),
		"Fracture Force": str(fracture_force),
		"Max Pierce Count": str(max_pierce_count),
		"Max Bounce Count": str(max_bounce_count),
		"Level": str(get_total_upgrade_level()),
	}
	return stats

func _generate_id_from_path() -> String:
	# Generates a unique ID based on the resource path
	var path: String = resource_path
	if path.is_empty():
		# Fallback for runtime-created resources
		return "ammo_runtime_" + str(get_instance_id())

	# Extract filename without extension and use as ID
	var filename = path.get_file().get_basename()
	return "ammo_" + filename

#endregion

#region Getters and Setters

## Returns the total number of pierces this ammo can perform, including upgrades.
func get_total_pierce() -> int:
	var pierce_upgrade: int = upgrade_modifiers.get("pierce_upgrade", 0)
	return max_pierce_count + pierce_upgrade

## Returns the total number of bounces this ammo can perform, including upgrades.
func get_total_bounce() -> int:
	var bounce_upgrade: int = upgrade_modifiers.get("bounce_upgrade", 0)
	return max_bounce_count + bounce_upgrade

## Returns the total upgrade level across all available upgrades.
func get_total_upgrade_level() -> int:
	var total_level: int = 0
	for upgrade in available_upgrades:
		total_level += upgrade.upgrade_levels
	return total_level

## Calculates the final damage dealt by the bullet based on global and weapon multipliers.[br]
## [param global_multiplier]: The global damage multiplier applied to all ammo.[br]
## [param weapon_multiplier]: The weapon-specific damage multiplier applied to this ammo.[br]
## Returns the final damage value after applying all multipliers and upgrades.
func get_final_damage(global_multiplier_percent: float = 1.0, weapon_multiplier_percent: float = 0.0) -> float:
	var damage_upgrade: float = upgrade_modifiers.get("damage_upgrade", 0.0)
	damage_final = bullet_damage * global_multiplier_percent * (1.0 + weapon_multiplier_percent) * (1.0 + damage_upgrade)
	return damage_final

## Returns the speed of the bullet, applying any speed upgrades.
func get_ammo_speed() -> float:
	var speed_upgrade: float = upgrade_modifiers.get("ammo_speed_upgrade", 0.0)
	return bullet_speed * (1.0 + speed_upgrade)

## Returns the max bounce count, applying any bounce upgrades.
func get_bounces() -> int:
	var bounce_upgrade: int = upgrade_modifiers.get("bounce_upgrade", 0)
	return max_bounce_count + bounce_upgrade

## Returns the max pierce count, applying any pierce upgrades.
func get_pierces() -> int:
	var pierce_upgrade: int = upgrade_modifiers.get("pierce_upgrade", 0)
	return max_pierce_count + pierce_upgrade

## Returns the number of bullets to spawn per shoot, applying any bullet count upgrades.
## A random value is chosen between [param bullets_per_shoot_min] and [param bullets_per_shoot_max].
## This allows for variability in the number of bullets fired, enhancing gameplay dynamics.
func get_ammo_count() -> int:
	var bullet_count_upgrade: int = upgrade_modifiers.get("bullet_count_upgrade", 0)
	return randi_range(bullets_per_shoot_min, bullets_per_shoot_max) + bullet_count_upgrade

## Returns the laser length, applying any laser length upgrades.
func get_laser_length() -> float:
	var laser_length_upgrade: float = upgrade_modifiers.get("laser_length_upgrade", 0.0)
	return laser_length * (1.0 + laser_length_upgrade)

## Returns the explosion radius, applying any explosion radius upgrades.
## This is used for explosive bullets to determine the area of effect damage.
func get_explosion_radius() -> float:
	var explosion_radius_upgrade: float = upgrade_modifiers.get("explosion_radius_upgrade", 0.0)
	return explosion_radius * (1.0 + explosion_radius_upgrade)

## Returns a random bullet spawn interval based on the min and max values
func get_bullet_spawn_interval() -> float:
	return randf_range(bullet_spawn_interval_min, bullet_spawn_interval_max)

## Returns a random lifetime between min and max lifetime
func get_bullet_lifetime() -> float:
	return randf_range(min_lifetime, max_lifetime)

#endregion