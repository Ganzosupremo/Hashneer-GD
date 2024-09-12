class_name FractureBullet extends RigidBody2D

signal Despawn(ref)

@export var radius: float = 50.0
@export var speed: float = 300.0

@onready var _poly := $Polygon2D
@onready var _col_poly := $CollisionPolygon2D
@onready var _timer := $Timer
@onready var _collision_detection_polygon: CollisionPolygon2D = %CollisionDetectionPolygon

@onready var trail_particles: PackedScene = preload("res://Scenes/WeaponSystem/bullet_particles.tscn")
@onready var trail: PackedScene = preload("res://Scenes/WeaponSystem/bullet_trail.tscn")


var quadrant_builder: QuadrantBuilder = null
var launch_velocity : float = 0.0
var direction: Vector2 = Vector2.RIGHT
var ammo_details: AmmoDetails


func _ready() -> void:
	setPolygon(PolygonLib.createCirclePolygon(radius, 2))

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() <= 0: return
	
	var body = state.get_contact_collider_object(0)
	if body is FracturableStaticBody2D and body is not BlockCore and quadrant_builder:
		var pos : Vector2 = state.get_contact_collider_position(0)
		quadrant_builder.fracture_quadrant_on_collision(pos, body, launch_velocity, ammo_details.bullet_damage, ammo_details.bullet_speed)
		
		call_deferred("destroy")
	if body is BlockCore and quadrant_builder:
		quadrant_builder.fracture_all(body, ammo_details.bullet_damage)
		call_deferred("destroy")

func set_velocity(vel: Vector2):
	launch_velocity = vel.length()

func spawn(pos : Vector2, launch_vector : Vector2, lifetime : float, quadrant_builder: QuadrantBuilder, ammo_details: AmmoDetails) -> void:
	self.ammo_details = ammo_details
	self.quadrant_builder = quadrant_builder
	
	set_velocity(launch_vector)
	global_position = pos
	_timer.start(lifetime)
	#set_trail_particles(ammo_details.emits_particles, ammo_details.lifetime_randomness)
	#set_bullet_trail(ammo_details.has_trail, ammo_details.trail_length, ammo_details.trail_gradient)
	
	linear_velocity = launch_vector


func despawn() -> void:
	global_rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0


func destroy() -> void:
	_timer.stop()
	#set_bullet_trail(false, 0, Gradient.new())
	#set_trail_particles(false, 0, 0)
	emit_signal("Despawn", self)


func setPolygon(polygon : PackedVector2Array) -> void:
	_poly.set_polygon(polygon)
	_col_poly.set_polygon(polygon)
	_collision_detection_polygon.set_polygon(polygon)


func _on_Timer_timeout() -> void:
	destroy()


func _on_collision_detection_body_entered(body: Node2D) -> void:
	call_deferred("destroy")

func set_bullet_trail(enabled: bool, length: int, gradient: Gradient):
	var instance = trail.instantiate()
	add_child(instance)
	instance.set_trail(enabled, length, gradient)

func set_trail_particles(enabled: bool = true, lifetime_randomness: float = 0.5, randomness: float = 0.5) -> void:
	var instance: EffectParticles = trail_particles.instantiate()
	add_child(instance)
	instance.set_trail_particles(ammo_details.has_trail, lifetime_randomness, randomness)
	instance.position = global_position
	instance.randomness = randomness
	instance.process_material.lifetime_randomness = lifetime_randomness
	instance.start_particles()
