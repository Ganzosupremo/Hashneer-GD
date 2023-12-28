extends GPUParticles2D
class_name BulletParticles

signal finished()

func init_particles(data: ParticleEffectDetails):
	self.lifetime = data.lifetime
	self.amount = data.amount
	self.one_shot = data.one_shot
	self.speed_scale = data.speed_scale
	self.explosiveness = data.explosiveness
	self.randomness = data.randomness
	self.texture = data.particle_texture
	self.process_material = data.process_material

func start_particles():
	
	var timer = get_tree().create_timer(lifetime)
	emitting = true
	
	if timer.timeout:
		emit_signal("finished")

"""
This method is used to set the trail particles that the bullet leaves behind,
to init the particles on collision or for other purposes use the init_particles()
"""
func set_trail_particles(enabled: bool, _lifetime_randomness, _new_randomness):
	if enabled: start_particles()
	else: stop_particles()
	
#	self.randomness = new_randomness
#	self.particle_process_material.lifetime_randomness = lifetime_randomness

func stop_particles():
	emitting = false

func set_particles_direction(to: Vector3):
	process_material.direction = to

func set_particle_lifetime(new_lifetime: float):
	self.lifetime = new_lifetime
