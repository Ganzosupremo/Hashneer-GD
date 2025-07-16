extends Node2D
class_name VFXManager

# Enumerates the effects that can be spawned by this manager
enum EffectType { 
	EXPLOSION, 
	DEBRIS, 
	SPARKS, 
	SCREEN_FLASH,
	WEAPON_FIRE,
	PLAYER_HIT,
	ENEMY_HIT,
	ENEMY_DEATH,
	PLAYER_DEATH,
	BLANK_EFFECT, # Used for placeholder effects or no effect
	LASER_BEAM, # Specific to laser beam effects
	}

@export var _explosion_effect: PackedScene = preload("res://Scenes/VFX/ExplosionHitEffect.tscn")
@export var _debris_effect: PackedScene = preload("res://Scenes/VFX/DebrisEffect.tscn")
@export var _sparks_effect: PackedScene = preload("res://Scenes/VFX/SparksEffect.tscn")
@export var _screen_flash_scene: PackedScene = preload("res://Scenes/VFX/ScreenFlash.tscn")
@export var _weapon_fire_effect: PackedScene = preload("res://Scenes/VFX/WeaponFireEffect.tscn")
@export var _hit_effect: PackedScene = preload("res://Scenes/VFX/HitEffect.tscn")
@export var _death_effect: PackedScene = preload("res://Scenes/VFX/DeathEffect.tscn")
@export var _blank_effect: PackedScene = preload("res://Scenes/VFX/BlankEffect.tscn")
@export var _laser_beam_hit_effect: PackedScene = preload("res://Scenes/VFX/LaserBeamHit.tscn")


var active_effects: Array[Node] = []

func _register_effect(effect: Node, lifetime: float) -> void:
	active_effects.append(effect)
	var timer: Timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(Callable(self, "_on_effect_timeout").bind(effect, timer))

func _on_effect_timeout(effect: Node, timer: Timer) -> void:
	active_effects.erase(effect)
	if is_instance_valid(effect):
		effect.queue_free()
	timer.queue_free()


func _spawn_particles(scene: PackedScene, transform_effect: Transform2D, params: VFXEffectProperties) -> Node2D:
	var effect = scene.instantiate() as VFXEffect
	add_child(effect)
	effect.transform = transform_effect
	if effect is VFXEffect:
		effect.set_effect_properties(params)
		effect.start_effect()
	_register_effect(effect, effect.lifetime)

	return effect

# Entry point for spawning effects based on an effect type
func spawn_effect(effect_type: EffectType, 
	transform_effect: Transform2D = Transform2D.IDENTITY, 
	props: VFXEffectProperties = null, duration: float = 0.1, color: Color = Color(1,1,1,0.8), ) -> Node:
	
	match effect_type:
		EffectType.EXPLOSION:
			return _spawn_explosion(transform_effect, props)
		EffectType.DEBRIS:
			return _spawn_debris(transform_effect, props)
		EffectType.SPARKS:
			return _spawn_sparks(transform_effect, props)
		EffectType.SCREEN_FLASH:
			return _spawn_screen_flash(duration, color)
		EffectType.WEAPON_FIRE:
			return _spawn_weapon_fire(transform_effect, props)
		EffectType.PLAYER_HIT, EffectType.ENEMY_HIT:
			return _spawn_hit(transform_effect, props)
		EffectType.ENEMY_DEATH, EffectType.PLAYER_DEATH:
			return _spawn_death(transform_effect, props)
		EffectType.LASER_BEAM:
			return _spawn_laser_beam_hit(transform_effect, props)
		EffectType.BLANK_EFFECT:
			return _spawn_particles(_blank_effect, transform_effect, props)
	return null

func _spawn_explosion(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(_explosion_effect, transform_effect, props)

func _spawn_debris(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(_debris_effect, transform_effect, props)

func _spawn_sparks(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(_sparks_effect, transform_effect, props)

func _spawn_weapon_fire(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(_weapon_fire_effect, transform_effect, props)

func _spawn_hit(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(_hit_effect, transform_effect, props)

func _spawn_death(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(_death_effect, transform_effect, props)

func _spawn_screen_flash(duration: float = 0.1, color: Color = Color(1,1,1,0.8)) -> Node:
	var flash: ScreenFlash = _screen_flash_scene.instantiate()
	add_child(flash)
	flash.start_flash(duration, color)
	_register_effect(flash, duration)
	return flash

func _spawn_laser_beam_hit(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	var laser_hit_effect: LaserBeamHitEffect = _laser_beam_hit_effect.instantiate()
	add_child(laser_hit_effect)
	
	# Set only position, avoid inheriting rotation from parent transforms
	laser_hit_effect.global_position = transform_effect.get_origin()
	laser_hit_effect.rotation = 0.0  # Reset rotation to avoid player movement influence
	
	# Calculate the direction sparks should fly (opposite to laser direction)
	# Add 180 degrees to make sparks fly away from the impact point
	var laser_angle_degrees = rad_to_deg(transform_effect.get_rotation()) + 180.0
	
	laser_hit_effect.set_hit_direction(laser_angle_degrees)
	
	# Use properties for customization if provided
	if props:
		laser_hit_effect.set_effect_colors(props.get_color(), Color.WHITE)
		laser_hit_effect.set_effect_properties(props)

	# Play the effect
	laser_hit_effect.play_effect()
	
	# Register for cleanup
	_register_effect(laser_hit_effect, 1.0)  # Max lifetime of the effect
	
	return laser_hit_effect

## Smoothly tween into and out of slow-motion.[br]
## [param duration]: How long to maintain the slowed time scale.[br]
## [param target_scale]: The slow-motion time scale (e.g., 0.5).[br]
## [param ramp_time]: Time to ramp down/up into/from slow-motion.
func slow_time(duration: float, target_scale: float = 0.5, ramp_time: float = 0.1) -> void:
	# Ramp down to slow motion
	var tween: Tween = create_tween()
	tween.tween_property(Engine, "time_scale", target_scale, ramp_time)
	# Hold slow-motion for duration
	tween.tween_interval(duration)
	# Ramp back to normal time
	tween.tween_property(Engine, "time_scale", 1.0, ramp_time)
