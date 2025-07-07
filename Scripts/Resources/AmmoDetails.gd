extends Resource
class_name AmmoDetails

enum BulletType {
	NORMAL,
	LASER,
	EXPLOSIVE,
	PIERCING,
	BOUNCING,
}

enum BulletPattern {
	SINGLE,
	RANDOM_SPREAD,
	SPREAD,
	CIRCLE,
	ARC,
}

@export_category("Ammo Details")
@export_subgroup("Lifetime and Bullet Damage")
## the min lifetime for the ammo, a random value is chosed between the min and max
@export var min_lifetime: float = 1.0
## the max lifetime for the ammo, a random value is chosed between the min and max
@export var max_lifetime: float = 10.0
## The damage dealt by the bullet
@export var bullet_damage: float = 25.0
## The speed of the bullet
@export var bullet_speed: float = 1000.0
@export_subgroup("Bullet Behaviour")
## Bullet behaviour type
@export var bullet_type: BulletType = BulletType.NORMAL
## Pattern used when firing this ammo
@export var bullet_pattern: BulletPattern = BulletPattern.SINGLE
@export_range(0.0, 360.0, 10.0) var pattern_arc_angle: float = 45.0
## Maximum number of targets this bullet can pierce
@export var max_pierce_count: int = 0
## Maximum number of bounces this bullet can do
@export var max_bounce_count: int = 0
## The explosive bullet will deal damage to the targets within this radius
@export var explosion_radius: float = 0.0
## The radius of this bullet
@export_subgroup("Bullet Size and Spawn Parameters")
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
@export var trail_gradient: Gradient
@export var trail_length: int = 20
@export_range(1.0, 30.0, 0.5) var trail_width: float = 20.0

@export_category("Fracture Parameters")
## Force applied to fractured objects, i.e. an enemy
@export var fracture_force: float = 15_000.0

@export_category("VFX")
## The VFX effect to spawn when the bullet collides with an object
@export var bullet_hit_vfx: VFXEffectProperties

## The damage dealt by the bullet multiplied by the damage multiplier
var bullet_damage_multiplied: float = 0.0
# Dictionary storing upgrade modifiers for this ammo
var upgrade_modifiers: Dictionary = {}

## Calculated final damage after applying multipliers
var damage_final: float = 0.0

func get_total_pierce() -> int:
	var pierce_upgrade: int = upgrade_modifiers.get("pierce_upgrade", 0)
	return max_pierce_count + pierce_upgrade

func get_total_bounce() -> int:
	var bounce_upgrade: int = upgrade_modifiers.get("bounce_upgrade", 0)
	return max_bounce_count + bounce_upgrade

func calculate_damage(global_multiplier: float, weapon_multiplier: float) -> float:
	var damage_upgrade: float = upgrade_modifiers.get("damage_upgrade", 1.0)
	damage_final = bullet_damage * global_multiplier * (1.0 + weapon_multiplier) * damage_upgrade
	return damage_final
