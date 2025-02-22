extends CharacterBody2D
class_name PlayerController

@export var speed: float = 200.0
@export var initial_weapon: WeaponDetails
@export var dead_sound_effect: SoundEffectDetails

@export_category("Abilities")
@export var abilities: Dictionary = {
	"block_core_finder": preload("res://Scenes/Player/Abilities/BlockCoreFinder.tscn"),
}

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
var quadrant_builder: QuadrantBuilder
var player_details: PlayerDetails
var damage_multiplier: float = 1.0
var weapons_array: Array = []
var _loaded_abilities: Dictionary = {}


func _ready() -> void:
	GameManager.player = self
	player_details = GameManager.player_details.duplicate(true)
	_health.zero_health.connect(on_zero_power)
	BitcoinNetwork.block_found.connect(_on_block_found)
	GameManager.current_block_core.destroyed.connect(deactivate_player)
	GameManager.game_terminated.connect(deactivate_player)
	set_player()

func _process(_delta: float) -> void:
	if !can_move: return
	
	fire()
	switch_weapon()
	rotation_container.look_at(get_global_mouse_position())
	

func _physics_process(delta) -> void:
	if !can_move: return
	move(delta)

## ___________________PUBLIC FUNCTIONS__________________________

func set_player() -> void:
	if !player_details: return
	_instantiate_abilities()
	_unlock_saved_abilities()
	_apply_stats()

	initial_weapon = player_details.initial_weapon
	weapons_array = player_details.weapons_array.duplicate(true)
	dead_sound_effect = player_details.dead_sound_effect
	_sound_effect_component.set_sound(dead_sound_effect)
	set_weapon()

func set_weapon() -> void:
	active_weapon.set_weapon(initial_weapon)
	
	for weapon in weapons_array:
		active_weapon.add_weapon_to_list(weapon)

func deactivate_player() -> void:
	can_move = false

func unlock_ability(ability_id: String) -> void:
	if !_loaded_abilities.has(ability_id):
		# print_debug("Ability with ID %s not found in player." % ability_id)		
		return
	
	_loaded_abilities[ability_id].enable()
	# print_debug("Unlocked ability: %s" % ability_id)


## ___________________PRIVATE FUNCTIONS__________________________

func _instantiate_abilities():
	for ability in abilities:
		var ability_instance: BaseAbility = abilities[ability].instantiate()
		if ability_instance is not BaseAbility: return

		ability_instance.disable()

		_loaded_abilities[ability] = ability_instance
		add_child(ability_instance)

func _unlock_saved_abilities() -> void:
	for ability_id in GameManager.unlocked_abilities.keys():
		unlock_ability(ability_id)

func _apply_stats() -> void:
	var stats_array = player_details.apply_stats()
	
	speed = stats_array[0]
	damage_multiplier = stats_array[1]
	_health.set_max_health(stats_array[2])


## ___________________INPUT FUNCTIONS__________________________

func move(delta: float) -> void:
	input = get_input()

	if input == Vector2.ZERO:
		if velocity.length() > (Constants.Player_Friction * delta):
			velocity -= velocity.normalized() * (Constants.Player_Friction * delta)
		else: velocity = Vector2.ZERO
	
	else:
		velocity += (input * Constants.Player_Acceleration * delta)
		velocity = velocity.limit_length(speed)
	move_and_slide()

func switch_weapon() -> void:
	if Input.is_action_just_pressed("Mouse_Wheel_Down"):
		active_weapon.select_previous_weapon()
	elif Input.is_action_just_pressed("Mouse_Wheel_Up"):
		active_weapon.select_next_weapon()


func fire() -> void:
	if Input.is_action_pressed("Fire"):
		fire_weapon.emit_signal("fire_weapon", true, fired_previous_frame, damage_multiplier)
		fired_previous_frame = true
	else:
		fired_previous_frame = false


## ___________________SIGNAL FUNCTIONS__________________________

func on_zero_power() -> void:
	deactivate_player()
	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).set_parallel(true)
	_sound_effect_component.play_sound()
	tween.tween_property(self, "scale", Vector2(0.0,0.0), 1.5).from_current()
	tween.tween_property(self, "rotation", 360.0, 1.0).from_current()
	
	await tween.finished
	visible = false

func _on_block_found(_block: BitcoinBlock):
	deactivate_player()

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
