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
var _laser_beam: LaserBeam

func _ready() -> void:
		quadrant_builder = get_tree().get_first_node_in_group("QuadrantBuilder")
		_initialize_bullet_pools()
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

func on_fire_weapon(has_fired: bool, fired_previous_frame: bool, player_damage_multiplier: float, target_position: Vector2 = Vector2.ZERO) -> void:
		weapon_fire(has_fired, fired_previous_frame, player_damage_multiplier, target_position)


## Fires the weapon based on the current state and parameters.[br]
## [param has_fired] - Indicates if the weapon has fired this frame.[br]
## [param player_damage_multiplier] - The damage multiplier applied to the player.[br]
## [param target_position] - The position where the weapon is aimed at, used for targeting purposes.[br]
## This method handles the firing logic, including cooldowns, spawning bullets, and
## managing laser beams if applicable. It also triggers camera shake effects and visual effects
## when firing the weapon.
## If the weapon is not ready to fire, it will reset the cooldown timer and destroy any
## existing laser beam if it was fired previously.
## If the weapon is ready to fire, it will spawn the appropriate ammo based on the current
## weapon and ammo details. It supports different bullet patterns and firing modes, including
## simultaneous firing of multiple bullets.
## It also handles the case where a laser beam is fired, updating its position and direction
## if it already exists, or creating a new laser beam instance if it does not.
func weapon_fire(has_fired: bool, fired_previous_frame: bool, player_damage_multiplier: float, target_position: Vector2 = Vector2.ZERO) -> void:
		var ammo: AmmoDetails = active_weapon_component.get_current_ammo()
		current_weapon = active_weapon_component.get_current_weapon()
		
		if ammo.bullet_type == AmmoDetails.BulletType.LASER:
				# Handle laser beam termination on release or ammo change
				if _handle_laser_beam_termination(has_fired, fired_previous_frame, ammo): return
				if ready_to_fire(has_fired, fired_previous_frame) or (_laser_beam != null):
						# If the weapon is ready to fire, we can proceed with firing
						_fire_laser(ammo, player_damage_multiplier, target_position)
		else:
				if ready_to_fire(has_fired, fired_previous_frame):
						_trigger_camera_shake()
						_fire_ammo(ammo, player_damage_multiplier, target_position)
						reset_cooldown_timer()

# Handles the termination of the laser beam based on the firing state and ammo type.
func _handle_laser_beam_termination(has_fired: bool, fired_previous_frame: bool, ammo: AmmoDetails) -> bool:
	# Stop on release
	if !has_fired and fired_previous_frame and _laser_beam:
		GameManager._player_camera.stop_constant_shake()
		_laser_beam.destroy()
		_laser_beam = null
		reset_cooldown_timer()
		return true
	# Stop if ammo type changed
	if _laser_beam and ammo.bullet_type != AmmoDetails.BulletType.LASER:
		GameManager._player_camera.stop_constant_shake()
		_laser_beam.destroy()
		_laser_beam = null
		reset_cooldown_timer()
		return true
	return false

# Performs firing effects such as spawning visual effects and shaking the camera.
# This method is called when the weapon is fired to create visual feedback for the player.
func _trigger_camera_shake() -> void:
		if shake_camera_on_fire and GameManager._player_camera:
				# Add trauma-based shake (small amount for firing)
				GameManager._player_camera.add_trauma(current_weapon.trauma_shake_amount)
				
				# Add directional recoil kick to camera
				var aim_angle = (bullet_spawn_position.global_position.direction_to(GameManager.get_player().get_global_mouse_position())).angle()
				GameManager.get_main_camera().recoil_kick(aim_angle, current_weapon.recoil_kick_strength)

				# Apply weapon recoil to player velocity (if not enemy weapon)
				if !is_enemy_weapon and GameManager.get_player():
						var recoil_direction = GameManager.get_player().get_global_mouse_position() - GameManager.get_player().global_position
						GameManager.get_player().apply_weapon_recoil(recoil_direction, current_weapon.recoil_strength)

# Fires a laser beam based on the provided ammo details and target position.
func _fire_laser(ammo: AmmoDetails, player_damage_multiplier: float, target_position: Vector2 = Vector2.ZERO) -> void:
	GameManager.get_player_camera().start_constant_shake_with_preset(Constants.ShakeMagnitude.Medium)
	var initial_vector: Vector2 = target_position - bullet_spawn_position.global_position
	
	if !_laser_beam:
		var scene_to_use: PackedScene = ammo.laser_beam_scene
		_laser_beam = scene_to_use.instantiate()
		get_node(".").add_child(_laser_beam)
		
		var lifetime: float = ammo.get_bullet_lifetime()
		ammo.get_final_damage(player_damage_multiplier, current_weapon.get_damage_multiplier())
		_laser_beam.spawn(bullet_spawn_position.global_position, bullet_spawn_position.global_transform, initial_vector, lifetime, quadrant_builder, ammo)
	else:
		# If the laser beam already exists, we just update its position and direction
		_laser_beam.update_beam(bullet_spawn_position.global_position, initial_vector)


# Fires ammo based on the provided ammo details and target position.
func _fire_ammo(ammo: AmmoDetails, player_damage_multiplier: float, target_position: Vector2 = Vector2.ZERO) -> void:
	#GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.WEAPON_FIRE, shoot_effect_position.global_transform, current_weapon.weapon_shoot_effect)
	
	_spawn_muzzle_flash_light()
	ammo.get_final_damage(player_damage_multiplier, current_weapon.get_damage_multiplier())
	
	var bullet_counter: int = 0
	var bullets_per_shoot: int = ammo.get_ammo_count()
	var spawn_interval: float = 0.0

	if bullets_per_shoot > 1 and !ammo.fire_pattern_simultaneous:
		spawn_interval = ammo.get_bullet_spawn_interval()

	# Play fire sound (pitch variation will be added in audio enhancement pass)
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

## Checks if the weapon is ready to fire based on the cooldown timer.
## This method returns true if the cooldown timer is less than or equal to zero,
## indicating that the weapon can fire again. It is used to determine if the weapon
## can be fired without waiting for the cooldown period to expire.
func ready_to_fire(has_fired: bool, fired_previous_frame: bool) -> bool:
	# Only fire when the trigger is pressed
	if has_fired:
		# Initial press always fires immediately
		if !fired_previous_frame:
			return true
		# Holding the trigger requires cooldown
		return fire_rate_cooldown_timer <= 0.0
	# Not pressing trigger: cannot fire
	return false

## Resets the cooldown timer for firing the weapon.
## This method is called to reset the cooldown timer after firing a weapon or when the weapon is not ready to fire.
## It sets the cooldown timer to the current weapon's fire cooldown value.
func reset_cooldown_timer() -> void:
	fire_rate_cooldown_timer = current_weapon.get_fire_cooldown()

# Checks if the provided pool is valid for use.
func _is_pool_valid(pool: PoolFracture) -> bool:
	if is_instance_valid(pool):
		return true
	elif pool != null:
		return true
	return false

# Initializes the bullet pools based on whether the weapon is for an enemy or player.
func _initialize_bullet_pools() -> void:
	if is_enemy_weapon:
		current_pool = get_tree().get_first_node_in_group("EBulletsPool")
	else:
		current_pool = get_tree().get_first_node_in_group("PBulletsPool")
	if not current_pool:
		DebugLogger.error("Bullet pool is not set for FireWeaponComponent. Please check the Node Group for mispellings.")
		return
	if use_object_pool and not current_pool:
		DebugLogger.error("Object pool is not set for FireWeaponComponent. Please check the Node Group for mispellings.")
		return

# Calculates bullet trajectory vectors based on the specified bullet pattern
# [br]
# This function determines the direction vectors for each bullet to be fired based
# on the ammo's bullet pattern, the number of bullets per shot, and the initial direction.[br]
# 
# [param ammo] - Contains bullet pattern and other ammo properties.[br]
# [param bullet_per_shot] - Number of bullets to be fired in a single shot.[br]
# [param initial_vector] - Base direction vector for the shot.[br]
# 
# [return Array] - Array of Vector2 representing normalized direction vectors for each bullet.
#
# Bullet patterns:
# [- SINGLE]: Returns just the normalized initial vector.[br]
# [- RANDOM_SPREAD]: Adds random angle variation within the weapon's spread range.[br]
# [- SPREAD/ARC]: Creates a fan pattern with evenly distributed angles across the specified arc.[br]
# [- CIRCLE]: Creates a circular pattern with bullets evenly distributed in 360 degrees.
func _calculate_bullet_spread(ammo: AmmoDetails, index: int, bullet_per_shot: int, initial_vector: Vector2) -> Array:
	var launch_vectors: Array = []
	match ammo.bullet_pattern:
		AmmoDetails.BulletPattern.SINGLE:
			# For SINGLE pattern, just return the initial vector normalized
			launch_vectors.append(initial_vector.normalized())
		AmmoDetails.BulletPattern.RANDOM_SPREAD:
			var angle: float = randf_range(-PI, PI) * current_weapon.get_spread()
			launch_vectors.append(initial_vector.normalized().rotated(angle))
		AmmoDetails.BulletPattern.ARC:
			var step: float = 0.0
			var arc_spread: float = ammo.pattern_arc_angle
			if bullet_per_shot > 1:
				step = deg_to_rad(arc_spread) / float(bullet_per_shot - 1)

			var angle: float = - arc_spread + step * index
			launch_vectors.append(initial_vector.normalized().rotated(angle))
		AmmoDetails.BulletPattern.SPREAD:
			var angle: float = randf_range(-current_weapon.get_spread(), current_weapon.get_spread())
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


# Spawns a brief muzzle flash light effect for visual impact
func _spawn_muzzle_flash_light() -> void:
	var muzzle_light = PointLight2D.new()
	muzzle_light.enabled = true
	muzzle_light.energy = 1.5
	muzzle_light.texture_scale = 2.0
	muzzle_light.color = Color(1.0, 0.9, 0.6)  # Warm yellow-orange flash
	shoot_effect_position.add_child(muzzle_light)
	
	# Flicker and fade out the light
	var tween = create_tween()
	tween.tween_property(muzzle_light, "energy", 0.0, 0.08)
	tween.tween_callback(func(): muzzle_light.queue_free())
