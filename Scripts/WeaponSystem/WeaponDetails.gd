extends Resource
class_name WeaponDetails

@export_category("Weapon Base Details")
@export var weapon_name: String = ""
@export var weapon_texture: Texture2D

# vars for sound effects go here 


@export_category("Ammo Details")
@export var ammo_details: AmmoDetails

@export_category("Weapon Fire Details")
@export var fire_rate: float = 0.25
@export var precharge_time: float = 0.0
@export_range(0.0, 1.0) var spread_min: float = 0.0
@export_range(0.0, 1.0) var spread_max: float = 0.001

@export_category("Weapon Shake")
@export var shake_strength: float = 1.0
@export var shake_decay: float = 5.0

@export_category("Weapon Bullet Details")
## The damage dealt by the bullet
@export var bullet_damage: float = 25.0
## The speed of the bullet
@export var bullet_speed: float = 1000.0

## The amount of bullets to spawn per single shoot, a random value will be selected from the min and max
@export var bullets_per_shoot_min: int = 1
## The amount of bullets to spawn per single shoot, a random value will be selected from the min and max
@export var bullets_per_shoot_max: int = 1
## A delay between bullet spawn, a random value will be selected between the min and max
@export_range(0.0, 0.2) var bullet_spawn_interval_min: float = 0.0
## A delay between bullet spawn, a random value will be selected between the min and max
@export_range(0.0, 0.2) var bullet_spawn_interval_max: float = 0.0

func set_fire_rate(value: float) -> void:
	fire_rate = value

