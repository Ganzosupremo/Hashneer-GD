extends Node2D
class_name FireWeaponComponent

signal fire_weapon(has_fired: bool, fired_previous_frame: bool, damage_multiplier: float, target_position: Vector2)

@export var main_event_bus: MainEventBus

@export var shake_camera_on_fire: bool = true
@export var active_weapon_component: ActiveWeaponComponent

@export var is_enemy_weapon: bool
@export var use_object_pool: bool = false
@export var bullet_scene: PackedScene = preload("res://Scenes/QuadrantTerrain/FractureBullet.tscn")

@onready var bullet_spawn_position : Marker2D = %BulletFirePosition
@onready var shoot_effect_position: Marker2D = %ShootEffectPosition
@onready var _fire_cooldown_timer: Timer = %FireCooldownTimer


var fire_rate_cooldown_timer: float = 0.0
var current_weapon: WeaponDetails
var quadrant_builder: QuadrantBuilder
var current_pool: PoolFracture

func _ready() -> void:
	quadrant_builder = get_tree().get_first_node_in_group("QuadrantBuilder")
	initialize_bullet_pools()
	if _fire_cooldown_timer == null:
		_fire_cooldown_timer = Timer.new()
		add_child(_fire_cooldown_timer)
		_fire_cooldown_timer.autostart = false
		_fire_cooldown_timer.one_shot = false

func _process(delta: float) -> void:
	fire_rate_cooldown_timer -= delta

func _enter_tree() -> void:
	fire_weapon.connect(on_fire_weapon)

func _exit_tree() -> void:
	fire_weapon.disconnect(on_fire_weapon)

func on_fire_weapon(_has_fired:bool, _fired_previous_frame: bool, damage_multiplier: float, target_position: Vector2 = Vector2.ZERO) -> void:
	weapon_fire(damage_multiplier, target_position)

func weapon_fire(damage_multiplier: float, target_position: Vector2 = Vector2.ZERO) -> void:
	if ready_to_fire():
		current_weapon = active_weapon_component.get_current_weapon()
		GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.WEAPON_FIRE, shoot_effect_position.global_transform, current_weapon.weapon_shoot_effect)
		
		if shake_camera_on_fire:
			GameManager.shake_camera(current_weapon.amplitude,\
			current_weapon.frequency, current_weapon.duration, current_weapon.axis_ratio,\
			current_weapon.armonic_ration, current_weapon.phase_offset, current_weapon.samples, current_weapon.shake_trans)
		
		fire_ammo(damage_multiplier, target_position)
		reset_cooldown_timer()

func fire_ammo(damage_multiplier: float, target_position: Vector2 = Vector2.ZERO) -> void:
	var ammo: AmmoDetails = active_weapon_component.get_current_ammo()
	var total_damage: float = ammo.bullet_damage * damage_multiplier
	ammo.bullet_damage_multiplied = total_damage
	fire_ammo_async(ammo, target_position)

# Allows to fire many bullets at once
func fire_ammo_async(ammo: AmmoDetails, target_position: Vector2 = Vector2.ZERO):
	var ammo_counter: int = 0

	var bullets_per_shoot: int = randi_range(ammo.bullets_per_shoot_min, ammo.bullets_per_shoot_max)
	var spawn_interval: float = 0.0
	
	if bullets_per_shoot > 1:
		spawn_interval = randf_range(ammo.bullet_spawn_interval_min, ammo.bullet_spawn_interval_max)

	AudioManager.create_2d_audio_at_location(shoot_effect_position.global_position, current_weapon.fire_sound.sound_type, current_weapon.fire_sound.destination_audio_bus)
	while ammo_counter < bullets_per_shoot:
		ammo_counter += 1
		
		var bullet: FractureBullet
		#if !is_pool_valid(current_pool) and is_enemy_weapon:
			#current_pool = get_tree().get_first_node_in_group("EBulletsPool")
		if use_object_pool:
			bullet = current_pool.getInstance()
		else:
			bullet = bullet_scene.instantiate()
			get_node("..").add_child(bullet)
		
		# change if the bullet doesn't spawn on the world
		#owner.owner.add_child(bullet)
		if not bullet: return
		
		var spread_angle = randf_range(-current_weapon.spread_min, current_weapon.spread_max)

		var initial_vector: Vector2 = target_position - bullet_spawn_position.global_position
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

func is_pool_valid(pool: PoolFracture) -> bool:
	if is_instance_valid(pool): 
		return true
	elif pool != null: 
		return true
	
	return false

func initialize_bullet_pools() -> void:
	if is_enemy_weapon:
		current_pool = get_tree().get_first_node_in_group("EBulletsPool")
		print_debug("{0}. FireWeaponComponent: Using enemy pool for firing bullets.".format([get_parent().name]))
	else:
		current_pool = get_tree().get_first_node_in_group("PBulletsPool")
		print_debug("{0}. FireWeaponComponent: Using player pool for firing bullets.".format([get_parent().name]))
	if not current_pool:
		push_error("Bullet pool is not set for FireWeaponComponent. Please check the Node Group for mispellings.")
		return
	if use_object_pool and not current_pool:
		push_error("Object pool is not set for FireWeaponComponent. Please check the Node Group for mispellings.")
		return
