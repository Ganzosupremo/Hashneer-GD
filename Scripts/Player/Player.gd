extends CharacterBody2D
class_name PlayerController

@export var speed : float = 200.0
@export var initial_weapon: WeaponDetails

var auto_fire_timer : Timer
var auto_fire_delay : float = 1.5
var weapons_array: Array

@onready var bullet_spawn_position : Marker2D = %BulletFirePosition
@onready var fire_weapon: FireWeapon = %FireWeapon
@onready var active_weapon: ActiveWeapon = %ActiveWeapon
@onready var _health: Health = %Health
@onready var camera = %AdvancedCamera
@onready var _bullets_pool: PoolFracture = $"../Pool_FractureBullets"
@onready var _fracurable_test: Node2D = $".."

var fired_previous_frame: bool = false
var can_move: bool = true
var quadrant_builder: QuadrantBuilder


const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	GameManager.player = self
	PersistenceDataManager.load_game()
	speed += add_speed_upgrades()
	_health.zero_health.connect(on_zero_power)
	quadrant_builder = get_tree().get_first_node_in_group("QuadrantBuilder")
	set_weapon()
	
func set_weapon() -> void:
	active_weapon.set_weapon(initial_weapon)
	weapons_array = []
	weapons_array.append(initial_weapon)
	for i in weapons_array.size():
		weapons_array[i].weapon_list_index = i

func _process(_delta: float) -> void:
	if !can_move: return
	
	fire()
	look_at(get_global_mouse_position())

func _physics_process(_delta) -> void:
	move()


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

func on_zero_power() -> void:
	can_move = false
	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.0,0.0), 1.5).from_current()
	tween.tween_property(self, "rotation", 360.0, 1.0).from_current()
	
	await tween.finished
	
	visible = false

func add_speed_upgrades() -> float:
	var total : float = 0.0
	var speed1: String = "Increase Movement Speed I"
	var speed2: String = "Increase Movement Speed II"
	var speed3: String = "Increase Movement Speed III"
	total += UpgradesManager.get_skill_power(speed1)
	total += UpgradesManager.get_skill_power(speed2)
	total += UpgradesManager.get_skill_power(speed3)
		
	return total

func fire() -> void:
	if Input.is_action_pressed("Fire"):
		fire_weapon.emit_signal("fire_weapon", true, fired_previous_frame)
		fired_previous_frame = true
	else:
		fired_previous_frame = false

## ------------------------------------------
## SETTERS AND GETTERS

func get_initial_health() -> float:
	return _health.get_initial_health()

func get_current_health() -> float:
	return _health.get_current_health()

func get_health_node() -> Health:
	return _health

func get_player_camera() -> PlayerCamera:
	return camera

func get_active_weapon_node() -> ActiveWeapon:
	return active_weapon

func get_current_weapon() -> WeaponDetails:
	return get_active_weapon_node().get_current_weapon()

## ----------- PERSISTENCE DATA FUNCTIONS --------------------------------------

func save_data():
	var data: PlayerData = PlayerData.new(speed, _health.get_initial_health(), active_weapon.get_current_weapon(), active_weapon.weapons_array)
	SaveSystem.set_var("player_data", data)
#	data.player_data.current_weapon = active_weapon.get_current_weapon()
#	data.player_data.weapons_array = weapons_array

func load_data():
	var data = SaveSystem.get_var("player_data")
	active_weapon.set_weapon(data["current_weapon"])
	weapons_array = data["weapons_array"]
