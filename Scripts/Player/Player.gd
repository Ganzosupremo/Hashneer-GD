extends CharacterBody2D
class_name PlayerController

@export var speed : float = 200.0
@export var bullet_scene : PackedScene = preload("res://Scenes/Player/Bullet.tscn")
@export var initial_weapon: WeaponDetails
@export var enable_auto_fire : bool = false

var auto_fire_timer : Timer
var auto_fire_delay : float = 1.5

@onready var bullet_spawn_position : Marker2D = %BulletFirePosition
@onready var fire_weapon: FireWeapon = %FireWeapon
@onready var active_weapon: ActiveWeapon = %ActiveWeapon
@onready var health: Health = %Health
@onready var camera = %AdvancedCamera

var other_collider : Node2D
var quadrant_terrain: QuadrantBuilder
var fired_previous_frame: bool = false
var can_move: bool = true

func _ready():
	GameManager.player = self
	active_weapon.set_weapon(initial_weapon)
	speed += add_speed_upgrades()
	health.zero_power.connect(on_zero_power)
	
	if enable_auto_fire: set_auto_fire_timer()

func set_auto_fire_timer() -> void:
	auto_fire_timer = Timer.new()
	add_child(auto_fire_timer)
	auto_fire_timer.wait_time = auto_fire_delay
	auto_fire_timer.one_shot = false
	auto_fire_timer.timeout.connect(Callable(self, "auto_fire"))
	auto_fire_timer.start()

func _process(_delta: float) -> void:
	if !can_move: return
	
	fire()
	look_at(get_global_mouse_position())

func _physics_process(_delta):
	move()

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
	
	if (UpgradesManager.is_skill_unlocked("MovementSpeed_UpgradeI")):
		total += UpgradesManager.upgrades["MovementSpeed_UpgradeI"]["power"]
	if (UpgradesManager.is_skill_unlocked("MovementSpeed_UpgradeII")):
		total += UpgradesManager.upgrades["MovementSpeed_UpgradeII"]["power"]
	if (UpgradesManager.is_skill_unlocked("MovementSpeed_UpgradeIII")):
		total += UpgradesManager.upgrades["MovementSpeed_UpgradeIII"]["power"]
	return total

func fire():
	if enable_auto_fire == true:
		fire_weapon.emit_signal("fire_weapon", true, fired_previous_frame)
		return
	
	if Input.is_action_pressed("Fire"):
		fire_weapon.emit_signal("fire_weapon", true, fired_previous_frame)
		fired_previous_frame = true
	else:
		fired_previous_frame = false

func auto_fire() -> void:
	if !enable_auto_fire: return
	fire()
