extends CharacterBody2D
class_name PlayerController

@export var speed: float = 200.0
@export var initial_weapon: WeaponDetails
@export var dead_sound_effect: SoundEffectDetails

@onready var bullet_spawn_position : Marker2D = %BulletFirePosition
@onready var fire_weapon: FireWeaponComponent = %FireWeapon
@onready var active_weapon: ActiveWeaponComponent = %ActiveWeapon
@onready var _health: HealthComponent = %Health
@onready var camera: PlayerCamera = %AdvancedCamera
@onready var _bullets_pool: PoolFracture = $"../Pool_FractureBullets"
@onready var _sound_effect_component: SoundEffectComponent = $SoundEffectComponent
#@onready var animation_component: AnimationComponentUI = $AnimationComponent

var fired_previous_frame: bool = false
var can_move: bool = true
var quadrant_builder: QuadrantBuilder
var player_details: PlayerDetails = PlayerDetails.new()
var damage_multiplier: float = 1.0
var weapons_array: Array = []

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	player_details = GameManager.player_details
	GameManager.player = self
	PersistenceDataManager.load_game()
	_health.zero_health.connect(on_zero_power)
	BitcoinNetwork.block_found.connect(_on_block_found)
	set_player()

func set_player():
	if !player_details: return
	
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

func _on_block_found(_block: BitcoinBlock):
	can_move = false

func _process(_delta: float) -> void:
	if !can_move: return
	
	fire()
	switch_weapon()
	look_at(get_global_mouse_position())
	

func _physics_process(_delta) -> void:
	if !can_move: return
	move()

func _apply_stats() -> void:
	var stats_array = player_details.apply_stats()
	
	speed = stats_array[0]
	damage_multiplier = stats_array[1]
	_health.set_max_health(stats_array[2])


## ------------ INPUT FUNCTIONS ------------------------------------

func move() -> void:
	var direction_horizontal : float = Input.get_axis("Move_left", "Move_right")
	var direction_vertical : float = Input.get_axis("Move_up","Move_down")
	
	if direction_horizontal:
		velocity.x = direction_horizontal * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	if direction_vertical:
		velocity.y = direction_vertical * speed
	else:
		velocity.y = move_toward(velocity.y, 0, speed)
	
	if direction_horizontal != 0 and direction_vertical != 0:
		velocity = Vector2(direction_horizontal, direction_vertical) * speed * 0.7
	move_and_slide()

func switch_weapon() -> void:
	if Input.is_action_just_pressed("Mouse_Wheel_Down"):
		active_weapon.select_previous_weapon()
	elif Input.is_action_just_pressed("Mouse_Wheel_Up"):
		active_weapon.select_next_weapon()


func fire() -> void:
	if Input.is_action_pressed("Fire"):
		fire_weapon.emit_signal("fire_weapon", true, fired_previous_frame)
		fired_previous_frame = true
	else:
		fired_previous_frame = false


func on_zero_power() -> void:
	can_move = false
	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).set_parallel(true)
	_sound_effect_component.play_sound()
	tween.tween_property(self, "scale", Vector2(0.0,0.0), 1.5).from_current()
	tween.tween_property(self, "rotation", 360.0, 1.0).from_current()
	
	await tween.finished
	visible = false


## ------------------------------------------
## SETTERS AND GETTERS

func get_max_health() -> float:
	return _health.get_max_health()

func get_current_health() -> float:
	return _health.get_current_health()

func get_health_node() -> HealthComponent:
	return _health

func get_player_camera() -> PlayerCamera:
	return camera

func get_active_weapon_node() -> ActiveWeaponComponent:
	return active_weapon

func get_current_weapon() -> WeaponDetails:
	return get_active_weapon_node().get_current_weapon()

func add_weapon_to_array(weapon_to_add: WeaponDetails) -> void:
	if !weapons_array.has(weapon_to_add):
		weapons_array.append(weapon_to_add)

## ----------- PERSISTENCE DATA FUNCTIONS --------------------------------------

func save_data():
	var data: PlayerSaveData = PlayerSaveData.new(speed, _health.get_initial_health(), active_weapon.get_current_weapon(), active_weapon.weapons_array)
	SaveSystem.set_var("player_data", data)
	#data.player_data.current_weapon = active_weapon.get_current_weapon()
	#data.player_data.weapons_array = weapons_array

func load_data():
	var data = SaveSystem.get_var("player_data")
	#active_weapon.set_weapon(data["current_weapon"])
	#weapons_array = data["weapons_array"]
