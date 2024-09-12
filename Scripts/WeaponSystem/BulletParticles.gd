extends GPUParticles2D
class_name EffectParticles

@onready var _timer: Timer = %Timer

func _ready() -> void:
	emitting = false

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
	_timer.start(lifetime)
	emitting = true

"""
This method is used to set the trail particles that the bullet leaves behind,
to init the particles on collision or for other purposes use the init_particles()
"""
func set_trail_particles(enabled: bool, _lifetime_randomness, _new_randomness):
	if enabled: start_particles()
	else: stop_particles()


func stop_particles():
	emitting = false

func set_particles_direction(to: Vector3):
	process_material.direction = to

func set_particle_lifetime(new_lifetime: float):
	self.lifetime = new_lifetime

func _on_timer_timeout() -> void:
	stop_particles()
