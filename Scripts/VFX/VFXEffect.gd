class_name VFXEffect extends GPUParticles2D


func start_effect() -> void:
	emitting = true

func set_effect_properties(props: VFXEffectProperties) -> void:
	if props == null:
		return
	
	amount = props.amount
	lifetime = props.lifetime
	one_shot = props.one_shot
	speed_scale = props.speed_scale
	explosiveness = props.explosiveness
	randomness = props.randomness
	texture = props.particle_texture
	process_material = props.process_material
