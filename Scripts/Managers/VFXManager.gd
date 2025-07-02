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
	}

@export var explosion_effect: PackedScene = preload("res://Scenes/VFX/ExplosionHitEffect.tscn")
@export var debris_effect: PackedScene = preload("res://Scenes/VFX/DebrisEffect.tscn")
@export var sparks_effect: PackedScene = preload("res://Scenes/VFX/SparksEffect.tscn")
@export var screen_flash_scene: PackedScene = preload("res://Scenes/VFX/ScreenFlash.tscn")
@export var weapon_fire_effect: PackedScene = preload("res://Scenes/VFX/WeaponFireEffect.tscn")
@export var hit_effect: PackedScene = preload("res://Scenes/VFX/HitEffect.tscn")
@export var death_effect: PackedScene = preload("res://Scenes/VFX/DeathEffect.tscn")


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
	var effect = scene.instantiate()
	add_child(effect)
	effect.transform = transform_effect
	if effect is GPUParticles2D:
		_set_effects_properties(effect, params)
		effect.restart()
	_register_effect(effect, effect.lifetime)

	return effect

func _set_effects_properties(effect: GPUParticles2D, props: VFXEffectProperties = VFXEffectProperties.new()) -> void:
	if !is_instance_valid(effect) or props == null:
		return
	for params_key in props.get_property_list():
		effect.set(params_key.name, props.get(params_key.name))

# Entry point for spawning effects based on an effect type
func spawn_effect(effect_type: EffectType, 
	transform_effect: Transform2D = Transform2D.IDENTITY, 
	duration: float = 0.1, color: Color = Color(1,1,1,0.8), props: VFXEffectProperties = VFXEffectProperties.new()) -> Node2D:
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
	return null

func _spawn_explosion(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(explosion_effect, transform_effect, props)

func _spawn_debris(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(debris_effect, transform_effect, props)

func _spawn_sparks(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(sparks_effect, transform_effect, props)

func _spawn_weapon_fire(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(weapon_fire_effect, transform_effect, props)

func _spawn_hit(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(hit_effect, transform_effect, props)

func _spawn_death(transform_effect: Transform2D, props: VFXEffectProperties) -> Node2D:
	return _spawn_particles(death_effect, transform_effect, props)

func _spawn_screen_flash(duration: float = 0.1, color: Color = Color(1,1,1,0.8)):
	var flash: ScreenFlash = screen_flash_scene.instantiate()
	add_child(flash)
	flash.start_flash(duration, color)
	_register_effect(flash, duration)
	return flash
