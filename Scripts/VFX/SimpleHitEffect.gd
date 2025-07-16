class_name SimpleHitEffect extends Node2D
## Simple laser hit effect that can be spawned directly. Alternative to using the VFXManager system
##
## Simple laser hit effect that can be spawned directly
## Alternative to using the VFXManager system


@export var laser_hit_scene: PackedScene = preload("res://Scenes/VFX/LaserBeamHit.tscn")

## Spawns a laser hit effect at the specified position and angle
static func spawn_at(parent: Node, spawn_position: Vector2, angle_radians: float = 0.0, intensity: float = 1.0) -> Node2D:
	var scene = preload("res://Scenes/VFX/LaserBeamHit.tscn")
	var effect: Node2D = scene.instantiate()
	parent.add_child(effect)
	effect.global_position = spawn_position
	
	# Set direction based on angle
	var angle_degrees = rad_to_deg(angle_radians)
	if effect.has_method("set_hit_direction"):
		effect.set_hit_direction(angle_degrees)
	
	# Play with intensity
	if effect.has_method("play_effect_with_intensity"):
		effect.play_effect_with_intensity(intensity)
	elif effect.has_method("play_effect"):
		effect.play_effect()
	
	# Auto-cleanup after effect finishes
	var cleanup_timer = Timer.new()
	effect.add_child(cleanup_timer)
	cleanup_timer.wait_time = 1.5  # Max effect duration
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): effect.queue_free())
	cleanup_timer.start()
	
	return effect

## Instance method version for easier use
func spawn_effect_at(spawn_position: Vector2, angle_radians: float = 0.0, intensity: float = 1.0) -> Node2D:
	return SimpleHitEffect.spawn_at(get_parent(), spawn_position, angle_radians, intensity)
