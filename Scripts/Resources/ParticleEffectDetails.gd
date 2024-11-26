extends Resource
class_name ParticleEffectDetails

@export_category("Base Params")
@export var amount: int = 50
@export_range(0.01, 2.0) var lifetime: float = 1.0
@export var one_shot: bool = false
@export_range(1.0, 10.0) var speed_scale: float = 1.0
@export_range(0.0, 1.0) var explosiveness: float = 0.0
"""Emission lifetime randomness ratio"""
@export_range(0.0, 1.0) var randomness: float = 0.5
@export var particle_texture: Texture2D

@export var process_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
