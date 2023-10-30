extends Node2D

signal spawn_effect(effect: PackedScene, transform_effect: Transform2D)

@export var explosion_effect: PackedScene = preload("res://Scenes/VFX/Explosion_hit_effect.tscn")

var current_effect: GPUParticles2D

func _ready():
	spawn_effect.connect(Callable(self, "on_spawn_effect"))

func on_spawn_effect(effect: PackedScene, other_transform: Transform2D):
	var effect_ins: GPUParticles2D = effect.instantiate()
	add_child(effect_ins)
	effect_ins.transform = other_transform

func spawn_explosion_effect(at_transform: Transform2D):
	var explosion_ins: GPUParticles2D = explosion_effect.instantiate()
	current_effect = explosion_ins
	add_child(explosion_ins)
	explosion_ins.transform = at_transform
