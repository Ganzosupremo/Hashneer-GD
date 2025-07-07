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
@onready var bouncy_material: PhysicsMaterial = preload("res://Resources/WeaponResourcesUtils/FractureBulletPhysicsMaterial.tres")


var q_b: QuadrantBuilder = null
var launch_velocity : float = 0.0
var ammo_details: AmmoDetails
var bullet_type: AmmoDetails.BulletType = AmmoDetails.BulletType.NORMAL
var remaining_pierce: int = 0
var remaining_bounce: int = 0
var last_collision_body: Node2D = null


func _ready() -> void:
	# Delete if using the PoolFracturePool
	if not use_object_pool:
		Despawn.connect(despawn)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() <= 0: 
		last_collision_body = null
		return

	var body = state.get_contact_collider_object(0)
	if body == last_collision_body:
		return
	
	last_collision_body = body
	var hit_pos: Vector2 = state.get_contact_collider_position(0)
	_spawn_vfx_effect(hit_pos)
	_handle_collision(body, hit_pos)

func _spawn_vfx_effect(hit_pos: Vector2) -> void:
	var angle: float = linear_velocity.angle() + PI
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.SPARKS, Transform2D(angle, hit_pos), ammo_details.bullet_hit_vfx)

## Handles collision between a bullet and a target object
## @param body: The Node2D that was collided with
## @param pos: The Vector2 position of the collision
## 
## Applies appropriate damage behavior based on the type of object hit:
## - FracturableStaticBody2D: Fractures the quadrant at collision point
## - BlockCore: Fractures the block core
## - BaseEnemy: Applies damage with force and knockback
## - ShieldComponent: Makes the shield absorb damage
## - PlayerController: Damages the player
## After handling the collision type, processes the hit effect
func _handle_collision(body: Node2D, pos: Vector2) -> void:
	var damage_to_deal = ammo_details.damage_final

	if body is FracturableStaticBody2D and body is not BlockCore and q_b:
			q_b.fracture_quadrant_on_collision(pos, body, launch_velocity, damage_to_deal, ammo_details.bullet_speed)
	elif body is BlockCore and q_b:
			q_b.fracture_block_core(damage_to_deal, "Player")
	elif body is BaseEnemy:
			var force: Vector2 = (body.global_position - global_position).normalized() * ammo_details.fracture_force
			body.call_deferred("damage", Vector2(damage_to_deal, damage_to_deal), global_position, force, 0.25, modulate)
	elif body is ShieldComponent:
			body.call_deferred("absorb_damage", damage_to_deal, global_position)
	elif body is PlayerController:
			body.damage(damage_to_deal)
	# else:
	# 	_schedule_destruction()
	_process_hit(body)

## Processes what happens to the bullet after hitting something
## @param body: The Node2D that was hit
## @param body_pos: The Vector2 position of the hit
##
## Behavior depends on bullet type:
## - NORMAL/LASER/EXPLOSIVE: Destroys bullet immediately
## - PIERCING: Decrements remaining pierce count, destroys if depleted
## - BOUNCING: Decrements bounce count and reflects if possible, otherwise destroys
## - Other types: Destroys bullet
func _process_hit(body: Node2D) -> void:
	match bullet_type:
		AmmoDetails.BulletType.NORMAL, AmmoDetails.BulletType.LASER, AmmoDetails.BulletType.EXPLOSIVE:
			_schedule_destruction()
		AmmoDetails.BulletType.PIERCING:
			if remaining_pierce >= 0 and _can_pierce_through(body):
				remaining_pierce -= 1
			else:
				_schedule_destruction()
			
		AmmoDetails.BulletType.BOUNCING:
			if remaining_bounce >= 0 and _can_bounce_off(body):
				print_debug("FractureBullet: Bouncing off {0} from {1}, remaining bounces: {2}".format([_can_bounce_off(body), body.name, remaining_bounce]))
				remaining_bounce -= 1
			else:
				_schedule_destruction()
		_:
			_schedule_destruction()


func _can_bounce_off(body: Node2D) -> bool:
	if body is StaticBody2D or body is FracturableStaticBody2D:
		return true
	elif body is TileMapLayer:
		return true
	elif body is BlockCore: 
		return true
	return false

func _can_pierce_through(body: Node2D) -> bool:
	if body is StaticBody2D or body is FracturableStaticBody2D or body is BlockCore:
		return false
	elif body is TileMapLayer:
		return false
	elif body is ShieldComponent:
		return false
	elif body is BaseEnemy:
		return true
	elif body is PlayerController:
		return true
	return false

func _schedule_destruction() -> void:
	call_deferred("destroy")

func set_velocity(vel: Vector2):
	launch_velocity = vel.length()

func spawn(pos : Vector2, launch_vector : Vector2, lifetime : float, quadrant_builder: QuadrantBuilder, ammo_data: AmmoDetails) -> void:
	self.ammo_details = ammo_data
	self.q_b = quadrant_builder

	self.remaining_bounce = ammo_data.get_total_bounce()
	self.remaining_pierce = ammo_data.get_total_pierce()
	self.bullet_type = ammo_data.bullet_type

	setPolygon(PolygonLib.createCirclePolygon(ammo_data.size, 8))
	set_velocity(launch_vector)
	global_position = pos
	_timer.start(lifetime)
	set_bullet_trail(ammo_details.trail_length, ammo_details.trail_gradient)
	
	linear_velocity = launch_vector

func _set_physics_material() -> void:
	match bullet_type:
		AmmoDetails.BulletType.PIERCING:
			physics_material_override = null
		AmmoDetails.BulletType.BOUNCING:
			physics_material_override = bouncy_material
		_:
			physics_material_override = null

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

func set_bullet_trail(length: int, gradient: Gradient):
	trail.spawn(length, gradient, ammo_details.trail_width)
