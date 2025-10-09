## A physics-based projectile that can fracture objects and damage entities in the game world.
## 
## [FractureBullet] implements a dynamic projectile that interacts with various game objects
## like enemies, fracture-enabled terrain, shields, and players. It supports different bullet types
## with unique behaviors such as normal, piercing, bouncing, laser, and explosive variants.[br]
##
## The bullet handles its own collision detection, damage application, and visual effects.
## It works in conjunction with the [QuadrantBuilder] system to fracture terrain on impact.
@icon("res://Icons/FractureBulletIcon.svg")
class_name FractureBullet extends RigidBody2D


signal Despawn(ref)

## If [code]true[/code], the bullet will be managed by an object pool for reuse, otherwise it will be deleted after use.
@export var use_object_pool: bool = false
## The radius of the bullet, used for collision detection and visual representation.
@export var radius: float = 50.0
## The speed of the bullet, used to determine how fast it moves through the game world.
@export var speed: float = 300.0

@onready var _poly := $Polygon2D
@onready var _col_poly := $CollisionPolygon2D
@onready var _timer := %Timer
@onready var _collision_box_component_polygon: CollisionPolygon2D = %CollisionBoxComponentPolygon
## The bullet trail component that visually represents the bullet's path.
## It is used to create a visual effect that follows the bullet's movement.
## The trail can be customized with different lengths and gradients to match the bullet's appearance.
@onready var trail: BulletTrailComponent = %BulletTrail
@onready var _light_occluder_2d: LightOccluder2D = $LightOccluder2D
@onready var _bouncy_material: PhysicsMaterial = preload("res://Resources/WeaponResourcesUtils/FractureBulletPhysicsMaterial.tres")


var _quadrant_builder: QuadrantBuilder = null
var _launch_velocity : float = 0.0
var _ammo_details: AmmoDetails
var _bullet_type: AmmoDetails.BulletType = AmmoDetails.BulletType.NORMAL
var _remaining_pierce: int = 0
var _remaining_bounce: int = 0
var _last_collision_body: Node2D = null
var _prev_linear_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Delete if using the PoolFracturePool
	if not use_object_pool:
		Despawn.connect(despawn)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var prev_vel: Vector2 = linear_velocity
	if state.get_contact_count() <= 0: 
		_last_collision_body = null
		_prev_linear_velocity = prev_vel
		return

	var body = state.get_contact_collider_object(0)
	if body == _last_collision_body:
		return
	
	_last_collision_body = body
	var hit_pos: Vector2 = state.get_contact_collider_position(0)
	_spawn_vfx_effect(hit_pos)
	_handle_collision(body, hit_pos)
	_prev_linear_velocity = linear_velocity

## Initializes and spawns a bullet with the given properties.
## [br]
## [param pos] The initial world position where the bullet spawns.[br]
## [param launch_vector] The direction and speed of the bullet.[br]
## [param lifetime] How long the bullet exists before auto-destruction (in seconds).[br]
## [param q_b] Reference to the quadrant system for terrain interaction, see [QuadrantBuilder].[br]
## [param ammo_data] Contains bullet specifications like size, type, bounce/pierce counts, see [AmmoDetails].[br]
##[br]
## This method configures the bullet with properties from ammo_data, sets up its
## physics, appearance, and trail effects, then launches it in the specified direction.
func spawn(pos : Vector2, launch_vector : Vector2, lifetime : float, q_b: QuadrantBuilder, ammo_data: AmmoDetails) -> void:
	self._ammo_details = ammo_data
	self._quadrant_builder = q_b

	self._remaining_bounce = ammo_data.get_total_bounce()
	self._remaining_pierce = ammo_data.get_total_pierce()
	self._bullet_type = ammo_data.bullet_type

	setPolygon(PolygonLib.createCirclePolygon(ammo_data.size, 8))
	set_velocity(launch_vector)
	global_position = pos
	_timer.start(lifetime)
	set_bullet_trail(_ammo_details.trail_length, _ammo_details.trail_gradient)
	
	linear_velocity = launch_vector

## Resets the bullet's state and prepares it for despawning.[br]
## This method clears the bullet's rotation, velocity, and angular velocity,
## disables the bullet trail if it exists, and queues the bullet for deletion
## unless it is managed by an object pool.[br]
## [param _ref] Optional reference to a Node2D, defaults to null.[br]
## This method is typically called when the bullet is no longer needed,
## such as after it has collided with an object or after its lifetime has expired.
## It ensures that the bullet's state is reset and that it can be safely removed from the game world.[br]
## If using an object pool, it will not queue the bullet for deletion, allowing the pool to manage its lifecycle instead.
## If not using an object pool, it will call [code]queue_free()[/code] to remove the bullet from the scene tree.
##[br]
## Note: This method is connected to the [signal FractureBullet.Despawn] signal, which can be emitted
## to trigger the despawning process from other parts of the code.
##
## Example usage:
## [codeblock]
## var bullet: FractureBullet = FractureBullet.new()
## bullet.spawn(Vector2(100, 100), Vector2(1, 0), 5.0, _quadrant_builder, _ammo_details)
## # Later in the code, when the bullet should be removed:
## bullet.despawn()
## [/codeblock]
func despawn(_ref: Node2D = null) -> void:
	global_rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	

	if is_instance_valid(trail):
		trail.disable_trail()

	# Delete if using the PoolFracturePool
	if not use_object_pool:
		queue_free()

## Sets the launch velocity magnitude based on a 2D vector input.[br]
## Parameters:[br]
## - [param vel]: The velocity vector from which to extract the magnitude.[br]
## Note: This only stores the magnitude (length) of the vector, not its direction.
func set_velocity(vel: Vector2):
	_launch_velocity = vel.length()

## Destroys the bullet and emits the [signal FractureBullet.Despawn] signal.[br]
## This method stops the timer, disables the bullet trail if it exists,
## and emits the Despawn signal to notify any listeners that the bullet is being removed.[br]
func destroy() -> void:
	_timer.stop()

	if is_instance_valid(trail):
		trail.disable_trail()

	Despawn.emit(self)

## Sets the bullet trail properties for the bullet.[br]
## Parameters:[br]
## - [param length] The length of the bullet trail in pixels.[br]
## - [param gradient] The gradient used for the bullet trail's color and appearance.[br]
## This method initializes the bullet trail component with the specified length and gradient,
## and sets the trail width based on the ammo details.[br]
## It is typically called when the bullet is spawned to create a visual trail effect
## that follows the bullet's path.[br]
func set_bullet_trail(length: int, gradient: Gradient):
	trail.spawn(length, gradient, _ammo_details.trail_width)

## Sets the polygon shape for the bullet's collision and visual representation.[br]
## [param polygon] A PackedVector2Array defining the polygon shape to use for the bullet.[br]
## This method updates the [Polygon2D], [CollisionPolygon2D], and [CollisionBoxComponent]
## to use the specified polygon shape. It also updates the [LightOccluder2D] to match the polygon,
## allowing the bullet to cast shadows and occlude light based on its shape.[br]
## This is useful for creating custom-shaped bullets or adjusting the bullet's collision area
## to match the desired gameplay mechanics.[br]
## Example usage:
## [codeblock]
## var bullet: FractureBullet = FractureBullet.new()
## var polygon_shape: PackedVector2Array = PolygonLib.createCirclePolygon(50, 8)
## bullet.setPolygon(polygon_shape)
## [/codeblock]
##
func setPolygon(polygon : PackedVector2Array) -> void:
	_poly.set_polygon(polygon)
	_col_poly.set_polygon(polygon)
	_collision_box_component_polygon.set_polygon(polygon)
	_light_occluder_2d.occluder.polygon = polygon

func _spawn_vfx_effect(hit_pos: Vector2) -> void:
	var angle: float = linear_velocity.angle() + PI
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.SPARKS, Transform2D(angle, hit_pos), _ammo_details.bullet_hit_vfx)

# Handles collision between a bullet and a target object
# @param body: The Node2D that was collided with
# @param pos: The Vector2 position of the collision
# 
# Applies appropriate damage behavior based on the type of object hit:
# - FracturableStaticBody2D: Fractures the quadrant at collision point
# - BlockCore: Fractures the block core
# - BaseEnemy: Applies damage with force and knockback
# - ShieldComponent: Makes the shield absorb damage
# - PlayerController: Damages the player
# After handling the collision type, processes the hit effect
func _handle_collision(body: Node2D, pos: Vector2) -> void:
	_deal_damage(body, pos)
	_process_hit(body)

func _deal_damage(body: Node2D, pos: Vector2) -> void:
	var damage_to_deal = _ammo_details.damage_final

	if body is FracturableStaticBody2D and body is not BlockCore and _quadrant_builder:
			_quadrant_builder.fracture_quadrant_on_collision(pos, body, _launch_velocity, damage_to_deal, _ammo_details.bullet_speed)
	elif body is BlockCore and _quadrant_builder:
			_quadrant_builder.fracture_block_core(damage_to_deal, "Player")
	elif body is BaseEnemy:
			var force: Vector2 = (body.global_position - global_position).normalized() * _ammo_details.fracture_force
			body.call_deferred("damage", Vector2(damage_to_deal, damage_to_deal) * 0.5, global_position, force, 0.25, Color.MISTY_ROSE)
	elif body is PlayerController:
		body.damage(damage_to_deal, (body.global_position - global_position).normalized(), true, 0.25, 0.15)
			# Trigger camera shake and slow-motion effects on player hit
		GameManager.player_camera.shake_with_preset(Constants.ShakeMagnitude.Large)
		# Slow down time briefly when player is hit by enemy bullet
		# GameManager.vfx_manager.slow_time(0.25, 0.35, 0.15)

# Processes what happens to the bullet after hitting something
# [param body]: The Node2D that was hit.
# [param body_pos]: The Vector2 position of the hit.[br]
#
# Behavior depends on bullet type see [AmmoDetails.BulletType]:
# - NORMAL/LASER/EXPLOSIVE: Destroys bullet immediately.[br]
# - PIERCING: Decrements remaining pierce count, destroys if depleted.[br]
# - BOUNCING: Decrements bounce count and reflects if possible, otherwise destroys.[br]
# - Other types: Destroys bullet
func _process_hit(body: Node2D) -> void:
	match _bullet_type:
		AmmoDetails.BulletType.NORMAL, AmmoDetails.BulletType.LASER:
			_schedule_destruction()
		AmmoDetails.BulletType.EXPLOSIVE:
			_explode()
		AmmoDetails.BulletType.PIERCING:
			if _remaining_pierce > 0 and _can_pierce_through(body):
				_remaining_pierce -= 1
				linear_velocity = _prev_linear_velocity
			else:
				_schedule_destruction()
		AmmoDetails.BulletType.BOUNCING:
			if _remaining_bounce > 0 and _can_bounce_off(body):
				_remaining_bounce -= 1
			else:
				_schedule_destruction()
		_:
			_schedule_destruction()

#region Helpers

func _explode() -> void:
	if !_can_explode():
		# Create a failed explosion visual and sound effect here
		GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.BLANK_EFFECT, global_transform, _ammo_details.failed_explosion_vfx)
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectDetails.SoundEffectType.QUADRANT_CORE_DESTROYED, AudioManager.DestinationAudioBus.SFX)
		# If it can't explode, just destroy the bullet
		_schedule_destruction()
		return

	# Spawn explosion VFX at the bullet position
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.EXPLOSION, global_transform)
	# Play explosion sound using a generic sound effect, change to a explosion sound when available
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectDetails.SoundEffectType.QUADRANT_CORE_DESTROYED, AudioManager.DestinationAudioBus.SFX)

	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = _ammo_details.explosion_radius

	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0, global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.collision_mask = _ammo_details.explosion_layer_mask
	params.exclude = [self.get_rid()] # Exclude self from the query

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var results: Array = space_state.intersect_shape(params, 32)
	for result in results:
		var body = result.collider
		if body is Node2D:
			_deal_damage(body, global_position)
	_schedule_destruction()


func _can_explode() -> bool:
	# 90% chance to explode
	if randf() < 0.1:
		return false
	if _ammo_details.explosion_radius <= 0.0:
		return false
	if _bullet_type != AmmoDetails.BulletType.EXPLOSIVE:
		return false
	return true

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

func _set_physics_material() -> void:
	match _bullet_type:
		AmmoDetails.BulletType.PIERCING:
			physics_material_override = null
		AmmoDetails.BulletType.BOUNCING:
			physics_material_override = _bouncy_material
		_:
			physics_material_override = null

func _on_Timer_timeout() -> void:
	destroy()

#endregion
