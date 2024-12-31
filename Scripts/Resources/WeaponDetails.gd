class_name WeaponDetails extends Resource

@export_category("Weapon Base Details")
@export var weapon_name: String = ""
@export var weapon_texture: Texture2D

@export var fire_sound: SoundEffectDetails
## This will be added to the bullet's final damage
@export_range(1.0, 5.0, 0.5) var weapon_damage_multiplier: float

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
## The strength of the shake
@export var shake_strength: float = 1.0
## How fast the camera will stop shaking, with higher values the shake will be shorter.
@export var shake_decay: float = 5.0

var weapon_list_index: int = 0

func set_fire_rate(value: float) -> void:
	fire_rate = value

func set_precharge_time(value: float) -> void:
	precharge_time = value

func _to_string() -> String:
	return "WeaponDetails for %s" % weapon_name + "\n\nWeapon texture: %s" % weapon_texture + "\n\nFire sound: %s" % fire_sound + "\n\nAmmo details: %s" % ammo_details + "\n\nWeapon shoot effect: %s" % weapon_shoot_effect + "\n\nFire rate: %.2f" % fire_rate + "\n\nPrecharge time: %.2f" % precharge_time + "\n\nWeapon spread: min %.2f - max %.2f" % [spread_min, spread_max] + "\n\nCamera shake strength: %.2f" % shake_strength + "\n\nCamera shake decay: %.2f" % shake_decay