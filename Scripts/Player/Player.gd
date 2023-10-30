extends CharacterBody2D
#class_name PlayerController

@export var speed : float = 200.0
@export var bullet_scene : PackedScene = preload("res://Scenes/Player/Bullet.tscn")

var auto_fire_timer : Timer
var auto_fire_delay : float = 1.5

@export var enable_auto_fire : bool = false
@onready var bullet_spawn_position : Marker2D = %BulletFirePosition

var other_collider : Node2D
var quadrant_terrain: QuadrantBuilder

func _ready():
	if enable_auto_fire: set_auto_fire_timer()

func set_auto_fire_timer() -> void:
	auto_fire_timer = Timer.new()
	add_child(auto_fire_timer)
	auto_fire_timer.wait_time = auto_fire_delay
	auto_fire_timer.one_shot = false
	auto_fire_timer.timeout.connect(Callable(self, "auto_fire"))
	auto_fire_timer.start()

func _physics_process(delta):
	move()
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("Fire"): fire()

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

func fire():
	var bullet_instance := bullet_scene.instantiate()
	owner.add_child(bullet_instance)
	bullet_instance.transform = bullet_spawn_position.global_transform
#	bullet_instance.set_carve_radius(100)
	
func auto_fire() -> void:
	if !enable_auto_fire: return
	fire()

func mine():
	if other_collider.is_in_group("Destructibles"):
		var terrain = other_collider.get_parent() as DestroyableTerrain
#		terrain.clip(mine_polygon)

	if quadrant_terrain != null:
#		quadrant_terrain.carve(mine_polygon.global_position, mine_polygon)
		EffectsManager.spawn_explosion_effect(global_transform)
		queue_redraw()
