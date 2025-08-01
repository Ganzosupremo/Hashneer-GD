class_name LaserBeamRect extends Node2D

signal Despawn(ref: Node2D)

@export var use_object_pool: bool = true
@export var width: float = 16.0

@onready var _timer: Timer = $Timer
@onready var _laser_rect: TextureRect = $LaserRect

var _ammo_details: AmmoDetails = null
var _quadrant_builder: QuadrantBuilder = null
var _direction: Vector2 = Vector2.ZERO
var _length: float = 300.0
var _launch_velocity: float = 0.0
var _hit_timestamps: Dictionary = {}
var _damage_cooldown: float = 0.1

func _ready() -> void:
	if _timer:
		_timer.timeout.connect(_on_timer_timeout)

func spawn(pos: Vector2, origin_transform: Transform2D, launch_vector: Vector2, lifetime: float, quadrant_builder: QuadrantBuilder, ammo_data: AmmoDetails) -> void:
	_ammo_details = ammo_data
	_damage_cooldown = ammo_data.laser_damage_cooldown
	_quadrant_builder = quadrant_builder
	_direction = launch_vector.normalized()
	_launch_velocity = launch_vector.length()
	_length = ammo_data.laser_length
	global_transform = origin_transform
	global_position = pos
	rotation = _direction.angle()
	_timer.start(lifetime)
	update_beam(pos, launch_vector)

func destroy() -> void:
	_timer.stop()
	Despawn.emit(self)
	queue_free()

func update_beam(origin: Vector2, launch_vector: Vector2 = _direction) -> void:
	global_position = origin
	_direction = launch_vector.normalized()
	rotation = _direction.angle()
	var end_pos: Vector2 = global_position + _direction * _length

	# Physics raycast for collision detection
	var params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	params.from = global_position
	params.to = end_pos
	params.collision_mask = _ammo_details.laser_collision_mask
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.exclude = [self]

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var results: Dictionary = space_state.intersect_ray(params)
	
	# Calculate actual beam length based on collision
	var actual_length = _length
	if not results.is_empty():
		var hit_pos: Vector2 = results.position
		actual_length = global_position.distance_to(hit_pos)
		
		# Apply damage to hit target
		var collider = results.collider
		if collider is Node2D:
			_apply_damage(collider, hit_pos)
			_spawn_vfx_effect(hit_pos)
	
	# Update TextureRect size and shader parameters
	if _laser_rect:
		_laser_rect.size.x = actual_length
		_laser_rect.size.y = width
		_laser_rect.position.y = -width * 0.5
		
		# Update shader beam_length parameter for smooth cutoff
		if _laser_rect.material and _laser_rect.material is ShaderMaterial:
			var shader_material = _laser_rect.material as ShaderMaterial
			shader_material.set_shader_parameter("beam_length", actual_length / _length)

func _apply_damage(body: Node2D, pos: Vector2) -> void:
	var now: float = Time.get_ticks_msec()
	var last: float = _hit_timestamps.get(body, 0.0)
	if now - last < _damage_cooldown * 1000.0:
		return
	
	var damage_to_deal = _ammo_details.damage_final
	
	if body is FracturableStaticBody2D and body is not BlockCore and _quadrant_builder:
		_quadrant_builder.call_deferred("fracture_quadrant_on_collision", pos, body, _launch_velocity, damage_to_deal, _ammo_details.bullet_speed)
	elif body is BlockCore and _quadrant_builder:
		_quadrant_builder.call_deferred("fracture_block_core", damage_to_deal, "Player")
	elif body is BaseEnemy:
		var force: Vector2 = (body.global_position - global_position).normalized() * _ammo_details.fracture_force
		body.call_deferred("damage", Vector2(damage_to_deal, damage_to_deal) * 0.5, global_position, force, 0.25, modulate)
	elif body is ShieldComponent:
		body.call_deferred("absorb_damage", damage_to_deal, global_position)
		# Note: Rect lasers continue through shields but deal reduced damage
	elif body is PlayerController:
		body.damage(damage_to_deal)

func _spawn_vfx_effect(hit_pos: Vector2) -> void:
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.SPARKS, Transform2D(rotation, hit_pos), _ammo_details.bullet_hit_vfx)
	AudioManager.create_2d_audio_at_location(hit_pos, SoundEffectDetails.SoundEffectType.QUADRANT_CORE_DESTROYED, AudioManager.DestinationAudioBus.WEAPONS)

func _on_timer_timeout() -> void:
	destroy()
