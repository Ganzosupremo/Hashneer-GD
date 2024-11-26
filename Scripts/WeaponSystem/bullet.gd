extends Area2D
class_name BulletC

@onready var destruction_polygon: CollisionPolygon2D = %ExplosionPolygon
@onready var gfx = %GFX
@onready var trail_particles: EffectParticles = %BulletTrailParticles
@onready var trail: BulletTrailComponent = %BulletTrail
@onready var colli_par_scene: PackedScene = preload("res://Scenes/WeaponSystem/bullet_particles.tscn")

@export_range(200.0, 4000.0) var bullet_speed : float = 10.0
@export var bullet_damage: float = 25.0
@export var custom_carve_radius : bool = false
@export var carve_radius : int = 50

var direction : Vector2 = Vector2.RIGHT
var lifetime: float = 1.0
var collider : Node2D
var quadrant_builder: QuadrantBuilder
var ammo_details: AmmoDetails

func _ready():
	look_at(position + direction)
	if custom_carve_radius: set_destruction_polygon_size(carve_radius)

func init_bullet(data: AmmoDetails):
	ammo_details = data
	set_bullet_lifetime(data.min_lifetime, data.max_lifetime)
	set_bullet_trail(data.has_trail, data.trail_length, data.trail_gradient)
	set_bullet_particles(data.emits_particles, data.lifetime_randomness, data.randomness)
	
	self.bullet_damage = data.bullet_damage
	self.bullet_damage += add_damage_to_bullet()
	self.bullet_speed = data.bullet_speed

func _physics_process(delta):
	move_ammo(delta)

func move_ammo(delta: float):
	var distance_vector = bullet_speed * delta * direction
	self.position += distance_vector

#func _on_area_entered(area: Area2D) -> void:
	#if area is BlockCore:
		#if area.take_damage(bullet_damage, false) == true:
			#var block = build_block()
			#area.mine_core("player", block)

func build_block() -> BitcoinBlock:
	var ins = BitcoinBlock.new(GameManager.builder_args.level_index, Time.get_datetime_string_from_system(false, true), "Block mined by the Player")
	return ins

## Add the additional damage gained from upgrades to the bullet
func add_damage_to_bullet() -> float:
	var total: float = 0.0
	var copper = "Copper Bullets"
	total += UpgradesManager.get_skill_power(copper)
	return total

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): return
	
	get_quadrant_builder()
	collider = body
	gfx.visible = false
	explode(body)

func explode(_body: Node2D):
	spawn_hit_effect()
	
	if quadrant_builder != null:
		quadrant_builder.carve(destruction_polygon.global_position, destruction_polygon, bullet_damage)
		queue_redraw()

	call_deferred("queue_free")

func spawn_hit_effect():
	var d = colli_par_scene.instantiate()
	get_parent().add_child(d)
	d.init_particles(ammo_details.collision_effect_details)
	d.position = global_position
	d.start_particles()

func set_carve_radius(new_value: int):
	carve_radius = new_value
	set_destruction_polygon_size()

func set_bullet_lifetime(min_lifetime: float = 1.0, max_lifetime: float = 2.0) -> void:
	var timer : Timer = Timer.new()
	add_child(timer)
	
	lifetime = randf_range(min_lifetime, max_lifetime)
	
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(func(): queue_free())
	timer.start()

func set_bullet_trail(enabled: bool, length: int, gradient: Gradient):
	trail.spawn(length, gradient)

func set_bullet_particles(enabled: bool = true, lifetime_randomness = 0.5, randomness = 0.5) -> void:
	trail_particles.randomness = randomness
	trail_particles.process_material.lifetime_randomness = lifetime_randomness
	trail_particles.emitting = enabled

func set_bullet_direction(to_direction: Vector2) -> void:
	direction = to_direction
	trail_particles.process_material.direction = (Vector3(-to_direction.x, -to_direction.y, 0.0))

func set_destruction_polygon_size(radius: float = 50.0) -> void:
	var number_points : int = 16
	var pol: PackedVector2Array = [] 
	for i in range(number_points):
		var angle = lerp(-PI, PI, float(i)/number_points)
		pol.push_back(position + Vector2(cos(angle), sin(angle)) * radius)
	destruction_polygon.polygon = pol

func get_carve_radius() -> int:
	return carve_radius

func get_quadrant_builder() -> void:
	quadrant_builder = get_tree().get_first_node_in_group("QuadrantBuilder")
