extends Resource
class_name QuadrantBuilderArgs

var quadrant_size: int
var grid_size: Vector2
var quadrant_texture: Texture2D
var hit_sound: SoundEffectDetails

var initial_health: float
var drop_rate_multiplier: float
var level_index: int

var block_core_cuts_delaunay: int
var block_core_cut_min_area: float

func _init() -> void:
	quadrant_size = 0
	grid_size = Vector2.ZERO
	quadrant_texture = null
	initial_health = 0.0
	drop_rate_multiplier = 0.0
	level_index = -1
	block_core_cuts_delaunay = 100
	block_core_cut_min_area = 50.0

func get_initial_quadrant_health() -> float:
	return initial_health
