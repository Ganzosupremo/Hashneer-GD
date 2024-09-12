class_name WeaponDetails extends Resource

@export_category("Weapon Base Details")
@export var weapon_name: String = ""
@export var weapon_texture: Texture2D

# vars for sound effects go here 


@export_category("Ammo Details")
@export var ammo_details: AmmoDetails


@export_category("Shoot Effect")
@export var weapon_shoot_effect: ParticleEffectDetails

@export_category("Weapon Fire Details")
@export var fire_rate: float = 0.25
@export var precharge_time: float = 0.0
@export_range(0.0, 1.0) var spread_min: float = 0.0
@export_range(0.0, 1.0) var spread_max: float = 0.001

@export_category("Weapon Shake")
@export var shake_strength: float = 1.0
@export var shake_decay: float = 5.0

var weapon_list_index: int = 0

func set_fire_rate(value: float) -> void:
	fire_rate = value
