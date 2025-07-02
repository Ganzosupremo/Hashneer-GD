extends CharacterBody2D
class_name PlayerController

@export_category("Events")
@export var main_event_bus: MainEventBus

@export_category("Parameters")
@export var player_details: PlayerDetails
@export var speed: float = 200.0
@export var initial_weapon: WeaponDetails
@export var dead_sound_effect: SoundEffectDetails
@export var move_sound_effect: SoundEffectDetails
@export var sound_on_hurt: SoundEffectDetails
@export var mass: float = 5.0
@export var anti_gravity_thrust: float = 300.0

var gravity_force: Vector2 = Vector2.ZERO  # Store gravity force


@onready var bullet_spawn_position : Marker2D = %BulletFirePosition
@onready var fire_weapon: FireWeaponComponent = %FireWeapon
@onready var active_weapon: ActiveWeaponComponent = %ActiveWeapon
@onready var _health: HealthComponent = %Health
@onready var _sound_effect_component: SoundEffectComponent = %SFXSoundComponent
@onready var movement_sound_effect_component: SoundEffectComponent = %MovementSoundEffectComponent
@onready var rotation_container: Node2D = $RotationContainer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var edge_polygon: Polygon2D = $EdgePolygon

var fired_previous_frame: bool = false
var can_move: bool = true
var input: Vector2 = Vector2.ZERO
var damage_multiplier: float = 1.0
var weapons_array: Array = []
var gravity_sources: Array = []
var abilities: Array = []


func _ready() -> void:
	gravity_sources.clear()
	GameManager.player = self
	_health.zero_health.connect(on_zero_power)
	main_event_bus.level_completed.connect(deactivate_player)
	movement_sound_effect_component.set_sound(move_sound_effect)
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
	_apply_stats()

	initial_weapon = player_details.initial_weapon
	weapons_array = player_details.weapons_array.duplicate(true)
	dead_sound_effect = player_details.dead_sound_effect
	set_weapon()

func set_weapon() -> void:
	active_weapon.set_weapon(initial_weapon)
	
	for weapon in weapons_array:
		active_weapon.add_weapon_to_list(weapon)

func deactivate_player(_args: MainEventBus.LevelCompletedArgs = null) -> void:
	can_move = false

	for ability in abilities:
		ability.disable()

func apply_gravity(force: Vector2) -> void:
	gravity_force = force

func damage(_damage: float) -> void:
	AudioManager.create_2d_audio_at_location(global_position, sound_on_hurt.sound_type, sound_on_hurt.destination_audio_bus)
	animation_player.play("hit-flash")
	get_health_node().take_damage(_damage)

#endregion

func _unlock_saved_abilities() -> void:
	for ability_id in PlayerStatsManager.get_unlocked_abilities().keys():
		var ability: BaseAbility = PlayerStatsManager.get_unlocked_ability(ability_id).instantiate()
		add_child(ability)
		abilities.append(ability)
		ability.enable()

func _apply_stats() -> void:
	var stats = player_details.apply_stats()
	
	speed = stats.Speed
	damage_multiplier = stats.Damage
	_health.set_max_health(stats.Health)

#region Input

func move(delta: float) -> void:
	input = get_input()

	var total_gravity = calculate_total_gravity()

	if input == Vector2.ZERO:
		velocity += total_gravity * delta
		if velocity.length() > (Constants.Player_Friction * delta):
			velocity -= velocity.normalized() * (Constants.Player_Friction * delta)
		else:
			velocity = Vector2.ZERO
	else:
		# Calculate movement velocity based on input
		velocity += (input * Constants.Player_Acceleration * delta)
		velocity = velocity.limit_length(Constants.Player_Max_Speed)
		AudioManager.create_2d_audio_at_location_with_persistent_player(global_position, move_sound_effect.sound_type, move_sound_effect.destination_audio_bus)
	move_and_slide()

func switch_weapon() -> void:
	if Input.is_action_just_pressed("Mouse_Wheel_Down"):
		active_weapon.select_previous_weapon()
	elif Input.is_action_just_pressed("Mouse_Wheel_Up"):
		active_weapon.select_next_weapon()


func fire() -> void:
	if Input.is_action_pressed("Fire"):
		fire_weapon.fire_weapon.emit(true, fired_previous_frame, damage_multiplier, get_global_mouse_position())
		fired_previous_frame = true
	else:
		fired_previous_frame = false

func add_weapon_to_array(weapon_to_add: WeaponDetails) -> void:
	if !weapons_array.has(weapon_to_add):
		weapons_array.append(weapon_to_add)
		active_weapon._weapons_list = weapons_array

#endregion

#region Signal

func on_zero_power() -> void:
	# _sound_effect_component.set_sound(dead_sound_effect)
	deactivate_player()
	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).set_parallel(true)
	# _sound_effect_component.play_sound()
	AudioManager.create_2d_audio_at_location(global_position, dead_sound_effect.sound_type, dead_sound_effect.destination_audio_bus)
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
