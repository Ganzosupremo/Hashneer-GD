extends CharacterBody2D
class_name PlayerController

@export var player_details: PlayerDetails
@export var speed: float = 200.0
@export var initial_weapon: WeaponDetails
@export var dead_sound_effect: SoundEffectDetails
@export var move_sound_effect: SoundEffectDetails
@export var mass: float = 5.0
@export var anti_gravity_thrust: float = 300.0

var gravity_force: Vector2 = Vector2.ZERO  # Store gravity force


# @export_category("Abilities")
# @export var abilities: Dictionary = {
# 	"block_core_finder": preload("res://Scenes/Player/Abilities/BlockCoreFinder.tscn"),
# }

@onready var bullet_spawn_position : Marker2D = %BulletFirePosition
@onready var fire_weapon: FireWeaponComponent = %FireWeapon
@onready var active_weapon: ActiveWeaponComponent = %ActiveWeapon
@onready var _health: HealthComponent = %Health
@onready var camera: AdvanceCamera = %AdvancedCamera
@onready var _bullets_pool: PoolFracture = $"../Pool_FractureBullets"
@onready var _sound_effect_component: SoundEffectComponent = $SoundEffectComponent
@onready var rotation_container: Node2D = $RotationContainer

var fired_previous_frame: bool = false
var can_move: bool = true
var input: Vector2 = Vector2.ZERO
var damage_multiplier: float = 1.0
var weapons_array: Array = []
# var _loaded_abilities: Dictionary = {}


func _ready() -> void:
	GameManager.player = self
	_health.zero_health.connect(on_zero_power)
	BitcoinNetwork.block_found.connect(_on_block_found)
	GameManager.level_completed.connect(deactivate_player)
	_sound_effect_component.set_sound(move_sound_effect)
	set_player()

func _process(_delta: float) -> void:
	if !can_move: return
	
	fire()
	switch_weapon()
	rotation_container.look_at(get_global_mouse_position())
	

func _physics_process(delta) -> void:
	if !can_move: return
	
	# Apply gravity force
	velocity += gravity_force * delta

	move(delta)

	# Reset gravity force after applying it
	gravity_force = Vector2.ZERO

#region Public Functions

func set_player() -> void:
	if !player_details: return
	# _instantiate_abilities()
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

func deactivate_player() -> void:
	can_move = false

# func unlock_ability(ability_id: String) -> void:
# 	if !_loaded_abilities.has(ability_id):
# 		# print_debug("Ability with ID %s not found in player." % ability_id)		
# 		return
	
# 	_loaded_abilities[ability_id].enable()
# 	# print_debug("Unlocked ability: %s" % ability_id)


func apply_central_force(force: Vector2) -> void:
	# Scale the force for better handling
	# var adjusted_force = force * 0.1  # Scale down to avoid extreme acceleration
	# print("Applying force: ", force)
	velocity += force
	move_and_slide()

func apply_gravity(force: Vector2) -> void:
	# print("Applying gravity: ", force)
	gravity_force = force

#endregion

## ___________________PRIVATE FUNCTIONS__________________________

# func _instantiate_abilities():
# 	for ability in abilities:
# 		var ability_instance: BaseAbility = abilities[ability].instantiate()
# 		if ability_instance is not BaseAbility: return

# 		ability_instance.disable()

# 		_loaded_abilities[ability] = ability_instance
# 		add_child(ability_instance)

func _unlock_saved_abilities() -> void:
	for ability_id in PlayerStatsManager.get_unlocked_abilities().keys():
		var ability: BaseAbility = PlayerStatsManager.get_unlocked_ability(ability_id).instantiate()
		add_child(ability)
		ability.enable()


func _apply_stats() -> void:
	var stats_array = player_details.apply_stats()
	
	speed = stats_array[0]
	damage_multiplier = stats_array[1]
	_health.set_max_health(stats_array[2])


## ___________________INPUT FUNCTIONS__________________________

func move(delta: float) -> void:
	input = get_input()
	var movement_velocity := Vector2.ZERO

	if input == Vector2.ZERO:
		# Handle friction, but only for the player's movement component
		# This prevents friction from completely stopping gravity effects
		if velocity.length() > (Constants.Player_Friction * delta):
			movement_velocity = velocity.normalized() * max(0, velocity.length() - (Constants.Player_Friction * delta))
		_sound_effect_component.stop_sound()
	else:
		# Apply anti-gravity thrust when space is held
		if Input.is_action_pressed("thrust"):
			# Get direction to center and apply thrust in opposite direction
			var direction_to_center = GameManager.current_quadrant_builder._grid_center - global_position
			if direction_to_center.length() > 10:
				movement_velocity -= direction_to_center.normalized() * anti_gravity_thrust * delta

		# Calculate movement velocity based on input
		movement_velocity = velocity + (input * Constants.Player_Acceleration * delta)
		_sound_effect_component.play_sound()

	velocity = movement_velocity.limit_length(speed)
	move_and_slide()

func switch_weapon() -> void:
	if Input.is_action_just_pressed("Mouse_Wheel_Down"):
		active_weapon.select_previous_weapon()
	elif Input.is_action_just_pressed("Mouse_Wheel_Up"):
		active_weapon.select_next_weapon()


func fire() -> void:
	if Input.is_action_pressed("Fire"):
		fire_weapon.fire_weapon.emit(true, fired_previous_frame, damage_multiplier)
		fired_previous_frame = true
	else:
		fired_previous_frame = false


## ___________________SIGNAL FUNCTIONS__________________________

func on_zero_power() -> void:
	_sound_effect_component.set_sound(dead_sound_effect)
	deactivate_player()
	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).set_parallel(true)
	_sound_effect_component.play_sound()
	tween.tween_property(self, "scale", Vector2(0.0,0.0), 1.5).from_current()
	tween.tween_property(self, "rotation", 360.0, 1.0).from_current()
	
	await tween.finished
	visible = false

func _on_block_found(_block: BitcoinBlock):
	# deactivate_player()
	pass

## _________________SETTERS AND GETTERS______________________

func get_max_health() -> float:
	return _health.get_max_health()

func get_current_health() -> float:
	return _health.get_current_health()

func get_health_node() -> HealthComponent:
	return _health

func get_player_camera() -> AdvanceCamera:
	return camera

func get_input() -> Vector2:
	var local: Vector2 = Vector2.ZERO
	local.x = Input.get_axis("Move_left", "Move_right")
	local.y = Input.get_axis("Move_up","Move_down")
	return local.normalized()


func get_active_weapon_node() -> ActiveWeaponComponent:
	return active_weapon

func get_current_weapon() -> WeaponDetails:
	return get_active_weapon_node().get_current_weapon()

func add_weapon_to_array(weapon_to_add: WeaponDetails) -> void:
	if !weapons_array.has(weapon_to_add):
		weapons_array.append(weapon_to_add)
		active_weapon._weapons_list = weapons_array
