extends Node2D
class_name FireWeaponComponent
## This component is responsible for firing weapons in the game.
## 
## It handles the firing logic, cooldowns, and bullet spawning.
## It is designed to be used with the [ActiveWeaponComponent] to manage the current weapon and ammo.
## It also handles the camera shake effect when firing a weapon.


## Signal emitted when a weapon is fired.[br]
## Parameters:[br]
## [param has_fired] - Indicates if the weapon has fired this frame.[br]
## [param fired_previous_frame] - Indicates if the weapon was fired in the previous frame.[br]
## [param player_damage_multiplier] - The damage multiplier applied to the player.[br]
## [param target_position] - The position where the weapon is aimed at, used for targeting purposes.[br]
## This signal is connected to the [method on_fire_weapon] function to handle the firing logic.
signal fire_weapon(has_fired: bool, fired_previous_frame: bool, player_damage_multiplier: float, target_position: Vector2)

@export var main_event_bus: MainEventBus

@export var shake_camera_on_fire: bool = true
@export var active_weapon_component: ActiveWeaponComponent

@export var is_enemy_weapon: bool
@export var use_object_pool: bool = false
@export var bullet_scene: PackedScene = preload("res://Scenes/QuadrantTerrain/FractureBullet.tscn")

@onready var bullet_spawn_position: Marker2D = %BulletFirePosition
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

func on_fire_weapon(_has_fired: bool, _fired_previous_frame: bool, player_damage_multiplier: float, target_position: Vector2 = Vector2.ZERO) -> void:
	weapon_fire(player_damage_multiplier, target_position)

func weapon_fire(player_damage_multiplier: float, target_position: Vector2 = Vector2.ZERO) -> void:
	if ready_to_fire():
		current_weapon = active_weapon_component.get_current_weapon()
		GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.WEAPON_FIRE, shoot_effect_position.global_transform, current_weapon.weapon_shoot_effect)
		
		if shake_camera_on_fire:
			GameManager.shake_camera(current_weapon.amplitude, \
			current_weapon.frequency, current_weapon.duration, current_weapon.axis_ratio, \
			current_weapon.armonic_ration, current_weapon.phase_offset, current_weapon.samples, current_weapon.shake_trans)
		
		fire_ammo(player_damage_multiplier, target_position)
		reset_cooldown_timer()

func fire_ammo(player_damage_multiplier: float, target_position: Vector2 = Vector2.ZERO) -> void:
	var ammo: AmmoDetails = active_weapon_component.get_current_ammo()
	ammo.damage_final = ammo.calculate_damage(player_damage_multiplier, current_weapon.weapon_damage_multiplier)
	fire_ammo_async(ammo, target_position)

# Allows to fire many bullets at once
func fire_ammo_async(ammo: AmmoDetails, target_position: Vector2 = Vector2.ZERO):
	var bullet_counter: int = 0
	var bullets_per_shoot: int = randi_range(ammo.bullets_per_shoot_min, ammo.bullets_per_shoot_max)
	var spawn_interval: float = 0.0

	if bullets_per_shoot > 1 and !ammo.fire_pattern_simultaneous:
		spawn_interval = randf_range(ammo.bullet_spawn_interval_min, ammo.bullet_spawn_interval_max)

	AudioManager.create_2d_audio_at_location(shoot_effect_position.global_position, current_weapon.fire_sound.sound_type, current_weapon.fire_sound.destination_audio_bus)

	var initial_vector: Vector2 = target_position - bullet_spawn_position.global_position
	var launch_vectors: Array = []

	while bullet_counter < bullets_per_shoot:
		bullet_counter += 1
		launch_vectors.append_array(_calculate_bullet_spread(ammo, bullet_counter, bullets_per_shoot, initial_vector))

		var bullet: FractureBullet
		if use_object_pool:
			bullet = current_pool.getInstance()
		else:
			bullet = bullet_scene.instantiate()
			get_node("..").add_child(bullet)

		if not bullet: return

		var launch_vector: Vector2 = launch_vectors[bullet_counter - 1]
		var launch_magnitude: float = ammo.bullet_speed

		bullet.spawn(bullet_spawn_position.position, launch_vector * launch_magnitude, randf_range(ammo.min_lifetime, ammo.max_lifetime), quadrant_builder, ammo)
		bullet.transform = bullet_spawn_position.global_transform

		if spawn_interval > 0.0:
			# If we have a spawn interval, we need to wait before firing the next bullet
			_fire_cooldown_timer.start(spawn_interval)
			await _fire_cooldown_timer.timeout

func ready_to_fire() -> bool:
	return fire_rate_cooldown_timer <= 0.0

func reset_cooldown_timer() -> void:
	if current_weapon.shots_per_second != 0:
		fire_rate_cooldown_timer = 1.0 / current_weapon.shots_per_second
	else:
		fire_rate_cooldown_timer = 0.0

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

## Calculates bullet trajectory vectors based on the specified bullet pattern
## 
## This function determines the direction vectors for each bullet to be fired based
## on the ammo's bullet pattern, the number of bullets per shot, and the initial direction.
## 
## [@param ammo: AmmoDetails] - Contains bullet pattern and other ammo properties.
## [@param bullet_per_shot: int] - Number of bullets to be fired in a single shot.
## [@param initial_vector: Vector2] - Base direction vector for the shot.
## 
## [@return Array] - Array of Vector2 representing normalized direction vectors for each bullet.
##
## Bullet patterns:
## [- SINGLE]: Returns just the normalized initial vector.
## [- RANDOM_SPREAD]: Adds random angle variation within the weapon's spread range.
## [- SPREAD/ARC]: Creates a fan pattern with evenly distributed angles across the specified arc.
## [- CIRCLE]: Creates a circular pattern with bullets evenly distributed in 360 degrees.
func _calculate_bullet_spread(ammo: AmmoDetails, index: int, bullet_per_shot: int, initial_vector: Vector2) -> Array:
	var launch_vectors: Array = []
	match ammo.bullet_pattern:
		AmmoDetails.BulletPattern.SINGLE:
			# For SINGLE pattern, just return the initial vector normalized
			launch_vectors.append(initial_vector.normalized())
		AmmoDetails.BulletPattern.RANDOM_SPREAD:
			var angle: float = randf_range(-PI, PI) * current_weapon.spread
			launch_vectors.append(initial_vector.normalized().rotated(angle))
		AmmoDetails.BulletPattern.ARC:
			var step: float = 0.0
			var arc_spread: float = ammo.pattern_arc_angle
			if bullet_per_shot > 1:
				step = deg_to_rad(arc_spread) / float(bullet_per_shot - 1)

			var angle: float = - arc_spread + step * index
			launch_vectors.append(initial_vector.normalized().rotated(angle))
		AmmoDetails.BulletPattern.SPREAD:
			var angle: float = randf_range(-current_weapon.spread, current_weapon.spread)
			launch_vectors.append(initial_vector.normalized().rotated(angle))
		AmmoDetails.BulletPattern.CIRCLE:
			var angle_step: float = TAU / float(bullet_per_shot)
			launch_vectors.append(Vector2.RIGHT.rotated(angle_step * index))
		AmmoDetails.BulletPattern.SPIRAL:
			var step = deg_to_rad(ammo.pattern_arc_angle)
			var angle: float = step * (index - 1) + current_weapon.get_random_spread()
			launch_vectors.append(Vector2.RIGHT.rotated(angle))
		AmmoDetails.BulletPattern.DOUBLE_SPIRAL:
			var step = deg_to_rad(ammo.pattern_arc_angle)

			var pair_index: int = int((index - 1) / 2)
			var dir = 1 if index % 2 == 0 else -1
			var angle: float = step * pair_index * dir + current_weapon.get_random_spread()
			launch_vectors.append(Vector2.RIGHT.rotated(angle))
		AmmoDetails.BulletPattern.WAVE:
			var wave_step = TAU / max(bullet_per_shot, 1)
			var amplitude = deg_to_rad(ammo.pattern_arc_angle)

			var angle: float = sin(wave_step * (index - 1)) * amplitude
			launch_vectors.append(initial_vector.normalized().rotated(angle))
		AmmoDetails.BulletPattern.SINE_WAVE:
			var amplitude = deg_to_rad(ammo.pattern_arc_angle)

			var angle: float = sin(float(index - 1)) * amplitude
			launch_vectors.append(initial_vector.normalized().rotated(angle))
		AmmoDetails.BulletPattern.SQUARE:
			var angle_square = PI / 2 * ((index - 1) % 4)
			launch_vectors.append(Vector2.RIGHT.rotated(angle_square))
		AmmoDetails.BulletPattern.STAR:
			var points = 5
			var step_star = TAU / points

			var angle: float = step_star * (((index - 1) * 2) % points)
			launch_vectors.append(Vector2.RIGHT.rotated(angle))
		AmmoDetails.BulletPattern.CROSS:
			var cross_angles = [0.0, PI / 2, PI, 3 * PI / 2]

			launch_vectors.append(Vector2.RIGHT.rotated(cross_angles[index % 4]))
		AmmoDetails.BulletPattern.DIAGONAL_CROSS:
			var diag_angles = [PI / 4, 3 * PI / 4, 5 * PI / 4, 7 * PI / 4]

			launch_vectors.append(Vector2.RIGHT.rotated(diag_angles[index % 4]))
		AmmoDetails.BulletPattern.FLOWER:
			var petal_step = TAU / max(bullet_per_shot, 1)

			var angle: float = sin((index - 1) * 2.0) * deg_to_rad(ammo.pattern_arc_angle) + petal_step * (index - 1)
			launch_vectors.append(Vector2.RIGHT.rotated(angle))
		AmmoDetails.BulletPattern.GRID:
			var step_angle = TAU / max(bullet_per_shot, 1)

			var angle: float = step_angle * index
			launch_vectors.append(Vector2.LEFT.rotated(angle))
		_:
			launch_vectors.append(initial_vector.normalized())
	return launch_vectors
