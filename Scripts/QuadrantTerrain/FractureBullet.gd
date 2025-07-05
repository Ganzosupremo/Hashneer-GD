class_name FractureBullet extends RigidBody2D

signal Despawn(ref)

@export var use_object_pool: bool = false
@export var radius: float = 50.0
@export var speed: float = 300.0

@onready var _poly := $Polygon2D
@onready var _col_poly := $CollisionPolygon2D
@onready var _timer := %Timer
@onready var _collision_box_component_polygon: CollisionPolygon2D = %CollisionBoxComponentPolygon
@onready var trail: BulletTrailComponent = %BulletTrail
@onready var light_occluder_2d: LightOccluder2D = $LightOccluder2D


var q_b: QuadrantBuilder = null
var launch_velocity : float = 0.0
var ammo_details: AmmoDetails


func _ready() -> void:
	# Delete if using the PoolFracturePool
	if not use_object_pool:
		Despawn.connect(despawn)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() <= 0: return

	var body = state.get_contact_collider_object(0)
	var hit_pos: Vector2 = state.get_contact_collider_position(0)

	_spawn_vfx_effect(hit_pos)
	_handle_collision(body, hit_pos)
	# if body is FracturableStaticBody2D and body is not BlockCore and q_b:
	# 	var pos : Vector2 = state.get_contact_collider_position(0)
	# 	q_b.fracture_quadrant_on_collision(pos, body, launch_velocity, damage_to_deal, ammo_details.bullet_speed)
	# 	call_deferred("destroy")
	# elif body is BlockCore and q_b:
	# 	q_b.fracture_block_core(damage_to_deal, "Player")
	# 	call_deferred("destroy")
	# elif body is BaseEnemy:
	# 	var force: Vector2 = (body.global_position - global_position).normalized() * ammo_details.fracture_force
	# 	body.call_deferred("damage", ammo_details.fracture_damage, global_position, force, 0.25, modulate)
	# 	call_deferred("destroy")
	# elif body is ShieldComponent:
	# 	body.call_deferred("absorb_damage", ammo_details.fracture_damage.x, global_position)
	# 	call_deferred("destroy")
	# elif body is PlayerController:
	# 	body.damage(ammo_details.bullet_damage)
	# 	call_deferred("destroy")

func _spawn_vfx_effect(hit_pos: Vector2) -> void:
	var angle: float = linear_velocity.angle() + PI
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.SPARKS, Transform2D(angle, hit_pos), ammo_details.bullet_hit_vfx)

func _handle_collision(body: Node2D, pos: Vector2) -> void:
	var damage_to_deal = ammo_details.bullet_damage_multiplied
	
	if body is FracturableStaticBody2D and body is not BlockCore and q_b:
		q_b.fracture_quadrant_on_collision(pos, body, launch_velocity, damage_to_deal, ammo_details.bullet_speed)
		_schedule_destruction()
	elif body is BlockCore and q_b:
		q_b.fracture_block_core(damage_to_deal, "Player")
		_schedule_destruction()
	elif body is BaseEnemy:
		var force: Vector2 = (body.global_position - global_position).normalized() * ammo_details.fracture_force
		body.call_deferred("damage", ammo_details.fracture_damage, global_position, force, 0.25, modulate)
		_schedule_destruction()
	elif body is ShieldComponent:
		body.call_deferred("absorb_damage", ammo_details.fracture_damage.x, global_position)
		_schedule_destruction()
	elif body is PlayerController:
		body.damage(ammo_details.bullet_damage)
		_schedule_destruction()

func _schedule_destruction() -> void:
	call_deferred("destroy")

func set_velocity(vel: Vector2):
	launch_velocity = vel.length()

func spawn(pos : Vector2, launch_vector : Vector2, lifetime : float, quadrant_builder: QuadrantBuilder, ammo_data: AmmoDetails) -> void:
	self.ammo_details = ammo_data
	self.q_b = quadrant_builder
	
	setPolygon(PolygonLib.createCirclePolygon(ammo_data.size, 8))
	set_velocity(launch_vector)
	global_position = pos
	_timer.start(lifetime)
	set_bullet_trail(ammo_details.trail_length, ammo_details.trail_gradient)
	
	linear_velocity = launch_vector


func despawn(_ref: Node2D = null) -> void:
	global_rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	

	if is_instance_valid(trail):
		trail.disable_trail()

	# Delete if using the PoolFracturePool
	if not use_object_pool:
		queue_free()


func destroy() -> void:
	_timer.stop()

	if is_instance_valid(trail):
		trail.disable_trail()

	emit_signal("Despawn", self)


func setPolygon(polygon : PackedVector2Array) -> void:
	_poly.set_polygon(polygon)
	_col_poly.set_polygon(polygon)
	_collision_box_component_polygon.set_polygon(polygon)
	light_occluder_2d.occluder.polygon = polygon


func _on_Timer_timeout() -> void:
	destroy()


func _on_collision_detection_body_entered(_body: Node2D) -> void:
	call_deferred("destroy")


func set_bullet_trail(length: int, gradient: Gradient):
	trail.spawn(length, gradient, ammo_details.trail_width)
