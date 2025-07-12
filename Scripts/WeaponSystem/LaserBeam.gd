class_name LaserBeam extends Node2D

signal Despawn(ref: Node2D)

@export var use_object_pool: bool = true
@export var width: float = 16.0
@export var fade_in_duration: float = 0.2  # How long it takes for the laser to fully appear
@export var fade_out_duration: float = 0.15  # How long it takes for the laser to disappear

@onready var _timer: Timer = $Timer
@onready var _line: Line2D = $Line2D

var _ammo_details: AmmoDetails = null
var _quadrant_builder: QuadrantBuilder = null
var _direction: Vector2 = Vector2.ZERO
var _length: float = 300.0
var _launch_velocity: float = 0.0
var _hit_timestamps: Dictionary = {}
var _damage_cooldown: float = 0.1

# Tween related variables
var _progress_tween: Tween
var _is_fading_out: bool = false

func _ready() -> void:
	if _timer:
		_timer.timeout.connect(_on_timer_timeout)
	
	# Set initial progress to 0 (invisible)
	_set_shader_progress(0.0)

func spawn(pos: Vector2, origin_transform: Transform2D, launch_vector: Vector2, lifetime: float, quadrant_builder: QuadrantBuilder, ammo_data: AmmoDetails) -> void:
	_ammo_details = ammo_data
	_damage_cooldown = ammo_data.laser_damage_cooldown
	_quadrant_builder = quadrant_builder
	_direction = launch_vector.normalized()
	_launch_velocity = launch_vector.length()
	_length = ammo_data.laser_length
	_line.width = width
	global_transform = origin_transform
	global_position = pos
	rotation = _direction.angle()
	_timer.start(lifetime)
	update_beam(pos, launch_vector)
	
	# Start fade-in animation
	_start_fade_in()

func destroy() -> void:
	if !_is_fading_out:
		_start_fade_out()
	else:
		_finish_destroy()

func _finish_destroy() -> void:
	if _progress_tween:
		_progress_tween.kill()
	_timer.stop()
	Despawn.emit(self)
	queue_free()

func update_beam(origin: Vector2, launch_vector: Vector2 = _direction) -> void:
	global_position = origin
	_direction = launch_vector.normalized()
	rotation = _direction.angle()
	var end_pos: Vector2 = global_position + _direction * _length

	# Ensure laser is at full progress when actively updating (firing)
	if !_is_fading_out and get_progress() < 1.0:
		_set_shader_progress(1.0)

	var params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	params.from = global_position
	params.to = end_pos
	params.collision_mask = _ammo_details.laser_collision_mask
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.exclude = [self]

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var results: Dictionary = space_state.intersect_ray(params)
	_line.clear_points()
	_line.add_point(Vector2.ZERO)
	
	
	if results.is_empty(): return
	
	var collider = results.collider
	if collider is Node2D:
		var hit_pos: Vector2 = results.position
		_line.add_point(to_local(hit_pos))
		_apply_damage(collider, hit_pos)
		_spawn_vfx_effect(hit_pos)

func _apply_damage(body: Node2D, hit_pos: Vector2) -> void:
	var now: float = Time.get_ticks_msec()
	var last: float = _hit_timestamps.get(body, 0.0)
	if now - last < _damage_cooldown * 1000.0:
		return
	
	var damage_to_deal = _ammo_details.damage_final
	
	if body is FracturableStaticBody2D and body is not BlockCore and _quadrant_builder:
		_quadrant_builder.call_deferred("fracture_quadrant_on_collision", hit_pos, body, _launch_velocity, damage_to_deal, _ammo_details.bullet_speed)
	elif body is BlockCore and _quadrant_builder:
		_quadrant_builder.call_deferred("fracture_block_core", damage_to_deal, "Player")
	elif body is BaseEnemy:
		var force: Vector2 = (body.global_position - global_position).normalized() * _ammo_details.fracture_force
		body.call_deferred("damage", Vector2(damage_to_deal, damage_to_deal) * 0.25, hit_pos, force, 0.25, modulate)
	elif body is ShieldComponent:
		body.call_deferred("absorb_damage", damage_to_deal, hit_pos)
	elif body is PlayerController:
		body.damage(damage_to_deal)

func _spawn_vfx_effect(hit_pos: Vector2) -> void:
	# Calculate the direction the laser is traveling (from laser origin to hit point)
	var hit_direction = (hit_pos - global_position).normalized()
	var hit_angle = hit_direction.angle() + PI
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.LASER_BEAM, Transform2D(hit_angle, hit_pos), _ammo_details.bullet_hit_vfx)
	AudioManager.create_2d_audio_at_location(hit_pos, SoundEffectDetails.SoundEffectType.QUADRANT_CORE_DESTROYED, SoundEffectDetails.DestinationAudioBus.WEAPONS)

func _on_timer_timeout() -> void:
	destroy()

func _start_fade_in() -> void:
	_is_fading_out = false
	if _progress_tween:
		_progress_tween.kill()
	
	_progress_tween = create_tween()
	_progress_tween.tween_method(_set_shader_progress, 0.0, 1.0, fade_in_duration)

func _start_fade_out() -> void:
	_is_fading_out = true
	if _progress_tween:
		_progress_tween.kill()
	
	_progress_tween = create_tween()
	_progress_tween.tween_method(_set_shader_progress, 1.0, 0.0, fade_out_duration)
	_progress_tween.tween_callback(_finish_destroy)

func _set_shader_progress(progress: float) -> void:
	if _line and _line.material and _line.material is ShaderMaterial:
		var shader_material = _line.material as ShaderMaterial
		shader_material.set_shader_parameter("progress", progress)

## Manually set the laser progress (useful for testing or external control).[br]
## [param progress]: A float value between 0.0 (invisible) and 1.0 (fully visible).
func set_progress(progress: float) -> void:
	_set_shader_progress(progress)

## Get the current laser progress value.[br]
## Returns a float between 0.0 (invisible) and 1.0 (fully visible)
## This is useful for testing or external control of the laser beam's visibility
func get_progress() -> float:
	if _line and _line.material and _line.material is ShaderMaterial:
		var shader_material = _line.material as ShaderMaterial
		return shader_material.get_shader_parameter("progress")
	return 0.0
