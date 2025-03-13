extends Resource
class_name QuadrantBuilderArgs

@export var debug_name: String = ""
@export var quadrant_size: int = 200
@export var grid_size: Vector2 = Vector2(6, 6)
@export var quadrant_texture: Texture2D
@export var hit_sound: SoundEffectDetails

@export var initial_health: float = 50.0
@export var fiat_drop_rate_factor: float = 1.0
@export var level_index: int = 0

@export var block_core_cuts_delaunay: int = 200
@export var block_core_cut_min_area: float = 100.0

func _init() -> void:
	quadrant_size = 0
	grid_size = Vector2.ZERO
	quadrant_texture = null
	initial_health = 0.0
	fiat_drop_rate_factor = 0.0
	level_index = -1
	block_core_cuts_delaunay = 100
	block_core_cut_min_area = 50.0

func get_initial_quadrant_health() -> float:
	return initial_health
