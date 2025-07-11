extends Resource
class_name AmmoDetails
## This resource contains all the details about the ammo, such as bullet type, damage, speed, lifetime, etc.
##
## This resource is used by the [FractureBullet] to determine how the bullet behaves, what damage it deals, and how it interacts with the environment.
## It is also used by the [WeaponDetails] to determine how the weapon fires the bullets, how many bullets to fire, and what patterns to use.
## The [AmmoDetails] resource is designed to be flexible and extensible, allowing for easy addition of new bullet types and behaviors.

## Defines the different types of bullets that can be used in the game.[br]
## Each bullet type has its own unique behavior and properties.
enum BulletType 
{

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

@export_category("Ammo Details")
@export_subgroup("Lifetime and Bullet Damage")
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

## Calculated final damage after applying multipliers.
var damage_final: float = 0.0

## Returns the total number of pierces this ammo can perform, including upgrades.
func get_total_pierce() -> int:
	var pierce_upgrade: int = upgrade_modifiers.get("pierce_upgrade", 0)
	return max_pierce_count + pierce_upgrade

## Returns the total number of bounces this ammo can perform, including upgrades.
func get_total_bounce() -> int:
	var bounce_upgrade: int = upgrade_modifiers.get("bounce_upgrade", 0)
	return max_bounce_count + bounce_upgrade

## Calculates the final damage dealt by the bullet based on global and weapon multipliers.[br]
## [param global_multiplier]: The global damage multiplier applied to all ammo.[br]
## [param weapon_multiplier]: The weapon-specific damage multiplier applied to this ammo.[br]
## Returns the final damage value after applying all multipliers and upgrades.
func calculate_damage(global_multiplier: float, weapon_multiplier: float) -> float:
	var damage_upgrade: float = upgrade_modifiers.get("damage_upgrade", 1.0)
	damage_final = bullet_damage * global_multiplier * (1.0 + weapon_multiplier) * damage_upgrade
	return damage_final
