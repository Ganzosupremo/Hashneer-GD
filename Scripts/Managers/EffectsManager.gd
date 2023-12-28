extends Node2D

signal spawn_effect(effect: PackedScene, transform_effect: Transform2D)

@export var explosion_effect: PackedScene = preload("res://Scenes/VFX/Explosion_hit_effect.tscn")
@onready var effect_scene: PackedScene = preload("res://Scenes/WeaponSystem/bullet_particles.tscn")


var current_effect

func _ready():
	spawn_effect.connect(Callable(self, "on_spawn_effect"))

func on_spawn_effect(effect: PackedScene, other_transform: Transform2D):
	var effect_ins: GPUParticles2D = effect.instantiate()
	add_child(effect_ins)
	effect_ins.transform = other_transform

func spawn_collision_effect(data: ParticleEffectDetails, at_transform: Transform2D):
	var ins = effect_scene.instantiate()
	current_effect = ins
	ins.init_particles(data)
	ins.transform = at_transform
	ins.start_particles()
	return ins
	

func spawn_explosion_effect(at_transform: Transform2D, _data: ParticleEffectDetails = null) -> GPUParticles2D:
	var explosion_ins = explosion_effect.instantiate()
	current_effect = explosion_ins
	add_child(explosion_ins)
	explosion_ins.transform = at_transform
	
	return explosion_ins
