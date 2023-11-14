extends Area2D
class_name BulletC

@export_range(10.0, 50.0) var bullet_speed : float = 10.0
@export var bullet_damage: float = 25.0
@export var custom_carve_radius : bool = false
@export var carve_radius : int = 10: get = get_carve_radius
@export var hit_effect_scene: PackedScene = preload("res://Scenes/VFX/Explosion_hit_effect.tscn")

@onready var destruction_polygon: CollisionPolygon2D = %ExplosionPolygon

var direction : Vector2 = Vector2.RIGHT
var bullet_velocity : Vector2
var lifetime : float = 1.0
var collider : Node2D
var quadrant_builder: QuadrantBuilder
var time_since_spawn: float = 0.0

func _ready():
	bullet_damage += add_damage_to_bullet()
	print(bullet_damage)
	
	get_quadrant_builder()
	if custom_carve_radius: set_destruction_polygon_size()
	set_bullet_lifetime()
	set_movement_vector()

## Add the additional damage gained from upgrades to the bullet
func add_damage_to_bullet() -> float:
	var total: float = 0
	if UpgradesManager.is_skill_unlocked("Copper_bullets_upgrade"):
		total += UpgradesManager["upgrades"]["Copper_bullets_upgrade"]["power"]
	if UpgradesManager.is_skill_unlocked("Silver_bullets_upgrade"):
		total += UpgradesManager["upgrades"]["Silver_bullets_upgrade"]["power"]
	if UpgradesManager.is_skill_unlocked("Gold_bullets_upgrade"):
		total += UpgradesManager["upgrades"]["Gold_bullets_upgrade"]["power"]
	return total

func _physics_process(delta):
	position += transform.x * bullet_speed

func set_bullet_lifetime() -> void:
	var timer : Timer = Timer.new()
	add_child(timer)
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(func(): queue_free())
	timer.start()

func set_destruction_polygon_size() -> void:
	var number_points : int = 16
	var pol: PackedVector2Array = [] 
	for i in range(number_points):
		var angle = lerp(-PI, PI, float(i)/number_points)
		pol.push_back(position + Vector2(cos(angle), sin(angle)) * carve_radius)
	destruction_polygon.polygon = pol
#	destruction_polygon.position = position
#	destruction_polygon.global_position = global_position

func get_quadrant_builder() -> void:
	quadrant_builder = QuadrantBuilder.get_instance()

func set_movement_vector():
	direction = Vector2(cos(rotation), sin(rotation))
	bullet_velocity = direction * bullet_speed

func _on_collision_area_body_entered(body):
	print("Bullet collided with: ", body.name)  # Add this line
	if body.is_in_group("Player"): return
	collider = body
	queue_free()
	explode()
	
func explode():
	if quadrant_builder != null:
		spawn_hit_effect()
		quadrant_builder.carve(destruction_polygon.global_position, destruction_polygon, bullet_damage)
		queue_redraw()
	
func spawn_hit_effect():
	EffectsManager.spawn_explosion_effect(global_transform)
	call_deferred("queue_free")

func set_carve_radius(new_value: int):
	carve_radius = new_value
	set_destruction_polygon_size()

func get_carve_radius() -> int:
	return carve_radius


func _on_area_entered(area: Area2D) -> void:
	if area is CenterBlock:
		area.take_damage(bullet_damage)
