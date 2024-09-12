extends Node2D
class_name FireWeapon

signal fire_weapon(has_fired: bool, fired_previous_frame: bool)

@onready var bullet_scene: PackedScene = preload("res://Scenes/QuadrantTerrain/FractureBullet.tscn")

@onready var bullet_spawn_position : Marker2D = %BulletFirePosition
@onready var shoot_effect_position: Marker2D = %ShootEffectPosition
@onready var effect_particles: PackedScene = preload("res://Scenes/WeaponSystem/bullet_particles.tscn")
@onready var _fire_cooldown_timer: Timer = %FireCooldownTimer

var player: PlayerController
var fire_rate_cooldown_timer: float = 0.0
var current_weapon: WeaponDetails

func _ready() -> void:
	player = get_parent()

func _process(delta: float) -> void:
	fire_rate_cooldown_timer -= delta

func _enter_tree() -> void:
	fire_weapon.connect(on_fire_weapon)

func _exit_tree() -> void:
	fire_weapon.disconnect(on_fire_weapon)

func on_fire_weapon(_has_fired:bool, _fired_previous_frame: bool) -> void:
	weapon_fire()

func weapon_fire() -> void:
	if ready_to_fire():
		current_weapon = player.active_weapon.get_current_weapon()
		player.get_player_camera().shake(current_weapon.shake_strength, current_weapon.shake_decay)
		fire_ammo()
		reset_cooldown_timer()

func fire_ammo() -> void:
	var ammo: AmmoDetails = player.active_weapon.get_current_ammo()
	var shoot_effect = player.active_weapon.get_current_weapon().weapon_shoot_effect
	_create_fire_effects(shoot_effect)
	fire_ammo_async(ammo)

func _create_fire_effects(shoot_effect: ParticleEffectDetails):
	var ins: EffectParticles = effect_particles.instantiate()
	add_child(ins)
	ins.emitting = false
	ins.init_particles(shoot_effect)
	ins.position = shoot_effect_position.position
	ins.start_particles()

func fire_ammo_async(ammo: AmmoDetails):
	var ammo_counter: int = 0
	
	var bullets_per_shoot: int = randi_range(ammo.bullets_per_shoot_min, ammo.bullets_per_shoot_max)
	var spawn_interval: float = 0.0
	
	if bullets_per_shoot > 1:
		spawn_interval = randf_range(ammo.bullet_spawn_interval_min, ammo.bullet_spawn_interval_max)
	else:
		spawn_interval = 0.0
	
	while ammo_counter < bullets_per_shoot:
		ammo_counter += 1
		var bullet: FractureBullet = player._bullets_pool.getInstance() #GameManager.pool_fracture_bullets.getInstance()
		print(bullet)
		if not bullet: 
			return
			
		var spread_angle = randf_range(-current_weapon.spread_min, current_weapon.spread_max)

		var initial_vector: Vector2 = get_global_mouse_position() - bullet_spawn_position.global_position
		var launch_vector: Vector2 = initial_vector.normalized().rotated(spread_angle)
		var launch_magnitude: float = ammo.bullet_speed
		
		bullet.spawn(bullet_spawn_position.position, launch_vector * launch_magnitude, randf_range(ammo.min_lifetime, ammo.max_lifetime), player.quadrant_builder, ammo)
		
		bullet.transform = bullet_spawn_position.global_transform
		
		_fire_cooldown_timer.start(spawn_interval)
		await _fire_cooldown_timer.timeout
	
	#for sound effects

func ready_to_fire() -> bool:
	if fire_rate_cooldown_timer >= 0.0:
		return false
	
	return true

func reset_cooldown_timer() -> void:
	fire_rate_cooldown_timer = current_weapon.fire_rate
