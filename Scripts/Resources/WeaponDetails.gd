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
@export var weapon_shoot_effect: VFXEffectProperties

@export_category("Weapon Fire Details")
@export var fire_rate: float = 0.25
@export var precharge_time: float = 0.0
@export_range(0.0, 1.0) var spread_min: float = 0.0
@export_range(0.0, 1.0) var spread_max: float = 0.001

@export_category("Weapon Shake")
## Movement to side to side
@export var amplitude: float = 3.0
@export var frequency: float = 5.0
## Duration of movement
@export var duration: float = .5
@export var axis_ratio: float = 0.0
## The ratio for the Lissajous' curves. If it has more than two entries, the rest will be ignored.
@export var armonic_ration: Array[int] = [1,1]
@export var phase_offset: int = 90
## Smoothness of the movement
@export var samples: int = 10
@export var shake_trans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR

var weapon_list_index: int = 0

func set_fire_rate(value: float) -> void:
	fire_rate = value

func set_precharge_time(value: float) -> void:
	precharge_time = value


func _init(_weapon_name: String = "Default", _weapon_texture = null) -> void:
	weapon_name = "Default Weapon"
	weapon_texture = null
	fire_sound = null
	weapon_damage_multiplier = 1.0
	ammo_details = AmmoDetails.new()
	weapon_shoot_effect = null
	fire_rate = 0.25
	precharge_time = 0.0
	spread_min = 0.0
	spread_max = 0.001


func _to_string() -> String:
	return "Weapon name: %s" % weapon_name + "\n\nWeapon texture: %" % weapon_texture + "\n\nFire sound: %" % fire_sound + "\n\nAmmo details: %" % ammo_details + "\n\nWeapon shoot effect: %" % weapon_shoot_effect + "\n\nFire rate: %.2f" % fire_rate + "\n\nPrecharge time: %.2f" % precharge_time + "\n\nWeapon spread: min %.2f - max %.2f" % [spread_min, spread_max]
