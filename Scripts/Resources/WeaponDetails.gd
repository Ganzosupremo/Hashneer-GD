class_name WeaponDetails extends Resource

@export_category("Weapon Base Details")
@export var weapon_name: String = ""
@export var weapon_texture: Texture2D

@export var fire_sound: SoundEffectDetails
## This will be added to the bullet's final damage
@export_range(0.0, 1.0, 0.5) var weapon_damage_multiplier: float

@export_category("Ammo Details")
@export var ammo_details: AmmoDetails


@export_category("Shoot Effect")
@export var weapon_shoot_effect: VFXEffectProperties

@export_category("Weapon Fire Details")
## Shots that can be fired per second
@export var shots_per_second: float = 1.0
@export var precharge_time: float = 0.0
## Maximum spread angle in radians for patterns that use spread
@export_range(0.0, 1.0) var spread: float = 0.0

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

func get_random_spread() -> float:
	# Returns a random spread value between minus and plus defined  spread
	return randf_range(-spread, spread)

func set_fire_rate(value: float) -> void:
	shots_per_second = value

func set_precharge_time(value: float) -> void:
	precharge_time = value

func _init(_weapon_name: String = "Default", _weapon_texture = null) -> void:
	weapon_name = "Default Weapon"
	weapon_texture = null
	fire_sound = null
	weapon_damage_multiplier = 1.0
	ammo_details = AmmoDetails.new()
	weapon_shoot_effect = null
	shots_per_second = 1.0
	precharge_time = 0.0
	spread = 0.0
