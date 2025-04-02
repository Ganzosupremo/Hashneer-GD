extends Node2D
class_name FireWeaponComponent

signal fire_weapon(has_fired: bool, fired_previous_frame: bool, damage_multiplier: float)

@export var player_camera: AdvanceCamera
@export var active_weapon_component: ActiveWeaponComponent
@export var _fire_effect_particles: GPUParticles2D
 
@onready var bullet_scene: PackedScene = preload("res://Scenes/QuadrantTerrain/FractureBullet.tscn")

@onready var bullet_spawn_position : Marker2D = %BulletFirePosition
@onready var shoot_effect_position: Marker2D = %ShootEffectPosition
@onready var _fire_cooldown_timer: Timer = %FireCooldownTimer
@onready var sound_effect_component: SoundEffectComponent = $SoundEffectComponent


var fire_rate_cooldown_timer: float = 0.0
var current_weapon: WeaponDetails
var quadrant_builder: QuadrantBuilder

func _ready() -> void:
	quadrant_builder = get_tree().get_first_node_in_group("QuadrantBuilder")

func _process(delta: float) -> void:
	fire_rate_cooldown_timer -= delta

func _enter_tree() -> void:
	fire_weapon.connect(on_fire_weapon)

func _exit_tree() -> void:
	fire_weapon.disconnect(on_fire_weapon)

func on_fire_weapon(_has_fired:bool, _fired_previous_frame: bool, damage_multiplier: float) -> void:
	weapon_fire(damage_multiplier)

func weapon_fire(damage_multiplier: float) -> void:
	if ready_to_fire():
		current_weapon = active_weapon_component.get_current_weapon()
		sound_effect_component.set_sound(current_weapon.fire_sound)
		_fire_effect_particles.global_position = shoot_effect_position.global_position
		_fire_effect_particles.restart()
		
		if GameManager.player_camera:
			GameManager.shake_camera(current_weapon.amplitude,\
			current_weapon.frequency, current_weapon.duration, current_weapon.axis_ratio,\
			current_weapon.armonic_ration, current_weapon.phase_offset, current_weapon.samples, current_weapon.shake_trans)
		
		fire_ammo(damage_multiplier)
		reset_cooldown_timer()

func fire_ammo(damage_multiplier: float) -> void:
	var ammo: AmmoDetails = active_weapon_component.get_current_ammo()
	var total_damage: float = ammo.bullet_damage * damage_multiplier
	ammo.bullet_damage_multiplied = total_damage
	fire_ammo_async(ammo)

# Allows to fire many bullets at once
func fire_ammo_async(ammo: AmmoDetails):
	var ammo_counter: int = 0

	var bullets_per_shoot: int = randi_range(ammo.bullets_per_shoot_min, ammo.bullets_per_shoot_max)
	var spawn_interval: float = 0.0
	
	if bullets_per_shoot > 1:
		spawn_interval = randf_range(ammo.bullet_spawn_interval_min, ammo.bullet_spawn_interval_max)
	
	sound_effect_component.play_sound()
	while ammo_counter < bullets_per_shoot:
		ammo_counter += 1
		var bullet: FractureBullet = bullet_scene.instantiate()
		# change if the bullet doesn't spawn on the world
		owner.owner.add_child(bullet)
		if not bullet: 
			return
		
		var spread_angle = randf_range(-current_weapon.spread_min, current_weapon.spread_max)

		var initial_vector: Vector2 = get_global_mouse_position() - bullet_spawn_position.global_position
		var launch_vector: Vector2 = initial_vector.normalized().rotated(spread_angle)
		var launch_magnitude: float = ammo.bullet_speed
		
		bullet.spawn(bullet_spawn_position.position, launch_vector * launch_magnitude, randf_range(ammo.min_lifetime, ammo.max_lifetime), quadrant_builder, ammo)
		bullet.transform = bullet_spawn_position.global_transform
		
		_fire_cooldown_timer.start(spawn_interval)
		await _fire_cooldown_timer.timeout

	


func ready_to_fire() -> bool:
	if fire_rate_cooldown_timer >= 0.0:
		return false
	
	return true

func reset_cooldown_timer() -> void:
	fire_rate_cooldown_timer = current_weapon.fire_rate
