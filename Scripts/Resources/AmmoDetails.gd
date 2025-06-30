extends Resource
class_name AmmoDetails

@export_category("Base Details")
## the min lifetime for the ammo, a random value is chosed between the min and max
@export var min_lifetime: float = 1.0
## the max lifetime for the ammo, a random value is chosed between the min and max
@export var max_lifetime: float = 10.0
## The damage dealt by the bullet
@export var bullet_damage: float = 25.0
## The speed of the bullet
@export var bullet_speed: float = 1000.0
# The radius of this bullet
@export var size: int = 10

### The amount of bullets to spawn per single shoot, a random value will be selected from the min and max
@export var bullets_per_shoot_min: int = 1
## The amount of bullets to spawn per single shoot, a random value will be selected from the min and max
@export var bullets_per_shoot_max: int = 1
## A delay between bullet spawn, a random value will be selected between the min and max
@export_range(0.0, 0.25) var bullet_spawn_interval_min: float = 0.0
"""A delay between bullet spawn, a random value will be selected between the min and max"""
@export_range(0.0, 0.25) var bullet_spawn_interval_max: float = 0.0

@export_category("Bullet Trail")
@export var trail_gradient: Gradient
@export var trail_length: int = 20
@export_range(1.0, 30.0, 0.5) var trail_width: float = 20.0

@export_category("Fracture Parameters")
## The amount of damage dealed to a fracturable object, i.e. an enemy
@export var fracture_damage: Vector2 = Vector2(50, 50)
## The amount of force applied to a fracturable object, i.e. an enemy
@export var fracture_force: float = 15_000.0


@export_category("Bullet Particles Trail")
## DEPRECATED: Use bullet trail instead
@export var emits_trail_particles: bool = true
## DEPRECATED: Use bullet trail instead
@export var particle_trail_details: ParticleEffectDetails
## DEPRECATED: Emission lifetime randomness ratio
@export_range(0.0, 1.0) var randomness: float = 0.5
## DEPRECATED: Particle lifetime randomness ratio, escales the lifetime of it's original value
@export_range(0.0, 1.0) var lifetime_randomness = 0.25

## The damage dealt by the bullet multiplied by the damage multiplier
var bullet_damage_multiplied: float = 0.0

func _init(_damage = 25.0, _speed = 1000.0) -> void:
	bullet_damage = _damage
	bullet_speed = _speed
