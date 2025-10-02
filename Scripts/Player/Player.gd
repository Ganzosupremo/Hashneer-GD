extends CharacterBody2D
class_name PlayerController
## This is the player controller script that handles player movement, firing weapons, and applying damage.
## 
## It extends the [CharacterBody2D] class and uses various components to manage health, weapons, and abilities.
## This script is responsible for player input, movement, firing weapons, and handling player health.
## It also manages the player's abilities and interactions with gravity sources.
## It is designed to be flexible and extensible, allowing for easy addition of new weapons and abilities.
## It uses the [MainEventBus] for event handling and the [PlayerDetails] resource for player configuration.
## It also uses the [AudioManager] for sound effects and the [VFXManager] for visual effects.


@export_category("Events")
@export var main_event_bus: MainEventBus

@export_category("Parameters")
@export var player_details: PlayerDetails

var move_sound_effect: SoundEffectDetails
var hit_sound_effect: SoundEffectDetails
var death_vfx: VFXEffectProperties
var hit_vfx: VFXEffectProperties
var gravity_force: Vector2 = Vector2.ZERO  # Store gravity force
var speed: float = 200.0
var initial_weapon: WeaponDetails
var dead_sound_effect: SoundEffectDetails

@onready var bullet_spawn_position : Marker2D = %BulletFirePosition
@onready var fire_weapon: FireWeaponComponent = %FireWeapon
@onready var active_weapon: ActiveWeaponComponent = %ActiveWeapon
@onready var _health: HealthComponent = %Health
@onready var rotation_container: Node2D = $RotationContainer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var edge_polygon: Polygon2D = $EdgePolygon

var fired_previous_frame: bool = false
var can_move: bool = true
var input: Vector2 = Vector2.ZERO
var player_damage_multiplier_percent: float = 1.0
var weapons_array: Array = []
var gravity_sources: Array = []
var abilities: Array = []

# Footstep system
var footstep_timer: float = 0.0
var base_step_interval: float = 0.45  # ~2.2 Hz at walking speed

# Squash and stretch
var squash_tween: Tween
var previous_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	gravity_sources.clear()
	GameManager.player = self
	_health.zero_health.connect(on_zero_power)
	main_event_bus.level_completed.connect(deactivate_player)
	set_player()
	edge_polygon.polygon = PolygonLib.createCirclePolygon(20.0, 6)

func _process(_delta: float) -> void:
	if !can_move: return
	
	fire()
	switch_weapon()
	rotation_container.look_at(get_global_mouse_position())

func _physics_process(delta) -> void:
	if !can_move: return

	velocity += gravity_force * delta
	move(delta)
	
	gravity_force = Vector2.ZERO

#region Public Functions

func set_player() -> void:
	if !player_details: return
	
	_unlock_saved_abilities()
	speed = player_details.speed
	player_damage_multiplier_percent = player_details.damage_multiplier_percent
	_health.set_max_health(player_details.max_health)
	
	_apply_stats()

	initial_weapon = player_details.initial_weapon
	weapons_array = player_details.weapons_array.duplicate(true)
	dead_sound_effect = player_details.dead_sound_effect
	move_sound_effect = player_details.move_sound_effect
	hit_sound_effect = player_details.hit_sound_effect
	death_vfx = player_details.death_vfx
	hit_vfx = player_details.hit_vfx
	set_weapon()

func set_weapon() -> void:
	active_weapon.set_weapon(initial_weapon)
	
	for weapon in weapons_array:
		if weapon == null: continue
		active_weapon.add_weapon_to_list(weapon)

func deactivate_player(_args: MainEventBus.LevelCompletedArgs = null) -> void:
	can_move = false
	collision_layer = 0
	collision_mask = 0
	for ability in abilities:
		ability.disable()

func apply_gravity(force: Vector2) -> void:
	gravity_force = force

## Applies damage to the player and plays hit sound and visual effects.
## [param _damage]: The amount of damage to apply.[br]
## [param hit_position]: The position where the hit occurred, used for visual effects.
## If not provided, defaults to [Vector2.ZERO].
func damage(_damage: float, hit_position: Vector2 = Vector2.ZERO) -> void:
	AudioManager.create_2d_audio_at_location(global_position, hit_sound_effect.sound_type, hit_sound_effect.destination_audio_bus)
	var angle: float = 0.0
	if hit_position != Vector2.ZERO:
		angle = (global_position - hit_position).angle()
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.PLAYER_HIT, Transform2D(angle, global_position), hit_vfx)
	animation_player.play("hit-flash")

	# Add camera trauma and hitstop on hit
	if GameManager.get_main_camera():
		GameManager.get_main_camera().add_trauma(0.25)
	apply_hitstop(0.06, 0.3)


	get_health_node().take_damage(_damage)


## Applies a brief time slowdown effect (hitstop/freeze frame).[br]
## [param duration]: How long the hitstop lasts in seconds.[br]
## [param time_scale]: The time scale to apply (0.0 = full freeze, 1.0 = normal)
func apply_hitstop(duration: float = 0.08, time_scale: float = 0.15) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale, true, false, true).timeout
	Engine.time_scale = 1.0
#endregion

func _unlock_saved_abilities() -> void:
	for ability_label in PlayerStatsManager.get_unlocked_abilities().keys():
		var ability_scene: PackedScene = PlayerStatsManager.get_unlocked_abilities().get(ability_label, null)
		if ability_scene == null:
			DebugLogger.error("Ability with label '%s' not found in unlocked abilities." % ability_label)
			continue
		var ability: BaseAbility = ability_scene.instantiate()
		add_child(ability)
		abilities.append(ability)
		ability.enable()

func _apply_stats() -> void:
	var stats: Dictionary = player_details.apply_stats()
	
	speed = stats.Speed
	player_damage_multiplier_percent = stats.Damage
	_health.set_max_health(stats.Health)

#region Input

func move(delta: float) -> void:
	input = get_input()
		
	var total_gravity = calculate_total_gravity()
	velocity += total_gravity * delta
	
	if input == Vector2.ZERO:
		# Apply friction when no input
		if velocity.length() > (Constants.Player_Friction * delta):
			velocity -= velocity.normalized() * (Constants.Player_Friction * delta)
		else:
			velocity = Vector2.ZERO
		footstep_timer = 0.0  # Reset footstep timer when stopped
	else:
		# Steer-based movement for better responsiveness
		var desired_velocity = input * Constants.Player_Max_Speed
			
		# Apply aim-aligned strafe assist
		var aim_direction = (get_global_mouse_position() - global_position).normalized()
		var input_aim_alignment = input.dot(aim_direction)
		var steer_bonus = 1.0
		if input_aim_alignment > 0.7:
			steer_bonus = Constants.Player_Steer_Assist
			
		# Determine acceleration based on movement context
		var accel_rate = Constants.Player_Acceleration
			
		# Check if we're turning or braking
		var current_direction = velocity.normalized()
		var input_dot = current_direction.dot(input)
			
		if velocity.length() > 10.0:
			if input_dot < -0.3:
				# Braking/reversing
				accel_rate = Constants.Player_Brake_Accel
			elif input_dot < 0.7:
				# Turning
				accel_rate = Constants.Player_Turn_Accel
			else:
				# Normal movement
				accel_rate = Constants.Player_Deceleration if velocity.length() > desired_velocity.length() else Constants.Player_Acceleration
			
		# Steer toward desired velocity
		var accel_factor = min(1.0, (accel_rate * steer_bonus * delta) / Constants.Player_Max_Speed)
		velocity = velocity.lerp(desired_velocity, accel_factor)
			
		# Clamp to max speed
		velocity = velocity.limit_length(Constants.Player_Max_Speed)
			
		# Footstep cadence system
		var speed_ratio = velocity.length() / Constants.Player_Max_Speed
		var step_interval = base_step_interval / max(speed_ratio, 0.5)  # Faster steps when moving faster
			
		footstep_timer += delta
		if footstep_timer >= step_interval:
			footstep_timer = 0.0
			AudioManager.create_2d_audio_at_location(global_position, move_sound_effect.sound_type, move_sound_effect.destination_audio_bus)
			
		# Apply squash/stretch based on acceleration
		_apply_squash_stretch()
	
	previous_velocity = velocity
	move_and_slide()

func switch_weapon() -> void:
	if Input.is_action_just_pressed("Mouse_Wheel_Down"):
		active_weapon.select_previous_weapon()
	elif Input.is_action_just_pressed("Mouse_Wheel_Up"):
		active_weapon.select_next_weapon()

## Applies weapon recoil to player velocity
## [param recoil_direction]: Direction of the recoil (usually opposite to firing direction)
## [param recoil_strength]: Strength of the recoil knockback
func apply_weapon_recoil(recoil_direction: Vector2, recoil_strength: float = 80.0) -> void:
	velocity -= recoil_direction.normalized() * recoil_strength


func fire() -> void:
	if Input.is_action_pressed("Fire"):
		fired_previous_frame = true
		fire_weapon.fire_weapon.emit(true, fired_previous_frame, player_damage_multiplier_percent, get_global_mouse_position())
	else:
		fired_previous_frame = false
		fire_weapon.fire_weapon.emit(false, fired_previous_frame, player_damage_multiplier_percent, get_global_mouse_position())

func add_weapon_to_array(weapon_to_add: WeaponDetails) -> void:
	if !weapons_array.has(weapon_to_add):
		weapons_array.append(weapon_to_add)
		active_weapon._weapons_list = weapons_array

# Applies subtle squash and stretch based on acceleration/deceleration
func _apply_squash_stretch() -> void:
	var acceleration = (velocity - previous_velocity).length()
		
	if acceleration > 100.0:  # Only apply if accelerating significantly
		var squash_amount = clamp(acceleration / 5000.0, 0.0, 0.08)
		var target_scale = Vector2.ONE
				
		# Determine if accelerating or braking
		var velocity_change = velocity.length() - previous_velocity.length()
				
		if velocity_change > 0:
			# Accelerating: squash in direction of movement
			var move_direction = velocity.normalized()
			target_scale = Vector2(1.0 - squash_amount, 1.0 + squash_amount)
		else:
			# Braking: stretch in direction of movement
			target_scale = Vector2(1.0 + squash_amount, 1.0 - squash_amount)
				
			if squash_tween:
				squash_tween.kill()
				
			squash_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			squash_tween.tween_property(self, "scale", target_scale, 0.15)
			squash_tween.tween_property(self, "scale", Vector2.ONE, 0.1)


#endregion

#region Signal

func on_zero_power() -> void:
	deactivate_player()
	
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.PLAYER_DEATH, global_transform, death_vfx)
	AudioManager.create_2d_audio_at_location(global_position, dead_sound_effect.sound_type, dead_sound_effect.destination_audio_bus)
	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.0,0.0), 1.5).from_current()
	tween.tween_property(self, "rotation", 360.0, 1.0).from_current()
	
	await tween.finished
	visible = false

func _on_pickups_collector_area_entered(area: Area2D) -> void:
	if area.is_in_group("GravitySource"):
		gravity_sources.append(area)

func _on_pickups_collector_area_exited(area: Area2D) -> void:
	gravity_sources.erase(area)

#endregion

#region Getters

func get_max_health() -> float:
	return _health.get_max_health()

func get_current_health() -> float:
	return _health.get_current_health()

func get_health_node() -> HealthComponent:
	return _health

func get_input() -> Vector2:
	var local: Vector2 = Vector2.ZERO
	local.x = int(Input.get_axis("Move_left", "Move_right"))
	local.y = int(Input.get_axis("Move_up","Move_down"))
	return local.normalized()

func calculate_total_gravity() -> Vector2:
		var total: Vector2 = Vector2.ZERO
		for source in gravity_sources:
			var direction = source.global_position - global_position
			var distance = direction.length()
			
			# Prevent extreme gravity at close range
			var min_effective_distance = 50.0  # Minimum distance for gravity calculations
			var max_strength = 1500.0  # Absolute maximum gravity force
			
			# Smooth distance calculation with lower bound
			var effective_distance = max(distance, min_effective_distance)
			
			# Modified gravity calculation with cubic falloff
			var strength = source.gravity * pow(
				source.gravity_point_unit_distance / effective_distance, 
				1.5  # Reduced from quadratic (2) to 1.5 for smoother transition
			)
			
			# Apply absolute maximum cap
			strength = min(strength, max_strength)
			
			total += direction.normalized() * strength
		return total

func get_active_weapon_node() -> ActiveWeaponComponent:
	return active_weapon

func get_current_weapon() -> WeaponDetails:
	return get_active_weapon_node().get_current_weapon()
#endregion
