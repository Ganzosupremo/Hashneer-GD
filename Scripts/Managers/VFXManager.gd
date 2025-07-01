extends Node2D
class_name VFXManager

# Enumerates the effects that can be spawned by this manager
enum EffectType { EXPLOSION, DEBRIS, SPARKS, SCREEN_FLASH }

@export var explosion_effect: PackedScene = preload("res://Scenes/VFX/Explosion_hit_effect.tscn")
@export var debris_effect: PackedScene = preload("res://Scenes/VFX/DebrisEffect.tscn")
@export var sparks_effect: PackedScene = preload("res://Scenes/VFX/SparksEffect.tscn")
@export var screen_flash_scene: PackedScene = preload("res://Scenes/VFX/ScreenFlash.tscn")

func spawn_particles(scene: PackedScene, transform_effect: Transform2D) -> Node2D:
    var effect = scene.instantiate()
    add_child(effect)
    effect.transform = transform_effect
    if effect is GPUParticles2D:
        effect.restart()
    return effect

# Entry point for spawning effects based on an effect type
func spawn_effect(effect_type: EffectType, transform_effect: Transform2D = Transform2D.IDENTITY, duration: float = 0.1, color: Color = Color(1,1,1,0.8)):
    match effect_type:
        EffectType.EXPLOSION:
            return _spawn_explosion(transform_effect)
        EffectType.DEBRIS:
            return _spawn_debris(transform_effect)
        EffectType.SPARKS:
            return _spawn_sparks(transform_effect)
        EffectType.SCREEN_FLASH:
            return _spawn_screen_flash(duration, color)
    return null

func _spawn_explosion(transform_effect: Transform2D):
    return spawn_particles(explosion_effect, transform_effect)

func _spawn_debris(transform_effect: Transform2D):
    return spawn_particles(debris_effect, transform_effect)

func _spawn_sparks(transform_effect: Transform2D):
    return spawn_particles(sparks_effect, transform_effect)

func _spawn_screen_flash(duration: float = 0.1, color: Color = Color(1,1,1,0.8)):
    var flash: ScreenFlash = screen_flash_scene.instantiate()
    add_child(flash)
    flash.start_flash(duration, color)
    return flash

