class_name LaserBeamHitEffect extends Node2D

@onready var sparks: GPUParticles2D = $Sparks
@onready var flash: GPUParticles2D = $Flash
@onready var glow: GPUParticles2D = $Glow

## Plays the complete laser hit effect
func play_effect() -> void:
	if sparks:
		sparks.restart()
		sparks.emitting = true
	
	if flash:
		flash.restart()
		flash.emitting = true
	
	if glow:
		glow.restart()
		glow.emitting = true

## Plays the effect with custom intensity (0.0 to 2.0)
func play_effect_with_intensity(intensity: float = 1.0) -> void:
	intensity = clamp(intensity, 0.1, 2.0)
	
	if sparks:
		sparks.amount = int(30 * intensity)
		sparks.restart()
		sparks.emitting = true
	
	if flash:
		flash.amount = int(3 * intensity)
		var flash_material: ParticleProcessMaterial = flash.process_material
		if flash_material:
			flash_material.scale_min = 3.5 * intensity
			flash_material.scale_max = 5.5 * intensity
		flash.restart()
		flash.emitting = true
	
	if glow:
		var glow_material: ParticleProcessMaterial = glow.process_material
		if glow_material:
			glow_material.scale_min = 6. * intensity
			glow_material.scale_max = 8.0 * intensity
		glow.restart()
		glow.emitting = true

## Sets the hit direction for sparks (in degrees, 0 = right, 90 = down)
func set_hit_direction(angle_degrees: float) -> void:
	if sparks and sparks.process_material:
		var spark_material: ParticleProcessMaterial = sparks.process_material
		if spark_material:
			# Convert angle to direction vector
			var rad = deg_to_rad(angle_degrees)
			spark_material.direction = Vector3(cos(rad), sin(rad), 0)

## Sets custom colors for the effect
func set_effect_colors(primary_color: Color, secondary_color: Color = Color.WHITE) -> void:
	if sparks and sparks.process_material:
		var spark_material = sparks.process_material as ParticleProcessMaterial
		if spark_material:
			spark_material.color = primary_color
	
	if flash and flash.process_material:
		var flash_material = flash.process_material as ParticleProcessMaterial
		if flash_material:
			flash_material.color = secondary_color

## Returns true if any particles are still emitting
func is_playing() -> bool:
	var sparks_playing: bool = sparks and sparks.emitting
	var flash_playing: bool = flash and flash.emitting  
	var glow_playing: bool = glow and glow.emitting
	return sparks_playing or flash_playing or glow_playing

## Stops all particle emission immediately
func stop_effect() -> void:
	if sparks:
		sparks.emitting = false
	if flash:
		flash.emitting = false
	if glow:
		glow.emitting = false
